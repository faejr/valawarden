using App.Configs;
using App.Models;
using Gee;

namespace App.Widgets {
    public class CipherItem : Gtk.ListBoxRow {
        public Cipher cipher { get; set; }

        private Gtk.Grid grid;
        private Gtk.Image img;
        private AlignedLabel line1;
        private AlignedLabel line2;

        public CipherItem (Cipher cipher) {
            Object (cipher: cipher);
            build_ui ();
        }

        private void build_ui () {
            set_activatable (true);

            grid = new Gtk.Grid ();
            grid.orientation = Gtk.Orientation.VERTICAL;
            grid.column_homogeneous = false;

            img = new Gtk.Image.from_icon_name ("image-missing", Gtk.IconSize.LARGE_TOOLBAR);
            img.margin_left = 8;
            img.valign = Gtk.Align.CENTER;

            line1 = new AlignedLabel ("", Gtk.Align.START);
            line1.get_style_context ().add_class ("h3");
            line1.ellipsize = Pango.EllipsizeMode.END;
            line1.margin_top = 4;
            line1.margin_left = 8;
            line1.margin_right = 8;
            line1.margin_bottom = 0;
            line1.set_vexpand (true);
            line1.set_hexpand (true);

            line2 = new AlignedLabel ("", Gtk.Align.START);
            line2.margin_top = 0;
            line2.margin_left = 8;
            line2.margin_right = 8;
            line2.margin_bottom = 4;
            line2.ellipsize = Pango.EllipsizeMode.END;
            line2.set_vexpand (true);
            line2.set_hexpand (true);
            line2.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

            var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
            separator.hexpand = true;

            add (grid);
            grid.attach (img, 0, 0, 1, 2);
            grid.attach (line1, 1, 0, 1, 1);
            grid.attach (line2, 1, 1, 1, 1);
            grid.attach (separator, 0, 10, 2, 1);

            load_data ();
            show_all ();
        }

        public void load_data () {
            line2.label = _cipher.username;
            line1.label = _cipher.name;
        }
    }
}