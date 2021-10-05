class_name ColorPalettePicker
extends PanelContainer

# -------------------------------------------------------------------------------------------------
const PALETTE_BUTTON = preload("res://UI/Components/PaletteButton.tscn")

# -------------------------------------------------------------------------------------------------
signal color_changed(color)

# -------------------------------------------------------------------------------------------------
export var add_new_palette_dialog_path: NodePath
export var edit_palette_dialog: NodePath
export var toolbar_path: NodePath

onready var _toolbar = get_node(toolbar_path)
onready var _palette_selection_button: OptionButton = $MarginContainer/VBoxContainer/Buttons/PaletteSelectionButton
onready var _color_grid: GridContainer = $MarginContainer/VBoxContainer/ColorGrid

var _active_palette_button: PaletteButton
var _active_palette_button_index := -1

# -------------------------------------------------------------------------------------------------
func _ready() -> void:
	update_palettes()

# -------------------------------------------------------------------------------------------------
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton && event.pressed:
		var should_hide := !Utils.is_mouse_in_control(self)
		should_hide = should_hide && !Utils.is_mouse_in_control(_toolbar.get_brush_color_button())
		should_hide = should_hide && !get_parent().is_dialog_open()
		should_hide = should_hide && !_palette_selection_button.get_popup().visible
		should_hide = should_hide && !AlertDialog.visible
		if visible && should_hide:
			hide()
	
	if event is InputEventKey && event.pressed && event.scancode == KEY_ESCAPE:
		hide()

# -------------------------------------------------------------------------------------------------
func update_palettes() -> void:
	# Add palettes to the dropdown
	_palette_selection_button.clear()
	for palette in PaletteManager.palettes:
		_palette_selection_button.add_item(palette.name)
	
	# Load the active palette
	var active_palette := PaletteManager.get_active_palette()
	_palette_selection_button.selected = PaletteManager.get_active_palette_index()
	_create_buttons(active_palette)
	_activate_palette_button(_color_grid.get_child(0), 0)

# -------------------------------------------------------------------------------------------------
func _create_buttons(palette: Palette) -> void:
	# Remove old buttons
	_active_palette_button = null
	for c in _color_grid.get_children():
		_color_grid.remove_child(c)
		c.queue_free()
	
	# Add new ones
	var index := 0
	for color in palette.colors:
		var button: PaletteButton = PALETTE_BUTTON.instance()
		_color_grid.add_child(button)
		button.color = color
		button.connect("pressed", self, "_on_platte_button_pressed", [button, index])
		index += 1
	
	# Adjust ui size
	rect_size = get_combined_minimum_size()
	
# -------------------------------------------------------------------------------------------------
func _activate_palette_button(button: PaletteButton, button_index: int) -> void:
	if _active_palette_button != null:
		_active_palette_button.selected = false
	_active_palette_button = button
	_active_palette_button_index = button_index
	_active_palette_button.selected = true

# -------------------------------------------------------------------------------------------------
func _on_platte_button_pressed(button: PaletteButton, index: int) -> void:
	_activate_palette_button(button, index)
	emit_signal("color_changed", button.color)

# -------------------------------------------------------------------------------------------------
func _on_PaletteSelectionButton_item_selected(index: int) -> void:
	PaletteManager.set_active_palette_index(index)
	PaletteManager.save()
	
	var palette := PaletteManager.get_active_palette()
	_create_buttons(palette)
	_activate_palette_button(_color_grid.get_child(0), index)

# -------------------------------------------------------------------------------------------------
func _on_AddPaletteButton_pressed() -> void:
	var dialog: NewPaletteDialog = get_node(add_new_palette_dialog_path)
	dialog.duplicate_current_palette = false
	dialog.popup_centered()

# -------------------------------------------------------------------------------------------------
func _on_EditColorButton_pressed() -> void:
	var palette := PaletteManager.get_active_palette()
	if palette.builtin:
		# TODO: i18n
		AlertDialog.dialog_text = "Editing built-in palettes is not possible.\nIf you want to customize this palette you can make a copy and edit that instead."
		AlertDialog.popup_centered()
	else:
		hide()
		var edit_popup: EditPaletteDialog = get_node(edit_palette_dialog)
		edit_popup.setup(PaletteManager.get_active_palette(), _active_palette_button_index)
		edit_popup.popup_centered()

# -------------------------------------------------------------------------------------------------
func _on_DuplicatePaletteButton_pressed() -> void:
	var dialog: NewPaletteDialog = get_node(add_new_palette_dialog_path)
	dialog.duplicate_current_palette = true
	dialog.popup_centered()
