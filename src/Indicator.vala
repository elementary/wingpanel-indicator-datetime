/*
 * Copyright (c) 2011-2019 elementary, Inc. (https://elementary.io)
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
    private Widgets.CalendarModel default_calendar_model;
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
        default_calendar_model = Widgets.CalendarModel.get_default ();

        panel_label = new Widgets.PanelLabel ();

        calendar = new Widgets.Calendar ();
        calendar.margin_top = 6;
        calendar.margin_bottom = 6;

        var settings_button = new Gtk.ModelButton ();
        settings_button.text = _("Date & Time Settings…");

        main_grid = new Gtk.Grid ();
        main_grid.attach (calendar, 0, 0);
        // event_grid gets attached here when created
        main_grid.attach (new Wingpanel.Widgets.Separator (), 0, 2);
        main_grid.attach (settings_button, 0, 3);

        visible = true;

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

    public override Gtk.Widget get_display_widget () {
        return panel_label;
    }

    public override Gtk.Widget? get_widget () {
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

        var events = default_calendar_model.get_events (calendar.selected_date);
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

            var menuitem_label = new Gtk.Label (e.get_label ());
            menuitem_label.hexpand = true;
            menuitem_label.lines = 3;
            menuitem_label.ellipsize = Pango.EllipsizeMode.END;
            menuitem_label.max_width_chars = 30;
            menuitem_label.wrap = true;
            menuitem_label.wrap_mode = Pango.WrapMode.WORD_CHAR;
            menuitem_label.xalign = 0;

            var menuitem_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            menuitem_box.margin_end = 6;
            menuitem_box.margin_start = 6;
            menuitem_box.add (menuitem_icon);
            menuitem_box.add (menuitem_label);

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

        default_calendar_model.events_added.connect (update_events_model);
        default_calendar_model.events_updated.connect (update_events_model);
        default_calendar_model.events_removed.connect (update_events_model);
    }

    public override void closed () {
        default_calendar_model.events_added.disconnect (update_events_model);
        default_calendar_model.events_updated.disconnect (update_events_model);
        default_calendar_model.events_removed.disconnect (update_events_model);
    }
}

public Wingpanel.Indicator get_indicator (Module module) {
    debug ("Activating DateTime Indicator");
    var indicator = new DateTime.Indicator ();

    return indicator;
}
