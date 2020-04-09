namespace DateTimeIndicator {
    public class Widgets.EventsListBox : Gtk.ListBox {

        public EventsListBox () {
            selection_mode = Gtk.SelectionMode.NONE;

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

            set_header_func (header_update_func);
            set_placeholder (placeholder_label);
            set_sort_func (sort_function);
        }

        public void update_events (GLib.DateTime? selected_date) {
            foreach (unowned Gtk.Widget widget in get_children ()) {
                widget.destroy ();
            }

            if (selected_date == null) {
                return;
            }

            var model = Models.CalendarModel.get_default ();

            var events_on_day = new Gee.TreeMap<string, EventRow> ();

            model.source_events.@foreach ((source, component_map) => {
                foreach (var comp in component_map.get_values ()) {
                    if (Util.calcomp_is_on_day (comp, selected_date)) {
                        unowned ICal.Component ical = comp.get_icalcomponent ();
                        var event_uid = ical.get_uid ();
                        if (!events_on_day.has_key (event_uid)) {
                            events_on_day[event_uid] = new EventRow (selected_date, ical, source);

                            add (events_on_day[event_uid]);
                        }
                    }
                }
            });

            show_all ();
            return;
        }

        private void header_update_func (Gtk.ListBoxRow lbrow, Gtk.ListBoxRow? lbbefore) {
            var row = (EventRow) lbrow;
            if (lbbefore != null) {
                var before = (EventRow) lbbefore;
                if (row.is_allday == before.is_allday) {
                    row.set_header (null);
                    return;
                }

                if (row.is_allday != before.is_allday) {
                    var header_label = new Granite.HeaderLabel (_("During the Day"));
                    header_label.margin_start = header_label.margin_end = 6;

                    row.set_header (header_label);
                    return;
                }
            } else {
                if (row.is_allday) {
                    var allday_header = new Granite.HeaderLabel (_("All Day"));
                    allday_header.margin_start = allday_header.margin_end = 6;

                    row.set_header (allday_header);
                }
                return;
            }
        }

        [CCode (instance_pos = -1)]
        private int sort_function (Gtk.ListBoxRow child1, Gtk.ListBoxRow child2) {
            var e1 = (EventRow) child1;
            var e2 = (EventRow) child2;

            if (e1.start_time.compare (e2.start_time) != 0) {
                return e1.start_time.compare (e2.start_time);
            }

            // If they have the same date, sort them wholeday first
            if (e1.is_allday) {
                return -1;
            } else if (e2.is_allday) {
                return 1;
            }

            return 0;
        }
    }
}
