using Gtk;
using App.Configs;

namespace App.Widgets {
    public class CipherHeader : Gtk.Grid {
        private Gtk.Image item_image;
        private Gtk.Entry name_entry;

        public CipherHeader () {
            orientation = Gtk.Orientation.VERTICAL;
            column_homogeneous = false;
            set_vexpand (false);
            set_hexpand (false);

            item_image = new Gtk.Image.from_icon_name ("image-missing", Gtk.IconSize.DIALOG);
            item_image.pixel_size = 64;
            item_image.valign = Gtk.Align.START;

            name_entry = new Gtk.Entry ();
            name_entry.get_style_context ().add_class ("entry-name");
            name_entry.set_vexpand (false);
            name_entry.set_hexpand (true);
            name_entry.margin_left = 10;
            name_entry.focus_out_event.connect ((event) => {
                name_entry.select_region (0, 0);

                return false;
            });

            attach (item_image, 0, 0, 1, 1);
            attach (name_entry, 1, 0, 1, 1);
        }

        public void set_text (string text) {
            name_entry.text = text;
        }
    }
}