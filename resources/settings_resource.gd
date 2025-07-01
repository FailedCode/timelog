extends Resource
class_name AppSettings
## Bundles all Settings into a single object
## This way there unified properties/Methods instead of accessing "textColorPicker.color" or
## whatever UI element is used to set it.

# Settings
## ID for languageOptions
var language:int = 0
var dailyWorkingHours:float = 0
var dateFormat:String = ""
var diffSecondsToggle:bool = false

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
	dailyWorkingHours = config_file.get_value("main", "DailyWorkingHours", 0)		
	dateFormat = config_file.get_value("main", "DateFormat", "")
	diffSecondsToggle = config_file.get_value("main", "DiffSecondsToggle", false)

func save_to_file(settings_path:String):
	var config_file := ConfigFile.new()
	config_file.set_value("main", "language", getLanugageString())
	config_file.set_value("main", "DailyWorkingHours", dailyWorkingHours)
	config_file.set_value("main", "DateFormat", dateFormat)
	config_file.set_value("main", "DiffSecondsToggle", diffSecondsToggle)
	config_file.save(settings_path)

func getLanugageString() -> String:
	return languageOptions.get(max(language, 0), SYSTEM_LANGUAGE)
