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
    private Gtk.Grid main_grid;
    private Gtk.Grid event_dot_grid;
    public GLib.DateTime date { get; construct set; }
    public int id { get; construct; }
    private Gtk.Label label;
    private bool valid_grab = false;

    public GridDay (GLib.DateTime date, int id) {
        Object (
            date: date,
            id: id
        );
    }

    construct {
        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("/io/elementary/desktop/wingpanel/datetime/GridDay.css");

        unowned Gtk.StyleContext style_context = get_style_context ();
        style_context.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        style_context.add_class ("circular");

        label = new Gtk.Label (null);

        can_focus = true;
        events |= Gdk.EventMask.BUTTON_PRESS_MASK;
        events |= Gdk.EventMask.KEY_PRESS_MASK;
        events |= Gdk.EventMask.SMOOTH_SCROLL_MASK;

        label.name = "date";

        main_grid = new Gtk.Grid ();
        main_grid.halign = Gtk.Align.CENTER;
        main_grid.valign = Gtk.Align.CENTER;
        main_grid.attach (label, 0, 0);

        event_dot_grid = new Gtk.Grid ();
        event_dot_grid.halign = Gtk.Align.CENTER;

        add (main_grid);
        set_size_request (32, 32);
        halign = Gtk.Align.CENTER;
        show_all ();

        // Signals and handlers
        button_press_event.connect (on_button_press);
        key_press_event.connect (on_key_press);
        scroll_event.connect ((event) => {return Util.on_scroll_event (event);});

        var model = Widgets.CalendarModel.get_default ();
        model.events_added.connect (update_event_days);
        model.events_updated.connect (update_event_days);
        model.events_removed.connect (update_event_days);

        notify["date"].connect (() => {
            label.label = date.get_day_of_month ().to_string ();
        });
    }

    public async void update_event_days () {
        var model = Widgets.CalendarModel.get_default ();
        var events = model.get_events (date);

        // Unload unnecessary widgets
        if (event_dot_grid != null) {
            event_dot_grid.destroy ();
        }

        var event_dot = new Granite.AsyncImage ();
        event_dot.pixel_size = 6;

        if (events.size <= 4) {
            foreach (var e in events) {
                event_dot.gicon_async = new ThemedIcon ("pager-checked-symbolic");
                Util.set_event_calendar_color (e.cal, event_dot);
                event_dot_grid.add (event_dot);
                main_grid.margin_top = 6;
            }
        } else if (events.size > 4) {
            event_dot.gicon_async = new ThemedIcon ("events-bar-symbolic");
            event_dot_grid.add (event_dot);
            main_grid.margin_top = 6;
        }
        event_dot_grid.show_all ();
        main_grid.attach (event_dot_grid, 0, 1);
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
    }

    private bool on_button_press (Gdk.EventButton event) {
        if (event.type == Gdk.EventType.2BUTTON_PRESS && event.button == Gdk.BUTTON_PRIMARY)
            on_event_add (date);
        valid_grab = true;
        grab_focus ();
        return false;
    }

    private bool on_key_press (Gdk.EventKey event) {
        if (event.keyval == Gdk.keyval_from_name("Return") ) {
            on_event_add (date);
            return true;
        }

        return false;
    }
}
