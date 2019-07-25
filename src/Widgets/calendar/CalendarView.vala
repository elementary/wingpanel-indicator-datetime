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
 * Represents the entire calendar, including the headers, the week labels and the grid.
 */
public class DateTime.Widgets.CalendarView : Gtk.Grid {
    /*
     * Event emitted when the day is double clicked or the ENTER key is pressed.
     */
    public signal void on_event_add (GLib.DateTime date);
    public signal void selection_changed (GLib.DateTime? new_date);
    public signal void event_updates ();

    public GLib.DateTime? selected_date { get; private set; }

    private WeekLabels weeks;
    private Header header;
    private Grid grid;
    private Gtk.Stack stack;
    private Gtk.Grid big_grid;

    /* Smooth scrolling support */
    private const double DELTA_PER_MONTH = 4.0;
    private double total_x_delta = 0;
    private double total_y_delta= 0;
    public bool natural_scroll_touchpad { get; set; }
    public bool natural_scroll_mouse { get; set; }

    construct {
        var touchpad_settings = new GLib.Settings ("org.gnome.desktop.peripherals.touchpad");
        touchpad_settings.bind ("natural-scroll", this, "natural-scroll-touchpad", SettingsBindFlags.DEFAULT);
        var mouse_settings = new GLib.Settings ("org.gnome.desktop.peripherals.mouse");
        mouse_settings.bind ("natural-scroll", this, "natural-scroll-mouse", SettingsBindFlags.DEFAULT);

        big_grid = create_big_grid ();

        stack = new Gtk.Stack ();
        stack.add (big_grid);
        stack.show_all ();
        stack.expand = true;

        var model = CalendarModel.get_default ();
        model.parameters_changed.connect (on_model_parameters_changed);

        stack.notify["transition-running"].connect (() => {
            if (stack.transition_running == false) {
                stack.get_children ().foreach ((child) => {
                    if (child != stack.visible_child) {
                        child.destroy ();
                    }
                });
            }
        });

        DateTime.Indicator.settings.changed["show-weeks"].connect (on_show_weeks_changed);
        scroll_event.connect (handle_scroll_event);

        add (stack);
    }

    private Gtk.Grid create_big_grid () {
        weeks = new WeekLabels ();

        header = new Header ();

        grid = new Grid ();

        var new_big_grid = new Gtk.Grid ();
        new_big_grid.expand = true;
        new_big_grid.attach (header, 1, 0);
        new_big_grid.attach (grid, 1, 1);
        new_big_grid.attach (weeks, 0, 1);
        new_big_grid.show_all ();

        grid.on_event_add.connect ((date) => on_event_add (date));
        grid.selection_changed.connect ((date) => {
            selected_date = date;
            selection_changed (date);
        });

        weeks.notify["child-revealed"].connect (() => {
            header.queue_draw ();
        });

        return new_big_grid;
    }

    //--- Public Methods ---//

    public void today () {
        var calmodel = CalendarModel.get_default ();
        var today = Util.strip_time (new GLib.DateTime.now_local ());
        var start = Util.get_start_of_month (today);
        selected_date = today;
        if (!start.equal (calmodel.month_start)) {
            calmodel.month_start = start;
        }
        sync_with_model ();

        grid.set_focus_to_today ();
    }

    //--- Signal Handlers ---//

    private void on_show_weeks_changed () {
        var model = CalendarModel.get_default ();
        weeks.update (model.data_range.first_dt, model.num_weeks);
    }

    /* Indicates the month has changed */
    private void on_model_parameters_changed () {
        var model = CalendarModel.get_default ();
        if (grid.grid_range != null && model.data_range.equals (grid.grid_range))
            return; // nothing to do

        sync_with_model ();

        selected_date = null;
        selection_changed (selected_date);
    }

    //--- Helper Methods ---//

    /* Sets the calendar widgets to the date range of the model */
    private void sync_with_model () {
        var model = CalendarModel.get_default ();
        if (grid.grid_range != null && (model.data_range.equals (grid.grid_range) || grid.grid_range.first_dt.compare (model.data_range.first_dt) == 0)) {
            grid.update_today();
            return; // nothing else to do
        }

        GLib.DateTime previous_first = null;
        if (grid.grid_range != null)
            previous_first = grid.grid_range.first_dt;

        big_grid = create_big_grid ();
        stack.add (big_grid);

        header.update_columns (model.week_starts_on);
        weeks.update (model.data_range.first_dt, model.num_weeks);
        grid.set_range (model.data_range, model.month_start);

        if (previous_first != null) {
            if (previous_first.compare (grid.grid_range.first_dt) == -1) {
                stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT;
            } else {
                stack.transition_type = Gtk.StackTransitionType.SLIDE_RIGHT;
            }
        }

        stack.set_visible_child (big_grid);
    }

    /* Handles both SMOOTH and non-SMOOTH events.
     * In order to deliver smooth volume changes it:
     * * accumulates very small changes until they become significant.
     * * ignores rapid changes in direction.
     * * responds to both horizontal and vertical scrolling.
     * In the case of diagonal scrolling, it ignores the event unless movement in one direction
     * is more than twice the movement in the other direction.
     */
    public bool handle_scroll_event (Gdk.EventScroll e) {
        if (stack.transition_running) {
            return true;
        }

        double dir = 0.0;
        bool natural_scroll;
        var source_device = e.get_source_device ();
        var event_source = e.get_source_device ().input_source;

        /* Fallback to device name to try to detect a touch device that reports itself as a mouse */
        bool is_touchpad = (event_source == Gdk.InputSource.TOUCHPAD ||
                           source_device.get_name ().up ().contains ("TOUCH"));

        bool is_mouse = !is_touchpad && (event_source == Gdk.InputSource.MOUSE);

        if (is_mouse) {
            natural_scroll = natural_scroll_mouse;
        } else if (is_touchpad) {
            natural_scroll = natural_scroll_touchpad;
        } else {
            natural_scroll = false;
        }

        switch (e.direction) {
            case Gdk.ScrollDirection.SMOOTH:
            /* Mouse events may also be SMOOTH */
                if (is_mouse) {
                    e.delta_x *= DELTA_PER_MONTH;
                    e.delta_y *= DELTA_PER_MONTH;
                }

                var abs_x = double.max (e.delta_x.abs (), 0.0001);
                var abs_y = double.max (e.delta_y.abs (), 0.0001);

                if (abs_y / abs_x > 2.0) {
                    total_y_delta += e.delta_y;
                } else if (abs_x / abs_y > 2.0) {
                    total_x_delta += e.delta_x;
                }

                break;

            case Gdk.ScrollDirection.UP:
                total_y_delta -= DELTA_PER_MONTH;
                break;
            case Gdk.ScrollDirection.DOWN:
                total_y_delta += DELTA_PER_MONTH;
                break;
            case Gdk.ScrollDirection.LEFT:
                total_x_delta -= DELTA_PER_MONTH;
                break;
            case Gdk.ScrollDirection.RIGHT:
                total_x_delta += DELTA_PER_MONTH;
                break;
            default:
                break;
        }


        /* The figure of 2.0  is chosen to reduce speed of month switching when scrolling */
        if (total_y_delta.abs () >= DELTA_PER_MONTH) {
            dir = natural_scroll ? total_y_delta : -total_y_delta;
        } else if (total_x_delta.abs () >= DELTA_PER_MONTH) {
            dir = natural_scroll ? -total_x_delta : total_x_delta;
        }

        if (dir != 0.0) {
            DateTime.Widgets.CalendarModel.get_default ().change_month (dir > 0 ? -1 : 1);
            total_y_delta = 0.0;
            total_x_delta = 0.0;
        }

        return true;
    }
}
