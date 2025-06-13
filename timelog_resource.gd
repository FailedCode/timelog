extends Resource
class_name Timelog
## The timelog is pretty simple: date and time genreally tell when a Task ended
## The first entry on a day is the start time for the following task
## The text part can be basically anyting - but there are some specialities
## - Text containing "**" is a pause, like "lunch **" - this does not count toward daily working hours
## - Text containing "***" marks something entirly ignored
## - Tasks are broken um by ":" into sub-tasks - this is used for grouping
## - The text should never be empty - that would make no sense and is annoying to debug

var timestamp:int = 0
var text:String = ""

func _init(tstamp:int = 0, txt:String = "") -> void:
	txt = txt.strip_edges()
	if txt.is_empty():
		txt = "[EMPTY]"
	if tstamp == 0:
		txt = "[ZERO TIMESTAMP]" + txt
	self.text = txt
	self.timestamp = tstamp

func _to_string() -> String:
	var date = Time.get_datetime_string_from_unix_time(self.timestamp, true)
	return "{date}: {text}".format({
		"date": date,
		"text": self.text,
	})
