using Gee;

namespace App.Models {
    public class Folder : Granite.Widgets.SourceList.ExpandableItem {
        private ArrayList<Cipher> _ciphers;

        public string ? id { get; set; }

        public Folder (string name = "") {
            base (name);
            _ciphers = new ArrayList<Cipher>();
        }

        public ArrayList<Cipher> get_ciphers () {
            return _ciphers;
        }

        public void add_cipher (Cipher cipher) {
            _ciphers.add (cipher);
        }

        public bool remove_cipher (Cipher cipher) {
            return _ciphers.remove (cipher);
        }
    }
}
