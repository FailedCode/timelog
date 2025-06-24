extends Control

## All Settings are stored here:
const settings_path:String = "user://settings.ini"

## The file serves as long-time storage
const timelog_path:String = "user://timelog.txt"

## The todo items
const todo_path:String = "user://todo.txt"

## In memory representation of the log
var timelog:Dictionary

## used to update the TimeDiffLabel
var lastEntryTimestamp:int = 0

## This tracks wich day is currently selected
var currentDateTimestamp:int

## store locales with translations for those values
var languageOptions:Dictionary

## When this is used, it means "use whatever language the system uses"
const SYSTEM_LANGUAGE = "system"

## currently, the value does not matter
const AUTO_DAY_START_TEXT = "arrived"

@onready var input:LineEdit = %Input
@onready var timeDiffLabel:Label = %TimeDiffLabel
@onready var current:RichTextLabel = %CurrentDay
@onready var grouped:RichTextLabel = %GroupedDay
@onready var dailyWorkingHoursLabel:Label = %DailyWorkingHoursLabel
@onready var dailyWorkingHours:Slider = %DailyWorkingHours
@onready var tabContainer:TabContainer = %TabContainer
@onready var tabLabelContainer:Node = %TabLabelContainer
@onready var todoTree:Tree = %TodoTree


@onready var selectedLanguageButton:OptionButton = %SelectedLanguageButton
@onready var dateLabel:Label = %DateLabel
@onready var dateFormat:LineEdit = %DateFormat
@onready var dateFormatPreviewLabel:Label = %DateFormatPreviewLabel
@onready var diffSecondsToggle:CheckButton = %DiffSecondsToggle
@onready var textColorPicker:ColorPickerButton = %TextColorPicker
@onready var timeColorPicker:ColorPickerButton = %TimeColorPicker
@onready var pauseColorPicker:ColorPickerButton = %PauseColorPicker

func _ready() -> void:
	currentDateTimestamp = time()
	create_language_selection()
	load_user_settings()
	create_tab_labels()
	set_translation()
	
	load_timelog()
	auto_day_start()
	
	# WIP
	#var root = todoTree.create_item()
	#root.set_text(0, "root")
	#var item = todoTree.create_item(root)
	#item.set_text(0, "child")

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

## the godot docs suggest to remove everything in square brackets - that might be a little
## too much if you have some task that look like "[#12334] ticket something"
## We keep the user supplied text as-is and just escape square brackets for display purposes
func escape_bb_tags(text:String) -> String:
	text = text.replace("[", "@@LEFT_BRACKET@@")
	text = text.replace("]", "@@RIGHT_BRACKET@@")
	text = text.replace("@@LEFT_BRACKET@@", "[lb]")
	text = text.replace("@@RIGHT_BRACKET@@", "[rb]")
	return text

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
	selectedLanguageButton.select(languageOptions.get(config_file.get_value("main", "language", SYSTEM_LANGUAGE)))
	v = config_file.get_value("main", "DailyWorkingHours", 0)
	if v > 0:
		dailyWorkingHours.value = float(v)
	v = config_file.get_value("main", "DateFormat", "")
	if v != "":
		dateFormat.text = v
	diffSecondsToggle.button_pressed = config_file.get_value("main", "DiffSecondsToggle", false)

func save_user_settings():
	var config_file := ConfigFile.new()
	config_file.set_value("main", "language", languageOptions.get(max(selectedLanguageButton.selected, 0)))
	config_file.set_value("main", "DailyWorkingHours", dailyWorkingHours.value)
	config_file.set_value("main", "DateFormat", dateFormat.text)
	config_file.set_value("main", "DiffSecondsToggle", diffSecondsToggle.button_pressed)
	#config_file.set_value("main", "RoundingMinutes",  roundingMinutes.text)
	#config_file.set_value("main", "TextColorPicker", textColorPicker.text)
	#config_file.set_value("main", "TimeColorPicker", timeColorPicker.text)
	#config_file.set_value("main", "PauseColorPicker", pauseColorPicker.text)
	config_file.save(self.settings_path)

## switch the language of the application
func set_translation(language:String = SYSTEM_LANGUAGE):
	if language == SYSTEM_LANGUAGE:
		# if this locale isn't available in the TranslationServer
		# we will fall back to "en" as set in: internationalization/locale/fallback
		language = OS.get_locale_language()
	TranslationServer.set_locale(language)
	trigger_setting_updates()

## Fill possible language options
func create_language_selection():
	var locales:Array = [SYSTEM_LANGUAGE]
	locales.append_array(TranslationServer.get_loaded_locales())
	var id:int = 0
	for locale in locales:
		languageOptions.set(id, locale) # needed for switching languages
		languageOptions.set(locale, id) # needed for setting the right ID when loading settings
		selectedLanguageButton.add_item(tr(locale.to_upper() + "_LANGUAGE"), id)
		id += 1

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

## After loading or when changing language, there are texts that need
## to be updated
func trigger_setting_updates():
	dailyWorkingHours.value_changed.emit(dailyWorkingHours.value)
	dateFormat.text_changed.emit(dateFormat.text)

## Here the actual user input is handled!
func _on_input_text_submitted(new_text: String) -> void:
	input.text = ""
	new_text = new_text.strip_edges()
	if new_text.is_empty():
		return
	add_timelog_entry_now(new_text)
	save_timelog()
	# Look & Feel: Reset time difference immediately
	timeDiffLabel.text = time_diff(0)

## write all timelog Resources back to disk
func save_timelog():
	var file = FileAccess.open(self.timelog_path, FileAccess.WRITE)
	var lines = ""
	var timelogKeys = timelog.keys()
	# dictionary keys are not necassarly in order
	timelogKeys.sort()
	for date in timelogKeys:
		var day = timelog.get(date)
		for entry in day:
			lines += str(entry) + "\n"
		lines += "\n"
	file.store_string(lines)
	file.close()

## parse into timelog Resources
func load_timelog():
	if !FileAccess.file_exists(self.timelog_path):
		#print("load_timelog: No logfile")
		return
	var file = FileAccess.open(self.timelog_path, FileAccess.READ)
	var lines = file.get_as_text(true).split("\n", false);
	file.close()
	for line in lines:
		var parts = line.split(": ", false, 1)
		#print("parsing line: ", parts)
		if len(parts) < 2:
			#print("skip")
			continue
		if len(parts[1]) == 0:
			#print("skip empty text")
			continue
		# TODO: Use regex; 
		# Allow missing seconds
		if len(parts[0]) == 16:
			parts[0] += ":00"
		var timestamp = Time.get_unix_time_from_datetime_string(parts[0])
		if timestamp == -1:
			#print("error parsing time")
			continue
		lastEntryTimestamp = timestamp
		add_timelog_entry(timestamp, parts[1])
	update_text_controls()
	#timelogPerDay.get_or_add()

## Both the text in the main window and the one with the grouped output
## basically need to be updated at the same time
func update_text_controls():
	update_current_text()
	update_grouped_text()

## update the main view with all recorded tasks
func update_current_text():
	var txt:String = ""
	var timediff = 0
	var timelast = 0
	var timeWorked = 0
	var timePaused = 0
	var colorTime:String = timeColorPicker.color.to_html()
	var timelog_today = get_timelog_entries(currentDateTimestamp)
	for entry in timelog_today:
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
		txt += wrap_color(time_diff(timediff), colorTime) + "\t\t" + wrap_color(escape_bb_tags(entry.text), color) + "\n"
	txt += "\n"
	var workTimeLeft = (dailyWorkingHours.value * 3600) - timeWorked
	txt += "Time worked: " + wrap_color(time_diff(timeWorked), colorTime) + "\n"
	txt += "Time paused: " + wrap_color(time_diff(timePaused), colorTime) + "\n"
	txt += "Time left: " + wrap_color(time_diff(workTimeLeft), colorTime) + "\n"
	current.text = txt

func update_grouped_text():
	var txt:String = ""
	var timediff = 0
	var timelast = 0
	var colorText:String = textColorPicker.color.to_html()
	var colorTime:String = timeColorPicker.color.to_html()
	var groupedDict:Dictionary
	var timelog_today = get_timelog_entries(currentDateTimestamp)
	for entry:Timelog in timelog_today:
		if timelast == 0:
			timelast = entry.timestamp
			continue
		timediff = entry.timestamp - timelast
		timelast = entry.timestamp
		if entry.text.contains("**"):
			continue
		var group:Array = entry.text.split(": ", false, 1)
		var diff:int = groupedDict.get(group[0], 0)
		groupedDict.set(group[0], diff + timediff)
	
	for groupText in groupedDict.keys():
		var groupdiff:int = groupedDict.get(groupText, 0)
		txt += wrap_color(time_diff(groupdiff), colorTime) + "\t\t" + wrap_color(escape_bb_tags(groupText), colorText) + "\n"
	grouped.text = txt

## If there is no start entry for today, add one - since opening the app
## basically always means we want to track this day
func auto_day_start():
	var timelog_today = get_timelog_entries(currentDateTimestamp)
	if timelog_today.is_empty():
		add_timelog_entry_now(AUTO_DAY_START_TEXT)

## How do you know I program PHP?!
func time() -> int:
	return floor(Time.get_unix_time_from_system())

## hours/minutes elapsed for tasks
## if statistics for a week are summed up, this may be > 24h
func time_diff(seconds:int) -> String:
	var hours:int = floor(seconds / 3600.0)
	seconds -= hours * 3600
	var minutes:int = floor(seconds / 60.0)
	seconds -= minutes * 60
	if diffSecondsToggle.button_pressed:
		return "%02d:%02d:%02d"%[hours, minutes, seconds]
	return "%02d:%02d"%[hours, minutes]

## Date String like "2025-06-09" used as Dictionary key to seperate days
## TODO: "virtual midnight" would need to implemented here as well
func get_date_string(tstamp:int) -> String:
	var d = Time.get_datetime_dict_from_unix_time(tstamp)
	return "%04d-%02d-%02d"%[d["year"], d["month"], d["day"]]

## Every day is a entry in the dictionary timelog
## the day is an array of Timelog entries
func add_timelog_entry(tstamp:int, text:String):
	var key = get_date_string(tstamp)
	var day = timelog.get_or_add(key, [])
	day.append(Timelog.new(tstamp, text))

## Service function
func add_timelog_entry_now(text:String):
	lastEntryTimestamp = time()
	add_timelog_entry(lastEntryTimestamp, text)
	update_text_controls()

## based on a time stamp, find entries
## TODO: "virtual midnight" would need to implemented here as well
func get_timelog_entries(tstamp:int) -> Array:
	var key = get_date_string(tstamp)
	return timelog.get_or_add(key, [])

func _on_date_back_button_pressed() -> void:
	currentDateTimestamp -= 86400
	dateLabel.text = get_date_formated(dateFormat.text, currentDateTimestamp)
	update_text_controls()

func _on_date_forward_button_pressed() -> void:
	currentDateTimestamp += 86400
	if (currentDateTimestamp > time()):
		currentDateTimestamp = time()
	dateLabel.text = get_date_formated(dateFormat.text, currentDateTimestamp)
	update_text_controls()

func _on_date_today_button_pressed() -> void:
	currentDateTimestamp = time()
	dateLabel.text = get_date_formated(dateFormat.text, currentDateTimestamp)
	update_text_controls()

## settings change
func _on_selected_language_button_item_selected(index: int) -> void:
	# get the language code from the Dictionary here, so the
	# text for the button can be translated as well
	set_translation(languageOptions.get(index, SYSTEM_LANGUAGE))
	# Update the Text 
	for i in selectedLanguageButton.item_count:
		var locale:String = languageOptions.get(i)
		selectedLanguageButton.set_item_text(i, tr(locale.to_upper() + "_LANGUAGE"))

## settings change
## if you work for more than 10 hours a day... I don't know what to tell you, but that is too much
func _on_daily_working_hours_value_changed(value: float) -> void:
	dailyWorkingHoursLabel.text = "Tägliche Arbeitszeit: {v} h".format({"v": value})
	if value > 10:
		dailyWorkingHours.modulate = Color(0.8, 0, 0)
	else:
		dailyWorkingHours.modulate = Color(1, 1, 1) 

## settings change
## The tabs can't have no name, so fall back on the placeholder
func _on_tabLabel_changed(new_text:String, tab:Node, tabLabel:Node) -> void:
	if new_text.strip_edges().is_empty():
		new_text = tabLabel.placeholder_text
	tab.name = new_text

## settings change
func _on_diff_seconds_toggle_toggled(_toggled_on: bool) -> void:
	update_text_controls()

## settings change
func _on_tabs_moveable_toggled(toggled_on: bool) -> void:
	tabContainer.drag_to_rearrange_enabled = toggled_on

## settings change
func _on_date_format_text_changed(new_text: String) -> void:
	# Example timestamp: 2025-02-27 14:05:45
	dateFormatPreviewLabel.text = get_date_formated(new_text, 1740661545)
	dateLabel.text = get_date_formated(new_text, currentDateTimestamp)

## open "user://" to fiddle with the files by hand
func _on_open_user_folder_button_pressed() -> void:
	OS.shell_open(OS.get_user_data_dir())

## Runs Every Second
func _on_second_timer_timeout() -> void:
	if lastEntryTimestamp == 0:
		return
	timeDiffLabel.text = time_diff(time() - lastEntryTimestamp)

## When the application shuts down, we save all data
func _on_tree_exiting() -> void:
	save_user_settings()
	save_timelog()

	
