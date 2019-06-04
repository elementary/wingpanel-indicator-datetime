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
    public class ControlHeader : Gtk.Box {
        public signal void left_clicked ();
        public signal void right_clicked ();
        public signal void center_clicked ();
        public ControlHeader () {
            Object (orientation : Gtk.Orientation.HORIZONTAL);

            var left_button = new Gtk.Button.from_icon_name ("pan-start-symbolic");
            var right_button = new Gtk.Button.from_icon_name ("pan-end-symbolic");
            var center_label = new Gtk.Label (new GLib.DateTime.now_local ().format (_("%OB %Y")));
            var center_button = new Gtk.Button ();
            center_button.set_tooltip_text (_("Go To Current Month…"));

            var stack = new Gtk.Stack ();
            stack.hexpand = true;
            stack.add (center_button);
            stack.add (center_label);

            CalendarModel.get_default ().parameters_changed.connect (() => {
                var date = CalendarModel.get_default ().month_start;
                var curr_date = new GLib.DateTime.now_local ();
                center_button.set_label (date.format (_("%OB %Y")));
                center_label.set_label (curr_date.format (_("%OB %Y")));
                stack.set_visible_child (center_label);
            });

            var box_header = new Gtk.HBox (false, -1);
            box_header.pack_end (right_button, false, false, 0);
            box_header.pack_end (stack, true, true, 6);
            box_header.pack_end (left_button, false, false, 0);

            left_button.clicked.connect (() => {
                left_clicked ();
                if (center_button.get_label () != center_label.get_label ()) {
                    stack.set_visible_child (center_button);
                } else {
                    stack.set_visible_child (center_label);
                }
            });

            right_button.clicked.connect (() => {
                right_clicked ();
                if (center_button.get_label () != center_label.get_label ()) {
                    stack.set_visible_child (center_button);
                } else {
                    stack.set_visible_child (center_label);
                }
            });

            center_button.clicked.connect (() => {
                center_clicked ();
                stack.set_visible_child (center_label);
            });

            left_button.can_focus = false;
            right_button.can_focus = false;
            center_button.can_focus = false;
            center_label.can_focus = false;
            stack.can_focus = false;

            add (box_header);

            margin_bottom = 4;
            set_size_request (-1, 30);
        }
    }
}
