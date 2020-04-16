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

namespace DateTimeIndicator {
    public class Indicator : Wingpanel.Indicator {
        public static GLib.Settings settings;

        private Widgets.PanelLabel panel_label;
        private Widgets.CalendarView calendar;

#if USE_EVO
        private Widgets.EventsListBox event_listbox;
        private Services.EventsManager event_manager;
#endif

        private Gtk.Grid main_grid;
        private uint update_events_idle_source = 0;

        private bool opened_widget = false;

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
                calendar.day_double_click.connect (() => {
                    close ();
                });

                var settings_button = new Gtk.ModelButton ();
                settings_button.text = _("Date & Time Settings…");

                main_grid = new Gtk.Grid ();
                main_grid.margin_top = 12;
                main_grid.attach (calendar,                           0, 0);
                main_grid.attach (new Wingpanel.Widgets.Separator (), 0, 1);
                main_grid.attach (settings_button,                    0, 2);

#if USE_EVO
                event_manager = new Services.EventsManager ();
                event_manager.events_updated.connect (update_events_model);
                event_manager.events_added.connect ((source, events) => {
                    calendar.add_event_dots (source, events);
                    update_events_model (source, events);
                });
                event_manager.events_removed.connect ((source, events) => {
                    calendar.remove_event_dots (source, events);
                    update_events_model (source, events);
                });

                event_listbox = new Widgets.EventsListBox ();
                event_listbox.row_activated.connect ((row) => {
                    calendar.show_date_in_maya (((EventRow) row).date);
                    close ();
                });

                var scrolled_window = new Gtk.ScrolledWindow (null, null);
                scrolled_window.hscrollbar_policy = Gtk.PolicyType.NEVER;
                scrolled_window.vscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
                scrolled_window.add (event_listbox);

                main_grid.attach (new Gtk.Separator (Gtk.Orientation.VERTICAL), 1, 0, 1, 3);
                main_grid.attach (scrolled_window,                              2, 0, 1, 3);

                var size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
                size_group.add_widget (calendar);
                size_group.add_widget (event_listbox);

                event_manager.open.begin ((obj, res) => {
                    calendar.selection_changed.connect ((date) => {
                        idle_update_events ();
                    });
                });
#endif

                var model = Models.CalendarModel.get_default ();
                model.notify["month-start"].connect (() => {
                    model.compute_ranges ();
#if USE_EVO
                    event_listbox.clear_list ();
                    event_manager.load_all_sources ();
#endif
                });

                settings_button.clicked.connect (() => {
                    try {
                        AppInfo.launch_default_for_uri ("settings://time", null);
                    } catch (Error e) {
                        warning ("Failed to open time and date settings: %s", e.message);
                    }
                });
            }

            return main_grid;
        }

#if USE_EVO
        private void update_events_model (E.Source source, Gee.Collection<ECal.Component> events) {
            if (opened_widget) {
                idle_update_events ();
            }
        }

        private void idle_update_events () {
            if (update_events_idle_source > 0) {
                GLib.Source.remove (update_events_idle_source);
            }

            update_events_idle_source = GLib.Idle.add (() => {
                event_listbox.update_events (calendar.selected_date, event_manager.source_events);

                update_events_idle_source = 0;
                return GLib.Source.REMOVE;
            });
        }
#endif

        public override void opened () {
            calendar.show_today ();

            opened_widget = true;
        }

        public override void closed () {
            opened_widget = false;
        }
    }
}

public Wingpanel.Indicator get_indicator (Module module) {
    debug ("Activating DateTime Indicator");
    var indicator = new DateTimeIndicator.Indicator ();

    return indicator;
}
