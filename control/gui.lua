-- Constants
local REACTION_PREFIX = "reaction-"
local REACTION_DEMO_PREFIX = "reaction-demo-"
local FRAME_NAME = "frame"
local TABLE_NAME = "table"
local SELECTOR_SUFFIX = "-selector"
local REACTION_TABLE_COMPONENT_NAME_MAP = {}
for _, component_name in ipairs(MOLECULE_REACTION_COMPONENT_NAMES) do
	REACTION_TABLE_COMPONENT_NAME_MAP[REACTION_PREFIX..component_name] = component_name
end
local REACTION_DEMO_TABLE_REACTANT_NAME_MAP = {}
local REACTION_TABLE_SELECTOR_NAME_MAP = {}
local REACTION_DEMO_TABLE_SELECTOR_NAME_MAP = {}
for _, reactant_name in ipairs(MOLECULE_REACTION_REACTANT_NAMES) do
	REACTION_DEMO_TABLE_REACTANT_NAME_MAP[REACTION_DEMO_PREFIX..reactant_name] = reactant_name
	REACTION_TABLE_SELECTOR_NAME_MAP[REACTION_PREFIX..reactant_name..SELECTOR_SUFFIX] = reactant_name
	REACTION_DEMO_TABLE_SELECTOR_NAME_MAP[REACTION_DEMO_PREFIX..reactant_name..SELECTOR_SUFFIX] = reactant_name
end


-- Utilities
local function close_gui(player_index, gui)
	if gui.relative[MOLECULE_REACTION_NAME] then
		gui.relative[MOLECULE_REACTION_NAME].destroy()
		global.current_gui_entity[player_index] = nil
	end
end

local function gui_add_recursive(gui, element_spec)
	local children_spec = element_spec.children
	element_spec.children = nil
	local element = gui.add(element_spec)
	if not children_spec then return end
	for _, child_spec in ipairs(children_spec) do gui_add_recursive(element, child_spec) end
end

local function update_reaction_table_sprite(element, chest_inventory, product)
	local item = next(chest_inventory.get_contents())
	if item then
		element.sprite = "item/"..item
	elseif product then
		element.sprite = "item/"..product
	else
		element.sprite = nil
	end
end

local function update_all_reaction_table_sprites(gui, entity_number)
	local reaction_table =
		gui.relative[MOLECULE_REACTION_NAME].outer[REACTION_PREFIX..FRAME_NAME][REACTION_PREFIX..TABLE_NAME]
	local building_data = global.molecule_reaction_building_data[entity_number]
	local building_definition = BUILDING_DEFINITIONS[building_data.entity.name]
	local chest_inventories = building_data.chest_inventories
	for _, reactant_name in ipairs(building_definition.reactants) do
		update_reaction_table_sprite(reaction_table[REACTION_PREFIX..reactant_name], chest_inventories[reactant_name])
	end
	local products = building_data.reaction.products
	for _, product_name in ipairs(building_definition.products) do
		update_reaction_table_sprite(
			reaction_table[REACTION_PREFIX..product_name], chest_inventories[product_name], products[product_name])
	end
end

local function get_demo_state(entity_name)
	local demo_state = global.gui_demo_items[entity_name]
	if not demo_state then
		demo_state = {reactants = {}, products = {}, selectors = {}}
		global.gui_demo_items[entity_name] = demo_state
	end
	return demo_state
end

local function demo_reaction(building_data, demo_state, reaction_demo_table)
	for product_name, _ in pairs(demo_state.products) do
		demo_state.products[product_name] = nil
	end
	local building_definition = BUILDING_DEFINITIONS[building_data.entity.name]
	local valid_reaction = true
	for _, reactant in pairs(demo_state.reactants) do
		if game.item_prototypes[reactant].group.name ~= MOLECULES_GROUP_NAME then
			valid_reaction = false
			break
		end
	end
	for reactant_name, _ in pairs(building_definition.selectors) do
		if not demo_state.selectors[reactant_name] then
			valid_reaction = false
			break
		end
	end
	if valid_reaction then building_definition.reaction(demo_state) end
	for _, product_name in ipairs(building_definition.products) do
		local element = reaction_demo_table[REACTION_DEMO_PREFIX..product_name]
		local product = demo_state.products[product_name]
		if product then
			element.sprite = "item/"..product
		else
			element.sprite = nil
		end
	end
end

local function demo_reaction_with_reactant(building_data, demo_state, element, reactant_name, reactant)
	demo_state.reactants[reactant_name] = reactant
	if reactant then
		element.sprite = "item/"..reactant
	else
		element.sprite = nil
	end
	demo_reaction(building_data, demo_state, element.parent)
end


-- Molecule reaction building GUI construction
local function build_molecule_reaction_gui(entity, gui, building_definition)
	local demo_state = get_demo_state(entity.name)
	function build_molecule_spec(name_prefix, component_name, is_reactant)
		if not building_definition.has_component[component_name] then return {type = "empty-widget"} end
		local spec = {
			type = "sprite-button",
			name = name_prefix..component_name,
			tooltip = {"factoriochem."..entity.name.."-"..component_name.."-tooltip"},
			style = "factoriochem-big-slot-button",
		}
		if name_prefix == REACTION_PREFIX then
			spec.tooltip = {"factoriochem.reaction-table-component-tooltip", spec.tooltip}
		elseif name_prefix == REACTION_DEMO_PREFIX then
			if is_reactant then
				spec.tooltip = {"factoriochem.reaction-demo-table-reactant-tooltip", spec.tooltip}
				if demo_state.reactants[component_name] then
					spec.sprite = "item/"..demo_state.reactants[component_name]
				end
			elseif demo_state.products[component_name] then
				spec.sprite = "item/"..demo_state.products[component_name]
			end
		end
		return spec
	end
	function build_selector_spec(name_prefix, reactant_name)
		local selector = building_definition.selectors[reactant_name]
		if not selector then return {type = "empty-widget"} end
		local spec = {
			type = "choose-elem-button",
			name = name_prefix..reactant_name..SELECTOR_SUFFIX,
			elem_type = "item",
			elem_filters = {{filter = "subgroup", subgroup = MOLECULE_REACTION_SELECTOR_PREFIX..selector}},
			tooltip = {"factoriochem."..entity.name.."-"..reactant_name..SELECTOR_SUFFIX.."-tooltip"},
		}
		if name_prefix == REACTION_PREFIX then
			spec.item = global.molecule_reaction_building_data[entity.unit_number].reaction.selectors[reactant_name]
		elseif name_prefix == REACTION_DEMO_PREFIX then
			spec.item = demo_state.selectors[reactant_name]
		end
		return spec
	end
	function build_reaction_table_spec(name_prefix)
		return {
			type = "table",
			name = name_prefix.."table",
			column_count = 3,
			children = {
				-- title row
				{type = "empty-widget"},
				{type = "label", caption = {"factoriochem."..name_prefix.."table-header"}},
				{type = "empty-widget"},
				-- base/result row
				build_molecule_spec(name_prefix, BASE_NAME, true),
				build_selector_spec(name_prefix, BASE_NAME),
				build_molecule_spec(name_prefix, RESULT_NAME),
				-- catalyst/bonus row
				build_molecule_spec(name_prefix, CATALYST_NAME, true),
				{type = "label", caption = {"factoriochem.reaction-transition"}},
				build_molecule_spec(name_prefix, BONUS_NAME),
				-- modifier/remainder row
				build_molecule_spec(name_prefix, MODIFIER_NAME, true),
				build_selector_spec(name_prefix, MODIFIER_NAME),
				build_molecule_spec(name_prefix, REMAINDER_NAME),
			},
		}

	end
	local gui_spec = {
		-- outer
		type = "frame",
		caption = {"factoriochem.reaction"},
		name = MOLECULE_REACTION_NAME,
		anchor = {
			gui = defines.relative_gui_type.assembling_machine_gui,
			position = defines.relative_gui_position.right
		},
		children = {{
			-- inner
			type = "flow",
			name = "outer",
			style = "inset_frame_container_vertical_flow",
			direction = "vertical",
			children = {{
				-- reaction frame
				type = "frame",
				name = REACTION_PREFIX.."frame",
				style = "inside_shallow_frame_with_padding",
				direction = "vertical",
				children = {build_reaction_table_spec(REACTION_PREFIX)},
			}, {
				-- reaction demo frame
				type = "frame",
				style = "inside_shallow_frame_with_padding",
				direction = "vertical",
				children = {build_reaction_table_spec(REACTION_DEMO_PREFIX)},
			}},
		}},
	}
	gui_add_recursive(gui.relative, gui_spec)
	update_all_reaction_table_sprites(gui, entity.unit_number)
end


-- Event handling
local function on_gui_opened(event)
	local entity = event.entity
	if not entity then return end
	local gui = game.get_player(event.player_index).gui
	close_gui(event.player_index, gui)

	local building_definition = BUILDING_DEFINITIONS[entity.name]
	if building_definition then
		build_molecule_reaction_gui(entity, gui, building_definition)
	else
		return
	end
	global.current_gui_entity[event.player_index] = entity.unit_number
end

local function on_gui_closed(event)
	close_gui(event.player_index, game.get_player(event.player_index).gui)
end

local function on_gui_click(event)
	local element = event.element
	local building_data = global.molecule_reaction_building_data[global.current_gui_entity[event.player_index]]

	local reaction_table_component_name = REACTION_TABLE_COMPONENT_NAME_MAP[element.name]
	if reaction_table_component_name then
		local player = game.get_player(event.player_index)
		local chest_inventory = building_data.chest_inventories[reaction_table_component_name]
		local chest_contents = chest_inventory.get_contents()
		if next(chest_contents) then
			local player_inventory = player.get_main_inventory()
			for name, count in pairs(chest_contents) do
				added = player_inventory.insert({name = name, count = count})
				if added > 0 then chest_inventory.remove({name = name, count = added}) end
			end
			update_reaction_table_sprite(element, chest_inventory)
		elseif player.cursor_stack and player.cursor_stack.valid_for_read then
			chest_inventory.find_empty_stack().transfer_stack(player.cursor_stack)
			update_reaction_table_sprite(element, chest_inventory)
		end
		return
	end

	local reaction_demo_table_reactant_name = REACTION_DEMO_TABLE_REACTANT_NAME_MAP[element.name]
	if reaction_demo_table_reactant_name then
		local player = game.get_player(event.player_index)
		local demo_state = get_demo_state(building_data.entity.name)
		local reaction_reactant =
			next(building_data.chest_inventories[reaction_demo_table_reactant_name].get_contents())
		if event.button == defines.mouse_button_type.right then
			demo_reaction_with_reactant(building_data, demo_state, element, reaction_demo_table_reactant_name, nil)
		elseif player.cursor_stack and player.cursor_stack.valid_for_read then
			demo_reaction_with_reactant(
				building_data, demo_state, element, reaction_demo_table_reactant_name, player.cursor_stack.name)
		elseif reaction_reactant then
			demo_reaction_with_reactant(
				building_data, demo_state, element, reaction_demo_table_reactant_name, reaction_reactant)
		end
		return
	end
end

local function on_gui_elem_changed(event)
	local element = event.element
	local building_data = global.molecule_reaction_building_data[global.current_gui_entity[event.player_index]]

	local reaction_table_selector_reactant_name = REACTION_TABLE_SELECTOR_NAME_MAP[element.name]
	if reaction_table_selector_reactant_name then
		building_data.reaction.selectors[reaction_table_selector_reactant_name] = element.elem_value
		for i, reactant_name in ipairs(MOLECULE_REACTION_REACTANT_NAMES) do
			if reactant_name == reaction_table_selector_reactant_name then
				local settings_behavior = building_data.settings.get_control_behavior()
				if element.elem_value then
					settings_behavior.set_signal(
						i, {signal = {type = "item", name = element.elem_value}, count = 1})
				else
					settings_behavior.set_signal(i, nil)
				end
				break
			end
		end
		entity_assign_cache(building_data, BUILDING_DEFINITIONS[building_data.entity.name])
		return
	end

	local reaction_demo_table_selector_reactant_name = REACTION_DEMO_TABLE_SELECTOR_NAME_MAP[element.name]
	if reaction_demo_table_selector_reactant_name then
		local demo_state = get_demo_state(building_data.entity.name)
		demo_state.selectors[reaction_demo_table_selector_reactant_name] = element.elem_value
		demo_reaction(building_data, demo_state, element.parent)
		return
	end
end


-- Global event handling
function gui_on_init()
	global.current_gui_entity = {}
	global.gui_demo_items = {}
end

function gui_on_nth_tick(event_data)
	for player_index, entity_number in pairs(global.current_gui_entity) do
		update_all_reaction_table_sprites(game.get_player(player_index).gui, entity_number)
	end
end

script.on_event(defines.events.on_gui_opened, on_gui_opened)
script.on_event(defines.events.on_gui_closed, on_gui_closed)
script.on_event(defines.events.on_gui_click, on_gui_click)
script.on_event(defines.events.on_gui_elem_changed, on_gui_elem_changed)
