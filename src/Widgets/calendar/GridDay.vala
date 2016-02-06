// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2011-2015 Maya Developers (http://launchpad.net/maya)
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

    public GLib.DateTime date { get; private set; }
    Gtk.Label label;
    int id;
    bool valid_grab = false;

    public GridDay (GLib.DateTime date, int id) {
        this.date = date;
        this.id = id;

        label = new Gtk.Label ("");
        set_size_request (32, 25);
        // EventBox Properties
        can_focus = true;
        events |= Gdk.EventMask.BUTTON_PRESS_MASK;
        events |= Gdk.EventMask.KEY_PRESS_MASK;
        events |= Gdk.EventMask.SMOOTH_SCROLL_MASK;
        var style_provider = Util.Css.get_css_provider ();
        get_style_context ().add_provider (style_provider, 600);
        get_style_context ().add_class ("cell");

        label.halign = Gtk.Align.CENTER;
        label.valign = Gtk.Align.CENTER;
        label.get_style_context ().add_provider (style_provider, 600);
        label.name = "date";

        add (label);
        show_all ();

        // Signals and handlers
        button_press_event.connect (on_button_press);
        key_press_event.connect (on_key_press);
        scroll_event.connect ((event) => {return Util.on_scroll_event (event);});
    }

    public override bool draw (Cairo.Context cr) {
        base.draw (cr);
        Gtk.Allocation size;
        get_allocation (out size);

        cr.set_source_rgba (0.0, 0.0, 0.0, 0.25);
        cr.set_line_width (1.0);

        // Draw left and top black strokes
        if (id % 7 == 0) {
            cr.move_to (0.5, 0.5);
        } else {
            cr.move_to (0.5, size.height); // start in bottom left. 0.5 accounts for cairo's default stroke offset of 1/2 pixels
            cr.line_to (0.5, 0.5); // move to upper left corner
        }
        if (id > 6) {
            cr.line_to (size.width + 0.5, 0.5); // move to upper right corner
        }
        cr.stroke ();

        // Draw inner highlight stroke
        cr.rectangle (1, 1, size.width - 1, size.height - 1);
        cr.set_source_rgba (1.0, 1.0, 1.0, 0.2);
        cr.stroke ();
        return false;
    }

    public void update_date (GLib.DateTime date) {
        this.date = date;
        label.label = date.get_day_of_month ().to_string ();
    }

    public void set_selected (bool selected) {
        if (selected) {
            set_state_flags (Gtk.StateFlags.SELECTED, true);
        } else {
            set_state_flags (Gtk.StateFlags.NORMAL, true);
        }
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
