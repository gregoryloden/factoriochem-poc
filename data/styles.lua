local gui_style = data.raw["gui-style"]["default"]
gui_style["factoriochem-big-slot-button"] = {
	type = "button_style",
	parent = "slot_button",
	size = gui_style.slot_button.size + 32,
}
gui_style["factoriochem-dropdown"] = {
	type = "dropdown_style",
	parent = "dropdown",
	minimal_width = 0,
}
gui_style["factoriochem-textfield"] = {
	type = "textbox_style",
	parent = "textbox",
	width = 150,
}
gui_style["factoriochem-titlebar-drag-handle"] = {
	type = "empty_widget_style",
	parent = "draggable_space",
	horizontally_stretchable = "on",
	height = 24,
}
gui_style["factoriochem-inside-deep-frame-with-padding"] = {
	type = "frame_style",
	parent = "inside_deep_frame",
	padding = 12,
}
gui_style["factoriochem-tool-button-24"] = {
	type = "button_style",
	parent = "tool_button",
	size = gui_style.tool_button.size + 8,
}
gui_style["factoriochem-periodic-table"] = {
	type = "table_style",
	vertical_spacing = 0,
	column_alignments = {
		{column = 1, alignment = "top-center"},
		{column = 2, alignment = "top-center"},
		{column = 3, alignment = "top-center"},
		{column = 4, alignment = "top-center"},
		{column = 5, alignment = "top-center"},
		{column = 6, alignment = "top-center"},
		{column = 7, alignment = "top-center"},
		{column = 8, alignment = "top-center"},
		{column = 9, alignment = "top-center"},
		{column = 10, alignment = "top-center"},
		{column = 11, alignment = "top-center"},
		{column = 12, alignment = "top-center"},
		{column = 13, alignment = "top-center"},
		{column = 14, alignment = "top-center"},
		{column = 15, alignment = "top-center"},
		{column = 16, alignment = "top-center"},
		{column = 17, alignment = "top-center"},
		{column = 18, alignment = "top-center"},
		{column = 19, alignment = "top-center"},
	},
}
gui_style["factoriochem-small-label"] = {
	type = "label_style",
	font = "default-small",
}
