// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2011–2018 elementary, Inc. (https://elementary.io)
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
 *
 * Authored by: Maxwell Barvian
 *              Corentin Noël <corentin@elementaryos.org>
 */

/**
 * Represents a single day on the grid.
 */
public class DateTime.Widgets.GridDay : Gtk.EventBox {
    /*
     * Event emitted when the day is double clicked or the ENTER key is pressed.
     */
    public signal void on_event_add (GLib.DateTime date);

    public GLib.DateTime date { get; construct set; }

    private static Gtk.CssProvider provider;

    private Gee.ArrayList<string> event_dots;
    private Gtk.Grid event_grid;
    private Gtk.Label label;
    private bool valid_grab = false;

    public GridDay (GLib.DateTime date) {
        Object (date: date);
    }

    static construct {
    
        provider = new Gtk.CssProvider ();
        provider.load_from_resource ("/io/elementary/desktop/wingpanel/datetime/GridDay.css");
    }

    construct {
        unowned Gtk.StyleContext style_context = get_style_context ();
        style_context.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        style_context.add_class ("circular");

        label = new Gtk.Label (null);

        event_grid = new Gtk.Grid ();
        event_grid.halign = Gtk.Align.CENTER;
        event_grid.height_request = 6;

        var grid = new Gtk.Grid ();
        grid.halign = grid.valign = Gtk.Align.CENTER;
        grid.attach (label, 0, 0);
        grid.attach (event_grid, 0, 1);

        can_focus = true;
        events |= Gdk.EventMask.BUTTON_PRESS_MASK;
        events |= Gdk.EventMask.KEY_PRESS_MASK;
        events |= Gdk.EventMask.SMOOTH_SCROLL_MASK;
        set_size_request (35, 35);
        halign = Gtk.Align.CENTER;
        hexpand = true;
        add (grid);
        show_all ();

        // Signals and handlers
        button_press_event.connect (on_button_press);
        key_press_event.connect (on_key_press);
        scroll_event.connect ((event) => {return Util.on_scroll_event (event);});

        notify["date"].connect (() => {
            label.label = date.get_day_of_month ().to_string ();
        });

        event_dots = new Gee.ArrayList<string> ();
    }


    public void add_dots (E.Source source, ICal.Component ical) {
        var event_uid = ical.get_uid ();
        if (event_dots.contains (event_uid)) {
            return;
        }

        event_dots.add (event_uid);
        if (event_dots.size > 3) {
            return;
        }

        var event_dot = new Gtk.Image ();
        event_dot.gicon = new ThemedIcon ("pager-checked-symbolic");
        event_dot.pixel_size = 6;

        unowned Gtk.StyleContext style_context = event_dot.get_style_context ();
        style_context.add_class (Granite.STYLE_CLASS_ACCENT);
        style_context.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        var source_calendar = (E.SourceCalendar?) source.get_extension (E.SOURCE_EXTENSION_CALENDAR);
        Util.set_event_calendar_color (source_calendar, event_dot);

        event_grid.add (event_dot);
        event_dot.show ();
    }

    public void remove_dots (string event_uid) {
        if (!event_dots.contains (event_uid)) {
            return;
        }

        event_dots.remove (event_uid);
        if (event_dots.size >= 3) {
            return;
        }

        var dot = event_grid.get_children ();
        if (dot.length () > 0) {
            dot.nth_data (0).destroy ();
        }
    }

    public void set_selected (bool selected) {
        if (selected) {
            set_state_flags (Gtk.StateFlags.SELECTED, true);
        } else {
            set_state_flags (Gtk.StateFlags.NORMAL, true);
        }
    }

    public void grab_focus_force () {
        valid_grab = true;
        grab_focus ();
    }

    public override void grab_focus () {
        if (valid_grab) {
            base.grab_focus ();
            valid_grab = false;
        }
    }

    public void sensitive_container (bool sens) {
        label.sensitive = sens;
        event_grid.sensitive = sens;
    }

    private bool on_button_press (Gdk.EventButton event) {
        if (event.type == Gdk.EventType.2BUTTON_PRESS && event.button == Gdk.BUTTON_PRIMARY)
            on_event_add (date);
        valid_grab = true;
        grab_focus ();
        return false;
    }

    private bool on_key_press (Gdk.EventKey event) {
        if (event.keyval == Gdk.keyval_from_name ("Return") ) {
            on_event_add (date);
            return true;
        }

        return false;
    }
}
