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

public class DateTime.EventRow : Gtk.ListBoxRow {
    public DateTime.Event cal_event { get; construct; }

    private static Gtk.CssProvider css_provider;

    public EventRow (DateTime.Event cal_event) {
        Object (cal_event: cal_event);
    }

    static construct {
        css_provider = new Gtk.CssProvider ();
        css_provider.load_from_resource ("/io/elementary/desktop/wingpanel/datetime/EventRow.css");
    }

    construct {
        var event_image = new Gtk.Image.from_icon_name (cal_event.get_icon (), Gtk.IconSize.MENU);
        event_image.valign = Gtk.Align.START;

        var event_image_context = event_image.get_style_context ();
        event_image_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        var name_label = new Gtk.Label (cal_event.get_event_label ());
        name_label.hexpand = true;
        name_label.ellipsize = Pango.EllipsizeMode.END;
        name_label.lines = 3;
        name_label.max_width_chars = 30;
        name_label.wrap = true;
        name_label.wrap_mode = Pango.WrapMode.WORD_CHAR;
        name_label.xalign = 0;

        var name_label_context = name_label.get_style_context ();
        name_label_context.add_class ("title");
        name_label_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        var time_label = new Gtk.Label ("<small>%s</small>".printf (cal_event.get_event_times ()));
        time_label.use_markup = true;
        time_label.xalign = 0;
        time_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        var grid = new Gtk.Grid ();
        grid.column_spacing = 6;
        grid.margin = 3;
        grid.margin_start = grid.margin_end = 6;
        grid.attach (event_image, 0, 0);
        grid.attach (name_label, 1, 0);
        if (!cal_event.day_event) {
            grid.attach (time_label, 1, 1);
        }

        var grid_context = grid.get_style_context ();
        grid_context.add_class ("event");
        grid_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        add (grid);
    }
}
