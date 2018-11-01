using Gtk;
using App.Configs;

namespace App.Widgets {
    public class EntryWithLabel : Gtk.Grid {
        public AlignedLabel label;
        public Entry entry;

        public EntryWithLabel (string text, Gtk.Align aligned = Gtk.Align.END) {
            orientation = Gtk.Orientation.VERTICAL;

            label = new AlignedLabel (text, aligned);
            entry = new Entry ();

            add (label);
            add (entry);
        }

        public int width_chars {
            get {
                return entry.width_chars;
            } set {
                entry.width_chars = value;
            }
        }

        public string text {
            get {
                return entry.text;
            } set {
                entry.text = value;
            }
        }
    }
}