extends Control

## All Settings are stored here:
const SETTINGS_PATH:String = "user://settings.ini"

## The file serves as long-time storage
const TIMELOG_PATH:String = "user://timelog.txt"

## The todo items
const TODO_PATH:String = "user://todo.txt"

## Timelog Row
const sceneRow:PackedScene = preload("res://scenes/row.tscn")

## currently, the value does not matter
const AUTO_DAY_START_TEXT = "arrived"

## Contains all Application Settings
var appSettings:AppSettings

## In memory representation of the log
var timelog:Dictionary

## used to update the TimeDiffLabel
var lastEntryTimestamp:int = 0

## This tracks wich day is currently selected
var currentDateTimestamp:int

# Input Tab
@onready var input:LineEdit = %Input
@onready var timeDiffLabel:Label = %TimeDiffLabel
@onready var current:RichTextLabel = %CurrentDay
@onready var rowContainer:Node = %RowContainer
@onready var dailyWorkingHoursLabel:Label = %DailyWorkingHoursLabel
@onready var dailyWorkingHours:Slider = %DailyWorkingHours

# Grouped Tab
@onready var grouped:RichTextLabel = %GroupedDay

# Todo Tab
@onready var todoTree:Tree = %TodoTree

# Settings Tab
@onready var tabContainer:TabContainer = %TabContainer
@onready var tabLabelContainer:Node = %TabLabelContainer
@onready var selectedLanguageButton:OptionButton = %SelectedLanguageButton
@onready var dateLabel:Label = %DateLabel
@onready var dateFormat:LineEdit = %DateFormat
@onready var dateFormatPreviewLabel:Label = %DateFormatPreviewLabel
@onready var diffSecondsToggle:CheckButton = %DiffSecondsToggle
@onready var roundingMinutes:SpinBox = %RoundingMinutes
@onready var roundingGraceMinutes:SpinBox = %RoundingGraceMinutes
@onready var textColorPicker:ColorPickerButton = %TextColorPicker
@onready var timeColorPicker:ColorPickerButton = %TimeColorPicker
@onready var pauseColorPicker:ColorPickerButton = %PauseColorPicker


func _ready() -> void:
	appSettings = AppSettings.new()
	currentDateTimestamp = DateTime.time()
	create_language_selection()
	load_settings()
	create_tab_labels()
	load_timelog()
	auto_day_start()


## the godot docs suggest to remove everything in square brackets - that might be a little
## too much if you have some task that look like "[#12334] ticket something"
## We keep the user supplied text as-is and just escape square brackets for display purposes
func escape_bb_tags(text:String) -> String:
	text = text.replace("[", "@@LEFT_BRACKET@@")
	text = text.replace("]", "@@RIGHT_BRACKET@@")
	text = text.replace("@@LEFT_BRACKET@@", "[lb]")
	text = text.replace("@@RIGHT_BRACKET@@", "[rb]")
	return text

## Add BB color tag around a string
func wrap_color(text:String, color:String) -> String:
	return "[color={colorCode}]{text}[/color]".format({"text": text, "colorCode": color})

func load_settings():
	appSettings.load_from_file(SETTINGS_PATH)
	# set all UI elments with the loaded data
	selectedLanguageButton.select(appSettings.language)
	dailyWorkingHours.value = appSettings.dailyWorkingHours
	dateFormat.text = appSettings.dateFormat
	diffSecondsToggle.button_pressed = appSettings.diffSecondsToggle
	roundingMinutes.value = appSettings.roundingMinutes
	roundingGraceMinutes.value = appSettings.roundingGraceMinutes
	# apply settings
	set_translation(appSettings.getLanugageString())
	if appSettings.window_size != Vector2i(0,0):
		get_window().size = appSettings.window_size
	if appSettings.window_position != Vector2i(0,0):
		get_window().position = appSettings.window_position

func save_settings():
	# get_window() is not accessible in the settings resource class
	appSettings.window_size = get_window().size
	appSettings.window_position = get_window().position
	appSettings.save_to_file(SETTINGS_PATH)

## switch the language of the application
func set_translation(language:String = appSettings.SYSTEM_LANGUAGE):
	if language == appSettings.SYSTEM_LANGUAGE:
		# if this locale isn't available in the TranslationServer
		# we will fall back to "en" as set in: internationalization/locale/fallback
		language = OS.get_locale_language()
	TranslationServer.set_locale(language)
	trigger_setting_updates()

## Fill possible language options
func create_language_selection():
	var locales:Array = [appSettings.SYSTEM_LANGUAGE]
	locales.append_array(TranslationServer.get_loaded_locales())
	var id:int = 0
	for locale in locales:
		appSettings.languageOptions.set(id, locale) # needed for switching languages
		appSettings.languageOptions.set(locale, id) # needed for setting the right ID when loading settings
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
	timeDiffLabel.text = DateTime.time_diff(0, appSettings.diffSecondsToggle)

## write all timelog Resources back to disk
func save_timelog():
	var file = FileAccess.open(TIMELOG_PATH, FileAccess.WRITE)
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
	if !FileAccess.file_exists(TIMELOG_PATH):
		#print("load_timelog: No logfile")
		return
	var file = FileAccess.open(TIMELOG_PATH, FileAccess.READ)
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
		var timestamp = DateTime.iso8601_string_to_timestamp(parts[0])
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
	update_current_timelog()
	update_grouped_timelog()

func update_current_timelog():
	# empty the container
	for child in rowContainer.get_children():
		rowContainer.remove_child(child)
	
	var txt:String = ""
	var timediff = 0
	var timelast = 0
	var timeWorked = 0
	var timePaused = 0
	var timeStarted = 0
	var colorTime:String = timeColorPicker.color.to_html()
	var timelog_today = get_timelog_entries(currentDateTimestamp)
	for entry in timelog_today:
		if timelast == 0:
			timelast = entry.timestamp
			timeStarted = entry.timestamp
			continue
		timediff = entry.timestamp - timelast
		timelast = entry.timestamp
		var colorText:String = textColorPicker.color.to_html()
		if entry.text.contains("**"):
			timePaused += timediff
			colorText = pauseColorPicker.color.to_html()
		else:
			timeWorked += timediff
		
		var row = sceneRow.instantiate()
		rowContainer.add_child(row)
		row.set_timelog(DateTime.time_diff(timediff, appSettings.diffSecondsToggle), entry)
		row.set_colors(colorTime, colorText)
		row.timelog_changed.connect(update_text_controls)
	
	# statistics
	var workTimeLeft = (dailyWorkingHours.value * DateTime.SECONDS_PER_HOUR) - timeWorked
	var startTime = DateTime.get_date_formated("%h:%i", timeStarted)
	var stopTime = DateTime.get_date_formated("%h:%i", DateTime.time() + workTimeLeft)
	txt += tr("STAT_TIME_WORKED") + wrap_color(DateTime.time_diff(timeWorked, appSettings.diffSecondsToggle), colorTime) + " "
	txt += tr("STAT_TIME_PAUSED") + wrap_color(DateTime.time_diff(timePaused, appSettings.diffSecondsToggle), colorTime) + " "
	txt += tr("STAT_TIME_LEFT") + wrap_color(DateTime.time_diff(workTimeLeft, appSettings.diffSecondsToggle), colorTime) + " "
	txt += "(%s - %s)" % [wrap_color(startTime, colorTime), wrap_color(stopTime, colorTime)]
	current.text = txt

## Grouped output
## When switchting tasks back and forth, at the end of the day you still want
## to enter each in your time sheet / company software
func update_grouped_timelog():
	var txt:String = ""
	var timediff:int = 0
	var timelast:int = 0
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
	
	var miniumDiff:int = int(appSettings.roundingMinutes * DateTime.SECONDS_PER_MINUTE)
	var graceDiff:int = int(appSettings.roundingGraceMinutes * DateTime.SECONDS_PER_MINUTE)
	for groupText in groupedDict.keys():
		var groupdiff:int = groupedDict.get(groupText, 0)
		if miniumDiff > 0:
			var multiples:int = floor(groupdiff / float(miniumDiff))
			var rest:int = groupdiff % miniumDiff
			groupdiff = multiples * miniumDiff
			if rest > graceDiff:
				groupdiff += miniumDiff
			if groupdiff < miniumDiff:
				groupdiff = miniumDiff
		txt += wrap_color(DateTime.time_diff(groupdiff, appSettings.diffSecondsToggle), colorTime) \
			+ "\t\t" \
			+ wrap_color(escape_bb_tags(groupText), colorText) \
			+ "\n"
	grouped.text = txt

## If there is no start entry for today, add one - since opening the app
## basically always means we want to track this day
func auto_day_start():
	var timelog_today = get_timelog_entries(currentDateTimestamp)
	if timelog_today.is_empty():
		add_timelog_entry_now(AUTO_DAY_START_TEXT)

## Every day is a entry in the dictionary timelog
## the day is an array of Timelog entries
func add_timelog_entry(tstamp:int, text:String):
	var key = DateTime.get_date_string(tstamp)
	var day = timelog.get_or_add(key, [])
	day.append(Timelog.new(tstamp, text))

## Service function
func add_timelog_entry_now(text:String):
	lastEntryTimestamp = DateTime.time()
	add_timelog_entry(lastEntryTimestamp, text)
	update_text_controls()

## based on a time stamp, find entries
## TODO: "virtual midnight" would need to implemented here as well
func get_timelog_entries(tstamp:int) -> Array:
	var key = DateTime.get_date_string(tstamp)
	return timelog.get_or_add(key, [])

func _on_date_back_button_pressed() -> void:
	currentDateTimestamp -= DateTime.SECONDS_PER_DAY
	dateLabel.text = DateTime.get_date_formated(dateFormat.text, currentDateTimestamp)
	update_text_controls()

func _on_date_forward_button_pressed() -> void:
	currentDateTimestamp += DateTime.SECONDS_PER_DAY
	if (currentDateTimestamp > DateTime.time()):
		currentDateTimestamp = DateTime.time()
	dateLabel.text = DateTime.get_date_formated(dateFormat.text, currentDateTimestamp)
	update_text_controls()

func _on_date_today_button_pressed() -> void:
	currentDateTimestamp = DateTime.time()
	dateLabel.text = DateTime.get_date_formated(dateFormat.text, currentDateTimestamp)
	update_text_controls()

## Grouped
func _on_btn_copy_all_pressed() -> void:
	DisplayServer.clipboard_set(grouped.get_parsed_text())

## Grouped
## The "\t\t" from update_grouped_timelog isn't great... 
func _on_btn_copy_text_pressed() -> void:
	var clipboard_text:String = ""
	for line in grouped.get_parsed_text().split("\n", false):
		var parts = line.split("\t\t", false, 2)
		clipboard_text += parts[1] + "\n"
	DisplayServer.clipboard_set(clipboard_text)

## settings change
func _on_selected_language_button_item_selected(index: int) -> void:
	# get the language code from the Dictionary here, so the
	# text for the button can be translated as well
	appSettings.language = index
	set_translation(appSettings.getLanugageString())
	# Update the Text 
	for i in selectedLanguageButton.item_count:
		var locale:String = appSettings.languageOptions.get(i)
		selectedLanguageButton.set_item_text(i, tr(locale.to_upper() + "_LANGUAGE"))

## settings change
## if you work for more than 10 hours a day... I don't know what to tell you, but that is too much
func _on_daily_working_hours_value_changed(value: float) -> void:
	appSettings.dailyWorkingHours = value
	dailyWorkingHoursLabel.text = tr("DAILY_WORKING_HOURS_LABEL").format({"v": value})
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
	# TODO: appSettings.

## settings change
func _on_diff_seconds_toggle_toggled(toggled_on: bool) -> void:
	appSettings.diffSecondsToggle = toggled_on
	update_text_controls()

## settings change
func _on_tabs_moveable_toggled(toggled_on: bool) -> void:
	# TODO: appSettings.
	tabContainer.drag_to_rearrange_enabled = toggled_on

## settings change
func _on_date_format_text_changed(new_text: String) -> void:
	appSettings.dateFormat = new_text
	# Example timestamp: 2025-02-27 14:05:45
	dateFormatPreviewLabel.text = DateTime.get_date_formated(new_text, 1740661545)
	dateLabel.text = DateTime.get_date_formated(new_text, currentDateTimestamp)

## settings change
func _on_rounding_minutes_value_changed(value: float) -> void:
	appSettings.roundingMinutes = int(value)
	update_text_controls()

## settings change
func _on_rounding_grace_minutes_value_changed(value: float) -> void:
	appSettings.roundingGraceMinutes = int(value)
	update_text_controls()

## open "user://" to fiddle with the files by hand
func _on_open_user_folder_button_pressed() -> void:
	OS.shell_open(OS.get_user_data_dir())

## Runs Every Second
func _on_second_timer_timeout() -> void:
	if lastEntryTimestamp == 0:
		return
	timeDiffLabel.text = DateTime.time_diff(DateTime.time() - lastEntryTimestamp, appSettings.diffSecondsToggle)

## When the application shuts down, we save all data
func _on_tree_exiting() -> void:
	save_settings()
	save_timelog()
