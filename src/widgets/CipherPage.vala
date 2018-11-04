using App.Configs;
using App.Models;
using App.Widgets;
using Gee;

namespace App.Widgets {
    public class CipherPage : Gtk.Box {
        private Gtk.Box user_grid;
        private Gtk.Box notes_panel;

        private CipherHeader cipher_header;
        private AlignedLabel name_label;
        private EntryWithLabel username_entry;
        private EntryWithLabel password_entry;
        private EntryWithLabel totp_entry;
        private OTPPanel otp_panel;
        private Gtk.Grid entry_grid;

        private CipherPage () {
            build_ui ();
        }

        private void build_ui () {
            orientation = Gtk.Orientation.VERTICAL;

            var user_grid = new Gtk.Grid ();
            user_grid.column_spacing = 20;
            user_grid.row_spacing = 20;
            user_grid.orientation = Gtk.Orientation.HORIZONTAL;

            cipher_header = new CipherHeader ();
            cipher_header.set_vexpand (false);
            cipher_header.set_hexpand (false);

            entry_grid = new Gtk.Grid ();
            entry_grid.column_spacing = 20;
            entry_grid.row_spacing = 10;
            entry_grid.orientation = Gtk.Orientation.HORIZONTAL;
            entry_grid.get_style_context ().add_class ("entry-grid");

            username_entry = new EntryWithLabel (_ ("Username"), Gtk.Align.START);
            username_entry.entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "edit-copy");
            username_entry.entry.set_hexpand (true);
            username_entry.entry.icon_press.connect ((pos, event) => {
                if (pos == Gtk.EntryIconPosition.SECONDARY) {
                    Gtk.Clipboard clipboard = Gtk.Clipboard.get (Gdk.SELECTION_CLIPBOARD);
                    clipboard.set_text (username_entry.entry.text, -1);
                }
            });

            password_entry = new EntryWithLabel (_ ("Password"), Gtk.Align.START);
            password_entry.entry.set_visibility (false);
            password_entry.entry.set_hexpand (true);

            password_entry.entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "edit-copy");
            password_entry.entry.set_icon_from_icon_name (Gtk.EntryIconPosition.PRIMARY, "system-search");
            password_entry.entry.icon_press.connect ((pos, event) => {
                if (pos == Gtk.EntryIconPosition.PRIMARY) {
                    password_entry.entry.set_visibility (!password_entry.entry.get_visibility ());
                } else if (pos == Gtk.EntryIconPosition.SECONDARY) {
                    Gtk.Clipboard clipboard = Gtk.Clipboard.get (Gdk.SELECTION_CLIPBOARD);
                    clipboard.set_text (password_entry.entry.text, -1);
                }
            });

            totp_entry = new EntryWithLabel (_ ("Authenticator Key (TOTP)"), Gtk.Align.START);
            totp_entry.entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "edit-copy");
            totp_entry.entry.set_hexpand (true);
            totp_entry.entry.icon_press.connect ((pos, event) => {
                if (pos == Gtk.EntryIconPosition.SECONDARY) {
                    Gtk.Clipboard clipboard = Gtk.Clipboard.get (Gdk.SELECTION_CLIPBOARD);
                    clipboard.set_text (totp_entry.entry.text, -1);
                }
            });

            otp_panel = new OTPPanel ();
            otp_panel.hide ();

            user_grid.attach (cipher_header, 0, 0, 1, 1);
            user_grid.attach (entry_grid, 0, 1, 1, 1);
            entry_grid.attach (name_label, 1, 0, 1, 1);
            entry_grid.attach (username_entry, 0, 2, 1, 1);
            // TODO: Insert folder here
            entry_grid.attach (password_entry, 1, 2, 1, 1);
            entry_grid.attach (totp_entry, 0, 3, 1, 1);
            entry_grid.attach (otp_panel, 1, 3, 1, 1);

            add (user_grid);
            margin = 20;
        }

        public void set_cipher (Cipher cipher) {
            cipher_header.set_text (cipher.name);
            username_entry.text = cipher.username;
            password_entry.text = cipher.password;
            password_entry.entry.set_visibility (false);
            totp_entry.text = cipher.totp != null ? cipher.totp : "";
            if (cipher.totp != null) {
                otp_panel.set_key (cipher.totp);
                otp_panel.show ();
            } else {
                otp_panel.hide ();
            }
        }

        private static CipherPage ? instance;

        public static unowned CipherPage get_instance () {
            if (instance == null) {
                instance = new CipherPage ();
            }

            return instance;
        }
    }
}