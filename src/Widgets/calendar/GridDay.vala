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
    const string DAY_CSS = """
        .circular {
            border-radius: 50%;
        }
        .circular:selected > * {
            color: white;
        }
        .accent {
            font-weight: bold;
        }
        .event-accent {
            font-weight: bold;
        }
    """;

    /*
     * Event emitted when the day is double clicked or the ENTER key is pressed.
     */
    public signal void on_event_add (GLib.DateTime date);

    public Gtk.Grid main_grid;

    public GLib.DateTime date { get; private set; }
    Gtk.Label label;
    int id;
    bool valid_grab = false;

    public GridDay (GLib.DateTime date, int id) {
        this.date = date;
        this.id = id;

        label = new Gtk.Label ("");
        set_size_request (32, 32);

        var provider = new Gtk.CssProvider ();
        try {
            provider.load_from_data (DAY_CSS, DAY_CSS.length);
            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (Error e) {
            critical (e.message);
        }

        get_style_context ().add_class ("circular");

        // EventBox Properties
        can_focus = true;
        events |= Gdk.EventMask.BUTTON_PRESS_MASK;
        events |= Gdk.EventMask.KEY_PRESS_MASK;
        events |= Gdk.EventMask.SMOOTH_SCROLL_MASK;

        label.name = "date";

        main_grid = new Gtk.Grid ();
        main_grid.hexpand = true;
        main_grid.halign = Gtk.Align.CENTER;
        main_grid.valign = Gtk.Align.CENTER;
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.attach (label, 0, 0);

        add (main_grid);
        halign = Gtk.Align.CENTER;
        show_all ();

        // Signals and handlers
        button_press_event.connect (on_button_press);
        key_press_event.connect (on_key_press);
        scroll_event.connect ((event) => {return Util.on_scroll_event (event);});
    }

    public void update_date (GLib.DateTime date) {
        this.date = date;
        label.label = date.get_day_of_month ().to_string ();

        Widgets.CalendarModel.get_default ().events_added.connect (update_event_days);
        Widgets.CalendarModel.get_default ().events_updated.connect (update_event_days);
        Widgets.CalendarModel.get_default ().events_removed.connect (update_event_days);
    }

    public void update_event_days () {
        GLib.Idle.add (() => {
            var events = Widgets.CalendarModel.get_default ().get_events (date);
            var event_dot_grid = new Gtk.Grid ();
            event_dot_grid.column_homogeneous = true;
            if (event_dot_grid != null) {
                event_dot_grid.destroy ();
            }
            if (events.size != 0) {
                foreach (var e in events) {
                    if (e != null) {
                        var event_dot = new Gtk.Image.from_icon_name ("pager-checked-symbolic", Gtk.IconSize.MENU);
                        event_dot.visible = true;
                        event_dot.pixel_size = 6;
                        event_dot.halign = Gtk.Align.CENTER;
                        var dot_class = Util.get_event_dot_calendar_color (e.cal);
                        event_dot.get_style_context ().add_class (dot_class);
                        event_dot_grid.add (event_dot);
                        event_dot_grid.show_all ();
                    }
                }
                main_grid.attach (event_dot_grid, 0, 1);
            }
            return false;
        });
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
