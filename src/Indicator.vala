/*
 * Copyright (c) 2011-2016 elementary LLC. (https://elementary.io)
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

public class DateTime.Indicator : Wingpanel.Indicator {
    public static GLib.Settings settings;

    private Widgets.PanelLabel panel_label;
    private Gtk.Grid main_grid;
    private Widgets.CalendarView calendar;
    private Gtk.ListBox event_listbox;

    public Indicator () {
        Object (
            code_name: Wingpanel.Indicator.DATETIME,
            display_name: _("Date & Time"),
            description: _("The date and time indicator")
        );
    }

    static construct {
        settings = new GLib.Settings ("io.elementary.desktop.wingpanel.datetime");
    }

    construct {
        visible = true;
    }

    public override Gtk.Widget get_display_widget () {
        if (panel_label == null) {
            panel_label = new Widgets.PanelLabel ();
        }

        return panel_label;
    }

    public override Gtk.Widget? get_widget () {
        if (main_grid == null) {
            calendar = new Widgets.CalendarView ();
            calendar.margin_bottom = 6;

            var placeholder_label = new Gtk.Label (_("No Events on This Day"));
            placeholder_label.wrap = true;
            placeholder_label.wrap_mode = Pango.WrapMode.WORD;
            placeholder_label.margin_start = 12;
            placeholder_label.margin_end = 12;
            placeholder_label.max_width_chars = 20;
            placeholder_label.justify = Gtk.Justification.CENTER;
            placeholder_label.show_all ();

            var placeholder_style_context = placeholder_label.get_style_context ();
            placeholder_style_context.add_class (Gtk.STYLE_CLASS_DIM_LABEL);
            placeholder_style_context.add_class (Granite.STYLE_CLASS_H3_LABEL);

            event_listbox = new Gtk.ListBox ();
            event_listbox.selection_mode = Gtk.SelectionMode.NONE;
            event_listbox.set_header_func (header_update_func);
            event_listbox.set_placeholder (placeholder_label);
            event_listbox.set_sort_func (sort_function);
            event_listbox.set_filter_func (filter_function);

            var scrolled_window = new Gtk.ScrolledWindow (null, null);
            scrolled_window.hscrollbar_policy = Gtk.PolicyType.NEVER;
            scrolled_window.add (event_listbox);

            var settings_button = new Gtk.ModelButton ();
            settings_button.text = _("Date & Time Settings…");

            main_grid = new Gtk.Grid ();
            main_grid.margin_top = 12;
            main_grid.attach (calendar, 0, 0);
            main_grid.attach (new Gtk.Separator (Gtk.Orientation.VERTICAL), 1, 0);
            main_grid.attach (scrolled_window, 2, 0);
            main_grid.attach (new Wingpanel.Widgets.Separator (), 0, 2, 3);
            main_grid.attach (settings_button, 0, 3, 3);

            var size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
            size_group.add_widget (calendar);
            size_group.add_widget (event_listbox);

            var model = Widgets.CalendarModel.get_default ();
            foreach (var event in model.get_events ()) {
                var row = new DateTime.EventRow (event);
                event_listbox.add (row);
            }

            calendar.day_double_click.connect (() => {
                close ();
            });

            calendar.selection_changed.connect ((date) => {
                event_listbox.invalidate_filter ();
            });

            event_listbox.row_activated.connect ((row) => {
                calendar.show_date_in_maya (((DateTime.EventRow) row).start_time);
                close ();
            });

            settings_button.clicked.connect (() => {
                try {
                    AppInfo.launch_default_for_uri ("settings://time", null);
                } catch (Error e) {
                    warning ("Failed to open time and date settings: %s", e.message);
                }
            });

            model.events_added.connect (add_events);
            model.events_updated.connect (update_events);
            model.events_removed.connect (remove_events);

            main_grid.show_all ();
        }

        return main_grid;
    }

    private static int search_calcomp (Gtk.Widget widget, ECal.Component comp) {
        unowned EventRow row = widget as EventRow;
        return Util.calcomponent_compare_func (row.comp, comp);
    }

    private void add_events (E.Source source, Gee.Collection<ECal.Component> events) {
        foreach (var event in events) {
            GLib.List<weak Gtk.Widget> children = event_listbox.get_children ();
            unowned List<weak Gtk.Widget> found = children.search<ECal.Component> (event, search_calcomp);
            if (found == null) {
                var row = new DateTime.EventRow (event);
                event_listbox.add (row);
            }
        }
    }

    private void remove_events (E.Source source, Gee.Collection<ECal.Component> events) {
        GLib.List<weak Gtk.Widget> children = event_listbox.get_children ();
        foreach (var event in events) {
            unowned List<weak Gtk.Widget> found = children.search<ECal.Component> (event, search_calcomp);
            if (found != null) {
                var row = ((EventRow) found.data);
                row.destroy ();
            }
        }
    }

    private void update_events (E.Source source, Gee.Collection<ECal.Component> events) {
        
    }

    private bool filter_function (Gtk.ListBoxRow row) {
        var date = calendar.selected_date;
        if (calendar.selected_date == null) {
            date = new GLib.DateTime.now_local ();
            date = date.add_full (0, 0, 0, -date.get_hour (), -date.get_minute (), -date.get_second ());
        }

        unowned EventRow event_row = (EventRow) row;
        unowned ECal.Component comp = event_row.comp;
        if (Util.calcomp_is_on_day (comp, date)) {
            return true;
        }

        return false;
    }

    private static void header_update_func (Gtk.ListBoxRow lbrow, Gtk.ListBoxRow? lbbefore) {
        unowned DateTime.EventRow row = (DateTime.EventRow) lbrow;
        unowned DateTime.EventRow before = (DateTime.EventRow) lbbefore;
        if (before != null && row.is_allday == before.is_allday) {
            row.set_header (null);
            return;
        }

        var header_label = new Granite.HeaderLabel (row.is_allday ? _("All Day") : _("During the Day"));
        header_label.margin_start = header_label.margin_end = 6;
        row.set_header (header_label);
    }

    private static int sort_function (Gtk.ListBoxRow child1, Gtk.ListBoxRow child2) {
        unowned EventRow e1 = (EventRow) child1;
        unowned EventRow e2 = (EventRow) child2;

        /* Sort them wholeday first */
        if (e1.is_allday && e2.is_allday) {
            return Util.compare_event_alphabetically (e1.comp, e2.comp);
        } else if (e1.is_allday) {
            return -1;
        } else if (e2.is_allday) {
            return 1;
        }

        return Util.compare_events (e1.comp, e2.comp);
    }

    public override void opened () {
        calendar.show_today ();
    }

    public override void closed () {
        
    }
}

public Wingpanel.Indicator get_indicator (Module module) {
    debug ("Activating DateTime Indicator");
    var indicator = new DateTime.Indicator ();

    return indicator;
}
