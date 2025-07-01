extends Node
## Utility methods regarding date and time formating that are used in multiple places

const SECONDS_PER_DAY = 86400
const SECONDS_PER_HOUR = 3600
const SECONDS_PER_MINUTE = 60

var timezone:Dictionary

## Number of seconds from/to unix time
func get_timezone_offset() -> int:
	if timezone.is_empty():
		timezone = Time.get_time_zone_from_system()
	return timezone["bias"] * SECONDS_PER_MINUTE

## We aim to use the same datetime string as the users clock would show
## That means, we localize timestamps
func time() -> int:
	return floor(Time.get_unix_time_from_system()) + get_timezone_offset()

## hours/minutes elapsed for tasks
## if statistics for a week are summed up, this may be > 24h
func time_diff(seconds:int, enableSeconds:bool) -> String:
	var hours:int = floor(seconds / float(SECONDS_PER_HOUR))
	seconds -= hours * SECONDS_PER_HOUR
	var minutes:int = floor(seconds / float(SECONDS_PER_MINUTE))
	if enableSeconds:
		seconds -= minutes * SECONDS_PER_MINUTE
		return "%02d:%02d:%02d"%[hours, minutes, seconds]
	return "%02d:%02d"%[hours, minutes]

## returns a ISO 8601 datestring for saving
## all our timestamps are timezone corrected: A entry at 15:00 will be saved as such
func timestamp_to_iso8601_string(timestamp:int) -> String:
	return Time.get_datetime_string_from_unix_time(timestamp, true)

## When loading a ISO 8601 datestring we expect it to be in our local timezone
## further timezone manipulation isn't necassary
func iso8601_string_to_timestamp(date:String) -> int:
	return Time.get_unix_time_from_datetime_string(date)

## Date String like "2025-06-09" used as Dictionary key to seperate days
## TODO: "virtual midnight" would need to implemented here as well
func get_date_string(tstamp:int) -> String:
	var d = Time.get_datetime_dict_from_unix_time(tstamp)
	return "%04d-%02d-%02d"%[d["year"], d["month"], d["day"]]

## use a user controlled date format to display a timestamp
## mostly used for the date selector
## the timelog file itself uses the ISO 8601 format
func get_date_formated(format:String, timestamp:int = 0) -> String:
	var t:String = format.strip_edges()
	if t.is_empty():
		return ""
	var d:Dictionary
	if timestamp == 0:
		d = Time.get_datetime_dict_from_system()
	else:
		d = Time.get_datetime_dict_from_unix_time(timestamp)
	var wd = [tr("SUNDAY"), tr("MONDAY"), tr("TUESDAY"), tr("WEDNESDAY"), tr("THURSDAY"), tr("FRIDAY"), tr("SATURDAY")]
	var r = {
		"%y": str(d["year"]).substr(2),
		"%Y": d["year"],
		"%m": "%02d"%[ d["month"] ],
		"%d": "%02d"%[ d["day"] ],
		"%D": wd[ d["weekday"] ],
		"%h": "%02d"%[ d["hour"] ],
		"%i": "%02d"%[ d["minute"] ],
		"%s": "%02d"%[ d["second"] ],
	}
	for k in r:
		t = t.replace(str(k), str(r[k]))
	return t
