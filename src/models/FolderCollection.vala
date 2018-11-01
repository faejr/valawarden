using Gee;

namespace App.Models {
    public class FolderCollection : HashMap<string ? , Folder>{
        public FolderCollection () {
            base ();
            var folder = new Folder ();
            folder.id = null;
            folder.name = _ ("No folder");
            add (folder);
        }

        public void add (Folder folder) {
            this.set (folder.id, folder);
        }
    }
}