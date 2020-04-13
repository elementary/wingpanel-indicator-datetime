namespace DateTimeIndicator {
    public class Services.EventsManager : GLib.Object {
        public signal void events_added (E.Source source, Gee.Collection<ECal.Component> events);
        public signal void events_updated (E.Source source, Gee.Collection<ECal.Component> events);
        public signal void events_removed (E.Source source, Gee.Collection<ECal.Component> events);

        public HashTable<E.Source, Gee.TreeMultiMap<string, ECal.Component>> source_events { get; private set; }

        private E.SourceRegistry registry { get; private set; }
        private HashTable<string, ECal.Client> source_client;
        private HashTable<string, ECal.ClientView> source_view;

        construct {
            source_client = new HashTable<string, ECal.Client> (str_hash, str_equal);
            source_events = new HashTable<E.Source, Gee.TreeMultiMap<string, ECal.Component> > (Util.source_hash_func, Util.source_equal_func);
            source_view = new HashTable<string, ECal.ClientView> (str_hash, str_equal);
        }

        public async void open () {
            try {
                registry = yield new E.SourceRegistry (null);
                registry.source_removed.connect (remove_source);
                registry.source_added.connect (add_source);

                // Add sources
                registry.list_sources (E.SOURCE_EXTENSION_CALENDAR).foreach ((source) => {
                    E.SourceCalendar cal = (E.SourceCalendar) source.get_extension (E.SOURCE_EXTENSION_CALENDAR);
                    if (cal.selected == true && source.enabled == true) {
                        add_source (source);
                    }
                });
            } catch (GLib.Error error) {
                critical (error.message);
            }
        }

        public void load_all_sources () {
            lock (source_client) {
                foreach (var id in source_client.get_keys ()) {
                    var source = registry.ref_source (id);
                    E.SourceCalendar cal = (E.SourceCalendar) source.get_extension (E.SOURCE_EXTENSION_CALENDAR);

                    if (cal.selected == true && source.enabled == true) {
                        load_source (source);
                    }
                }
            }
        }

        private void remove_source (E.Source source) {
            debug ("Removing source '%s'", source.dup_display_name ());
            /* Already out of the model, so do nothing */
            unowned string uid = source.get_uid ();

            if (!source_view.contains (uid)) {
                return;
            }

            var current_view = source_view.get (uid);
            try {
                current_view.stop ();
            } catch (Error e) {
                warning (e.message);
            }

            source_view.remove (uid);
            lock (source_client) {
                source_client.remove (uid);
            }

            var events = source_events.get (source).get_values ().read_only_view;
            events_removed (source, events);
            source_events.remove (source);
        }

        private void load_source (E.Source source) {
            var model = Models.CalendarModel.get_default ();

            /* create empty source-event map */
            var events = new Gee.TreeMultiMap<string, ECal.Component> (
                (GLib.CompareDataFunc<ECal.Component>?) GLib.strcmp,
                (GLib.CompareDataFunc<ECal.Component>?) Util.calcomponent_compare_func
            );
            source_events.set (source, events);
            /* query client view */
            var iso_first = ECal.isodate_from_time_t ((time_t) model.data_range.first_dt.to_unix ());
            var iso_last = ECal.isodate_from_time_t ((time_t) model.data_range.last_dt.add_days (1).to_unix ());
            var query = @"(occur-in-time-range? (make-time \"$iso_first\") (make-time \"$iso_last\"))";

            ECal.Client client;
            lock (source_client) {
                client = source_client.get (source.dup_uid ());
            }

            if (client == null) {
                return;
            }

            debug ("Getting client-view for source '%s'", source.dup_display_name ());
            client.get_view.begin (query, null, (obj, results) => {
                var view = on_client_view_received (results, source, client);
                view.objects_added.connect ((objects) => on_objects_added (source, client, objects));
                view.objects_removed.connect ((objects) => on_objects_removed (source, client, objects));
                view.objects_modified.connect ((objects) => on_objects_modified (source, client, objects));
                try {
                    view.start ();
                } catch (Error e) {
                    critical (e.message);
                }

                source_view.set (source.dup_uid (), view);
            });
        }

        private void add_source (E.Source source) {
            debug ("Adding source '%s'", source.dup_display_name ());
            try {
                var client = (ECal.Client) ECal.Client.connect_sync (source, ECal.ClientSourceType.EVENTS, -1, null);
                source_client.insert (source.dup_uid (), client);
            } catch (Error e) {
                critical (e.message);
            }

            load_source (source);
        }

        private void debug_event (E.Source source, ECal.Component event) {
            unowned ICal.Component comp = event.get_icalcomponent ();
            debug (@"Event ['$(comp.get_summary())', $(source.dup_display_name()), $(comp.get_uid()))]");
        }

        private ECal.ClientView on_client_view_received (AsyncResult results, E.Source source, ECal.Client client) {
            ECal.ClientView view;
            try {
                debug ("Received client-view for source '%s'", source.dup_display_name ());
                bool status = client.get_view.end (results, out view);
                assert (status == true);
            } catch (Error e) {
                critical ("Error loading client-view from source '%s': %s", source.dup_display_name (), e.message);
            }

            return view;
        }

#if E_CAL_2_0
        private void on_objects_added (E.Source source, ECal.Client client, SList<ICal.Component> objects) {
#else
        private void on_objects_added (E.Source source, ECal.Client client, SList<weak ICal.Component> objects) {
#endif
            debug (@"Received $(objects.length()) added event(s) for source '%s'", source.dup_display_name ());
            var events = source_events.get (source);
            var added_events = new Gee.ArrayList<ECal.Component> ((Gee.EqualDataFunc<ECal.Component>?) Util.calcomponent_equal_func);
            var model = Models.CalendarModel.get_default ();
            objects.foreach ((comp) => {
                unowned string uid = comp.get_uid ();
#if E_CAL_2_0
                client.generate_instances_for_object_sync (comp, (time_t) model.data_range.first_dt.to_unix (), (time_t) model.data_range.last_dt.to_unix (), null, (comp, start, end) => {
                    var event = new ECal.Component.from_icalcomponent (comp);
#else
                client.generate_instances_for_object_sync (comp, (time_t) model.data_range.first_dt.to_unix (), (time_t) model.data_range.last_dt.to_unix (), (event, start, end) => {
#endif
                    debug_event (source, event);
                    events.set (uid, event);
                    added_events.add (event);
                    return true;
                });
            });

            events_added (source, added_events.read_only_view);
        }

#if E_CAL_2_0
        private void on_objects_modified (E.Source source, ECal.Client client, SList<ICal.Component> objects) {
#else
        private void on_objects_modified (E.Source source, ECal.Client client, SList<weak ICal.Component> objects) {
#endif
            debug (@"Received $(objects.length()) modified event(s) for source '%s'", source.dup_display_name ());
            var updated_events = new Gee.ArrayList<ECal.Component> ((Gee.EqualDataFunc<ECal.Component>?) Util.calcomponent_equal_func);

            objects.foreach ((comp) => {
                unowned string uid = comp.get_uid ();
                var events = source_events.get (source).get (uid);
                updated_events.add_all (events);
                foreach (var event in events) {
                    debug_event (source, event);
                }
            });

            events_updated (source, updated_events.read_only_view);
        }

#if E_CAL_2_0
        private void on_objects_removed (E.Source source, ECal.Client client, SList<ECal.ComponentId?> cids) {
#else
        private void on_objects_removed (E.Source source, ECal.Client client, SList<weak ECal.ComponentId?> cids) {
#endif
            debug (@"Received $(cids.length()) removed event(s) for source '%s'", source.dup_display_name ());
            var events = source_events.get (source);
            var removed_events = new Gee.ArrayList<ECal.Component> ((Gee.EqualDataFunc<ECal.Component>?) Util.calcomponent_equal_func);

            cids.foreach ((cid) => {
                if (cid == null) {
                    return;
                }

                var comps = events.get (cid.get_uid ());
                foreach (ECal.Component event in comps) {
                    removed_events.add (event);
                    debug_event (source, event);
                }
            });

            events_removed (source, removed_events.read_only_view);
        }
    }
}
