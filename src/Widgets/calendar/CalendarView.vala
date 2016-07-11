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
 * Represents the entire calendar, including the headers, the week labels and the grid.
 */
public class DateTime.Widgets.CalendarView : Gtk.Grid {
    /*
     * Event emitted when the day is double clicked or the ENTER key is pressed.
     */
    public signal void on_event_add (GLib.DateTime date);
    public signal void selection_changed (GLib.DateTime new_date);
    public signal void event_updates ();

    public GLib.DateTime? selected_date { get; private set; }

    private WeekLabels weeks { get; private set; }
    private Header header { get; private set; }
    private Grid grid { get; private set; }
    private Gtk.Stack stack { get; private set; }
    private Gtk.Grid big_grid { get; private set; }

    public CalendarView () {
        big_grid = create_big_grid ();

        stack = new Gtk.Stack ();
        stack.add (big_grid);
        stack.show_all ();
        stack.expand = true;

        var model = CalendarModel.get_default ();
        model.parameters_changed.connect (on_model_parameters_changed);

        Services.SettingsManager.get_default ().changed["show-weeks"].connect (on_show_weeks_changed);
        events |= Gdk.EventMask.BUTTON_PRESS_MASK;
        events |= Gdk.EventMask.KEY_PRESS_MASK;
        events |= Gdk.EventMask.SCROLL_MASK;
        events |= Gdk.EventMask.SMOOTH_SCROLL_MASK;
        add (stack);
    }

    public Gtk.Grid create_big_grid () {
        weeks = new WeekLabels ();
        weeks.notify["child-revealed"].connect (() => {
            header.queue_draw ();
        });

        header = new Header ();
        grid = new Grid ();
        grid.on_event_add.connect ((date) => on_event_add (date));
        grid.selection_changed.connect ((date) => {
            selected_date = date;
            selection_changed (date);
        });

        // Grid properties
        var new_big_grid = new Gtk.Grid ();
        new_big_grid.attach (header, 1, 0, 1, 1);
        new_big_grid.attach (grid, 1, 1, 1, 1);
        new_big_grid.attach (weeks, 0, 1, 1, 1);
        new_big_grid.show_all ();
        new_big_grid.expand = true;
        return new_big_grid;
    }

    public override bool scroll_event (Gdk.EventScroll event) {
        return Util.on_scroll_event (event);
    }

    //--- Public Methods ---//

    public void today () {
        var calmodel = CalendarModel.get_default ();
        var today = Util.strip_time (new GLib.DateTime.now_local ());
        var start = Util.get_start_of_month (today);
        selected_date = today;
        if (!start.equal (calmodel.month_start))
            calmodel.month_start = start;
        sync_with_model ();
        grid.focus_date (today);
    }

    //--- Signal Handlers ---//

    void on_show_weeks_changed () {
        var model = CalendarModel.get_default ();
        weeks.update (model.data_range.first, model.num_weeks);
    }

    /* Indicates the month has changed */
    void on_model_parameters_changed () {
        var model = CalendarModel.get_default ();
        if (grid.grid_range != null && model.data_range.equals (grid.grid_range))
            return; // nothing to do

        Idle.add ( () => {
            sync_with_model ();
            return false;
        });
    }

    //--- Helper Methods ---//

    /* Sets the calendar widgets to the date range of the model */
    void sync_with_model () {
        var model = CalendarModel.get_default ();
        if (grid.grid_range != null && (model.data_range.equals (grid.grid_range) || grid.grid_range.first.compare (model.data_range.first) == 0))
            return; // nothing to do

        GLib.DateTime previous_first = null;
        if (grid.grid_range != null)
            previous_first = grid.grid_range.first;
        var previous_big_grid = big_grid;
        big_grid = create_big_grid ();
        stack.add (big_grid);

        header.update_columns (model.week_starts_on);
        weeks.update (model.data_range.first, model.num_weeks);
        grid.set_range (model.data_range, model.month_start);

        // keep focus date on the same day of the month
        if (selected_date != null) {
            var bumpdate = model.month_start.add_days (selected_date.get_day_of_month() - 1);
            grid.focus_date (bumpdate);
        }

        if (previous_first != null) {
            if (previous_first.compare (grid.grid_range.first) == -1) {
                stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT;
            } else {
                stack.transition_type = Gtk.StackTransitionType.SLIDE_RIGHT;
            }
        }

        stack.set_visible_child (big_grid);
        Timeout.add (stack.transition_duration, () => {
            previous_big_grid.destroy ();
            return false;
        });
    }
}