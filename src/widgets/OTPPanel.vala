using Gtk;
using App.Configs;
using CircularProgressWidgets;

namespace App.Widgets {
    public class OTPPanel : Gtk.Grid {
        private AlignedLabel code_label;
        private CircularProgressBar progressBar;
        private Totp totp;

        private int timestep;
        private int64 timePassed;

        public OTPPanel () {
            orientation = Gtk.Orientation.VERTICAL;
            column_homogeneous = false;
            set_vexpand (false);
            set_hexpand (false);
            margin_top = 14;

            timestep = 30;
            GLib.Timeout.add_seconds (1, timer);

            code_label = new AlignedLabel ("", Gtk.Align.START);
            code_label.get_style_context ().add_class ("code-label");

            progressBar = new CircularProgressBar ();
            progressBar.line_width = 2;
            progressBar.max_value = timestep;
            progressBar.percentage = 1.0 - ((timePassed % timestep) * (1.0 / (double) timestep));
            progressBar.width_request = 25;
            progressBar.height_request = 25;

            attach (code_label, 1, 0, 1, 1);
            attach (progressBar, 0, 0, 1, 1);
        }

        private bool timer () {
            timePassed = GLib.get_real_time () / Totp.MICROSECONDS_TO_SECONDS;
            if (timePassed % timestep == 0) {
                code_label.label = totp.generate ();
            }
            progressBar.percentage = 1.0 - ((timePassed % timestep) * (1.0 / (double) timestep));

            return true;
        }

        public void set_key (string key) {
            totp = new Totp (key);
            code_label.label = totp.generate ();
        }
    }
}