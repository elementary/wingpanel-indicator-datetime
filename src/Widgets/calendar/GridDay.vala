/*-
 * Copyright 2011–2020 elementary, Inc. (https://elementary.io)
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

    private Gee.HashMap<string, Gtk.Widget> component_dots;
    private Gtk.Box event_box;
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
        label = new Gtk.Label (null);

        unowned var label_style_context = label.get_style_context ();
        label_style_context.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        label_style_context.add_class ("circular");

        event_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            halign = Gtk.Align.CENTER,
            height_request = 6
        };

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER

        };
        box.add (label);
        box.add (event_box);

        can_focus = true;
        events |= Gdk.EventMask.BUTTON_PRESS_MASK;
        events |= Gdk.EventMask.KEY_PRESS_MASK;
        set_css_name ("grid-day");
        halign = Gtk.Align.CENTER;
        hexpand = true;
        get_style_context ().add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        add (box);
        show_all ();

        // Signals and handlers
        button_press_event.connect (on_button_press);
        key_press_event.connect (on_key_press);

        notify["date"].connect (() => {
            label.label = date.get_day_of_month ().to_string ();
        });

        component_dots = new Gee.HashMap<string, Gtk.Widget> ();
    }

    public void add_component_dot (E.Source source, ICal.Component ical) {
        if (component_dots.size >= 3) {
            return;
        }

        var component_uid = ical.get_uid ();
        if (!component_dots.has_key (component_uid)) {
            var event_dot = new Gtk.Image () {
                gicon = new ThemedIcon ("pager-checked-symbolic"),
                pixel_size = 6
            };

            unowned var style_context = event_dot.get_style_context ();
            style_context.add_class (Granite.STYLE_CLASS_ACCENT);
            style_context.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

            unowned E.SourceSelectable? source_selectable = null;
            if (source.has_extension (E.SOURCE_EXTENSION_TASK_LIST)) {
                source_selectable = (E.SourceSelectable?) source.get_extension (E.SOURCE_EXTENSION_TASK_LIST);
            } else {
                source_selectable = (E.SourceSelectable?) source.get_extension (E.SOURCE_EXTENSION_CALENDAR);
            }
            Util.set_component_calendar_color (source_selectable, event_dot);

            component_dots[component_uid] = event_dot;

            event_box.add (event_dot);
        }
    }

    public void remove_component_dot (string component_uid) {
        var dot = component_dots[component_uid];
        if (dot != null) {
            dot.destroy ();
            component_dots.unset (component_uid);
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
        event_box.sensitive = sens;
    }

    private bool on_button_press (Gdk.EventButton event) {
        if (event.type == Gdk.EventType.2BUTTON_PRESS && event.button == Gdk.BUTTON_PRIMARY) {
            on_event_add (date);
        }
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
