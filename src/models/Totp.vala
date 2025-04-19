using GLib;

namespace App {
    /*
     * Bitwarden only supports SHA1 6 digits currently
     */
    class Totp {
        public const int MICROSECONDS_TO_SECONDS = 1000000;
        private uint8[] secret;
        private Hmac hmac;
        private ChecksumType checksumType;
        private int digits = 6;
        private size_t digest_len = 20;

        public Totp (string key = null, GLib.ChecksumType checksum = GLib.ChecksumType.SHA1) {
            if (key != null) {
                secret = base32_decode (key);
            }
            checksumType = checksum;
        }

        public void set_key(string key) {
            secret = base32_decode (key);
        }

        // https://tools.ietf.org/html/rfc6238
        public string generate () {
            hmac = new Hmac (checksumType, secret);
            hmac.update (get_time ());

            uint8[] digest = new uint8[1024];
            hmac.get_digest (digest, ref digest_len);
            var hash = digest[0 : digest_len];
            var offset = hash[hash.length - 1] & 0xf;
            var oneTimePassword = (
                ((hash[offset] & 0x7f) << 24) |
                ((hash[offset + 1] & 0xff) << 16) |
                ((hash[offset + 2] & 0xff) << 8) |
                (hash[offset + 3] & 0xff)
                ) % 1000000;

            var result = oneTimePassword.to_string ();
            while (result.length < digits) {
                result = "0" + result;
            }

            return result;
        }

        private uint8[] get_time (int timestep = 30) {
            var time = (GLib.get_real_time () / MICROSECONDS_TO_SECONDS) / timestep;
            var size = (int) sizeof (int64);
            var result = new uint8[size];
            for (int i = size - 1; i >= 0; i--) {
                result[i] = (uint8) (time & 0xFF);
                time >>= 8;
            }

            return result;
        }

        // https://stackoverflow.com/a/7135008
        private uint8[] base32_decode (owned string input) {
            while (input.has_suffix ("=")) {
                input = input[0 : input.length - 1];
            }

            input = input.ascii_up ();

            int byteCount = input.length * 5 / 8;
            uint8[] returnArray = new uint8[byteCount];
            for (int i = 0; i < byteCount; i++) {
                returnArray += 0x00;
            }

            uint8 curByte = 0, bitsRemaining = 8;
            int mask = 0, arrayIndex = 0;

            for (int i = 0; i < input.length; i++) {
                char c = input[i];
                int cValue = char_to_value (c);

                if (bitsRemaining > 5) {
                    mask = cValue << (bitsRemaining - 5);
                    curByte = (uint8) (curByte | mask);
                    bitsRemaining -= 5;
                } else {
                    mask = cValue >> (5 - bitsRemaining);
                    curByte = (uint8) (curByte | mask);
                    returnArray[arrayIndex++] = curByte;
                    curByte = (uint8) (cValue << (3 + bitsRemaining));
                    bitsRemaining += 3;
                }
            }

            if (arrayIndex != byteCount) {
                returnArray[arrayIndex] = curByte;
            }

            return returnArray;
        }

        private static int char_to_value (char c) {
            int value = (int) c;

            // 65-90 == uppercase letters
            if (value < 91 && value > 64) {
                return value - 65;
            }
            // 50-55 == numbers 2-7
            if (value < 56 && value > 49) {
                return value - 24;
            }
            // 97-122 == lowercase letters
            if (value < 123 && value > 96) {
                return value - 97;
            }

            throw new GLib.Error.literal (Quark.from_string (""), -1, "Character is not a Base32 character.");
        }
    }
}