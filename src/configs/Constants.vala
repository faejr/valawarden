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

namespace App.Configs {

    /**
     * The {@code Constants} class is responsible for defining all
     * the constants used in the application.
     *
     * @since 1.0.0
     */
    public class Constants {

        public abstract const string ID = "com.github.liljebergxyz.valawarden";
        public abstract const string VERSION = "0.1.0";
        public abstract const string PROGRAME_NAME = "Valawarden";
        public abstract const string APP_YEARS = "2018";
        public abstract const string APP_ICON = "com.github.liljebergxyz.valawarden";
        public abstract const string ABOUT_COMMENTS = "Unofficial native bitwarden client for elementary OS";
        public abstract const string TRANSLATOR_CREDITS = "Translators";
        public abstract const string MAIN_URL = "https://liljeberg.xyz";
        public abstract const string BUG_URL = "{{ repo-url }}/issues";
        public abstract const string HELP_URL = "{{ repo-url }}/wiki";
        public abstract const string TRANSLATE_URL = "{{ repo-url }}";
        public abstract const string TEXT_FOR_ABOUT_DIALOG_WEBSITE = "Website";
        public abstract const string TEXT_FOR_ABOUT_DIALOG_WEBSITE_URL = "https://liljeberg.xyz";
        public abstract const string URL_CSS = "/com/github/liljebergxyz/valawarden/css/style.css";
        public abstract const string[] ABOUT_AUTHORS = { "Daniel Liljeberg <liljebergxyz@protonmail.com>" };
        public abstract const Gtk.License ABOUT_LICENSE_TYPE = Gtk.License.GPL_3_0;
        public abstract const string BITWARDEN_USER_AGENT = "Valawarden";
        public abstract const string BITWARDEN_BASE_URL = "https://api.bitwarden.com";
        public abstract const string BITWARDEN_IDENTITY_URL = "https://identity.bitwarden.com";
        public abstract const string BITWARDEN_ICONS_URL = "https://icons.bitwarden.com";
        public abstract const string BITWARDEN_CLIENT_ID = "browser";
    }
}
