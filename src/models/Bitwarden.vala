using App.Configs;
using App.Models;
using App.Utils;
using GCrypt;

namespace App {
    public class Bitwarden {
        private const int TOTP_TFA_ID = 0;
        private Soup.SessionAsync session;
        private string valawarden_dir;
        private string sync_data_file = "sync-data.json";
        public uint8[] encryption_key;

        public Bitwarden () {
            session = new Soup.SessionAsync ();
            session.user_agent = "%s/%s".printf (Constants.BITWARDEN_USER_AGENT, Constants.VERSION);

            valawarden_dir = GLib.Environment.get_user_data_dir () + "/valawarden/";
            DirUtils.create_with_parents (valawarden_dir, 0766);
        }

        public ErrorObject login (string email, string password, int ? two_factor_provider = null, string ? two_factor_token = null, bool two_factor_remember = true) {
            var url = "%s/connect/token".printf (Constants.BITWARDEN_IDENTITY_URL);
            HashTable<string, string> form_data = new HashTable<string, string>(str_hash, str_equal);
            var settings = App.Configs.Settings.get_instance ();
            form_data.insert ("grant_type", "password");
            form_data.insert ("username", email);
            form_data.insert ("password", hash_password (password, email));
            form_data.insert ("scope", "api offline_access");
            form_data.insert ("client_id", Constants.BITWARDEN_CLIENT_ID);
            form_data.insert ("deviceType", "3");
            form_data.insert ("deviceIdentifier", settings.device_identifier);
            form_data.insert ("deviceName", "firefox");
            form_data.insert ("devicePushToken", "");
            if (two_factor_provider != null && two_factor_token != null) {
                form_data.insert ("twoFactorProvider", two_factor_provider.to_string ());
                form_data.insert ("twoFactorToken", two_factor_token);
                form_data.insert ("twoFactorRemember", two_factor_remember.to_string ());
            }

            Soup.Message message = Soup.Form.request_new_from_hash ("POST", url, form_data);

            var parser = make_request (message);

            var root_object = parser.get_root ().get_object ();
            ErrorObject error_object = check_login_response (root_object);
            if (error_object.error != "") {
                return error_object;
            }

            if (root_object.has_member ("access_token")
                && root_object.has_member ("refresh_token")
                && root_object.has_member ("expires_in")
                ) {
                parse_token (root_object);
            }

            if (root_object.has_member ("Key")) {
                var key = root_object.get_string_member ("Key");
                encryption_key = decrypted_key (key, email, password);
            }

            return error_object;
        }

        private ErrorObject check_login_response (Json.Object root_object) {
            var error_object = new ErrorObject ();
            var error = root_object.get_string_member ("error");
            if (error != null) {
                error_object.error = error;
                error_object.error_description = root_object.get_string_member ("error_description");
                var tfa_providers = root_object.get_array_member ("TwoFactorProviders");
                if (tfa_providers != null) {
                    bool supported_tfa_found = false;
                    for (int i = 0; i < tfa_providers.get_length (); i++) {
                        if (tfa_providers.get_int_element (i) == TOTP_TFA_ID) {
                            supported_tfa_found = true;
                        }
                    }

                    if (supported_tfa_found) {
                        error_object.error = "two_factor_required";
                    } else {
                        error_object.error_description = _ ("No supported two factor provider found");
                    }
                }

                return error_object;
            }

            return error_object;
        }

        public async bool unlock (string password) {
            var parser = new Json.Parser ();
            File file = File.new_for_path (valawarden_dir + sync_data_file);
            FileInputStream stream = yield file.read_async ();

            yield parser.load_from_stream_async (stream);

            var root_object = parser.get_root ().get_object ();
            if (!root_object.has_member ("Profile")) {
                return false;
            }
            var profile = root_object.get_object_member ("Profile");
            if (!profile.has_member ("Key")) {
                return false;
            }
            var key = profile.get_string_member ("Key");
            var email = profile.get_string_member ("Email");
            try {
                encryption_key = decrypted_key (key, email, password);
                return true;
            } catch (GLib.Error e) {
                return false;
            }

            return false;
        }

        public Json.Object ? sync () {
            if (!NetworkUtils.check_internet_connectivity ()) {
                return get_sync_data ();
            }
            var settings = App.Configs.Settings.get_instance ();
            var expiry_time = new DateTime.from_unix_utc (settings.expiry_time);
            var current_time = new DateTime.now_utc ();
            if (current_time.compare (expiry_time) >= 0) {
                refresh_token ();
            }

            var url = "%s/sync".printf (Constants.BITWARDEN_BASE_URL);
            Soup.Message message = new Soup.Message ("GET", url);
            var access_token = settings.access_token;
            if (access_token != null) {
                message.request_headers.append ("Authorization", "Bearer %s".printf (access_token));
            }

            var parser = make_request (message);

            settings.last_sync = current_time.to_unix ();
            FileUtils.set_contents (valawarden_dir + sync_data_file, Json.to_string (parser.get_root (), false));

            return parser.get_root ().get_object ();
        }

        public Json.Object ? get_sync_data () {
            var parser = new Json.Parser ();
            parser.load_from_file (valawarden_dir + sync_data_file);

            return parser.get_root ().get_object ();
        }

        private void refresh_token () {
            var url = "%s/connect/token".printf (Constants.BITWARDEN_IDENTITY_URL);
            HashTable<string, string> form_data = new HashTable<string, string>(str_hash, str_equal);
            var settings = App.Configs.Settings.get_instance ();
            form_data.insert ("grant_type", "refresh_token");
            form_data.insert ("client_id", Constants.BITWARDEN_CLIENT_ID);
            form_data.insert ("refresh_token", settings.refresh_token);

            Soup.Message message = Soup.Form.request_new_from_hash ("POST", url, form_data);

            var parser = make_request (message);
            var root_object = parser.get_root ().get_object ();
            parse_token (root_object);
        }

        private void parse_token (Json.Object object) {
            var settings = App.Configs.Settings.get_instance ();
            var access_token = object.get_string_member ("access_token");
            var refresh_token = object.get_string_member ("refresh_token");
            var expires_in = object.get_int_member ("expires_in");
            settings.access_token = access_token;
            settings.refresh_token = refresh_token;
            var expiry_time = new DateTime.now_utc ();
            expiry_time.add_seconds (expires_in);
            settings.expiry_time = expiry_time.to_unix ();
        }

        private uint8[] decrypted_key (string encrypted_key, string email, string password) {
            var key = make_key (password.data, email.down ().data, 5000);

            return decrypt_string (encrypted_key, key)[0 : 64];
        }

        private string hash_password (string password, string email, ulong iterations = 5000) {
            var key = make_key (password.data, email.data, iterations);

            return Base64.encode (make_key (key, password.data, 1));
        }

        private uint8[] make_key (uint8[] data, uint8[] salt, ulong iterations = 5000) {
            uint8 keybuffer[256 / 8];
            KeyDerivation.derive (data, KeyDerivation.Algorithm.PBKDF2, Hash.Algorithm.SHA256, salt, iterations, keybuffer);

            return keybuffer;
        }

        // TODO: Verify that this works
        private string make_enc_key (uint8[] key) {
            var pt = GCrypt.Random.random_bytes (64);
            var iv = GCrypt.Random.random_bytes (16);

            GCrypt.Cipher.Cipher cipher;
            GCrypt.Cipher.Cipher.open (out cipher, GCrypt.Cipher.Algorithm.AES256, GCrypt.Cipher.Mode.CBC, GCrypt.Cipher.Flag.SECURE);
            cipher.set_key (pt);
            cipher.set_iv (iv);
            uchar[] out_buffer = null;
            cipher.encrypt (out_buffer, key);

            return compose_encrypted_string (0, iv, out_buffer);
        }

        // TODO: Verify that this works
        private string compose_encrypted_string (int enc_type, uint8[] iv, uchar[] ct, uchar[] ? mac = null) {
            string outMac = null;
            if (mac != null) {
                outMac = Base64.encode (mac);
            }
            string[] v = { "%d.%s".printf (enc_type, Base64.encode (iv)), Base64.encode (ct), outMac };

            return string.join ("|", v);
        }

        // https://github.com/bitwarden/mobile/blob/1ec31c6899fd9ec6d86738986c75720ec490880f/src/App/Services/CryptoService.cs#L92
        public uint8[] decrypt_string (string encrypted_string, owned uint8[] key, owned uint8[] ? mac_key = null) {
            string[] split_string = encrypted_string.substring (2, -1).split ("|");
            var type = int.parse (encrypted_string.substring (0, 1));
            var iv = Base64.decode (split_string[0]);
            var ct = Base64.decode (split_string[1]);
            uint8[] mac = null;
            if (split_string.length > 2) {
                mac = Base64.decode (split_string[2]);
            }
            if (type == 2 && key.length == 32) {
                key = Crypto.stretch_key (key);
            }
            if (mac_key == null) {
                mac_key = key[key.length / 2 : key.length];
                key = key[0 : key.length / 2];
            }

            if (type != 0 && type != 2) {
                stderr.printf ("Type %d is not implemented", type);
            }
            if (type == 2) {
                if (mac == null) {
                    throw new GLib.Error.literal (Quark.from_string (""), -1, "mac required");
                }

                var macData = new ByteArray ();
                macData.append (iv);
                macData.append (ct);
                var cmac = Crypto.hmac (GLib.ChecksumType.SHA256, mac_key, macData.data);
                cmac = Crypto.trim_end (cmac);
                cmac = Crypto.trim_end (cmac);
                if (!Crypto.macs_equal (mac, cmac)) {
                    throw new GLib.Error.literal (Quark.from_string (""), -1, "mac is invalid");
                }
            }

            GCrypt.Cipher.Cipher cipher;
            GCrypt.Cipher.Cipher.open (out cipher, GCrypt.Cipher.Algorithm.AES256, GCrypt.Cipher.Mode.CBC, GCrypt.Cipher.Flag.SECURE);
            cipher.set_key (key);
            cipher.set_iv (iv);
            uint8[] out_buffer = new uint8[ct.length];
            cipher.decrypt (out_buffer, ct);

            return Crypto.add_terminating_zero (Crypto.remove_padding (out_buffer));
        }

        private Json.Parser make_request (Soup.Message message) {
            session.send_message (message);

            var parser = new Json.Parser ();

            try {
                parser.load_from_data ((string) message.response_body.data, -1);
            } catch (GLib.Error e) {
                stderr.printf ("I think something went wrong!\n");
            }

            return parser;
        }

        public async uint8[] ? download_icon (string url) {
            var icon_url = Constants.BITWARDEN_ICONS_URL + "/" + url + "/icon.png";

            stdout.printf ("Looking for: %s\n", valawarden_dir + "icons/" + Crypto.md5_string (url) + ".png");
            var icon_file = File.new_for_path (valawarden_dir + "icons/" + Crypto.md5_string (url) + ".png");
            if (icon_file.query_exists ()) {
                string etag;
                var icon = yield icon_file.load_bytes_async (null, out etag);

                // Check if icon is newer than 7 days
                if (((GLib.get_real_time () / 1000000) - int64.parse (etag.split (":")[0])) / 1440000 < 7) {
                    return icon.get_data ();
                }
            }

            var message = new Soup.Message ("GET", icon_url);
            var stream = yield session.send_async (message);
            var data = yield Utils.IO.input_stream_to_array(stream);

            yield icon_file.replace_contents_async(data, null, false, FileCreateFlags.NONE, null, null);

            return data;
        }

        private static Bitwarden ? instance;

        public static unowned Bitwarden get_instance () {
            if (instance == null) {
                instance = new Bitwarden ();
            }

            return instance;
        }
    }
}
