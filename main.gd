extends Control

## All Settings are stored here:
const settings_path:String = "user://settings.ini"

## The file serves as long-time storage
## TODO: add file selector in settings
var timelog_path:String = "user://timelog.txt"

## In memory representation of the log
var timelog:Array[Timelog]

## 
var lastEntryTimestamp:int = 0

@onready var input:LineEdit = %Input
@onready var timeDiffLabel:Label = %TimeDiffLabel
@onready var current:RichTextLabel = %CurrentDay
@onready var dailyWorkingHoursLabel:Label = %DailyWorkingHoursLabel
@onready var dailyWorkingHours:Slider = %DailyWorkingHours
@onready var tabContainer:TabContainer = %TabContainer
@onready var tabLabelContainer:Node = %TabLabelContainer
@onready var todoTree:Tree = %TodoTree
@onready var dateLabel:Label = %DateLabel
@onready var dateFormat:LineEdit = %DateFormat
@onready var dateFormatPreviewLabel:Label = %DateFormatPreviewLabel
@onready var textColorPicker:ColorPickerButton = %TextColorPicker
@onready var timeColorPicker:ColorPickerButton = %TimeColorPicker
@onready var pauseColorPicker:ColorPickerButton = %PauseColorPicker

func _ready() -> void:
	
	load_user_settings()
	create_tab_labels()
	
	# after loading settings, make sure signals are fired for consistency
	dailyWorkingHours.value_changed.emit(dailyWorkingHours.value)
	dateFormat.text_changed.emit(dateFormat.text)
	
	# WIP
	#var root = todoTree.create_item()
	#root.set_text(0, "root")
	#todoTree.create_item(root).set_text(0, "child")

## When the application shuts down, we save all data
func _on_tree_exiting() -> void:
	save_user_settings()

func get_date_formated(format:String, timestamp:int = 0) -> String:
	var t:String = format.strip_edges()
	if t.is_empty():
		return ""
	var d:Dictionary
	if timestamp == 0:
		d = Time.get_datetime_dict_from_system()
	else:
		d = Time.get_datetime_dict_from_unix_time(timestamp)
	var wd = ["Sonntag", "Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag"]
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

func remove_bb_tags(text:String) -> String:
	var regex = RegEx.new()
	regex.compile("\\[.*?\\]")
	return regex.sub(text, "", true)

func wrap_color(text:String, color:String) -> String:
	return "[color={colorCode}]{text}[/color]".format({"text": text, "colorCode": color})

func load_user_settings():
	var config_file := ConfigFile.new()
	var error := config_file.load(self.settings_path)
	if error:
		print("load_user_settings ERROR:", error)
		return;
	# Is there a smarter way to make sure sensible values are set?
	var v
	v = config_file.get_value("main", "DailyWorkingHours", 0)
	if v > 0:
		dailyWorkingHours.value = float(v)
	v = config_file.get_value("main", "DateFormat", "")
	if v != "":
		dateFormat.text = v

func save_user_settings():
	var config_file := ConfigFile.new()
	config_file.set_value("main", "DailyWorkingHours", dailyWorkingHours.value)
	config_file.set_value("main", "DateFormat", dateFormat.text)
	#config_file.set_value("main", "RoundingMinutes",  roundingMinutes.text)
	#config_file.set_value("main", "TextColorPicker", textColorPicker.text)
	#config_file.set_value("main", "TimeColorPicker", timeColorPicker.text)
	#config_file.set_value("main", "PauseColorPicker", pauseColorPicker.text)
	config_file.save(self.settings_path)

## Helper function to create text input for every Tab
## Adds the Tab node to the signal, so one general handler function can be reused
func create_tab_labels():
	# create input label for each tab
	for tab in tabContainer.get_children():
		var tabLabel = LineEdit.new()
		tabLabel.placeholder_text = tab.name
		tabLabel.size_flags_horizontal = Control.SIZE_FILL + Control.SIZE_EXPAND
		tabLabel.text_changed.connect(_on_tabLabel_changed.bind(tab, tabLabel))
		tabLabelContainer.add_child(tabLabel)

## Here the actual user input is handled!
func _on_input_text_submitted(new_text: String) -> void:
	input.text = ""
	new_text = new_text.strip_edges()
	if new_text.is_empty():
		return
	lastEntryTimestamp = time()
	timelog.append(Timelog.new(lastEntryTimestamp, remove_bb_tags(new_text)))
	update_current_text()
	# Look & Feel: Reset time difference immediately
	timeDiffLabel.text = time_diff(0)
	#current.append_text("\n" + wrap_color(str(log), "#FF00FF"))

func save_timelog():
	# TODO: Sort before saving
	# timelog.sort_custom()
	pass

func load_timelog():
	pass

func update_current_text():
	var txt:String = ""
	# TODO: find start of day
	# TODO: calculate time difference
	var timediff = 0
	var timelast = 0
	var timeWorked = 0
	var timePaused = 0
	var colorTime:String = timeColorPicker.color.to_html()
	for entry in timelog:
		if timelast == 0:
			timelast = entry.timestamp
			#txt += str(entry.text) + "\n"
			continue
		timediff = entry.timestamp - timelast
		timelast = entry.timestamp
		var color:String = textColorPicker.color.to_html()
		if entry.text.contains("**"):
			timePaused += timediff
			color = pauseColorPicker.color.to_html()
		else:
			timeWorked += timediff
		txt += wrap_color(time_diff(timediff), colorTime) + " " + wrap_color(entry.text, color) + "\n"
	txt += "\n"
	var workTimeLeft = (dailyWorkingHours.value * 3600) - timeWorked
	txt += "Time worked: " + wrap_color(time_diff(timeWorked), colorTime) + "\n"
	txt += "Time paused: " + wrap_color(time_diff(timePaused), colorTime) + "\n"
	txt += "Time left: " + wrap_color(time_diff(workTimeLeft), colorTime) + "\n"
	current.text = txt

## How do you know I program PHP?!
func time() -> int:
	return floor(Time.get_unix_time_from_system())

func time_diff(seconds:int) -> String:
	var hours:int = floor(seconds / 3600.0)
	seconds -= hours * 3600
	var minutes:int = floor(seconds / 60.0)
	seconds -= minutes * 60
	# TODO: Setting for seconds output
	return "%02d:%02d:%02d"%[hours, minutes, seconds]

func _on_daily_working_hours_value_changed(value: float) -> void:
	dailyWorkingHoursLabel.text = "Tägliche Arbeitszeit: {v} h".format({"v": value})
	if value > 10:
		dailyWorkingHours.modulate = Color(0.8, 0, 0)
	else:
		dailyWorkingHours.modulate = Color(1, 1, 1) 

func _on_tabLabel_changed(new_text:String, tab:Node, tabLabel:Node) -> void:
	if new_text.strip_edges().is_empty():
		new_text = tabLabel.placeholder_text
	tab.name = new_text

func _on_tabs_moveable_toggled(toggled_on: bool) -> void:
	tabContainer.drag_to_rearrange_enabled = toggled_on

func _on_date_format_text_changed(new_text: String) -> void:
	dateFormatPreviewLabel.text = get_date_formated(new_text)
	dateLabel.text = get_date_formated(new_text)

## Runs Every Second
func _on_second_timer_timeout() -> void:
	if lastEntryTimestamp == 0:
		return
	timeDiffLabel.text = time_diff(time() - lastEntryTimestamp)
