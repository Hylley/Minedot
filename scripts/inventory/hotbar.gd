extends NinePatchRect
class_name Hotbar

@onready var slots := \
[
	%'Hotbar Slot 1',
	%'Hotbar Slot 2',
	%'Hotbar Slot 3',
	%'Hotbar Slot 4',
	%'Hotbar Slot 5',
	%'Hotbar Slot 6',
	%'Hotbar Slot 7',
	%'Hotbar Slot 8'
]
@onready var selected_slot = 0

func get_slot(slot : int) -> Slot: return slots[slot]

func hotbar_change(amount : int):
	get_slot(selected_slot).hide_frame()

	if selected_slot + amount >= slots.size():
		selected_slot = 0
	elif selected_slot + amount < 0:
		selected_slot = slots.size() -1
	else:
		selected_slot = selected_slot + amount

	get_slot(selected_slot).show_frame()
	return get_slot(selected_slot).get_entry()
