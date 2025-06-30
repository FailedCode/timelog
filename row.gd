extends HBoxContainer

## Text updated
signal timelog_changed

## connected Timelog Resource
var timelog:Timelog

@onready var timeLabel:Label = %TimeLabel
@onready var textLabel:Label = %TextLabel
@onready var textEdit:LineEdit = %TextEdit
@onready var buttonEdit:Button = %BtnEdit

func _ready():
	pass

func set_timelog(time:String, timelogResource:Timelog):
	timeLabel.text = time
	textLabel.text = timelogResource.text
	timelog = timelogResource

func set_colors(timeLabelColor:Color, textLabelColor:Color):
	timeLabel.modulate = timeLabelColor
	textLabel.modulate = textLabelColor

#func _on_text_label_gui_input(event: InputEvent) -> void:
	#print(event)

#func _input(event: InputEvent):	
	#if event is InputEventMouseButton and event.is_pressed():
		#if event.is_double_click():
			#print(event)
			#print("double clicked!")

## Clicking Edit button enbales/disables editing mode
## TODO: would be great, if double-clicking could enable it
func _on_btn_edit_toggled(toggled_on: bool) -> void:
	if toggled_on:
		textLabel.hide()
		textEdit.show()
		textEdit.text = textLabel.text
		textEdit.grab_focus()
		textEdit.caret_column = len(textEdit.text)
		textEdit.select_all()
	else:
		textLabel.show()
		textEdit.hide()
		var newtext = textEdit.text.strip_edges()
		if !newtext.is_empty():
			textLabel.text = newtext
			timelog.text = newtext
			timelog_changed.emit()

## pressing return stops editing mode
func _on_text_edit_text_submitted(_new_text: String) -> void:
	buttonEdit.button_pressed = false
