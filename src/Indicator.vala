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
    private Gtk.Grid event_grid;
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
            calendar.margin_top = 6;
            calendar.margin_bottom = 6;

            var settings_button = new Gtk.ModelButton ();
            settings_button.text = _("Date & Time Settings…");

            main_grid = new Gtk.Grid ();
            main_grid.halign = Gtk.Align.CENTER;
            main_grid.valign = Gtk.Align.START;
            main_grid.attach (calendar, 0, 0);
            main_grid.attach (new Wingpanel.Widgets.Separator (), 0, 2);
            main_grid.attach (settings_button, 0, 3);

            calendar.day_double_click.connect (() => {
                close ();
            });

            calendar.selection_changed.connect ((date) => {
                idle_update_events ();
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

        update_events_idle_source = GLib.Idle.add (update_events);
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
            return GLib.Source.REMOVE;
        }

        event_grid = new Gtk.Grid ();
        event_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.attach (event_grid, 0, 1);

        foreach (var e in events) {
            var menuitem_icon = new Gtk.Image.from_icon_name (e.get_icon (), Gtk.IconSize.MENU);
            menuitem_icon.valign = Gtk.Align.START;

            var menuitem_label = new Gtk.Label ("");
            menuitem_label.set_markup ("<b>%s</b>".printf (e.get_event_label ()));
            menuitem_label.hexpand = true;
            menuitem_label.lines = 3;
            menuitem_label.ellipsize = Pango.EllipsizeMode.END;
            menuitem_label.max_width_chars = 30;
            menuitem_label.wrap = true;
            menuitem_label.wrap_mode = Pango.WrapMode.WORD_CHAR;
            menuitem_label.xalign = 0;

            var menuitem_times = new Gtk.Label ("");
            menuitem_times.set_markup ("<small>%s</small>".printf (e.get_event_times ()));
            menuitem_times.ellipsize = Pango.EllipsizeMode.END;
            menuitem_times.max_width_chars = 30;
            menuitem_times.wrap = true;
            menuitem_times.wrap_mode = Pango.WrapMode.WORD_CHAR;
            menuitem_times.xalign = 0;
            menuitem_times.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

            var menuitem_box = new Gtk.Grid ();
            menuitem_box.margin_end = 6;
            menuitem_box.margin_start = 6;
            menuitem_box.attach (menuitem_icon, 0, 0);
            menuitem_box.attach (menuitem_label, 1, 0);
            if (!e.day_event) {
                menuitem_box.attach (menuitem_times, 1, 1);
            }

            var menuitem = new Gtk.Button ();
            menuitem.add (menuitem_box);

            var style_context = menuitem.get_style_context ();
            style_context.add_class (Gtk.STYLE_CLASS_MENUITEM);
            style_context.remove_class (Gtk.STYLE_CLASS_BUTTON);
            style_context.remove_class ("text-button");

            event_grid.add (menuitem);
            menuitem.clicked.connect (() => {
                calendar.show_date_in_maya (e.date);
                this.close ();
            });
        }

        event_grid.show_all ();
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
