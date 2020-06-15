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

	public signal void connecting (E.Source source, Cancellable cancellable);
	public signal void connected (E.Source source);
	public signal void error_received (string error);
	
	public signal void components_added (Gee.Collection<ECal.Component> components, E.Source source);
	public signal void components_modified (Gee.Collection<ECal.Component> components);
	public signal void components_removed (Gee.Collection<ECal.Component> components);
	
	private ECal.ClientSourceType client_source_type { get; construct; }
	private E.SourceRegistry registry { get; private set; }
	private HashTable<string, ECal.Client> source_client;
	private HashTable<string, Gee.Collection<ECal.ClientView>> source_views;
	private HashTable<string, Gee.Collection<ECal.Component>> source_components;
	
	private CalendarStore (ECal.ClientSourceType client_source_type) {
		Object (client_source_type: client_source_type);
	}
	
	private static CalendarStore? event_store = null;
	private static CalendarStore? task_store = null;
	
	public static CalendarStore get_event_store () {
        if (event_store == null)
            event_store = new CalendarStore (ECal.ClientSourceType.EVENTS);
        return event_store;
    }
    
    public static CalendarStore get_task_store () {
        if (task_store == null)
            task_store = new CalendarStore (ECal.ClientSourceType.TASKS);
        return task_store;
    }
	
	/* The start of week, ie. Monday=1 or Sunday=7 */
	public GLib.DateWeekday calendar_week_starts_on { get; set; }

	construct {
		open.begin ();
		
		source_client = new HashTable<string, ECal.Client> (str_hash, str_equal);
		source_views = new HashTable<string, Gee.Collection<ECal.ClientView>> (str_hash, str_equal); // vala-lint=line-length
		source_components = new HashTable<string, Gee.Collection<ECal.Component>> (str_hash, str_equal); // vala-lint=line-length
		
		int calendar_week_start = Posix.NLTime.FIRST_WEEKDAY.to_string ().data[0];
		if (calendar_week_start >= 1 && calendar_week_start <= 7) {
			calendar_week_starts_on = (GLib.DateWeekday) (calendar_week_start - 1);
		}
	}
	
	private async void open () {
		try {
			registry = yield new E.SourceRegistry (null);
			registry.source_removed.connect (remove_source);
			registry.source_added.connect ((source) => add_source_async.begin (source));
			
			// Add Sources
			switch (client_source_type) {
				case ECal.ClientSourceType.EVENTS:
					registry.list_sources (E.SOURCE_EXTENSION_CALENDAR).foreach ((source) => {
						E.SourceCalendar cal = (E.SourceCalendar)source.get_extension (E.SOURCE_EXTENSION_CALENDAR);
						if (cal.selected == true && source.enabled == true) {
							add_source_async.begin (source);
						}
					});
					break;
					
				case ECal.ClientSourceType.TASKS:
					registry.list_sources (E.SOURCE_EXTENSION_TASK_LIST).foreach ((source) => {
						E.SourceTaskList list = (E.SourceTaskList)source.get_extension (E.SOURCE_EXTENSION_TASK_LIST);
						if (list.selected == true && source.enabled == true) {
							add_source_async.begin (source);
						}
					});
					break;
			}
            
            // load_all_sources ();
			
		} catch (Error error) {
			critical (error.message);
		}
	}
	
	private async void add_source_async (E.Source source) {
        debug ("Adding source '%s'", source.dup_display_name ());
        try {
            var cancellable = new GLib.Cancellable ();
            connecting (source, cancellable);
            var client = (ECal.Client) yield ECal.Client.connect (source, client_source_type, 30, cancellable);
            source_client.insert (source.get_uid (), client);
        } catch (Error e) {
            error_received (e.message);
        }

        Idle.add (() => {
            connected (source);
            //load_source (source);
            return GLib.REMOVE;
        });
    }
    
    private ECal.Client get_client (E.Source source) throws Error {
        ECal.Client client;
        lock (source_client) {
            client = source_client.get (source.dup_uid ());
        }
        return client;
    }
    
    public ECal.ClientView add_view (
    	E.Source source,
    	string sexp
    ) throws Error {
        ECal.Client client = get_client (source);
        debug ("Adding view for source '%s'", source.dup_display_name ());

        ECal.ClientView view;
        client.get_view_sync (sexp, out view, null);

        view.objects_added.connect ((objects) => on_objects_added_to_backend (source, view, objects));
        view.objects_modified.connect ((objects) => on_objects_modified_in_backend (source, view, objects));
        view.objects_removed.connect ((objects) => on_objects_removed_from_backend (source, view, objects));
        view.start ();

        lock (source_views) {
            var views = source_views.get (source.dup_uid ());

            if (views == null) {
                views = new Gee.ArrayList<ECal.ClientView> ((Gee.EqualDataFunc<ECal.ClientView>?) direct_equal);
            }
            views.add (view);

            source_views.set (source.dup_uid (), views);
        }

        return view;
    }
    
    /* -- Component API -- */
    
    public void add_component (E.Source source, ECal.Component component) {
    	var components = new Gee.ArrayList<ECal.Component> ((Gee.EqualDataFunc<ECal.Component>?) Util.calcomponent_equal_func);  // vala-lint=line-length
    	components.add (component);
    	
    	add_or_modify_components_in_frontend (source, components.read_only_view);
    	add_component_to_backend.begin (source, component, (obj, res) => {
    		remove_components_from_frontend (components.read_only_view, source);
    		components.clear ();
    		
    		try {
    			components.add (add_component_to_backend.end (obj, res));
    			add_or_modify_components_in_frontend (components.read_only_view, source);
    			
    		} catch (Error e) {
    			error_received (e.message);
    			critical (e.message);
    		}
    	});
    }
    
    public void modify_component (E.Source source, ECal.Component component) {
    	var components = new Gee.ArrayList<ECal.Component> ((Gee.EqualDataFunc<ECal.Component>?) Util.calcomponent_equal_func);  // vala-lint=line-length
    	components.add (component);
    	
    	add_or_modify_components_in_frontend (source, components.read_only_view);
    	modify_component_in_backend.begin (source, component, (obj, res) => {
    		remove_components_from_frontend (components.read_only_view, source);
    		components.clear ();
    		
    		try {
    			components.add (modify_component_in_backend.end (obj, res));
    			add_or_modify_components_in_frontend (components.read_only_view, source);
    			
    		} catch (Error e) {
    			error_received (e.message);
    			critical (e.message);
    		}
    	});
    }
    
    public void remove_component (E.Source source, ECal.Component component) {
    	var components = new Gee.ArrayList<ECal.Component> ((Gee.EqualDataFunc<ECal.Component>?) Util.calcomponent_equal_func);  // vala-lint=line-length
    	components.add (component);
    	
    	remove_components_from_frontend (source, components.read_only_view);
    	remove_component_from_backend.begin (source, component, (obj, res) => {
    		try {
    			remove_component_from_backend.end (obj, res);
    		
    		} catch (Error e) {
    			add_or_modify_components_in_frontend (components.read_only_view, source);
    			error_received (e.message);
    			critical (e.message);
    		}
    	});
    }
    
    /* -- Frontend Component Handlers -- */
    
    private void add_or_modify_components_in_frontend (E.Source source, Gee.Collection<ECal.Component> components) {
    	var added_components = new Gee.ArrayList<ECal.Component> ((Gee.EqualDataFunc<ECal.Component>?) Util.calcomponent_equal_func);  // vala-lint=line-length
    	var modified_components = new Gee.ArrayList<ECal.Component> ((Gee.EqualDataFunc<ECal.Component>?) Util.calcomponent_equal_func);  // vala-lint=line-length
    	
    	Gee.Collection<ECal.Component> all_source_components;
        lock (source_components) {
        	all_source_components = source_components.get (source.dup_uid ());
        	
        	if (all_source_components == null) {
	    		all_source_components = new Gee.ArrayList<ECal.Component> ((Gee.EqualDataFunc<ECal.Component>?) Util.calcomponent_equal_func);  // vala-lint=line-length
	    	}
	    	
	    	components.foreach ((component) => {
	    		if (all_source_components.remove (component)) {
	    			all_source_components.add (component);
	    			modified_components.add (component);
	    		} else {
	    			all_source_components.add (component);
	    			added_components.add (component);
	    		}
	    	});
	    	
	        source_components.set (source.dup_uid (), all_source_components);
        }
        
        if (!added_components.is_empty) {
        	components_added (added_components.read_only_view, source);
        }
        
        if (!modified_components.is_empty) {
        	components_modified (modified_components.read_only_view, source);
        }
    }
    
    private void remove_components_from_frontend (E.Source source, Gee.Collection<ECal.Component> components) {
    	Gee.Collection<ECal.Component> all_source_components;
        lock (source_components) {
        	all_source_components = source_components.get (source.dup_uid ());
        	
        	if (all_source_components != null && !all_source_components.is_empty) {
		    	components.foreach ((component) => {
		    		all_source_components.remove (component);
		    	});
		    	source_components.set (source.dup_uid (), all_source_components);
	    	}
	    }
	    
        components_removed (components.read_only_view, source);
    }
    
    /* -- Backend Component Handlers -- */
    
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
    
    private async void remove_component_from_backend (E.Source source, ECal.Component component, ECal.ObjModType mod_type) throws Error {
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
        client.remove_object (uid, rid, mod_type, null);
#endif
    }
    
    
    /* -- Backend Event Handlers -- */
    
#if E_CAL_2_0
    private void on_objects_added_to_backend (E.Source source, SList<ICal.Component> objects) {
#else
    private void on_objects_added_to_backend (E.Source source, SList<weak ICal.Component> objects) {
#endif
        debug (@"Received $(objects.length()) added component(s) for source '%s'", source.dup_display_name ());
        var added_components = new Gee.ArrayList<ECal.Component> ((Gee.EqualDataFunc<ECal.Component>?) Util.calcomponent_equal_func);  // vala-lint=line-length
        
        ECal.Client client = get_client (source);
        objects.foreach ((ical_comp) => {
            try {
                SList<ECal.Component> ecal_comps;
                client.get_objects_for_uid_sync (ical_comp.get_uid (), out ecal_comps, null);

                ecal_comps.foreach ((ecal_comp) => {
                    debug_component (source, ecal_comp);

                    if (!added_components.contains (ecal_comp)) {
                    	added_components.add (ecal_comp);
                    }
                });

            } catch (Error e) {
                warning (e.message);
            }
        });
        
        if (!added_components.is_empty) {
        	add_or_modify_components_in_frontend (source, added_components.read_only_view);
        }
    }
    
#if E_CAL_2_0
    private void on_objects_modified_in_backend (E.Source source, SList<ICal.Component> objects) {
#else
    private void on_objects_modified_in_backend (E.Source source, SList<weak ICal.Component> objects) {
#endif
		debug (@"Received $(objects.length()) modified component(s) for source '%s'", source.dup_display_name ());
        var modified_components = new Gee.ArrayList<ECal.Component> ((Gee.EqualDataFunc<ECal.Component>?) Util.calcomponent_equal_func);  // vala-lint=line-length
        
        ECal.Client client = get_client (source);
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
        	add_or_modify_components_in_frontend (source, modified_components.read_only_view);
        }
    }
    
#if E_CAL_2_0
    private void on_objects_removed_from_backend (E.Source source, ECal.Client client, SList<ECal.ComponentId?> cids) {
#else
    private void on_objects_removed_from_backend (E.Source source, ECal.Client client, SList<weak ECal.ComponentId?> cids) {
#endif
        debug (@"Received $(cids.length()) removed component(s) for source '%s'", source.dup_display_name ());
        var removed_components = new Gee.ArrayList<ECal.Component> ((Gee.EqualDataFunc<ECal.Component>?) Util.calcomponent_equal_func);  // vala-lint=line-length
        
        Gee.Collection<ECal.Component> all_source_components;
        lock (all_source_components) {
        	all_source_components = source_components.get (source.dup_uid ());
        	
        	if (all_source_components != null && !all_components.is_empty) {
	    		cids.foreach ((cid) => {
	    			foreach (var component in all_source_components) {
	    				if (cid.equal (component.get_id ()) {
	    					removed_components.add (component);
	    					break;
	    				}
	    			}
		    	});
	    	}
	    }
	    
	    if (!removed_components.is_empty) {
        	remove_components_from_frontend (source, removed_components.read_only_view);
        }
    }
    
	private void debug_component (E.Source source, ECal.Component component) {
        unowned ICal.Component comp = component.get_icalcomponent ();
        debug (@"Component ['$(comp.get_summary())', $(source.dup_display_name()), $(comp.get_uid()))]");
    }
}