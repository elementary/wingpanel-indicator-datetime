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
    private Grid grid;
    private Gtk.Stack stack;
    private Gtk.Grid big_grid;
    private Gtk.Label[] header_labels;

    construct {
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

        add (stack);
    }

    private Gtk.Grid create_big_grid () {
        weeks = new WeekLabels ();

        var new_big_grid = new Gtk.Grid ();
        new_big_grid.column_homogeneous = true;
        new_big_grid.expand = true;

        header_labels = new Gtk.Label[7];
        for (int c = 0; c < 7; c++) {
            header_labels[c] = new Gtk.Label (null);
            header_labels[c].margin_bottom = 4;
            header_labels[c].get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);

            new_big_grid.attach (header_labels[c], c + 1, 0);
        }

        grid = new Grid ();

        new_big_grid.attach (grid, 1, 1, 7);
        new_big_grid.attach (weeks, 0, 1);
        new_big_grid.show_all ();

        grid.on_event_add.connect ((date) => on_event_add (date));
        grid.selection_changed.connect ((date) => {
            selected_date = date;
            selection_changed (date);
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

        var date = Util.strip_time (new GLib.DateTime.now_local ());
        date = date.add_days (model.week_starts_on - date.get_day_of_week ());
        foreach (var label in header_labels) {
            label.label = date.format ("%a");
            date = date.add_days (1);
        }

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
}
