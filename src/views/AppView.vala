/*
 * Copyright (C) 2018  Daniel Liljeberg <liljebergxyz@protonmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

using App.Configs;
using App.Widgets;

namespace App.Views {

    /**
     * The {@code AppView} class.
     *
     * @since 1.0.0
     */
    public class AppView : Gtk.Box {

        private Gtk.Paned main_panel;
        private Gtk.Paned child_panel;
        private Sidebar sidebar;

        private Gtk.Grid grid;
        private Gtk.Entry password_entry;
        private Gtk.Button login_button;
        private Json.Object ? sync_data;

        /**
         * Constructs a new {@code AppView} object.
         */
        public AppView () {
            main_panel = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
            child_panel = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
            sidebar = new Sidebar ();

            main_panel.pack1 (sidebar, false, false);
            main_panel.pack2 (child_panel, true, false);
            child_panel.pack1 (CipherList.get_instance (), false, false);
            child_panel.pack2 (CipherPage.get_instance (), true, false);
            main_panel.position = (150);

            if (App.Api.get_instance ().encryption_key == null) {
                password_entry = new Gtk.Entry ();
                password_entry.set_visibility (false);
                login_button = new Gtk.Button.with_label (_ ("Unlock"));
                login_button.halign = Gtk.Align.CENTER;
                login_button.clicked.connect (on_login_clicked);

                grid = new Gtk.Grid ();
                grid.column_spacing = 12;
                grid.row_spacing = 6;
                grid.hexpand = true;
                grid.halign = Gtk.Align.CENTER;
                grid.attach (new AlignedLabel (_ ("Password:")), 0, 0);
                grid.attach (password_entry, 1, 0);
                grid.attach (login_button, 1, 1);
                this.set_center_widget (grid);
            } else {
                this.add (main_panel);
            }
        }

        private async void on_login_clicked () {
            var api = App.Api.get_instance ();
            if (yield api.unlock (password_entry.text)) {
                this.remove (grid);
                this.add (main_panel);
                sidebar.setup_folders ();
                main_panel.show_all ();
            }
        }
    }
}
