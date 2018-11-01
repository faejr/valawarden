namespace App.Models {
    public class Cipher {
        public string id { get; set; }
        public string name { get; set; }
        public string username { get; set; }
        public string password { get; set; }
        public string uri { get; set; }
        public string totp { get; set; }
    }
}
