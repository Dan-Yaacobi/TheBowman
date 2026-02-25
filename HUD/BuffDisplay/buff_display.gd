class_name BuffDisplay extends Control

@onready var texture_rect: TextureRect = $TextureRect
@onready var timer: Timer = $Timer
@onready var stacks_label: Label = $Stacks
@onready var texture_progress_bar: TextureProgressBar = $TextureProgressBar

@export var duration: float = 1.0
@export var texture: Texture
@export var stacks: int = 0
@export var max_stacks: int = 0

var ID: int
signal buff_ended(_buff: BuffDisplay)

func set_duration(_duration: float) -> void:
	duration = _duration
	
func _ready() -> void:
	if texture:
		texture_rect.texture = texture
	stacks_label.text = ""
	if stacks > 0:
		stacks_label.text = str(stacks)
	timer.wait_time = duration
	timer.timeout.connect(buff_over)
	timer.start()
	
func _process(_delta: float) -> void:
	var curr_time: float = (timer.wait_time - timer.time_left) / timer.wait_time
	texture_progress_bar.value = 1.0 - curr_time
	if texture_progress_bar.value <= texture_progress_bar.min_value:
		buff_over()
		
func add_stack(_stacks: int, _duration: float) -> void:
	if stacks < max_stacks:
		stacks += _stacks
		stacks_label.text = str(stacks)
	var new_time = timer.time_left + _duration
	timer.start(new_time)
	
func buff_over() -> void:
	buff_ended.emit(self.ID)
