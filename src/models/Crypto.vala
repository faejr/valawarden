using App.Configs;
using App.Models;
using GCrypt;

namespace App {
    public class Crypto {
        // Modified from https://stackoverflow.com/a/9722957
        public static uint8[] hmac (ChecksumType type, uint8[] key, uint8[] data) {
            int block_size = 64;
            switch (type) {
            case ChecksumType.MD5:
            case ChecksumType.SHA1:
                block_size = 64; /* RFC 2104 */
                break;
            case ChecksumType.SHA256:
                block_size = 64; /* RFC draft-kelly-ipsec-ciph-sha2-01 */
                break;
            }

            uint8[] buffer = key;
            if (key.length > block_size) {
                buffer = Checksum.compute_for_data (type, key).data;
            }
            buffer.resize (block_size);

            Checksum inner = new Checksum (type);
            Checksum outer = new Checksum (type);

            uint8[] padding = new uint8[block_size];
            for (int i = 0; i < block_size; i++) {
                padding[i] = 0x36 ^ buffer[i];
            }
            inner.update (padding, padding.length);
            for (int i = 0; i < block_size; i++) {
                padding[i] = 0x5c ^ buffer[i];
            }
            outer.update (padding, padding.length);

            size_t length = buffer.length;
            inner.update (data, data.length);
            inner.get_digest (buffer, ref length);

            outer.update (buffer, length);

            outer.get_digest (buffer, ref length);
            return buffer;
        }

        public static uint8[] stretch_key (uint8[] key) {
            var newKey = new ByteArray ();
            var encKey = hkdf_expand (key, "enc".data, 32);
            var macKey = hkdf_expand (key, "mac".data, 32);
            newKey.append (trim_end (encKey));
            newKey.append (trim_end (macKey));

            return newKey.data;
        }

        private static uint8[] hkdf_expand (uint8[] key, uint8[] info, uint size) {
            var hashLen = 32; // sha256
            var okm = new ByteArray ();
            var previousT = new uint8[0];
            var n = Math.ceil (size / hashLen);
            for (var i = 0; i < n; i++) {
                var t = new ByteArray ();
                t.append (previousT);
                t.append (info);
                uint8[] byte = { i + 1 };
                t.append (byte);
                previousT = Crypto.hmac (GLib.ChecksumType.SHA256, key, t.data);
                okm.append (previousT);
            }

            return okm.data;
        }

        public static uint8[] trim_end (uint8[] array) {
            var i = array.length;
            while (array[i] == 0) {
                i--;
            }

            i--;
            i |= i >> 1;
            i |= i >> 2;
            i |= i >> 4;
            i |= i >> 8;
            i |= i >> 16;
            i++;

            return array[0 : i];
        }

        public static bool macs_equal (uint8[] mac1, uint8[] mac2) {
            for (var i = 0; i < mac2.length; i++) {
                if (mac1[i] != mac2[i]) {
                    return false;
                }
            }

            return true;
        }

        public static uint8[] remove_padding (uint8[] buffer) {
            // Padding length is last character in buffer
            var last_char = buffer[buffer.length - 1];
            for (var i = 1; i <= last_char; ++i) {
                if (buffer[buffer.length - i] != last_char) {
                    throw new GLib.Error.literal (Quark.from_string (""), -1, "Buffer padding is invalid");
                }
            }

            return buffer[0 : buffer.length - last_char];
        }

        public static uint8[] add_terminating_zero (uint8[] buffer) {
            buffer.resize (buffer.length + 1);
            buffer[buffer.length - 1] = 0;

            return buffer;
        }
    }
}
