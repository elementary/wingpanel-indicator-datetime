/*
 * Copyright (c) 2011-2016 Wingpanel Developers (http://launchpad.net/wingpanel)
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
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

public class DateTime.Indicator : Wingpanel.Indicator {
    private Widgets.PanelLabel panel_label;

    private Gtk.Grid main_grid;

    private Widgets.Calendar calendar;

    private Wingpanel.Widgets.Button settings_button;

    private Gtk.Box event_box;

    public Indicator () {
        Object (code_name: Wingpanel.Indicator.DATETIME,
                display_name: _("Date & Time"),
                description: _("The date and time indicator"));
    }

    public override Gtk.Widget get_display_widget () {
        if (panel_label == null) {
            panel_label = new Widgets.PanelLabel ();
        }

        return panel_label;
    }

    public override Gtk.Widget? get_widget () {
        if (main_grid == null) {
            int position = 0;
            main_grid = new Gtk.Grid ();

            calendar = new Widgets.Calendar ();
            calendar.day_double_click.connect (() => {
                this.close ();
            });
            calendar.margin_top = 6;
            calendar.margin_bottom = 6;
            calendar.selection_changed.connect ((date) => {
                Idle.add (update_events);
            });
            main_grid.attach (calendar, 0, position++, 1, 1);

            event_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            main_grid.attach (event_box, 0, position++, 1, 1);

            settings_button = new Wingpanel.Widgets.Button (_("Date & Time Settings…"));
            settings_button.clicked.connect (() => {
                show_settings ();
                this.close ();
            });

            main_grid.attach (new Wingpanel.Widgets.Separator (), 0, position++, 1, 1);

            main_grid.attach (settings_button, 0, position++, 1, 1);
        }

        this.visible = true;

        return main_grid;
    }

    private void update_events_model (E.Source source, Gee.Collection<E.CalComponent> events) {
        Idle.add (update_events);
    }

    private bool update_events () {
        foreach (var w in event_box.get_children ()) {
            w.destroy ();
        }
        foreach (var e in Widgets.CalendarModel.get_default ().get_events (calendar.selected_date)) {
                var menuitem_icon = new Gtk.Image.from_icon_name (e.get_icon (), Gtk.IconSize.MENU);
                menuitem_icon.valign = Gtk.Align.START;

                var menuitem_label = new Gtk.Label (e.get_label ());
                menuitem_label.hexpand = true;
                menuitem_label.max_width_chars = 1;
                menuitem_label.wrap = true;
                menuitem_label.xalign = 0;

                var menuitem_grid = new Gtk.Grid ();
                menuitem_grid.column_spacing = 6;
                menuitem_grid.margin_end = 6;
                menuitem_grid.margin_start = 6;
                menuitem_grid.add (menuitem_icon);
                menuitem_grid.add (menuitem_label);

                var menuitem = new Gtk.Button ();
                menuitem.add (menuitem_grid);

                var style_context = menuitem.get_style_context ();
                style_context.add_class (Gtk.STYLE_CLASS_MENUITEM);
                style_context.remove_class (Gtk.STYLE_CLASS_BUTTON);
                style_context.remove_class ("text-button");

                event_box.add (menuitem);
                menuitem.clicked.connect (() => {
                    calendar.show_date_in_maya (e.date);
                    this.close ();
                });
        }

        event_box.show_all ();
        return false;
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

    private void show_settings () {
        close ();

        var list = new List<string> ();
        list.append ("datetime");

        try {
            var appinfo = AppInfo.create_from_commandline ("switchboard", null, AppInfoCreateFlags.SUPPORTS_URIS);
            appinfo.launch_uris (list, null);
        } catch (Error e) {
            warning ("%s\n", e.message);
        }
    }
}

public Wingpanel.Indicator get_indicator (Module module) {
    debug ("Activating DateTime Indicator");
    var indicator = new DateTime.Indicator ();

    return indicator;
}
