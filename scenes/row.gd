extends HBoxContainer
## Display a log entry with elapsed time and text
## allows to change the text

## Edit button signals popup to be opened
signal popup_open

## connected Timelog Resource
var timelog:Timelog

@onready var timeLabel:Label = %TimeLabel
@onready var textLabel:Label = %TextLabel
@onready var buttonEdit:Button = %BtnEdit

func set_timelog(time:String, timelogResource:Timelog):
	timeLabel.text = time
	textLabel.text = timelogResource.text
	timelog = timelogResource

func set_colors(timeLabelColor:Color, textLabelColor:Color):
	timeLabel.modulate = timeLabelColor
	textLabel.modulate = textLabelColor

func _on_btn_edit_pressed() -> void:
	popup_open.emit(timelog)
