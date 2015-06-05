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

public class DateTime.Services.WeatherManager : GLib.Object {
    private static WeatherManager? instance = null;

    public WeatherManager () {

    }

    public string get_temp (double lat, double lon) {
        var apiurl = "http://api.openweathermap.org/data/2.5/forecast/daily?lat=%s&lon=%s&mode=xml&units=metric&cnt=1&lang=de".printf (lat.to_string (), lon.to_string ());
        // var session = new Soup.Session ();
        // var message = new Soup.Message ("GET", apiurl);
        // session.send_message (message);
        // print ((string) message.response_body.flatten ().data);
        GLib.File file = GLib.File.new_for_uri (apiurl);
        try {
           var stream = new DataInputStream (file.read ());
            string line;
            // Read lines until end of file (null) is reached
            while ((line = stream.read_line (null)) != null) {
                stdout.printf ("%s\n", line);
            }
        } catch  (Error e) {
        }
        // try {
        //         var parser = new Json.Parser ();
        //         parser.load_from_data ((string) message.response_body.flatten ().data, -1);

        //         var root_object = parser.get_root ().get_object ();
        //         var response = root_object.get_object_member ("response");
        //         var results = response.get_array_member ("docs");
        //         int64 count = results.get_length ();
        //         int64 total = response.get_int_member ("numFound");
        //         stdout.printf ("got %lld out of %lld results:\n\n", count, total);

        //         foreach (var geonode in results.get_elements ()) {
        //             var geoname = geonode.get_object ();
        //             stdout.printf ("%s\n%s\n%f\n%f\n\n",
        //                           geoname.get_string_member ("name"),
        //                           geoname.get_string_member ("country_name"),
        //                           geoname.get_double_member ("lng"),
        //                           geoname.get_double_member ("lat"));
        //         }
        //     } catch (Error e) {
        //         stderr.printf ("I guess something is not working...\n");
        //     }
        return "";
    }

    public static WeatherManager get_default () {
        if (instance == null)
            instance = new WeatherManager ();

        return instance;
    }
}
