/*
 * Copyright 2019 elementary, Inc. (https://elementary.io)
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

public class DateTime.EventRow : Gtk.Button {
    public DateTime.Event cal_event { get; construct; }

    public EventRow (DateTime.Event cal_event) {
        Object (cal_event: cal_event);
    }

    construct {
        var event_image = new Gtk.Image.from_icon_name (cal_event.get_icon (), Gtk.IconSize.MENU);
        event_image.valign = Gtk.Align.START;

        var name_label = new Gtk.Label (cal_event.get_label ());
        name_label.hexpand = true;
        name_label.ellipsize = Pango.EllipsizeMode.END;
        name_label.lines = 3;
        name_label.max_width_chars = 30;
        name_label.wrap = true;
        name_label.wrap_mode = Pango.WrapMode.WORD_CHAR;
        name_label.xalign = 0;

        var grid = new Gtk.Grid ();
        grid.column_spacing = 6;
        grid.margin_start = grid.margin_end = 6;
        grid.attach (event_image, 0, 0);
        grid.attach (name_label, 1, 0);

        add (grid);

        var style_context = get_style_context ();
        style_context.add_class (Gtk.STYLE_CLASS_MENUITEM);
        style_context.remove_class (Gtk.STYLE_CLASS_BUTTON);
        style_context.remove_class ("text-button");
    }
}
