/*-
 * Copyright (c) 2015 Wingpanel Developers (http://launchpad.net/wingpanel)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Library General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

[DBus (name = "org.freedesktop.GeoClue2.Manager")]
private interface Geo.Manager : Object {
    public abstract async void get_client (out string client_path) throws IOError;
}

[DBus (name = "org.freedesktop.GeoClue2.Location")]
public interface Geo.Location : Object {
    public abstract double latitude { get; }
    public abstract double longitude { get; }
    public abstract double accuracy { get; }
    public abstract string description { owned get; }
}

[DBus (name = "org.freedesktop.GeoClue2.Client")]
private interface Geo.Client : Object {
    public abstract ObjectPath location { owned get; }
    public abstract string desktop_id { owned get; set; }
    public abstract uint distance_threshold { get; set; }
    public abstract uint requested_accuracy_level { get; set; }

    public signal void location_updated (ObjectPath old_path, ObjectPath new_path);

    public abstract async void start () throws IOError;
    public abstract async void stop () throws IOError;
}

public class DateTime.Services.GeolocationManager : Object {

    private static GeolocationManager? instance = null;

    public Geo.Location? geo_location { get; private set; default = null; }

    private const string DESKTOP_ID = "org.pantheon.desktop.wingpanel.indicators.datetime";

    private Geo.Manager manager;
    private Geo.Client client;


    public signal void location_changed (GWeather.Location location);

    public GeolocationManager () {
        init.begin ();
    }

    ~GeolocationManager () {
        if (client != null) {
            client.stop.begin ();
        }
    }

    public async void init () {
        string? client_path = null;

        try {
            manager = yield Bus.get_proxy (GLib.BusType.SYSTEM,
                                           "org.freedesktop.GeoClue2",
                                           "/org/freedesktop/GeoClue2/Manager");
        } catch (IOError e) {
            warning ("Failed to connect to GeoClue2 Manager service: %s", e.message);
            return;
        }

        try {
            yield manager.get_client (out client_path);
        } catch (IOError e) {
            warning ("Failed to connect to GeoClue2 Manager service: %s", e.message);
            return;
        }

        if (client_path == null) {
            warning ("The client path is not set");
            return;
        }

        try {
            client = yield Bus.get_proxy (GLib.BusType.SYSTEM,
                                          "org.freedesktop.GeoClue2",
                                          client_path);
        } catch (IOError e) {
            warning ("Failed to connect to GeoClue2 Client service: %s", e.message);
            return;
        }

        client.desktop_id = DESKTOP_ID;
        client.requested_accuracy_level = 4; // City Accuracy

        client.location_updated.connect ((old_path, new_path) => {
            on_location_updated.begin (old_path, new_path, (obj, res) => {
                on_location_updated.end (res);
            });
        });

        try {
            yield client.start ();
        } catch (IOError e) {
            warning ("Failed to start client: %s", e.message);
            return;
        }
    }

    public async void on_location_updated (ObjectPath old_path, ObjectPath new_path) {
        try {
            geo_location = yield Bus.get_proxy (GLib.BusType.SYSTEM,
                                                "org.freedesktop.GeoClue2",
                                                new_path);
        } catch (IOError e) {
            warning ("Failed to connect to GeoClue2 Location service: %s", e.message);
            return;
        }
        var location = GWeather.Location.get_world ().find_nearest_city (geo_location.latitude, geo_location.longitude);
        location_changed (location);
    }

    public static GeolocationManager get_default () {
        if (instance == null)
            instance = new GeolocationManager ();

        return instance;
    }
}