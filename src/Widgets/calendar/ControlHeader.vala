/*
 * Copyright (c) 2011-2016 elementary Developers (https://launchpad.net/elementary)
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
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */


namespace DateTime.Widgets {
    public class ControlHeader : Gtk.Box {
        public signal void left_clicked ();
        public signal void right_clicked ();
        public signal void center_clicked ();
        public ControlHeader () {
            Object (orientation : Gtk.Orientation.HORIZONTAL);
            var left_button = new ArrowButton (true);
            var right_button = new ArrowButton (false);
            var center_button = new CenterButton ();
            CalendarModel.get_default ().parameters_changed.connect (() => {
                var date = CalendarModel.get_default ().month_start;
                center_button.set_label (date.format ("%B %Y"));
            });
            left_button.clicked.connect (() => {
                left_clicked ();
            });
            right_button.clicked.connect (() => {
                right_clicked ();
            });
            center_button.clicked.connect (() => {
                center_clicked ();
            });
            add (left_button);
            pack_end (right_button, false, false, 0);
            pack_end (center_button, true, true, 0);
            margin_bottom = 4;
        }
    }
    class CenterButton : Gtk.Button {
        public CenterButton () {
            Object (focus_on_click: false, can_focus: false, relief: Gtk.ReliefStyle.NONE);
            var date = CalendarModel.get_default ().month_start;
            set_label (date.format ("%B %Y"));
            set_size_request (-1, 30);
        }

        public override bool draw (Cairo.Context cr) {
            base.draw (cr);
            Gtk.Allocation size;
            get_allocation (out size);
            cr.set_source_rgba (0.0, 0.0, 0.0, 0.25);
            cr.set_line_width (1.0);
            cr.move_to (0, 0.5);
            cr.line_to (size.width, 0.5);
            cr.move_to (0, size.height - 0.5);
            cr.line_to (size.width, size.height - 0.5);
            cr.stroke ();

            return false;
        }
    }

    class ArrowButton : Gtk.Button {
        bool left;
        public ArrowButton (bool left) {
            Object (focus_on_click: false, can_focus: false, relief: Gtk.ReliefStyle.NONE);
            this.left = left;
            set_size_request (-1, 30);
            Gtk.IconTheme icon_theme = Gtk.IconTheme.get_default ();
            try {
                if (left) {
                    Gdk.Pixbuf icon = icon_theme.load_icon ("pan-start-symbolic", 16, 0);
                    image = new Gtk.Image.from_pixbuf (icon);
                } else {
                    Gdk.Pixbuf icon = icon_theme.load_icon ("pan-end-symbolic", 16, 0);
                    image = new Gtk.Image.from_pixbuf (icon);
                }
            } catch (Error e) {
                warning (e.message);
            }
        }

        public override bool draw (Cairo.Context cr) {
            base.draw (cr);
            Gtk.Allocation size;
            get_allocation (out size);
            cr.set_source_rgba (0.0, 0.0, 0.0, 0.25);
            cr.set_line_width (1.0);

            if (left) {
                cr.move_to (4.5, 0.5);
                cr.line_to (size.width, 0.5);
                cr.line_to (size.width, size.height - 0.5);
                cr.line_to (4.5, size.height - 0.5);
                cr.curve_to (4.5, size.height - 0.5, 0.5, size.height - 0.5, 0.5, size.height - 4.5);
                cr.line_to (0.5, 4.5);
                cr.curve_to (0.5, 4.5, 0.5, 0.5, 4.5, 0.5);
            } else {
                cr.move_to (0, 0.5);
                cr.line_to (size.width - 4.5, 0.5);
                cr.curve_to (size.width - 4.5, 0.5, size.width - 0.5, 0.5, size.width - 0.5, 4.5);
                cr.line_to (size.width - 0.5, size.height - 4.5);
                cr.curve_to (size.width - 0.5, size.height - 4.5, size.width - 0.5, size.height - 0.5, size.width - 4.5, size.height - 0.5);
                cr.line_to (0.5, size.height - 0.5);
                cr.line_to (0.5, 0.5);
            }

            cr.stroke ();

            return false;
        }
    }
}