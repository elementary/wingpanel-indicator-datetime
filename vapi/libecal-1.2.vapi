/* libecalendar-1.2.vapi generated by vapigen, do not modify. */

[CCode (cprefix = "ECal", gir_namespace = "ECal", gir_version = "1.2", lower_case_cprefix = "e_cal_")]
namespace ECal {
	namespace BackendProperty {
		[CCode (cheader_filename = "libecal/libecal.h", cname = "CAL_BACKEND_PROPERTY_ALARM_EMAIL_ADDRESS")]
		public const string ALARM_EMAIL_ADDRESS;
		[CCode (cheader_filename = "libecal/libecal.h", cname = "CAL_BACKEND_PROPERTY_CAL_EMAIL_ADDRESS")]
		public const string CAL_EMAIL_ADDRESS;
		[CCode (cheader_filename = "libecal/libecal.h", cname = "CAL_BACKEND_PROPERTY_DEFAULT_OBJECT")]
		public const string DEFAULT_OBJECT;
	}
	[CCode (cheader_filename = "libecal/libecal.h", type_id = "e_cal_client_get_type ()")]
	public class Client : E.Client, GLib.AsyncInitable, GLib.Initable {
		[CCode (has_construct_function = false)]
		public Client (E.Source source, ECal.ClientSourceType source_type) throws GLib.Error;
		[Version (since = "3.8")]
		public static async E.Client connect (E.Source source, ECal.ClientSourceType source_type, uint32 wait_for_connected_seconds, GLib.Cancellable? cancellable) throws GLib.Error;
		[Version (since = "3.8")]
		public static E.Client connect_sync (E.Source source, ECal.ClientSourceType source_type, uint32 wait_for_connected_seconds, GLib.Cancellable? cancellable = null) throws GLib.Error;
		public async bool add_timezone (ICal.Timezone zone, GLib.Cancellable cancellable) throws GLib.Error;
		public bool add_timezone_sync (ICal.Timezone zone, GLib.Cancellable cancellable) throws GLib.Error;
		public bool check_one_alarm_only ();
		public bool check_organizer_must_accept ();
		public bool check_organizer_must_attend ();
		public bool check_recurrences_no_master ();
		public bool check_save_schedules ();
		public static bool check_timezones (ICal.Component comp, GLib.List comps, GLib.Callback tzlookup, void* ecalclient, GLib.Cancellable cancellable) throws GLib.Error;
		public async bool create_object (ICal.Component icalcomp, GLib.Cancellable? cancellable, out string uid) throws GLib.Error;
		public bool create_object_sync (ICal.Component icalcomp, out string uid, GLib.Cancellable? cancellable) throws GLib.Error;
		[CCode (has_construct_function = false)]
		public Client.@default (ECal.ClientSourceType source_type) throws GLib.Error;
		public async bool discard_alarm (string uid, string rid, string auid, GLib.Cancellable? cancellable) throws GLib.Error;
		public bool discard_alarm_sync (string uid, string rid, string auid, GLib.Cancellable? cancellable) throws GLib.Error;
		public static void free_ecalcomp_slist (GLib.SList<ECal.Component> ecalcomps);
		public static void free_icalcomp_slist (GLib.SList<ICal.Component> icalcomps);
		[CCode (has_construct_function = false)]
		public Client.from_uri (string uri, ECal.ClientSourceType source_type) throws GLib.Error;
		public void generate_instances (ulong start, ulong end, GLib.Cancellable? cancellable, ECal.RecurInstanceFn cb, void* cb_data, owned GLib.DestroyNotify? destroy_cb_data);
		public void generate_instances_for_object (ICal.Component icalcomp, time_t start, time_t end, GLib.Cancellable? cancellable, [CCode (delegate_target_pos = 5.33333, destroy_notify_pos = 5.66667)] ECal.RecurInstanceFn cb);
		public void generate_instances_for_object_sync (ICal.Component icalcomp, time_t start, time_t end, [CCode (delegate_target_pos = 4.33333)] ECal.RecurInstanceFn cb);
		public void generate_instances_sync (ulong start, ulong end, [CCode (delegate_target_pos = 3.33333)] ECal.RecurInstanceFn cb);
		public async bool get_attachment_uris (string uid, string rid, GLib.Cancellable? cancellable, out GLib.SList attachment_uris) throws GLib.Error;
		public bool get_attachment_uris_sync (string uid, string rid, GLib.SList attachment_uris, GLib.Cancellable? cancellable) throws GLib.Error;
		public unowned string get_component_as_string (ICal.Component icalcomp);
		public async bool get_default_object (GLib.Cancellable? cancellable, out ICal.Component icalcomp) throws GLib.Error;
		public bool get_default_object_sync (out unowned ICal.Component icalcomp, GLib.Cancellable? cancellable) throws GLib.Error;
		public unowned ICal.Timezone get_default_timezone ();
		public async bool get_free_busy (ulong start, ulong end, GLib.SList users, GLib.Cancellable? cancellable) throws GLib.Error;
		public bool get_free_busy_sync (ulong start, ulong end, GLib.SList users, GLib.Cancellable? cancellable) throws GLib.Error;
		public unowned string get_local_attachment_store ();
		public async bool get_object (string uid, string rid, GLib.Cancellable? cancellable, out ICal.Component icalcomp) throws GLib.Error;
		public async bool get_object_list (string sexp, GLib.Cancellable? cancellable, out GLib.SList<ICal.Component> icalcomps) throws GLib.Error;
		public async bool get_object_list_as_comps (string sexp, GLib.Cancellable? cancellable, out GLib.SList<ECal.Component> ecalcomps) throws GLib.Error;
		public bool get_object_list_as_comps_sync (string sexp, out GLib.SList<ECal.Component> ecalcomps, GLib.Cancellable? cancellable) throws GLib.Error;
		public bool get_object_list_sync (string sexp, out GLib.SList<ICal.Component> icalcomps, GLib.Cancellable? cancellable) throws GLib.Error;
		public bool get_object_sync (string uid, string rid, out ICal.Component icalcomp, GLib.Cancellable? cancellable) throws GLib.Error;
		public async bool get_objects_for_uid (string uid, GLib.Cancellable? cancellable, out GLib.SList<ECal.Component> ecalcomps) throws GLib.Error;
		public bool get_objects_for_uid_sync (string uid, out GLib.SList<ECal.Component> ecalcomps, GLib.Cancellable? cancellable) throws GLib.Error;
		public ECal.ClientSourceType get_source_type ();
		public async bool get_timezone (string tzid, GLib.Cancellable? cancellable, out ICal.Timezone zone) throws GLib.Error;
		public bool get_timezone_sync (string tzid, out ICal.Timezone zone, GLib.Cancellable? cancellable) throws GLib.Error;
		public async bool get_view (string sexp, GLib.Cancellable? cancellable, out ECal.ClientView view) throws GLib.Error;
		public bool get_view_sync (string sexp, out ECal.ClientView view, GLib.Cancellable? cancellable) throws GLib.Error;
		public async bool modify_object (ICal.Component icalcomp, ECal.ObjModType mod, GLib.Cancellable? cancellable) throws GLib.Error;
		public bool modify_object_sync (ICal.Component icalcomp, ECal.ObjModType mod, GLib.Cancellable? cancellable) throws GLib.Error;
		public async bool receive_objects (ICal.Component icalcomp, GLib.Cancellable? cancellable) throws GLib.Error;
		public bool receive_objects_sync (ICal.Component icalcomp, GLib.Cancellable? cancellable) throws GLib.Error;
		public async bool remove_object (string uid, string rid, ECal.ObjModType mod, GLib.Cancellable? cancellable) throws GLib.Error;
		public bool remove_object_sync (string uid, string rid, ECal.ObjModType mod, GLib.Cancellable? cancellable) throws GLib.Error;
		public static unowned ICal.Timezone resolve_tzid_cb (string tzid, void* data);
		public async bool send_objects (ICal.Component icalcomp, GLib.Cancellable? cancellable, out GLib.SList<string> users, out ICal.Component modified_icalcomp) throws GLib.Error;
		public bool send_objects_sync (ICal.Component icalcomp, out GLib.SList<string> users, out ICal.Component modified_icalcomp, GLib.Cancellable? cancellable) throws GLib.Error;
		public bool set_default () throws GLib.Error;
		public static bool set_default_source (E.Source source, ECal.ClientSourceType source_type) throws GLib.Error;
		public void set_default_timezone (ICal.Timezone zone);
		[CCode (has_construct_function = false)]
		public Client.system (ECal.ClientSourceType source_type) throws GLib.Error;
		public static unowned ICal.Timezone tzlookup (string tzid, void* ecalclient, GLib.Cancellable cancellable) throws GLib.Error;
		public static unowned ICal.Timezone tzlookup_icomp (string tzid, void* custom, GLib.Cancellable cancellable) throws GLib.Error;
		public virtual signal void free_busy_data (void* free_busy_ecalcomps);
	}
	[CCode (cheader_filename = "libecal/libecal.h", type_id = "e_cal_client_view_get_type ()")]
	public class ClientView : GLib.Object {
		[CCode (has_construct_function = false)]
		protected ClientView ();
		public bool is_running ();
		public void set_fields_of_interest (GLib.SList<string>? fields_of_interest) throws GLib.Error;
		public void set_flags (ECal.ClientViewFlags flags) throws GLib.Error;
		public void start () throws GLib.Error;
		public void stop () throws GLib.Error;
		public ECal.Client client { get; construct; }
		[NoAccessorMethod]
		public void* view { get; construct; }
		public virtual signal void complete (GLib.Error error);
		public virtual signal void objects_added (GLib.SList<weak ICal.Component> objects);
		public virtual signal void objects_modified (GLib.SList<weak ICal.Component> objects);
		public virtual signal void objects_removed (GLib.SList<weak ECal.ComponentId?> uids);
		public virtual signal void progress (uint percent, string message);
	}
	[CCode (cheader_filename = "libecal/libecal.h", type_id = "e_cal_component_get_type ()")]
	public class Component : GLib.Object {
		[CCode (has_construct_function = false)]
		public Component ();
		[CCode (has_construct_function = false)]
		public Component.from_string (string calobj);
		[CCode (has_construct_function = false)]
		public Component.from_icalcomponent (ICal.Component icalcomp);
		public void abort_sequence ();
		public void add_alarm (ECal.ComponentAlarm alarm);
		public unowned ECal.Component clone ();
		public void commit_sequence ();
		public bool event_dates_match (ECal.Component comp2);
		public static void free_attendee_list (GLib.SList<ECal.ComponentAttendee> attendee_list);
		public static void free_categories_list (GLib.SList<string> categ_list);
		public static void free_datetime (ECal.ComponentDateTime dt);
		public static void free_exdate_list (GLib.SList exdate_list);
		public static void free_geo (ICal.Geo geo);
		public static void free_icaltimetype (ICal.Time t);
		public static void free_id (ECal.ComponentId id);
		public static void free_percent (int percent);
		public static void free_period_list (GLib.SList period_list);
		public static void free_priority (int priority);
		public static void free_range (ECal.ComponentRange range);
		public static void free_recur_list (GLib.SList<ECal.ComponentRange> recur_list);
		public static void free_sequence (int sequence);
		public static void free_text_list (GLib.SList<ECal.ComponentText> text_list);
		public static string gen_uid ();
		public ECal.ComponentAlarm get_alarm (string auid);
		public GLib.List<string> get_alarm_uids ();
		public string get_as_string ();
		public void get_attachment_list (out GLib.SList<string> attachment_list);
		public void get_attendee_list (out GLib.SList<ECal.ComponentAttendee?> attendee_list);
		public void get_categories (out string? categories);
		public void get_categories_list (out GLib.SList<string> categ_list);
		public void get_classification (out ECal.ComponentClassification? classif);
		public void get_comment_list (out GLib.SList<ECal.ComponentText> text_list);
		public void get_completed (out ICal.Time? t);
		public void get_contact_list (out GLib.SList<ECal.ComponentText> text_list);
		public void get_created (out ICal.Time? t);
		public void get_description_list (out GLib.SList<ECal.ComponentText> text_list);
		public void get_dtend (out ECal.ComponentDateTime? dt);
		public void get_dtstamp (out ICal.Time? t);
		public void get_dtstart (out ECal.ComponentDateTime? dt);
		public void get_due (out ECal.ComponentDateTime? dt);
		public void get_exdate_list (out GLib.SList<ECal.ComponentDateTime> exdate_list);
		public void get_exrule_list (out GLib.SList<ICal.Recurrence> recur_list);
		public void get_exrule_property_list (out GLib.SList<ECal.ComponentRange> recur_list);
		public void get_geo (out ICal.Geo? geo);
		public unowned ICal.Component get_icalcomponent ();
		public ECal.ComponentId get_id ();
		public void get_last_modified (out ICal.Time? t);
		public void get_location (out string? location);
		public int get_num_attachments ();
		public void get_organizer (out ECal.ComponentOrganizer? organizer);
		public void get_percent (out int? percent);
		public int get_percent_as_int ();
		public void get_priority (out int? priority);
		public void get_rdate_list (out GLib.SList<ECal.ComponentPeriod> period_list);
		public void get_recurid (out ECal.ComponentRange? recur_id);
		public string get_recurid_as_string ();
		public void get_rrule_list (out GLib.SList<ICal.Recurrence> recur_list);
		public void get_rrule_property_list (out GLib.SList<ECal.ComponentRange> recur_list);
		public void get_sequence (out int? sequence);
		public void get_status (out ICal.PropertyStatus? status);
		public ECal.ComponentText get_summary ();
		public void get_transparency (out ECal.ComponentTransparency? transp);
		public void get_uid (out string uid);
		public void get_url (out string? url);
		public ECal.ComponentVType get_vtype ();
		public bool has_alarms ();
		public bool has_attachments ();
		public bool has_attendees ();
		public bool has_exceptions ();
		public bool has_exdates ();
		public bool has_exrules ();
		public bool has_organizer ();
		public bool has_rdates ();
		public bool has_recurrences ();
		public bool has_rrules ();
		public bool has_simple_recurrence ();
		public bool is_instance ();
		public void remove_alarm (string auid);
		public void remove_all_alarms ();
		public void rescan ();
		public void set_attachment_list (GLib.SList<string> attachment_list);
		public void set_attendee_list (GLib.SList<ECal.ComponentAttendee> attendee_list);
		public void set_categories (string categories);
		public void set_categories_list (GLib.SList<string> categ_list);
		public void set_classification (ECal.ComponentClassification classif);
		public void set_comment_list (GLib.SList<ECal.ComponentText> text_list);
		public void set_completed (ICal.Time t);
		public void set_contact_list (GLib.SList<ECal.ComponentText> text_list);
		public void set_created (ICal.Time t);
		public void set_description_list (GLib.SList<ECal.ComponentText> text_list);
		public void set_dtend (ECal.ComponentDateTime dt);
		public void set_dtstamp (ICal.Time t);
		public void set_dtstart (ECal.ComponentDateTime dt);
		public void set_due (ECal.ComponentDateTime dt);
		public void set_exdate_list (GLib.SList<ECal.ComponentDateTime>? exdate_list);
		public void set_exrule_list (GLib.SList<ICal.Recurrence> recur_list);
		public void set_geo (ICal.Geo* geo);
		public bool set_icalcomponent (owned ICal.Component icalcomp);
		public void set_last_modified (ICal.Time t);
		public void set_location (string location);
		public void set_new_vtype (ECal.ComponentVType type);
		public void set_organizer (ECal.ComponentOrganizer organizer);
		public void set_percent (int percent);
		public void set_percent_as_int (int percent);
		public void set_priority (int priority);
		public void set_rdate_list (GLib.SList<ECal.ComponentPeriod> period_list);
		public void set_recurid (ECal.ComponentRange recur_id);
		public void set_rrule_list (GLib.SList<ICal.Recurrence> recur_list);
		public void set_sequence (int sequence);
		public void set_status (ICal.PropertyStatus status);
		public void set_summary (ECal.ComponentText summary);
		public void set_transparency (ECal.ComponentTransparency transp);
		public void set_uid (string uid);
		public void set_url (string url);
		public void strip_errors ();
	}
	[CCode (cheader_filename = "libecal/libecal.h", free_function = "e_cal_component_alarm_free")]
	[Compact]
	public class ComponentAlarm {
		[CCode (has_construct_function = false)]
		public ComponentAlarm ();
		public ECal.ComponentAlarm clone ();
		public void get_action (out ECal.ComponentAlarmAction action);
		public void get_attach (out ICal.Attach attach);
		public void get_attendee_list (out GLib.SList<ECal.ComponentAttendee> attendee_list);
		public void get_description (out ECal.ComponentText description);
		public ICal.Component get_icalcomponent ();
		public void get_repeat (out ECal.ComponentAlarmRepeat repeat);
		public void get_trigger (out ECal.ComponentAlarmTrigger trigger);
		public unowned string get_uid ();
		public bool has_attendees ();
		public void set_action (ECal.ComponentAlarmAction action);
		public void set_attach (ICal.Attach attach);
		public void set_attendee_list (GLib.SList<ECal.ComponentAttendee> attendee_list);
		public void set_description (ECal.ComponentText description);
		public void set_repeat (ECal.ComponentAlarmRepeat repeat);
		public void set_trigger (ECal.ComponentAlarmTrigger trigger);
	}
	[CCode (cheader_filename = "libecal/libecal.h")]
	public struct Change {
		public weak ECal.Component comp;
		public ECal.ChangeType type;
	}
	[CCode (cheader_filename = "libecal/libecal.h")]
	public struct ComponentAlarmInstance {
		public weak string auid;
		public time_t trigger;
		public time_t occur_start;
		public time_t occur_end;
	}
	[CCode (cheader_filename = "libecal/libecal.h")]
	public struct ComponentAlarmRepeat {
		public int repetitions;
		public ICal.Duration duration;
	}
	[SimpleType]
	[CCode (cheader_filename = "libecal/libecal.h")]
	public struct ComponentAlarmTrigger {
		public ECal.ComponentAlarmTriggerKind type;
		[CCode(cname = "u.rel_duration")]
		public ICal.Duration rel_duration;
		[CCode(cname = "u.abs_time")]
		public ICal.Time abs_time;
		[CCode(cname = "_vala_e_cal_component_alarm_trigger_get_kind")]
		public ECal.ComponentAlarmTriggerKind get_kind () {
			return type;
		}

		[CCode(cname = "_vala_e_cal_component_alarm_trigger_set_kind")]
		public void set_kind (ECal.ComponentAlarmTriggerKind kind) {
			type = kind;
		}

		[CCode(cname = "_vala_e_cal_component_alarm_trigger_get_duration")]
		public unowned ICal.Duration get_duration () {
			return rel_duration;
		}

		[CCode(cname = "_vala_e_cal_component_alarm_trigger_set_duration")]
		public void set_duration (ICal.Duration duration) {
			rel_duration = duration;
		}
	}
	[CCode (cheader_filename = "libecal/libecal.h", free_function = "e_cal_component_alarms_free")]
	public struct ComponentAlarms {
		public weak ECal.Component comp;
		[CCode (cheader_filename = "libecal/libecal.h")]
		public weak GLib.SList<ECal.ComponentAlarmInstance> alarms;
		public void free ();
	}
	[CCode (cheader_filename = "libecal/libecal.h", has_type_id = false)]
	public struct ComponentAttendee {
		public weak string value;
		public weak string member;
		public ICal.ParameterCutype cutype;
		public ICal.ParameterRole role;
		public ICal.ParameterPartstat status;
		public bool rsvp;
		public weak string delto;
		public weak string delfrom;
		public weak string sentby;
		public weak string cn;
		public weak string language;
	}
	[CCode (cheader_filename = "libecal/libecal.h", free_function = "e_cal_component_free_datetime")]
	public struct ComponentDateTime {
		public ICal.Time? value;
		public weak string tzid;
		[CCode (cname = "_vala_e_cal_component_get_value")]
		public unowned ICal.Time? get_value () {
			return value;
		}
	}
	[CCode (cheader_filename = "libecal/libecal.h", copy_function = "g_boxed_copy", free_function = "g_boxed_free", type_id = "e_cal_component_id_get_type ()")]
	[Compact]
	public class ComponentId {
		[CCode (has_construct_function = false)]
		[Version (since = "3.10")]
		public ComponentId (string uid, string? rid);
		[Version (since = "3.10")]
		public ECal.ComponentId copy ();
		[Version (since = "3.10")]
		public bool equal (ECal.ComponentId id2);
		[Version (since = "3.10")]
		public uint hash ();
		public weak string uid;
		public weak string? rid;
		[CCode (cname = "_vala_e_cal_component_id_get_uid")]
		public unowned string get_uid () {
			return this.uid;
		}
		[CCode (cname = "_vala_e_cal_component_id_get_rid")]
		public unowned string? get_rid () {
			return this.rid;
		}
		public void set_uid (string uid);
		public void set_rid (string? rid);
	}
	[CCode (cheader_filename = "libecal/libecal.h")]
	public struct ComponentOrganizer {
		public weak string value;
		public weak string sentby;
		public weak string cn;
		public weak string language;
	}
	[CCode (cheader_filename = "libecal/libecal.h")]
	public struct ComponentPeriod {
		public ECal.ComponentPeriodType type;
		[CCode (cheader_filename = "libecal/libecal.h")]
		public ICal.Time start;
		[CCode(cname = "u.duration")]
		public ICal.Duration duration;
		[CCode(cname = "u.end")]
		public ICal.Time end;
	}
	[CCode (cheader_filename = "libecal/libecal.h", free_function = "e_cal_component_free_range")]
	public struct ComponentRange {
		public ECal.ComponentRangeType type;
		public ECal.ComponentDateTime datetime;
	}
	[CCode (cheader_filename = "libecal/libecal.h")]
	public struct ComponentText {
		public weak string value;
		public weak string altrep;
		[CCode (cname = "_vala_e_cal_component_text_get_altrep")]
		public unowned string get_altrep () {
			return this.altrep;
		}
		[CCode (cname = "_vala_e_cal_component_text_get_value")]
		public unowned string get_value () {
			return this.value;
		}
	}
	[CCode (cheader_filename = "libecal/libecal.h")]
	public struct ObjInstance {
		public weak string uid;
		public ulong start;
		public ulong end;
		[CCode (cname = "cal_obj_instance_list_free")]
		public static void list_free (GLib.List list);
	}
	[CCode (cheader_filename = "libecal/libecal.h", type_id = "e_timezone_cache_get_type")]
	public interface TimezoneCache {
		public void add_timezone (ICal.Timezone zone);
		public ICal.Timezone get_timezone (string tzid);
		public GLib.List<ICal.Timezone> list_timezones ();
		public signal void timezone_added (ICal.Timezone zone);
	}
	[CCode (cheader_filename = "libecal/libecal.h", cprefix = "E_CAL_CHANGE_", type_id = "e_cal_change_type_get_type ()")]
	public enum ChangeType {
		ADDED,
		MODIFIED,
		DELETED
	}
	[CCode (cheader_filename = "libecal/libecal.h", cprefix = "E_CAL_CLIENT_ERROR_")]
	public errordomain ClientError {
		NO_SUCH_CALENDAR,
		OBJECT_NOT_FOUND,
		INVALID_OBJECT,
		UNKNOWN_USER,
		OBJECT_ID_ALREADY_EXISTS,
		INVALID_RANGE;
		public static GLib.Error create (ECal.ClientError code, string custom_msg);
		public static GLib.Quark quark ();
		public static unowned string to_string (ECal.ClientError code);
	}
	[CCode (cheader_filename = "libecal/libecal.h", cprefix = "E_CAL_CLIENT_SOURCE_TYPE_", type_id = "e_cal_client_source_type_get_type ()")]
	public enum ClientSourceType {
		EVENTS,
		TASKS,
		MEMOS,
		LAST
	}
	[CCode (cheader_filename = "libecal/libecal.h", cprefix = "E_CAL_COMPONENT_ALARM_", has_type_id = false)]
	public enum ComponentAlarmAction {
		NONE,
		AUDIO,
		DISPLAY,
		EMAIL,
		PROCEDURE,
		UNKNOWN
	}
	[CCode (cheader_filename = "libecal/libecal.h", cprefix = "E_CAL_CLIENT_VIEW_FLAGS_")]
	[Flags]
	public enum ClientViewFlags {
		NONE,
		NOTIFY_INITIAL
	}
	[CCode (cheader_filename = "libecal/libecal.h", cname = "ECalComponentAlarmTriggerType", cprefix = "E_CAL_COMPONENT_ALARM_TRIGGER_", has_type_id = false)]
	public enum ComponentAlarmTriggerKind {
		NONE,
		RELATIVE_START,
		RELATIVE_END,
		ABSOLUTE
	}
	[CCode (cheader_filename = "libecal/libecal.h", cprefix = "E_CAL_COMPONENT_CLASS_", has_type_id = false)]
	public enum ComponentClassification {
		NONE,
		PUBLIC,
		PRIVATE,
		CONFIDENTIAL,
		UNKNOWN
	}
	[CCode (cheader_filename = "libecal/libecal.h", cprefix = "E_CAL_COMPONENT_FIELD_", has_type_id = false)]
	public enum ComponentField {
		CATEGORIES,
		CLASSIFICATION,
		COMPLETED,
		DTEND,
		DTSTART,
		DUE,
		GEO,
		PERCENT,
		PRIORITY,
		SUMMARY,
		TRANSPARENCY,
		URL,
		HAS_ALARMS,
		ICON,
		COMPLETE,
		RECURRING,
		OVERDUE,
		COLOR,
		STATUS,
		COMPONENT,
		LOCATION,
		NUM_FIELDS
	}
	[CCode (cheader_filename = "libecal/libecal.h", cprefix = "E_CAL_COMPONENT_PERIOD_", has_type_id = false)]
	public enum ComponentPeriodType {
		DATETIME,
		DURATION
	}
	[CCode (cheader_filename = "libecal/libecal.h", cprefix = "E_CAL_COMPONENT_RANGE_", has_type_id = false)]
	public enum ComponentRangeType {
		SINGLE,
		THISPRIOR,
		THISFUTURE
	}
	[CCode (cheader_filename = "libecal/libecal.h", cprefix = "E_CAL_COMPONENT_TRANSP_", has_type_id = false)]
	public enum ComponentTransparency {
		NONE,
		TRANSPARENT,
		OPAQUE,
		UNKNOWN
	}
	[CCode (cheader_filename = "libecal/libecal.h", cprefix = "E_CAL_COMPONENT_", has_type_id = false)]
	public enum ComponentVType {
		NO_TYPE,
		EVENT,
		TODO,
		JOURNAL,
		FREEBUSY,
		TIMEZONE
	}
	[CCode (cheader_filename = "libecal/libecal.h", cprefix = "E_CAL_LOAD_", has_type_id = false)]
	public enum LoadState {
		NOT_LOADED,
		AUTHENTICATING,
		LOADING,
		LOADED
	}
	[CCode (cheader_filename = "libecal/libecal.h", cprefix = "CAL_MODE_", has_type_id = false)]
	public enum Mode {
		INVALID,
		LOCAL,
		REMOTE,
		ANY
	}
	[CCode (cheader_filename = "libecal/libecal.h", cname="CalObjModType", cprefix = "E_CAL_OBJ_MOD_", has_type_id = false)]
	[Flags]
	public enum ObjModType {
		THIS,
		THIS_AND_PRIOR,
		THIS_AND_FUTURE,
		ONLY_THIS,
		ALL
	}
	[CCode (cheader_filename = "libecal/libecal.h", cprefix = "E_CAL_SET_MODE_", has_type_id = false)]
	public enum SetModeStatus {
		SUCCESS,
		ERROR,
		NOT_SUPPORTED
	}
	[CCode (cheader_filename = "libecal/libecal.h", cprefix = "E_CAL_SOURCE_TYPE_", has_type_id = false)]
	public enum SourceType {
		EVENT,
		TODO,
		JOURNAL,
		LAST
	}
	[CCode (cheader_filename = "libecal/libecal.h", cprefix = "E_CALENDAR_STATUS_", type_id = "e_calendar_status_get_type ()")]
	public enum CalendarStatus {
		OK,
		INVALID_ARG,
		BUSY,
		REPOSITORY_OFFLINE,
		NO_SUCH_CALENDAR,
		OBJECT_NOT_FOUND,
		INVALID_OBJECT,
		URI_NOT_LOADED,
		URI_ALREADY_LOADED,
		PERMISSION_DENIED,
		UNKNOWN_USER,
		OBJECT_ID_ALREADY_EXISTS,
		PROTOCOL_NOT_SUPPORTED,
		CANCELLED,
		COULD_NOT_CANCEL,
		AUTHENTICATION_FAILED,
		AUTHENTICATION_REQUIRED,
		DBUS_EXCEPTION,
		OTHER_ERROR,
		INVALID_SERVER_VERSION,
		NOT_SUPPORTED
	}
	namespace StaticCapability {
		[CCode (cheader_filename = "libecal/libecal.h", cname = "CAL_STATIC_CAPABILITY_CREATE_MESSAGES")]
		public const string CREATE_MESSAGES;
		[CCode (cheader_filename = "libecal/libecal.h", cname = "CAL_STATIC_CAPABILITY_DELEGATE_SUPPORTED")]
		public const string DELEGATE_SUPPORTED;
		[CCode (cheader_filename = "libecal/libecal.h", cname = "CAL_STATIC_CAPABILITY_DELEGATE_TO_MANY")]
		public const string DELEGATE_TO_MANY;
		[CCode (cheader_filename = "libecal/libecal.h", cname = "CAL_STATIC_CAPABILITY_HAS_UNACCEPTED_MEETING")]
		public const string HAS_UNACCEPTED_MEETING;
		[CCode (cheader_filename = "libecal/libecal.h", cname = "CAL_STATIC_CAPABILITY_NO_ALARM_REPEAT")]
		public const string NO_ALARM_REPEAT;
		[CCode (cheader_filename = "libecal/libecal.h", cname = "CAL_STATIC_CAPABILITY_NO_AUDIO_ALARMS")]
		public const string NO_AUDIO_ALARMS;
		[CCode (cheader_filename = "libecal/libecal.h", cname = "CAL_STATIC_CAPABILITY_NO_CONV_TO_ASSIGN_TASK")]
		public const string NO_CONV_TO_ASSIGN_TASK;
		[CCode (cheader_filename = "libecal/libecal.h", cname = "CAL_STATIC_CAPABILITY_NO_CONV_TO_RECUR")]
		public const string NO_CONV_TO_RECUR;
		[CCode (cheader_filename = "libecal/libecal.h", cname = "CAL_STATIC_CAPABILITY_NO_DISPLAY_ALARMS")]
		public const string NO_DISPLAY_ALARMS;
		[CCode (cheader_filename = "libecal/libecal.h", cname = "CAL_STATIC_CAPABILITY_NO_EMAIL_ALARMS")]
		public const string NO_EMAIL_ALARMS;
		[CCode (cheader_filename = "libecal/libecal.h", cname = "CAL_STATIC_CAPABILITY_NO_GEN_OPTIONS")]
		public const string NO_GEN_OPTIONS;
		[CCode (cheader_filename = "libecal/libecal.h", cname = "CAL_STATIC_CAPABILITY_NO_ORGANIZER")]
		public const string NO_ORGANIZER;
		[CCode (cheader_filename = "libecal/libecal.h", cname = "CAL_STATIC_CAPABILITY_NO_PROCEDURE_ALARMS")]
		public const string NO_PROCEDURE_ALARMS;
		[CCode (cheader_filename = "libecal/libecal.h", cname = "CAL_STATIC_CAPABILITY_NO_TASK_ASSIGNMENT")]
		public const string NO_TASK_ASSIGNMENT;
		[CCode (cheader_filename = "libecal/libecal.h", cname = "CAL_STATIC_CAPABILITY_NO_THISANDFUTURE")]
		public const string NO_THISANDFUTURE;
		[CCode (cheader_filename = "libecal/libecal.h", cname = "CAL_STATIC_CAPABILITY_NO_THISANDPRIOR")]
		public const string NO_THISANDPRIOR;
		[CCode (cheader_filename = "libecal/libecal.h", cname = "CAL_STATIC_CAPABILITY_NO_TRANSPARENCY")]
		public const string NO_TRANSPARENCY;
		[CCode (cheader_filename = "libecal/libecal.h", cname = "CAL_STATIC_CAPABILITY_ONE_ALARM_ONLY")]
		public const string ONE_ALARM_ONLY;
		[CCode (cheader_filename = "libecal/libecal.h", cname = "CAL_STATIC_CAPABILITY_ORGANIZER_MUST_ACCEPT")]
		public const string ORGANIZER_MUST_ACCEPT;
		[CCode (cheader_filename = "libecal/libecal.h", cname = "CAL_STATIC_CAPABILITY_ORGANIZER_MUST_ATTEND")]
		public const string ORGANIZER_MUST_ATTEND;
		[CCode (cheader_filename = "libecal/libecal.h", cname = "CAL_STATIC_CAPABILITY_ORGANIZER_NOT_EMAIL_ADDRESS")]
		public const string ORGANIZER_NOT_EMAIL_ADDRESS;
		[CCode (cheader_filename = "libecal/libecal.h", cname = "CAL_STATIC_CAPABILITY_RECURRENCES_NO_MASTER")]
		public const string RECURRENCES_NO_MASTER;
		[CCode (cheader_filename = "libecal/libecal.h", cname = "CAL_STATIC_CAPABILITY_REFRESH_SUPPORTED")]
		public const string REFRESH_SUPPORTED;
		[CCode (cheader_filename = "libecal/libecal.h", cname = "CAL_STATIC_CAPABILITY_REMOVE_ALARMS")]
		public const string REMOVE_ALARMS;
		[CCode (cheader_filename = "libecal/libecal.h", cname = "CAL_STATIC_CAPABILITY_REMOVE_ONLY_THIS")]
		public const string REMOVE_ONLY_THIS;
		[CCode (cheader_filename = "libecal/libecal.h", cname = "CAL_STATIC_CAPABILITY_REQ_SEND_OPTIONS")]
		public const string REQ_SEND_OPTIONS;
		[CCode (cheader_filename = "libecal/libecal.h", cname = "CAL_STATIC_CAPABILITY_SAVE_SCHEDULES")]
		public const string SAVE_SCHEDULES;
	}
	[CCode (cheader_filename = "libecal/libecal.h", cprefix = "", has_type_id = false)]
	public enum DataCalMode {
		Local,
		Remote,
		AnyMode
	}
	[CCode (cheader_filename = "libecal/libecal.h", instance_pos = 3.9)]
	public delegate bool RecurInstanceCb (ICal.Component icomp, ICal.Time instance_start, ICal.Time instance_end, GLib.Cancellable? cancellable = null) throws GLib.Error;
	[CCode (cheader_filename = "libecal/libecal.h", instance_pos = 1.9)]
	public delegate unowned ICal.Timezone? RecurResolveTimezoneCb (string tzid, GLib.Cancellable? cancellable = null) throws GLib.Error;
	[CCode (cheader_filename = "libecal/libecal.h")]
	public delegate bool RecurInstanceFn (ECal.Component comp, time_t instance_start, time_t instance_end);
	[CCode (cheader_filename = "libecal/libecal.h")]
	public delegate ICal.Timezone RecurResolveTimezoneFn (string tzid);
	[CCode (cheader_filename = "libecal/libecal.h")]
	public delegate ICal.Timezone TzLookup (string tzid, ECal.Client ecalclient, GLib.Cancellable? cancellable = null) throws GLib.Error;
	[CCode (cheader_filename = "libecal/libecal.h", cname = "cal_obj_uid_list_free")]
	public static void cal_obj_uid_list_free (GLib.List list);
	public static string cal_system_timezone_get_location ();
	[CCode (cheader_filename = "libecal/libecal.h", cname = "isodate_from_time_t")]
	public static unowned string isodate_from_time_t (time_t t);
	[CCode (cheader_filename = "libecal/libecal.h")]
	public static bool recur_generate_instances_sync (ICal.Component icalcomp, ICal.Time interval_start, ICal.Time interval_end, [CCode (delegate_target_pos = 4.5)] ECal.RecurInstanceCb? callback, [CCode (delegate_target_pos = 5.5)] ECal.RecurResolveTimezoneCb? get_tz_callback, ICal.Timezone default_timezone, GLib.Cancellable? cancellable = null) throws GLib.Error;
	namespace Util {
		[CCode (cheader_filename = "libecal/libecal.h", cname = "icaltimetype_to_tm")]
		public static Posix.tm icaltimetype_to_tm (ICal.Time itt);
		[CCode (cheader_filename = "libecal/libecal.h", cname = "icaltimetype_to_tm_with_zone")]
		public static Posix.tm icaltimetype_to_tm_with_zone (ICal.Time itt, ICal.Timezone from_zone, ICal.Timezone to_zone);
		[CCode (cheader_filename = "libecal/libecal.h", cname = "time_add_day")]
		public static time_t time_add_day (time_t time, int days);
		[CCode (cheader_filename = "libecal/libecal.h", cname = "time_add_day_with_zone")]
		public static time_t time_add_day_with_zone (time_t time, int days, ICal.Timezone zone);
		[CCode (cheader_filename = "libecal/libecal.h", cname = "time_add_month_with_zone")]
		public static time_t time_add_month_with_zone (time_t time, int months, ICal.Timezone zone);
		[CCode (cheader_filename = "libecal/libecal.h", cname = "time_add_week")]
		public static time_t time_add_week (time_t time, int weeks);
		[CCode (cheader_filename = "libecal/libecal.h", cname = "time_add_week_with_zone")]
		public static time_t time_add_week_with_zone (time_t time, int weeks, ICal.Timezone zone);
		[CCode (cheader_filename = "libecal/libecal.h", cname = "time_day_begin")]
		public static time_t time_day_begin (time_t t);
		[CCode (cheader_filename = "libecal/libecal.h", cname = "time_day_begin_with_zone")]
		public static time_t time_day_begin_with_zone (time_t time, ICal.Timezone zone);
		[CCode (cheader_filename = "libecal/libecal.h", cname = "time_day_end")]
		public static time_t time_day_end (time_t t);
		[CCode (cheader_filename = "libecal/libecal.h", cname = "time_day_end_with_zone")]
		public static time_t time_day_end_with_zone (time_t time, ICal.Timezone zone);
		[CCode (cheader_filename = "libecal/libecal.h", cname = "time_day_of_week")]
		public static int time_day_of_week (int day, int month, int year);
		[CCode (cheader_filename = "libecal/libecal.h", cname = "time_day_of_year")]
		public static int time_day_of_year (int day, int month, int year);
		[CCode (cheader_filename = "libecal/libecal.h", cname = "time_days_in_month")]
		public static int time_days_in_month (int year, int month);
		[CCode (cheader_filename = "libecal/libecal.h", cname = "time_from_isodate")]
		public static time_t time_from_isodate (string str);
		[CCode (cheader_filename = "libecal/libecal.h", cname = "time_is_leap_year")]
		public static bool time_is_leap_year (int year);
		[CCode (cheader_filename = "libecal/libecal.h", cname = "time_leap_years_up_to")]
		public static int time_leap_years_up_to (int year);
		[CCode (cheader_filename = "libecal/libecal.h", cname = "time_month_begin_with_zone")]
		public static time_t time_month_begin_with_zone (time_t time, ICal.Timezone zone);
		[CCode (cheader_filename = "libecal/libecal.h", cname = "time_to_gdate_with_zone")]
		public static void time_to_gdate_with_zone (GLib.Date date, time_t time, ICal.Timezone zone);
		[CCode (cheader_filename = "libecal/libecal.h", cname = "time_week_begin_with_zone")]
		public static time_t time_week_begin_with_zone (time_t time, int week_start_day, ICal.Timezone zone);
		[CCode (cheader_filename = "libecal/libecal.h", cname = "time_year_begin_with_zone")]
		public static time_t time_year_begin_with_zone (time_t time, ICal.Timezone zone);
		[CCode (cheader_filename = "libecal/libecal.h", cname = "tm_to_icaltimetype")]
		public static ICal.Time tm_to_icaltimetype (Posix.tm time, bool is_date);
		[CCode (cheader_filename = "libecal/libecal.h", cname = "e_cal_util_get_system_timezone_location")]
		public static string get_system_timezone_location ();
		[CCode (cheader_filename = "libecal/libecal.h", cname = "e_cal_util_get_system_timezone")]
		public static unowned ICal.Timezone get_system_timezone ();
		[CCode (cheader_filename = "libecal/libecal.h", cname = "e_cal_util_priority_from_string")]
		public static int priority_from_string (string string);
		[CCode (cheader_filename = "libecal/libecal.h", cname = "e_cal_util_priority_to_string")]
		public static unowned string priority_to_string (int priority);
		[CCode (cheader_filename = "libecal/libecal.h", cname = "e_cal_util_new_component")]
		public static ICal.Component new_component (ICal.ComponentKind kind);
		[CCode (cheader_filename = "libecal/libecal.h", cname = "e_cal_util_parse_ics_string")]
		public static ICal.Component parse_ics_string (string string);
		[CCode (cheader_filename = "libecal/libecal.h", cname = "e_cal_util_parse_ics_file")]
		public static ICal.Component parse_ics_file (string filename);
		public static bool cal_client_check_timezones (ICal.Component comp, GLib.List<ICal.Component> comps, TzLookup tzlookup, ECal.Client ecalclient, GLib.Cancellable? cancellable = null) throws GLib.Error;
	}
}
