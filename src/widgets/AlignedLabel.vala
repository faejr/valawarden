using Gtk;
using App.Configs;

namespace App.Widgets {
    public class AlignedLabel : Gtk.Label {

        public AlignedLabel (string text, Gtk.Align alignment = Gtk.Align.END) {
            label = text;
            halign = alignment;
        }
    }
}