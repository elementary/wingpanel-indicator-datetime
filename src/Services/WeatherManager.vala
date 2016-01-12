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

namespace DateTime.Services {
    public class WeatherManager : GLib.Object {
        private static WeatherManager? instance = null;
        const string APPID = "adfaa0ecdadbedda6a80ab984759b245";
        const string api = "http://api.openweathermap.org/data/2.5/%s?lat=%s&lon=%s&mode=json&units=%s&cnt=16&appid=%s";

        string units = "metric"; /* Standard, metric, and imperial */

        public TodayConditions today { get; private set; }
        Gee.HashMap<string, ForecastConditions> forecast;

        public signal void today_updated (Conditions conditions);
        public signal void forecasts_updated ();

        public WeatherManager () {
            forecast = new Gee.HashMap<string, ForecastConditions> ();
            var override_location = Services.SettingsManager.get_default ().location;

            if (override_location != null && override_location.length == 2) {
                var latitude = override_location[0];
                var longitude = override_location[1];
                debug ("location override is latitude:%f longitude:%f\n", latitude, longitude);
                Idle.add (() => {
                    load_today_weather (latitude, longitude);
                    today_updated (today);
                    load_forecast_weather (latitude, longitude);

                    return false;
                });
            } else {
                /* detect location with geolocation services */
                var geolocation = Services.GeolocationManager.get_default ();
                geolocation.location_changed.connect ((latitude, longitude) => {
                    debug ("geolocation found is latitude:%f longitude:%f\n", latitude, longitude);
                    load_today_weather (latitude, longitude);
                    today_updated (today);
                    load_forecast_weather (latitude, longitude);
                });
            }

            var lang = Environment.get_variable ("LANG");

            if (lang != null) {
                /* check if imperial units should be used */
                var regions = Services.SettingsManager.get_default ().imperial_regions;
                var region_strip = lang.substring (3, 2);

                foreach (var region in regions) {
                    if (region == region_strip) {
                        units = "imperial";
                        break;
                    }
                }
            }
        }

        public Conditions? get_forecast (GLib.DateTime date) {
            if (date == null) {
                return null;
            }

            var strip_date = Util.strip_time (date);

            if (strip_date.to_unix () == Util.strip_time (new GLib.DateTime.now_local ()).to_unix ()) {
                return today;
            }

            var day_forecast = forecast.get (strip_date.to_string ());

            return day_forecast;
        }

        public void load_today_weather (double lat, double lon) {
            var apiurl = api.printf ("weather", lat.to_string (), lon.to_string (), units, APPID);
            debug ("call weather api url %s", apiurl);
            var session = new Soup.Session ();
            var message = new Soup.Message ("GET", apiurl);
            session.send_message (message);
            debug ("recieved answer: %s", (string)message.response_body.flatten ().data);
            today = new TodayConditions ((string)message.response_body.flatten ().data, units == "metric");
        }

        public void load_forecast_weather (double lat, double lon) {
            var apiurl = api.printf ("forecast/daily", lat.to_string (), lon.to_string (), units, APPID);
            var session = new Soup.Session ();
            var message = new Soup.Message ("GET", apiurl);
            session.send_message (message);
            try {
                var parser = new Json.Parser ();
                parser.load_from_data ((string)message.response_body.flatten ().data, -1);
                var root_object = parser.get_root ().get_object ();
                var forecast_list = root_object.get_member ("list").get_array ();

                for (int i = 0; i < (int)forecast_list.get_length (); i++) {
                    var day = forecast_list.get_element (i).get_object ();
                    var date = new GLib.DateTime.from_unix_local (day.get_member ("dt").get_int ());
                    var single_forecast = new ForecastConditions (date, day, units == "metric");
                    forecast.set (Util.strip_time (date).to_string (), single_forecast);
                }
            } catch (Error e) {
                stderr.printf ("json parsing failed");
            }
        }

        public static WeatherManager get_default () {
            if (instance == null) {
                instance = new WeatherManager ();
            }

            return instance;
        }
    }

    public class Conditions : Object {
        public string summary { get; protected set; }
        public int temp_min { get; protected set; }
        public int temp_max { get; protected set; }
        public string provider = _("cc OpenWeatherMap");
        protected int id;
        protected string[] CONDITION = new string[1000];
        protected bool metric;

        public Conditions () {
            CONDITION[200] = _("Thunderstorm with light rain");
            CONDITION[201] = _("Thunderstorm with rain");
            CONDITION[202] = _("Thunderstorm with heavy rain");
            CONDITION[210] = _("Light thunderstorm");
            CONDITION[211] = _("Thunderstorm");
            CONDITION[212] = _("Heavy thunderstorm");
            CONDITION[221] = _("Ragged thunderstorm");
            CONDITION[230] = _("Thunderstorm with light drizzle");
            CONDITION[231] = _("Thunderstorm with drizzle");
            CONDITION[232] = _("Thunderstorm with heavy drizzle");
            CONDITION[300] = _("Light intensity drizzle");
            CONDITION[301] = _("Drizzle");
            CONDITION[302] = _("Heavy intensity drizzle");
            CONDITION[310] = _("Light intensity drizzle rain");
            CONDITION[311] = _("Drizzle rain");
            CONDITION[312] = _("Heavy intensity drizzle rain");
            CONDITION[321] = _("Shower drizzle");
            CONDITION[500] = _("Light rain");
            CONDITION[501] = _("Moderate rain");
            CONDITION[502] = _("Heavy intensity rain");
            CONDITION[503] = _("Very heavy rain");
            CONDITION[504] = _("Extreme rain");
            CONDITION[511] = _("Freezing rain");
            CONDITION[520] = _("Light intensity shower rain");
            CONDITION[521] = _("Shower rain");
            CONDITION[522] = _("Heavy intensity shower rain");
            CONDITION[600] = _("Light snow");
            CONDITION[601] = _("Snow");
            CONDITION[602] = _("Heavy snow");
            CONDITION[611] = _("Sleet");
            CONDITION[621] = _("Shower snow");
            CONDITION[701] = _("Mist");
            CONDITION[711] = _("Smoke");
            CONDITION[721] = _("Haze");
            CONDITION[731] = _("Sand");
            CONDITION[741] = _("Fog");
            CONDITION[800] = _("Clear"); /* sky is clear */
            CONDITION[801] = _("Partly sunny"); /* few cloud" */
            CONDITION[802] = _("Partly cloudy"); /* scattered cloud */
            CONDITION[803] = _("Cloudy"); /* broken cloud */
            CONDITION[804] = _("Overcast"); /* overcast cloud */
            CONDITION[900] = _("Tornado");
            CONDITION[901] = _("Tropical storm");
            CONDITION[902] = _("Hurricane");
            CONDITION[903] = _("Cold");
            CONDITION[904] = _("Hot");
            CONDITION[905] = _("Windy");
            CONDITION[906] = _("Hail");
        }

        protected string get_icon_string (int id, bool night, bool symbolic) {
            var id_short = int.parse (id.to_string ().substring (0, 1));
            string icon;

            switch (id_short) {
                case 2 :
                    icon = "weather-storm";

                    if (symbolic) {
                        icon += "-symbolic";
                    }

                    return icon;
                case 3 :
                    icon = "weather-showers-scattered";

                    if (symbolic) {
                        icon += "-symbolic";
                    }

                    return icon;
                case 5:
                    icon = "weather-showers";

                    if (symbolic) {
                        icon += "-symbolic";
                    }

                    return icon;
                case 6:
                    icon = "weather-snow";

                    if (symbolic) {
                        icon += "-symbolic";
                    }

                    return icon;
                case 7:
                    icon = "weather-fog";

                    if (symbolic) {
                        icon += "-symbolic";
                    }

                    return icon;
                case 8:

                    if (id == 800) {
                        icon = "weather-clear";

                        if (night) {
                            icon += "-night";
                        }

                        if (symbolic) {
                            icon += "-symbolic";
                        }

                        return icon;
                    } else if (id == 804) {
                        icon = "weather-overcast";

                        if (symbolic) {
                            icon += "-symbolic";
                        }

                        return icon;
                    }

                    icon = "weather-few-clouds";

                    if (night) {
                        icon += "-night";
                    }

                    if (symbolic) {
                        icon += "-symbolic";
                    }

                    return icon;
                case 9:
                    icon = "weather-severe-alert";

                    if (symbolic) {
                        icon += "-symbolic";
                    }

                    return icon;
            }

            return "";
        }

        public virtual string get_tooltip_string () {
            string data = _("Min: %d°\nMax: %d°\n%s");

            return data.printf (temp_min, temp_max, provider);
        }

        public virtual string get_temperature () {
            return "0";
        }

        public virtual string get_icon () {
            return "";
        }

        public virtual string get_symbolic_icon () {
            return "";
        }
    }

    public class TodayConditions : Conditions {
        public Util.DateRange sun_uptime { get; protected set; }
        public int temp { get; protected set; }

        public TodayConditions (string json_data, bool metric) {
            this.metric = metric;
            try {
                var parser = new Json.Parser ();
                parser.load_from_data (json_data, -1);
                var root_object = parser.get_root ().get_object ();
                var weather = root_object.get_member ("weather").get_array ().get_element (0).get_object ();
                var main = root_object.get_member ("main").get_object ();
                var sys = root_object.get_member ("sys").get_object ();
                id = (int)weather.get_member ("id").get_int ();
                summary = CONDITION[id];
                temp = (int)Math.round (main.get_member ("temp").get_double ());
                temp_min = (int)Math.round (main.get_member ("temp_min").get_double ());
                temp_max = (int)Math.round (main.get_member ("temp_max").get_double ());
                var sunrise = new GLib.DateTime.from_unix_local (sys.get_member ("sunrise").get_int ());
                var sunset = new GLib.DateTime.from_unix_local (sys.get_member ("sunset").get_int ());
                sun_uptime = new Util.DateRange (sunrise, sunset);
            } catch (Error e) {
                stderr.printf ("json parsing failed");
            }
        }

        public override string get_tooltip_string () {
            string data = _("Min: %d°\nMax: %d°\nSunrise: %s\nSunset:%s\n%s");

            return data.printf (temp_min, temp_max, sun_uptime.first.format (Util.TimeFormat ()),
             sun_uptime.last.format (Util.TimeFormat ()), provider);
        }

        public override string get_temperature () {
            if (metric) {
                return "%d%s".printf (temp, "°C");
            }
            return "%d%s".printf (temp, "°F");
        }

        public override string get_icon () {
            bool is_day = sun_uptime.contains (new GLib.DateTime.now_local ());

            return get_icon_string (id, !is_day, false);
        }

        public override string get_symbolic_icon () {
            bool is_day = sun_uptime.contains (new GLib.DateTime.now_local ());

            return get_icon_string (id, !is_day, true);
        }
    }

    public class ForecastConditions : Conditions {
        public GLib.DateTime date { get; private set; }

        public ForecastConditions (GLib.DateTime date, Json.Object day, bool metric) {
            this.metric = metric;
            this.date = date;
            var weather = day.get_member ("weather").get_array ().get_element (0).get_object ();
            var temp = day.get_member ("temp").get_object ();
            id = (int)weather.get_member ("id").get_int ();
            summary = CONDITION[id];
            temp_min = (int)Math.round (temp.get_member ("min").get_double ());
            temp_max = (int)Math.round (temp.get_member ("max").get_double ());
        }

        public override string get_temperature () {
            if (metric) {
                return "%d%s".printf (temp_max, "°C");
            }
            return "%d%s".printf (temp_max, "°F");
        }

        public override string get_icon () {
            return get_icon_string (id, false, false);
        }

        public override string get_symbolic_icon () {
            return get_icon_string (id, false, true);
        }
    }
}