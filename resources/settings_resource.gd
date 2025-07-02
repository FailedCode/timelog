extends Resource
class_name AppSettings
## Bundles all Settings into a single object
## This way there unified properties/Methods instead of accessing "textColorPicker.color" or
## whatever UI element is used to set it.

# Settings
## ID for languageOptions
var language:int = 0
var dailyWorkingHours:float = 8
var dateFormat:String = "%Y-%m-%d (%D)"
var diffSecondsToggle:bool = false
var roundingMinutes:int = 15
var roundingGraceMinutes:int = 5

var colorText:String = "efefef"
var colorTime:String = "db9200"
var colorPause:String = "757575"

var window_position:Vector2i = Vector2i(0,0)
var window_size:Vector2i = Vector2i(0,0)

# Additional Data
## store locales with translations for those values
var languageOptions:Dictionary

## When this is used, it means "use whatever language the system uses"
const SYSTEM_LANGUAGE = "system"

func load_from_file(settings_path:String):
	var config_file := ConfigFile.new()
	var error := config_file.load(settings_path)
	if error:
		print("load_from_file ERROR:", error)
		return
	language = languageOptions.get(config_file.get_value("main", "language", SYSTEM_LANGUAGE))
	dailyWorkingHours = config_file.get_value("main", "DailyWorkingHours", dailyWorkingHours)
	dateFormat = config_file.get_value("main", "DateFormat", dateFormat)
	diffSecondsToggle = config_file.get_value("main", "DiffSecondsToggle", diffSecondsToggle)
	roundingMinutes = config_file.get_value("main", "RoundingMinutes", roundingMinutes)
	roundingGraceMinutes = config_file.get_value("main", "RoundingGraceMinutes", roundingGraceMinutes)
	colorText = config_file.get_value("main", "colorText", colorText)
	colorTime = config_file.get_value("main", "colorTime", colorTime)
	colorPause = config_file.get_value("main", "colorPause", colorPause)
	
	window_position.x = config_file.get_value("gfx", "window_position_x", 0)
	window_position.y = config_file.get_value("gfx", "window_position_y", 0)
	window_size.x = config_file.get_value("gfx", "window_size_x", 0)
	window_size.y = config_file.get_value("gfx", "window_size_y", 0)

func save_to_file(settings_path:String):
	var config_file := ConfigFile.new()
	config_file.set_value("main", "language", getLanugageString())
	config_file.set_value("main", "DailyWorkingHours", dailyWorkingHours)
	config_file.set_value("main", "DateFormat", dateFormat)
	config_file.set_value("main", "DiffSecondsToggle", diffSecondsToggle)
	config_file.set_value("main", "RoundingMinutes", roundingMinutes)
	config_file.set_value("main", "RoundingGraceMinutes", roundingGraceMinutes)
	config_file.set_value("main", "colorText", colorText)
	config_file.set_value("main", "colorTime", colorTime)
	config_file.set_value("main", "colorPause", colorPause)
	
	config_file.set_value("gfx", "window_position_x", window_position.x)
	config_file.set_value("gfx", "window_position_y", window_position.y)
	config_file.set_value("gfx", "window_size_x", window_size.x)
	config_file.set_value("gfx", "window_size_y", window_size.y)
	
	config_file.save(settings_path)

func getLanugageString() -> String:
	return languageOptions.get(max(language, 0), SYSTEM_LANGUAGE)
