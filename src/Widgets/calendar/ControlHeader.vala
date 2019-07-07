/*
 * Copyright (c) 2011-2016 elementary LLC. (https://elementary.io)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA.
 */


namespace DateTime.Widgets {
    public class ControlHeader : Gtk.Grid {
        public signal void left_clicked ();
        public signal void right_clicked ();
        public signal void center_clicked ();

        public ControlHeader () {
            Object (orientation : Gtk.Orientation.HORIZONTAL);
        }

        construct {
            string style = """
                .header-label {
                    font-family: "Raleway", sans;
                    font-weight: 300;
                    font-size: 1.66em;
                }
            """;

            var provider = new Gtk.CssProvider ();
            try {
                provider.load_from_data (style, style.length);
                Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            } catch (Error e) {
                critical (e.message);
            }

            var label = new Gtk.Label (new GLib.DateTime.now_local ().format (_("%OB, %Y")));
            label.get_style_context ().add_class ("header-label");
            label.xalign = 0;
            label.width_chars = 13;

            var left_button = new Gtk.Button.from_icon_name ("pan-start-symbolic");
            var center_button = new Gtk.Button.from_icon_name ("office-calendar-symbolic");
            center_button.tooltip_text = _("Go to today's date");
            var right_button = new Gtk.Button.from_icon_name ("pan-end-symbolic");

            var box_label = new Gtk.Grid ();
            box_label.halign = Gtk.Align.START;
            box_label.valign = Gtk.Align.CENTER;
            box_label.add (label);

            var box_buttons = new Gtk.Grid ();
            box_buttons.halign = Gtk.Align.END;
            box_buttons.valign = Gtk.Align.CENTER;
            box_buttons.add (left_button);
            box_buttons.add (center_button);
            box_buttons.add (right_button);

            // XXX: Remove when GTK 4 Constraints lands on elementary
            var dummy_spacer = new Gtk.Grid ();
            dummy_spacer.hexpand = true;

            CalendarModel.get_default ().parameters_changed.connect (() => {
                var date = CalendarModel.get_default ().month_start;
                label.set_label (date.format (_("%OB, %Y")));
            });

            var grid = new Gtk.Grid ();
            grid.column_spacing = 6;
            grid.margin_start = 9;
            grid.margin_end = 9;
            grid.margin_top = 6;
            grid.attach (box_label, 0, 0, 1, 1);
            grid.attach (dummy_spacer, 1, 0, 1, 1);
            grid.attach (box_buttons, 2, 0, 1, 1);

            left_button.clicked.connect (() => {
                left_clicked ();
            });

            right_button.clicked.connect (() => {
                right_clicked ();
            });

            center_button.clicked.connect (() => {
                center_clicked ();
            });

            add (grid);
            get_style_context ().add_class ("linked");
            set_size_request (-1, 30);
        }
    }
}
