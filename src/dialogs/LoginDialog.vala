using Gtk;
using App.Configs;
using App.Widgets;

namespace App.Dialogs {
    public class LoginDialog : Gtk.Dialog {

        private static LoginDialog dialog;

        private Gtk.Window main_window;
        private App.Views.AppView app_view;

        private Gtk.Grid grid;
        private Gtk.Button login_button;
        private Gtk.Image logo;
        private Gtk.Entry instance_entry;
        private Gtk.Entry email_entry;
        private Gtk.Entry password_entry;
        private AlignedLabel two_factor_label;
        private Gtk.Entry two_factor_entry;
        private Gtk.Label error_label;

        public LoginDialog (Gtk.Window window, App.Views.AppView app_view) {
            Object (
                border_width: 6,
                deletable: true,
                resizable: false,
                title: _ ("Login"),
                transient_for: window
                );

            main_window = window;
            this.app_view = app_view;

            logo = new Image.from_resource ("/com/github/liljebergxyz/valawarden/images/logo128");
            logo.halign = Gtk.Align.CENTER;
            logo.hexpand = true;
            logo.margin_bottom = 24;

            error_label = new Label ("");
            error_label.hide ();

            instance_entry = new Entry ();
            instance_entry.text = App.Configs.Constants.BITWARDEN_BASE_URL;

            email_entry = new Entry ();

            password_entry = new Entry ();
            password_entry.set_visibility (false);

            two_factor_label = new AlignedLabel (_ ("OTP Code:"));
            two_factor_entry = new Entry ();

            login_button = new Gtk.Button.with_label (_ ("Login"));
            login_button.clicked.connect (on_login_clicked);
            login_button.halign = Gtk.Align.END;
            login_button.margin_top = 24;

            grid = new Gtk.Grid ();
            grid.column_spacing = 12;
            grid.row_spacing = 6;
            grid.hexpand = true;
            grid.halign = Gtk.Align.CENTER;
            grid.attach (logo, 0, 0, 2, 1);
            grid.attach (new AlignedLabel (_ ("Base url:")), 0, 1);
            grid.attach (instance_entry, 1, 1);
            grid.attach (new AlignedLabel (_ ("Email:")), 0, 2);
            grid.attach (email_entry, 1, 2);
            grid.attach (new AlignedLabel (_ ("Password:")), 0, 3);
            grid.attach (password_entry, 1, 3);
            grid.attach (two_factor_label, 0, 4);
            grid.attach (two_factor_entry, 1, 4);
            grid.attach (error_label, 0, 9, 2, 1);
            grid.attach (login_button, 1, 10);

            var content = get_content_area () as Gtk.Box;
            content.pack_start (grid, false, false, 0);

            show_all ();
            clear ();
        }

        private void clear () {
            password_entry.text = "";
            two_factor_entry.hide ();
            two_factor_label.hide ();
        }

        private void on_login_clicked () {
            string instance = instance_entry.text;
            string email = email_entry.text;
            string password = password_entry.text;

            var bitwarden = App.Bitwarden.get_instance ();
            App.Models.ErrorObject result;
            if (two_factor_entry.text != "") {
                result = bitwarden.login (email, password, 0, two_factor_entry.text);
            } else {
                result = bitwarden.login (email, password);
            }
            if (result.error != null) {
                error_label.label = _ (result.error_description);
                switch (result.error) {
                case "two_factor_required":
                    two_factor_label.show ();
                    two_factor_entry.show ();
                    break;
                case "invalid_grant":
                    switch (result.error_description) {
                    case "invalid_username_or_password":
                        error_label.label = _ ("Invalid username or password");
                        break;
                    }
                    break;
                }
                stdout.printf ("%s\n".printf (result.error));
            } else {
                App.Bitwarden.get_instance ().sync ();
                error_label.hide ();
                main_window.show_all ();
                app_view.activate ();
                destroy ();
            }
        }

        public static void open (Gtk.Window window, App.Views.AppView app_view) {
            if (dialog == null)
                dialog = new LoginDialog (window, app_view);
        }
    }
}