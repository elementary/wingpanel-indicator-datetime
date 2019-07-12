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
    private Gtk.ListBox event_listbox;
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
            event_listbox.margin_start = 12;
            event_listbox.margin_end = 12;
            event_listbox.selection_mode = Gtk.SelectionMode.NONE;
            event_listbox.set_placeholder (placeholder_label);

            var settings_button = new Gtk.ModelButton ();
            settings_button.text = _("Date & Time Settings…");

            var provider = new Gtk.CssProvider ();
            provider.load_from_resource ("/io/elementary/desktop/wingpanel/datetime/ControlHeader.css");
            var header_label = new Gtk.Label (_("Events"));
            header_label.get_style_context ().add_class ("header-label");
            header_label.get_style_context ().add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            header_label.halign = Gtk.Align.START;
            header_label.hexpand = true;
            header_label.margin_start = 6;

            var cal_icon = new Gtk.Image.from_icon_name ("office-calendar", Gtk.IconSize.LARGE_TOOLBAR);
            cal_icon.halign = Gtk.Align.END;
            var cal_button = new Gtk.Button ();
            cal_button.set_image (cal_icon);
            cal_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
            cal_button.get_style_context ().remove_class (Gtk.STYLE_CLASS_BUTTON);
            cal_button.get_style_context ().remove_class ("text-button");
            cal_button.set_tooltip_text (_("Open Calendar"));

            var header_grid = new Gtk.Grid ();
            header_grid.attach (header_label, 0, 0);
            header_grid.attach (cal_button, 1, 0);

            var event_pane = new Gtk.Grid ();
            event_pane.margin_top = 0;
            event_pane.row_spacing = 6;
            event_pane.orientation = Gtk.Orientation.VERTICAL;
            event_pane.add (header_grid);
            event_pane.add (event_listbox);

            main_grid = new Gtk.Grid ();
            main_grid.margin_top = 12;
            main_grid.attach (calendar, 0, 0);
            main_grid.attach (new Gtk.Separator (Gtk.Orientation.VERTICAL), 1, 0);
            main_grid.attach (event_pane, 2, 0);
            main_grid.attach (new Wingpanel.Widgets.Separator (), 0, 2, 3);
            main_grid.attach (settings_button, 0, 3, 3);

            var size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
            size_group.add_widget (calendar);
            size_group.add_widget (event_listbox);

            calendar.day_double_click.connect (() => {
                close ();
            });

            calendar.selection_changed.connect ((date) => {
                idle_update_events ();
            });

            event_listbox.row_activated.connect ((row) => {
                calendar.show_date_in_maya (((DateTime.EventRow) row).cal_event.date);
                close ();
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
        foreach (unowned Gtk.Widget widget in event_listbox.get_children ()) {
            widget.destroy ();
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

        foreach (var event in events) {
            var menuitem = new DateTime.EventRow (event);

            event_listbox.add (menuitem);
        }

        event_listbox.show_all ();
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
