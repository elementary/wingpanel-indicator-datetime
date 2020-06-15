/*
 * Copyright (c) 2011-2020 elementary, Inc. (https://elementary.io)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

public class CalendarStore : Object {

    public signal void error_received (GLib.Error e);

    /* Notifies when sources are added, updated, or removed */
    public signal void source_connecting (E.Source source, GLib.Cancellable cancellable);
    public signal void source_added (E.Source source);
    public signal void source_removed (E.Source source);

    /* Notifies when components are added, updated, or removed */
    public signal void components_added (Gee.Collection<ECal.Component> components, E.Source source);
    public signal void components_modified (Gee.Collection<ECal.Component> components, E.Source source);
    public signal void components_removed (Gee.Collection<ECal.Component> components, E.Source source);

    public ECal.ClientSourceType source_type { get; construct; }
    private E.SourceRegistry registry { get; private set; }
    private HashTable<string, ECal.Client> source_client;
    private HashTable<string, Gee.Collection<ECal.ClientView>> source_views;

    internal HashTable<string, Gee.TreeMultiMap<string, ECal.Component>> source_components;

    private GLib.Queue<E.Source> source_trash;
#if EDataServerUI
    private E.CredentialsPrompter credentials_prompter;
#endif
    private static GLib.Settings state_settings;

    private CalendarStore (ECal.ClientSourceType source_type) {
        Object (source_type: source_type);
    }

    private static CalendarStore? event_store = null;
    private static CalendarStore? task_store = null;

    public static CalendarStore get_event_store () {
        if (event_store == null)
            event_store = new CalendarStore (ECal.ClientSourceType.EVENTS);
        if (state_settings == null)
            state_settings = new GLib.Settings ("io.elementary.calendar.savedstate");
        return event_store;
    }

    public static CalendarStore get_task_store () {
        if (task_store == null)
            task_store = new CalendarStore (ECal.ClientSourceType.TASKS);
        if (state_settings == null)
            state_settings = new GLib.Settings ("io.elementary.tasks.savedstate");
        return task_store;
    }

    /* The start of week, ie. Monday=1 or Sunday=7 */
    public GLib.DateWeekday week_starts_on { get; set; default = GLib.DateWeekday.MONDAY; }

    /* The component that is currently dragged */
    public ECal.Component drag_component { get; set; }

    construct {
        open.begin ();

        source_client = new HashTable<string, ECal.Client> (str_hash, str_equal);
        source_views = new HashTable<string, Gee.Collection<ECal.ClientView>> (str_hash, str_equal);
        source_components = new HashTable<string, Gee.TreeMultiMap<string, ECal.Component>> (str_hash, str_equal);

        int week_start = Posix.NLTime.FIRST_WEEKDAY.to_string ().data[0];
        if (week_start >= 1 && week_start <= 7) {
            week_starts_on = (GLib.DateWeekday) (week_start - 1);
        }

        if (source_type == ECal.ClientSourceType.EVENTS) {
            events_month_start = Util.get_start_of_month (events_get_page ());
            events_compute_ranges ();
            notify["events-month-start"].connect (events_on_parameter_changed);
        }
    }

    private async void open () {
        try {
            registry = yield new E.SourceRegistry (null);
#if EDataServerUI
            credentials_prompter = new E.CredentialsPrompter (registry);
            credentials_prompter.set_auto_prompt (true);
#endif

            registry.source_added.connect (on_source_added_to_backend);
            registry.source_changed.connect (on_source_changed_in_backend);
            registry.source_removed.connect (on_source_removed_from_backend);

            // Connect to Sources
            list_sources ().foreach ((source) => {
                on_source_added_to_backend (source);
            });

        } catch (Error error) {
            critical (error.message);
        }
    }

    //--- Public Source API ---//

    public E.Source get_source_by_uid (string uid) {
        return registry.ref_source (uid);
    }

    public bool is_source_enabled (E.Source source) {
        switch (source_type) {
            case ECal.ClientSourceType.EVENTS:
                E.SourceCalendar cal = (E.SourceCalendar)source.get_extension (E.SOURCE_EXTENSION_CALENDAR);
                return cal.selected == true && source.enabled == true;

            case ECal.ClientSourceType.TASKS:
                E.SourceTaskList list = (E.SourceTaskList)source.get_extension (E.SOURCE_EXTENSION_TASK_LIST);
                return list.selected == true && source.enabled == true;

            default:
                return false;
        }
    }

    public bool is_source_readonly (E.Source source) {
        ECal.Client client;
        lock (source_client) {
            client = source_client.get (source.get_uid ());
        }

        if (client != null) {
            return client.is_readonly ();
        } else {
            critical ("No client was found for source '%s'", source.dup_display_name ());
        }

        return true;
    }

    public void trash_source (E.Source source) {
        source_trash.push_tail (source);
        on_source_removed_from_backend (source);
        source.set_enabled (false);
    }

    public void restore_source () {
        if (source_trash.is_empty ())
            return;

        var source = source_trash.pop_tail ();
        source.set_enabled (true);
        on_source_added_to_backend (source);
    }

    public void delete_trashed_sources () {
        E.Source source = source_trash.pop_tail ();
        while (source != null) {
            source.remove.begin (null);
            source = source_trash.pop_tail ();
        }
    }

    /**
     * We need to pass a valid S-expression as query to guarantee the callback events are fired.
     *
     * See `e-cal-backend-sexp.c` of evolution-data-server for available S-expressions:
     * https://gitlab.gnome.org/GNOME/evolution-data-server/-/blob/master/src/calendar/libedata-cal/e-cal-backend-sexp.c
     **/
    public void add_view (E.Source source, string sexp) throws Error {
        ECal.Client client;
        lock (source_client) {
            client = source_client.get (source.get_uid ());
        }
        debug ("Adding view for source '%s'", source.dup_display_name ());

        ECal.ClientView view;
        client.get_view_sync (sexp, out view, null);

        view.objects_added.connect ((objects) => on_objects_added_to_backend (source, objects));
        view.objects_modified.connect ((objects) => on_objects_modified_in_backend (source, objects));
        view.objects_removed.connect ((objects) => on_objects_removed_from_backend (source, objects));
        view.start ();

        lock (source_views) {
            var views = source_views.get (source.dup_uid ());

            if (views == null) {
                views = new Gee.ArrayList<ECal.ClientView> ((Gee.EqualDataFunc<ECal.ClientView>?) direct_equal);
            }
            views.add (view);

            source_views.set (source.dup_uid (), views);
        }
    }

    //--- Public Component API ---//

    public void add_component (E.Source source, ECal.Component component) {
        var components = new Gee.ArrayList<ECal.Component> ((Gee.EqualDataFunc<ECal.Component>?) Util.calcomponent_equal_func);  // vala-lint=line-length
        components.add (component);

        components_added (components.read_only_view, source);
        add_component_to_backend.begin (source, component, (obj, res) => {
            components_removed (components.read_only_view, source);
            components.clear ();

            try {
                components.add (add_component_to_backend.end (res));
                components_added (components.read_only_view, source);

            } catch (Error e) {
                error_received (e);
                critical (e.message);
            }
        });
    }

    public void modify_component (E.Source source, ECal.Component component, ECal.ObjModType mod_type) {
        var components = new Gee.ArrayList<ECal.Component> ((Gee.EqualDataFunc<ECal.Component>?) Util.calcomponent_equal_func);  // vala-lint=line-length
        components.add (component);

        components_modified (components.read_only_view, source);
        modify_component_in_backend.begin (source, component, mod_type, (obj, res) => {
            components.clear ();

            try {
                components.add (modify_component_in_backend.end (res));
                components_modified (components.read_only_view, source);

            } catch (Error e) {
                error_received (e);
                critical (e.message);
            }
        });
    }

    public void remove_component (E.Source source, ECal.Component component, ECal.ObjModType mod_type) {
        var components = new Gee.ArrayList<ECal.Component> ((Gee.EqualDataFunc<ECal.Component>?) Util.calcomponent_equal_func);  // vala-lint=line-length
        components.add (component);

        components_removed (components.read_only_view, source);
        remove_component_from_backend.begin (source, component, mod_type, (obj, res) => {
            try {
                remove_component_from_backend.end (res);

            } catch (Error e) {
                components_added (components.read_only_view, source);
                error_received (e);
                critical (e.message);
            }
        });
    }

    //--- Helper Methods To Display Calendar Events --//

    /* The events_month_start, events_num_weeks, or week_starts_on have been changed */
    public signal void events_parameters_changed ();

    /* The data_range is the range of dates for which this model is storing
     * data. The month_range is a subset of this range corresponding to the
     * calendar month that is being focused on. In summary:
     *
     * data_range.first_dt <= month_range.first_dt < month_range.last_dt <= data_range.last_dt
     *
     * There is no way to set the ranges publicly. They can only be modified by
     * changing one of the following properties: month_start, num_weeks, and
     * week_starts_on.
    */
    public Util.DateRange events_data_range { get; private set; }
    public Util.DateRange events_month_range { get; private set; }

    /* The first day of the month */
    public GLib.DateTime events_month_start { get; set; }

    /* The number of weeks to show */
    public int events_num_weeks { get; private set; default = 6; }

    public void events_change_month (int relative) {
        events_month_start = events_month_start.add_months (relative);
    }

    public void events_change_year (int relative) {
        events_month_start = events_month_start.add_years (relative);
    }

    public void events_load_all_sources () {
        lock (source_client) {
            foreach (var uid in source_client.get_keys ()) {
                var source = get_source_by_uid (uid);

                if (is_source_enabled (source)) {
                    events_load_source (source);
                }
            }
        }
    }

    private void events_load_source (E.Source source) {
        var iso_first = ECal.isodate_from_time_t ((time_t) events_data_range.first_dt.to_unix ());
        var iso_last = ECal.isodate_from_time_t ((time_t) events_data_range.last_dt.add_days (1).to_unix ());
        var query = @"(occur-in-time-range? (make-time \"$iso_first\") (make-time \"$iso_last\"))";

        try {
            add_view (source, query);
        } catch (Error e) {
            error_received (e);
            critical ("Error from source '%s': %s", source.dup_display_name (), e.message);
        }
    }

    private void events_on_parameter_changed () {
        events_compute_ranges ();
        events_parameters_changed ();
        events_load_all_sources ();
    }

    private GLib.DateTime events_get_page () {
        var events_month_page = state_settings.get_string ("events-month-page");
        if (events_month_page == null || events_month_page == "") {
            return new GLib.DateTime.now_local ();
        }

        var numbers = events_month_page.split ("-", 2);
        var dt = new GLib.DateTime.local (int.parse (numbers[0]), 1, 1, 0, 0, 0);
        dt = dt.add_months (int.parse (numbers[1]) - 1);
        return dt;
    }

    private void events_compute_ranges () {
        state_settings.set_string ("events-month-page", events_month_start.format ("%Y-%m"));

        var events_month_end = events_month_start.add_full (0, 1, -1);
        events_month_range = new Util.DateRange (events_month_start, events_month_end);

        int dow = events_month_start.get_day_of_week ();
        int wso = (int) week_starts_on;
        int offset = 0;

        if (wso < dow) {
            offset = dow - wso;
        } else if (wso > dow) {
            offset = 7 + dow - wso;
        }

        var data_range_first = events_month_start.add_days (-offset);

        dow = events_month_end.get_day_of_week ();
        wso = (int) (week_starts_on + 6);

        // WSO must be between 1 and 7
        if (wso > 7)
            wso = wso - 7;

        offset = 0;

        if (wso < dow)
            offset = 7 + wso - dow;
        else if (wso > dow)
            offset = wso - dow;

        var data_range_last = events_month_end.add_days (offset);

        events_data_range = new Util.DateRange (data_range_first, data_range_last);
        events_num_weeks = events_data_range.to_list ().size / 7;

        debug (@"Events date ranges: ($data_range_first <= $events_month_start < $events_month_end <= $data_range_last)");  // vala-lint=line-length
    }

    //--- Private Source Utilities --//

    private List<E.Source>? list_sources () {
        if (registry != null) {
            switch (source_type) {
                case ECal.ClientSourceType.EVENTS:
                    return registry.list_sources (E.SOURCE_EXTENSION_CALENDAR);
                case ECal.ClientSourceType.TASKS:
                    return registry.list_sources (E.SOURCE_EXTENSION_TASK_LIST);
            }
        }
        return null;
    }

    //--- Private Source Event Handlers --//

    private void on_source_added_to_backend (E.Source source) {
        if (is_source_enabled (source)) {
            connect_source.begin (source);
        }
    }

    private void on_source_changed_in_backend (E.Source source) {
        if (is_source_enabled (source)) {
            connect_source.begin (source);
        } else {
            disconnect_source.begin (source);
        }
    }

    private void on_source_removed_from_backend (E.Source source) {
        disconnect_source.begin (source);
    }

    private async void connect_source (E.Source source) {
        unowned string source_uid = source.get_uid ();

        if (source_client.contains (source_uid)) {
            return;
        }
        debug ("Connecting source '%s'", source.dup_display_name ());

        var cancellable = new GLib.Cancellable ();
        source_connecting (source, cancellable);

        try {
            var client = (ECal.Client) yield ECal.Client.connect (source, source_type, 30, cancellable);

            lock (source_client) {
                source_client.insert (source_uid, client);
            }

            // create empty source-component map
            var components = new Gee.TreeMultiMap<string, ECal.Component> (
                (GLib.CompareDataFunc<string>?) GLib.strcmp,
                (GLib.CompareDataFunc<ECal.Component>?) Util.calcomponent_compare_func);
            source_components.set (source_uid, components);

            Idle.add (() => {
                source_added (source);

                if (source_type == ECal.ClientSourceType.EVENTS) {
                    events_load_source (source);
                }
                return GLib.Source.REMOVE;
            });

        } catch (Error e) {
            error_received (e);
            warning (e.message);
        }
    }

    private async void disconnect_source (E.Source source) {
        unowned string source_uid = source.get_uid ();

        if (!source_client.contains (source_uid)) {
            return;
        }
        debug ("Disconnecting source '%s'", source.dup_display_name ());

        lock (source_views) {
            unowned Gee.Collection<ECal.ClientView> all_source_views = source_views.get (source_uid);

            if (all_source_views != null && all_source_views.is_empty) {
                all_source_views.foreach ((view) => {
                    try {
                        view.stop ();
                    } catch (Error e) {
                        warning (e.message);
                    }
                    return GLib.Source.CONTINUE;
                });
                source_views.remove (source_uid);
            }
        }

        lock (source_client) {
            source_client.remove (source_uid);
        }
        source_removed (source);

        var components = source_components.get (source_uid).get_values ().read_only_view;
        components_removed (components, source);
        source_components.remove (source_uid);

        source_removed (source);
    }

    //--- Private Component Event Handlers ---//

    private async ECal.Component add_component_to_backend (E.Source source, ECal.Component component) throws Error {
        var added_component = component.clone ();

        unowned ICal.Component comp = added_component.get_icalcomponent ();
        debug (@"Adding component '$(comp.get_uid())'");

        ECal.Client client;
        lock (source_client) {
            client = source_client.get (source.get_uid ());
        }

        string? uid;
#if E_CAL_2_0
        yield client.create_object (comp, ECal.OperationFlags.NONE, null, out uid);
#else
        yield client.create_object (comp, null, out uid);
#endif
        if (uid != null) {
            added_component.set_uid (uid);
        }
        return added_component;
    }

    private async ECal.Component modify_component_in_backend (E.Source source, ECal.Component component, ECal.ObjModType mod_type) throws Error {
        var modified_component = component.clone ();

        unowned ICal.Component comp = modified_component.get_icalcomponent ();
        debug (@"Updating component '$(comp.get_uid())' [mod_type=$(mod_type)]");

        ECal.Client client;
        lock (source_client) {
            client = source_client.get (source.get_uid ());
        }

#if E_CAL_2_0
        yield client.modify_object (comp, mod_type, ECal.OperationFlags.NONE, null);
#else
        yield client.modify_object (comp, mod_type, null);
#endif
        return modified_component;
    }

    private async void remove_component_from_backend (E.Source source, ECal.Component component, ECal.ObjModType mod_type) throws Error {  // vala-lint=line-length
        unowned ICal.Component comp = component.get_icalcomponent ();
        string uid = comp.get_uid ();
        string? rid = null;

        if (component.has_recurrences () && mod_type != ECal.ObjModType.ALL) {
            rid = component.get_recurid_as_string ();
            debug (@"Removing recurrent component '$rid'");
        }

        debug (@"Removing component '$uid'");
        ECal.Client client;
        lock (source_client) {
            client = source_client.get (source.get_uid ());
        }

#if E_CAL_2_0
        yield client.remove_object (uid, rid, mod_type, ECal.OperationFlags.NONE, null);
#else
        yield client.remove_object (uid, rid, mod_type, null);
#endif
    }

#if E_CAL_2_0
    private void on_objects_added_to_backend (E.Source source, SList<ICal.Component> objects) {
#else
    private void on_objects_added_to_backend (E.Source source, SList<weak ICal.Component> objects) {
#endif
        debug (@"Received $(objects.length()) added component(s) for source '%s'", source.dup_display_name ());
        var added_components = new Gee.ArrayList<ECal.Component> ((Gee.EqualDataFunc<ECal.Component>?) Util.calcomponent_equal_func);  // vala-lint=line-length

        ECal.Client client;
        lock (source_client) {
            client = source_client.get (source.get_uid ());
        }
        var source_comps = source_components.get (source.get_uid ());

        objects.foreach ((ical_comp) => {
            unowned string uid = ical_comp.get_uid ();

            try {
                SList<ECal.Component> ecal_comps;

                if (source_type == ECal.ClientSourceType.EVENTS) {
#if E_CAL_2_0
                    client.generate_instances_for_object_sync (ical_comp, (time_t) events_data_range.first_dt.to_unix (), (time_t) events_data_range.last_dt.to_unix (), null, (comp, start, end) => {  // vala-lint=line-length
                        var ecal_comp = new ECal.Component.from_icalcomponent (comp);
#else
                    client.generate_instances_for_object_sync (ical_comp, (time_t) events_data_range.first_dt.to_unix (), (time_t) events_data_range.last_dt.to_unix (), (comp, start, end) => {  // vala-lint=line-length
#endif
                        debug_component (source, comp);
                        source_comps.set (uid, comp);
                        added_components.add (comp);
                        return true;
                    });

                } else {
                    client.get_objects_for_uid_sync (ical_comp.get_uid (), out ecal_comps, null);

                    ecal_comps.foreach ((ecal_comp) => {
                        debug_component (source, ecal_comp);

                        if (!added_components.contains (ecal_comp)) {
                            added_components.add (ecal_comp);
                            source_comps.set (uid, ecal_comp);
                        }
                    });
                }

            } catch (Error e) {
                warning (e.message);
            }
        });

        if (!added_components.is_empty) {
            components_added (added_components.read_only_view, source);
        }
    }

#if E_CAL_2_0
    private void on_objects_modified_in_backend (E.Source source, SList<ICal.Component> objects) {
#else
    private void on_objects_modified_in_backend (E.Source source, SList<weak ICal.Component> objects) {
#endif
        debug (@"Received $(objects.length()) modified component(s) for source '%s'", source.dup_display_name ());
        var modified_components = new Gee.ArrayList<ECal.Component> ((Gee.EqualDataFunc<ECal.Component>?) Util.calcomponent_equal_func);  // vala-lint=line-length

        ECal.Client client;
        lock (source_client) {
            client = source_client.get (source.get_uid ());
        }

        objects.foreach ((ical_comp) => {
            try {
                SList<ECal.Component> ecal_comps;
                client.get_objects_for_uid_sync (ical_comp.get_uid (), out ecal_comps, null);

                ecal_comps.foreach ((ecal_comp) => {
                    debug_component (source, ecal_comp);

                    if (!modified_components.contains (ecal_comp)) {
                        modified_components.add (ecal_comp);
                    }
                });

            } catch (Error e) {
                warning (e.message);
            }
        });

        if (!modified_components.is_empty) {
            components_modified (modified_components.read_only_view, source);
        }
    }

#if E_CAL_2_0
    private void on_objects_removed_from_backend (E.Source source, SList<ECal.ComponentId?> cids) {
#else
    private void on_objects_removed_from_backend (E.Source source, SList<weak ECal.ComponentId?> cids) {
#endif
        debug (@"Received $(cids.length()) removed component(s) for source '%s'", source.dup_display_name ());
        var removed_components = new Gee.ArrayList<ECal.Component> ((Gee.EqualDataFunc<ECal.Component>?) Util.calcomponent_equal_func);  // vala-lint=line-length
        var source_comps = source_components.get (source.get_uid ());

        cids.foreach ((cid) => {
            if (cid == null) {
                return;
            }

            var comps = source_comps.get (cid.get_uid ());
            foreach (ECal.Component comp in comps) {
                removed_components.add (comp);
                debug_component (source, comp);
            }
        });

        if (!removed_components.is_empty) {
            components_removed (removed_components.read_only_view, source);
        }
    }

    private void debug_component (E.Source source, ECal.Component component) {
        unowned ICal.Component comp = component.get_icalcomponent ();
        debug (@"Component ['$(comp.get_summary())', $(source.dup_display_name()), $(comp.get_uid()))]");
    }
}
