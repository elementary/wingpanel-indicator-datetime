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
    private Widgets.PanelLabel panel_label;
    private Gtk.Grid main_grid;
    private Widgets.Calendar calendar;
    private Gtk.ListBox event_grid;
    private Gtk.Label no_events_label;
    private Gtk.ListBoxRow menuitem;
    private uint update_events_idle_source = 0;

    public Indicator () {
        Object (
            code_name: Wingpanel.Indicator.DATETIME,
            display_name: _("Date & Time"),
            description: _("The date and time indicator")
        );
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
            calendar = new Widgets.Calendar ();

            var settings_button = new Gtk.ModelButton ();
            settings_button.text = _("Date & Time Settings…");

            var header_label = new Gtk.Label (_("Events"));
            header_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
            header_label.halign = Gtk.Align.START;
            header_label.valign = Gtk.Align.CENTER;
            header_label.xalign = 0;

            header_label.width_chars = 7;

            var cal_icon = new Gtk.Image.from_icon_name ("office-calendar", Gtk.IconSize.DND);
            cal_icon.halign = Gtk.Align.END;

            var cal_button = new Gtk.Button ();
            cal_button.halign = Gtk.Align.END;
            cal_button.valign = Gtk.Align.CENTER;
            cal_button.set_image (cal_icon);
            cal_button.margin = 0;
            cal_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
            cal_button.set_tooltip_text (_("Open Calendar"));

            var header_grid = new Gtk.Grid ();

            header_grid.set_column_homogeneous (true);
            header_grid.margin_start = 12;
            header_grid.margin_end = 6;
            header_grid.attach (header_label, 0, 0);
            header_grid.attach (cal_button, 1, 0);

            var sep = new Gtk.Separator (Gtk.Orientation.VERTICAL);

            no_events_label = new Gtk.Label (_("No Events Scheduled"));
            no_events_label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);
            no_events_label.expand = true;
            no_events_label.sensitive = false;
            no_events_label.width_chars = 20;

            main_grid = new Gtk.Grid ();
            main_grid.margin_top = 6;
            main_grid.attach (calendar.heading, 0, 0);
            main_grid.attach (calendar, 0, 1);
            main_grid.attach (new Wingpanel.Widgets.Separator (), 0, 2);
            main_grid.attach (settings_button, 0, 3);
            main_grid.attach (sep, 1, 0, 1, 9);
            main_grid.attach (header_grid, 2, 0);
            main_grid.attach (no_events_label, 2, 1);

            calendar.day_double_click.connect (() => {
                close ();
            });

            calendar.selection_changed.connect ((date) => {
                idle_update_events ();
            });

            cal_button.clicked.connect (() => {
                calendar.open_maya ();
                this.close ();
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

    private void update_events_model (E.Source source, Gee.Collection<E.CalComponent> events) {
        idle_update_events ();
    }

    private void idle_update_events () {
        if (update_events_idle_source > 0) {
            GLib.Source.remove (update_events_idle_source);
        }

        update_events_idle_source = GLib.Idle.add (() => {
            update_events ();
            return false;
        });
    }

    private bool update_events () {
        if (event_grid != null) {
            event_grid.destroy ();
        }

        if (calendar.selected_date == null) {
            update_events_idle_source = 0;
            return GLib.Source.REMOVE;
        }

        var events = Widgets.CalendarModel.get_default ().get_events (calendar.selected_date);
        if (events.size == 0) {
            update_events_idle_source = 0;
            no_events_label.visible = true;
            return GLib.Source.REMOVE;
        }

        event_grid = new Gtk.ListBox ();
        event_grid.margin = 6;

        foreach (var e in events) {
            var color = Widgets.CalendarModel.get_default ().cal_color;

            string CSS = """
                .event-label {
                    color: shade (%s, 0.65);
                }
                .event {
                    background-color: alpha(%s, 0.15);
                    padding: 10px;
                    border-radius: 4px;
                }
                .event-icon {
                    color: shade (%s, 0.65);
                }
            """.printf (color, color, color);

            var provider = new Gtk.CssProvider ();
            try {
                provider.load_from_data (CSS, CSS.length);
                Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            } catch (Error e) {
                critical (e.message);
            }

            var menuitem_icon = new Gtk.Image.from_icon_name (e.get_icon (), Gtk.IconSize.MENU);
            menuitem_icon.get_style_context ().add_class ("event-icon");
            menuitem_icon.valign = Gtk.Align.CENTER;

            var menuitem_label = new Gtk.Label (e.get_label ());
            menuitem_label.hexpand = true;
            menuitem_label.lines = 3;
            menuitem_label.ellipsize = Pango.EllipsizeMode.END;
            menuitem_label.width_chars = 20;
            menuitem_label.wrap = true;
            menuitem_label.wrap_mode = Pango.WrapMode.WORD_CHAR;
            menuitem_label.xalign = 0;
            menuitem_label.get_style_context ().add_class ("event-label");

            var menuitem_box = new Gtk.Grid ();
            menuitem_box.add (menuitem_icon);
            menuitem_box.add (menuitem_label);

            menuitem = new Gtk.ListBoxRow ();
            menuitem.margin = 6;
            menuitem.add (menuitem_box);

            var style_context = menuitem.get_style_context ();
            style_context.add_class (Gtk.STYLE_CLASS_MENUITEM);
            style_context.remove_class (Gtk.STYLE_CLASS_BUTTON);
            style_context.remove_class ("text-button");

            event_grid.add (menuitem);

            /* Color events per calendar */
            Widgets.CalendarModel.get_default ().registry.list_sources (E.SOURCE_EXTENSION_CALENDAR).foreach ((source) => {
                E.SourceCalendar cal = (E.SourceCalendar)source.get_extension (E.SOURCE_EXTENSION_CALENDAR);
                Util.style_calendar_color (menuitem, cal.dup_color ());

                string style = """
                    /* Event Icon */
                    .event-icon {
                        color: shade(%s, 0.65);
                    }
                   """.printf(cal.dup_color ());

                var provider = new Gtk.CssProvider ();
                try {
                    provider.load_from_data (style, style.length);
                    Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
                } catch (Error e) {
                    critical (e.message);
                }

                cal.notify["color"].connect (() => {
                    Util.style_calendar_color (menuitem, cal.dup_color ());
                });
            });
        }

        event_grid.show_all ();
        main_grid.attach (event_grid, 2, 1);
        no_events_label.visible = false;
        update_events_idle_source = 0;
        return GLib.Source.REMOVE;
    }

    public override void opened () {
        calendar.show_today ();

        Widgets.CalendarModel.get_default ().events_added.connect (update_events_model);
        Widgets.CalendarModel.get_default ().events_updated.connect (update_events_model);
        Widgets.CalendarModel.get_default ().events_removed.connect (update_events_model);
    }

    public override void closed () {
        Widgets.CalendarModel.get_default ().events_added.disconnect (update_events_model);
        Widgets.CalendarModel.get_default ().events_updated.disconnect (update_events_model);
        Widgets.CalendarModel.get_default ().events_removed.disconnect (update_events_model);
    }
}

public Wingpanel.Indicator get_indicator (Module module) {
    debug ("Activating DateTime Indicator");
    var indicator = new DateTime.Indicator ();

    return indicator;
}
