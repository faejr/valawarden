using App.Configs;
using App.Models;
using Gee;

namespace App.Widgets {
    public class Sidebar : Granite.Widgets.SourceList {
        private static Granite.Widgets.SourceList.ExpandableItem folders_parent;
        private FolderCollection folders;
        private Folder all_items;

        public Sidebar () {
            connect_signals ();

            all_items = new Folder ();
            all_items.id = "all-items";
            all_items.name = _ ("All items");
            folders_parent = new Granite.Widgets.SourceList.ExpandableItem (_ ("Folders"));
            folders_parent.expanded = true;

            root.add (folders_parent);
            folders_parent.add (all_items);
        }

        private void connect_signals () {
            item_selected.connect ((item) => {
                if (item != null && item is Folder) {
                    Folder folder = (Folder) item;
                    var ciphers = folder.get_ciphers ();
                    CipherList.get_instance ().load_ciphers (ciphers);
                }
            });
        }

        public void setup_folders () {
            var bitwarden = App.Bitwarden.get_instance ();
            var sync_data = bitwarden.sync ();
            var folders_obj = sync_data.get_array_member ("Folders");
            parse_folders (folders_obj);

            var ciphers = sync_data.get_array_member ("Ciphers");
            parse_ciphers (ciphers);

            foreach (Folder folder in folders.values) {
                folders_parent.add (folder);
            }

            if (selected == null) {
                selected = all_items;
                item_selected (all_items);
                var listbox = CipherList.get_instance ().listbox;
                listbox.select_row (listbox.get_row_at_index (0));
            }
        }

        private void parse_folders (Json.Array ? folders_obj) {
            var bitwarden = App.Bitwarden.get_instance ();
            folders = new FolderCollection ();
            folders_obj.foreach_element ((array, index, node) => {
                var object = node.get_object ();

                var folder = new Folder ();
                folder.id = object.get_string_member ("Id");
                folder.name = (string) (bitwarden.decrypt_string (object.get_string_member ("Name"), bitwarden.encryption_key));
                folders.add (folder);
            });
        }

        private void parse_ciphers (Json.Array ? ciphers) {
            var bitwarden = App.Bitwarden.get_instance ();
            ciphers.foreach_element ((array, index, node) => {
                var object = node.get_object ();
                var login = object.get_object_member ("Login");

                var cipher = new Cipher ();
                cipher.name = (string) (bitwarden.decrypt_string (object.get_string_member ("Name"), bitwarden.encryption_key));
                cipher.username = (string) (bitwarden.decrypt_string (login.get_string_member ("Username"), bitwarden.encryption_key));
                cipher.password = (string) (bitwarden.decrypt_string (login.get_string_member ("Password"), bitwarden.encryption_key));
                cipher.uri = (string) (bitwarden.decrypt_string (login.get_string_member ("Uri"), bitwarden.encryption_key));
                string totp;
                if ((totp = login.get_string_member ("Totp")) != null) {
                    cipher.totp = (string) (bitwarden.decrypt_string (totp, bitwarden.encryption_key));
                }

                var folderId = object.get_string_member ("FolderId");
                var folder = folders.get (folderId);
                if (folder != null) {
                    folder.add_cipher (cipher);
                    all_items.add_cipher (cipher);
                }
            });
        }
    }
}
