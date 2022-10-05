---@diagnostic disable: param-type-mismatch, undefined-field
--[[
	Defold Printer Module
	Author: Insality

	require "printer.printer"

	node must contains prefab (text) and text_parent
	pritner see on text_parent size to placing letters. See template in module folder

	Usage:
	self.printer = printer.new(self, template_name)

	in update:
		self.printer:update(dt)
	if final
		self.printer:final()

	to write text:
		self.printer:print("string {stylename}next string")
		return true, if string will writing
		return false, if prev. string is writing and instant complete them

	to see if printer is print now:
		self.printer.is_print

	to instant complete current print manual:
		self.printer:instant_appear()

	New styles you can add with printer.add_styles({styles})

	Print usage:
	self.printer:print("This is {red}test with red style")
	self.printer:print("This is {amazing}multi-{blue}styled text")
	self.printer:print("This is text with{n}new line. And image here {image:coins}")
	self.printer:print("This is {red}red text and {/}return to default")
	self.printer:print("This is with source to use another default style", "Illidan")

	Full documentation read at:
	https://github.com/Insality/defold-printer/blob/master/README.md
--]]

local colors = require("printer.colors")
local utf8 = require("printer.utf8string")
local custom_regex = require("printer.regex")

local HASH_PRINT_DONE = hash("print_done")
local COLOR_INVISIBLE = vmath.vector4(1, 1, 1, 0)

local contains = function(t, value)
	for i = 1, #t do
		if t[i] == value then
			return i
		end
	end
	return false
end

local split = function(inputstr, sep)
	sep = sep or "%s"
	local t = {}
	local i = 1
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
			t[i] = str
			i = i + 1
	end
	return t
end

local M = {}
M.printers = {}


local styles = {
	default = {
		font_height = 28,
		spacing = 1, -- pixels between letters
		scale = 1, -- scale of character
		waving = false, -- if true - do waving by sinus
		color = "#FFFFFF",
		speed = 0.05,
		appear = 0.01,
		shaking = 0, -- shaking power. Set to 0 to disable
		sound = false,
		can_skip = true,
		shake_on_write = 0, -- when letter appear, shake dialogue screen
	}
}
local word_styles = {}
local source_styles = {}


local temp_pos = vmath.vector3()
local function update_shake(self, dt)
	self.shake_time = self.shake_time - dt

	if self.shake_time < 0 then
		self.shake_power = 0
		gui.set_position(self.node_parent, self.node_parent_pos)
	else
		temp_pos.x = self.node_parent_pos.x + (math.random() * self.shake_power * 2 - self.shake_power)
		temp_pos.y = self.node_parent_pos.y + (math.random() * self.shake_power * 2 - self.shake_power)
		gui.set_position(self.node_parent, temp_pos)
	end
end

local function get_style(self, name)
	if name == "/" or name == "default" or name == nil then
		if self.default_style == "default" then
			self.last_style = styles.default
			return styles.default
		else
			name = self.default_style
			self.last_style = styles[name]
		end
	end

	local style = {}
	for k, v in pairs(styles.default) do
		style[k] = v
	end

	for k, v in pairs(self.last_style) do
		style[k] = v
	end

	if styles[name] then
		for k, v in pairs(styles[name]) do
			style[k] = v
		end
	else
		print("[Printer]: No style name " .. name)
	end

	self.last_style = style
	return style
end


local function set_shake(self, power, time)
	self.shake_time = time
	self.shake_power = power
end


local function get_letter_size(node_data)
	local size
	if node_data.is_icon then
		size = gui.get_size(node_data.node)
		-- dirty hack
		size = {width = size.x, height = size.y}
	else
		size = gui.get_text_metrics_from_node(node_data.node)
	end
	local scale = gui.get_scale(node_data.node)

	if size.width == 0 then
		-- possibly whitespace
		size.width = size.max_ascent * 0.5
		size.height = size.max_ascent * 0.5
	end

	size.width = size.width * scale.x
	size.height = size.height * scale.y

	return size
end


local function get_word_size(word)
	local result = 0
	for i in pairs(word) do
		local nodeData = word[i]
		local size = get_letter_size(nodeData)
		result = result + size.width

		if i ~= #word then
			result = result + nodeData.style.spacing
		end
	end

	return result
end


local function check_new_line(self, word)
	local word_size = get_word_size(word)

	if self.prev_node then
		local last_pos = gui.get_position(self.prev_node.node)
		if last_pos.x + word_size >= self.parent_size.x * 0.5 then
			self.new_row = true
		end
	else
		self.new_row = false
	end
end


local function update_letter_pos(self, node_data)
	local is_new_row = false
	local is_node_new_row = contains(self.new_line_nodes, node_data.node)

	if self.new_row or is_node_new_row then
		is_new_row = true
		self.new_row = false
		self.current_row = self.current_row + 1
	end

	local style = node_data.style
	local pos = vmath.vector3()

	if not self.prev_node or is_new_row then
		-- first symbol
		local row_index = (self.current_row-1)
		pos.x = -self.parent_size.x * 0.5
		pos.y = self.parent_size.y * 0.5 - (row_index * style.font_height) - style.font_height * 0.5
	else
		local prev_pos = gui.get_position(self.prev_node.node)
		local prev_size = get_letter_size(self.prev_node)
		pos.x = prev_pos.x + prev_size.width  + self.prev_node.style.spacing
		pos.y = prev_pos.y
	end

	gui.set_position(node_data.node, pos)
	self.prev_node = node_data
end


local function set_word_pos(self, word)
	for i in pairs(word) do
		update_letter_pos(self, word[i])
	end
end


local function get_symbol(self, text, stylename)
	local is_icon = false
	local node

	local splited = split(stylename, ":")
	if #splited == 2 and splited[1] == "image" then
		-- icon create
		is_icon = true
		stylename = "default"
		node = gui.clone(self.prefab_icon)
		gui.play_flipbook(node, splited[2])
	else
		node = gui.clone(self.prefab)
		gui.set_text(node, text)
	end
	local node_data = {node = node, style = get_style(self, stylename), text = text, is_icon = is_icon}
	gui.set_enabled(node, true)
	gui.set_parent(node, self.node_parent)
	gui.set_color(node, COLOR_INVISIBLE)
	table.insert(self.current_letters, node_data)

	return node_data
end


local function create_symbol(self, text, stylename)
	local node_data = get_symbol(self, text, stylename)

	local node = node_data.node
	local style = node_data.style

	if style.scale ~= 1 then
		gui.set_scale(node, vmath.vector4(style.scale))
	end

	local last_word = self.current_words[#self.current_words]
	table.insert(last_word, node_data)
	if text == " " then
		table.insert(self.current_words, {})
	end

	return node_data
end


local function clear_prev_text(self)
	if self.current_letters then
		for i = 1, #self.current_letters do
			gui.delete_node(self.current_letters[i].node)
		end
	end
	self.current_letters = {}
	self.last_pos = false
	self.current_words = {{}}
	self.new_line_nodes = {}
end


local function modify_text(text)
	for k, v in pairs(word_styles) do
		text = custom_regex.replace_all_with_style(text, k, v)
	end
	return text
end


local function precreate_text(self)
	while #self.string > 0 do
		local uobj = utf8(self.string)
		local sym = tostring(uobj:sub(1, 1))
		if sym == "{" then
			local close_index = string.find(tostring(self.string), "}")
			local prev_style = self.stylename
			self.stylename = tostring(uobj:sub(2, close_index-1))
			if self.stylename == "n" then
				-- insert codename word -new-line-
				self.next_node_new_line = true
				self.stylename = prev_style
			end
			self.string = uobj:sub(close_index+1, #uobj)

			-- if style contains ":" - make whitespace next to it or write it
			-- For now use special for images
			if self.stylename:find(":") then
				self.string = " " .. self.string
			end

		else
			local node_data = create_symbol(self, sym, self.stylename)
			if node_data.is_icon then
				self.stylename = "default"
			end
			self.string = uobj:sub(2, #uobj)

			if self.next_node_new_line and sym ~= " " then
				self.next_node_new_line = false
				table.insert(self.new_line_nodes, node_data.node)
			end
		end
	end
end


local function update_text_pos(self)
	for i in pairs(self.current_words) do
		local word = self.current_words[i]

		check_new_line(self,word)
		set_word_pos(self, word)
	end
end


local function appear_node(self, node_data, is_instant)
	local style = node_data.style
	local node = node_data.node

	if node_data.text ~= " " and not is_instant and style.sound then
		M.play_sound(style.sound)
	end

	local color = colors.hex2rgba(self, style.color)
	if node_data.is_icon then
		color = vmath.vector4(1)
	end
	if style.appear > 0 and not is_instant then
		color.w = 0
		gui.set_color(node, color)
		color.w = 1
		gui.animate(node, gui.PROP_COLOR, color, gui.EASING_OUTSINE, style.appear)
	else
		color.w = 1
		gui.set_color(node, color)
	end

	if style.waving then
		local pos = gui.get_position(node)
		pos.y = pos.y + 2
		gui.set_position(node, pos)
		gui.animate(node, "position.y", pos.y-4, gui.EASING_INOUTSINE, 1, 0, nil, gui.PLAYBACK_LOOP_PINGPONG)
	end

	if style.shaking > 0 then
		local pos = gui.get_position(node)

		local next_shake
		next_shake = function()
			temp_pos.x = pos.x + (math.random() * style.shaking * 2 - style.shaking)
			temp_pos.y = pos.y + (math.random() * style.shaking * 2 - style.shaking)
			gui.animate(node, "position", temp_pos, gui.EASING_OUTSINE, 0.0175, 0.04, next_shake)
		end

		next_shake()
	end

	if style.shake_on_write > 0 then
		set_shake(self, style.shake_on_write, 0.05)
	end
end


local function print_next(self)
	local node_data = self.current_letters[self.current_index]

	appear_node(self, node_data)
	self.current_index = self.current_index + 1

	local next_data = self.current_letters[self.current_index]
	if next_data then
		self.write_timer = math.max(next_data.style.speed, node_data.style.speed)
		if node_data.text == "," then
			self.write_timer = math.min(self.write_timer * 3, 0.3)
		end
		if node_data.text == "." then
			self.write_timer = math.min(self.write_timer * 5, 0.5)
		end
		if node_data.text == " " then
			self.write_timer = 0
		end
	else
		self.is_print = false
		msg.post('.', HASH_PRINT_DONE)
	end
end


local function appear_text(self)
	self.current_index = 1
	if #self.current_letters > 0 then
		self.is_print = true
		print_next(self)
	end
end


local function init(self, node)
	self.prefab = gui.get_node(node .. "/prefab")
	self.prefab_icon = gui.get_node(node .. "/prefab_icon")
	self.node_parent = gui.get_node(node .. "/text_parent")
	self.shake_time = 0
	self.shake_power = 0
	self.write_timer = 0

	self.node_parent_pos = gui.get_position(self.node_parent)
	self.parent_size = gui.get_size(self.node_parent)

	gui.set_enabled(self.prefab, false)
	gui.set_enabled(self.prefab_icon, false)

	clear_prev_text(self)
end

--== PUBLIC FUNCTIONS ==--

function M.fadeout(self)
	self.is_print = false
	for i = 1, #self.current_letters do
		local node = self.current_letters[i].node
		gui.animate(node, 'color.w', 0, gui.EASING_LINEAR, 0.3)
	end
end


function M.instant_appear(self)
	local current_letter = self.current_letters[self.current_index]

	if self.is_print and current_letter.style.can_skip then
		self.is_print = false
		for i in pairs(self.current_letters) do
			appear_node(self, self.current_letters[i], true)
		end
	end
end


function M.print(self, str, source)
	self.node_parent_pos = gui.get_position(self.node_parent)
	self.parent_size = gui.get_size(self.node_parent)

	if self.is_print then
		self:instant_appear()
		return false
	else
		self.current_row = 1
		self.new_row = false
		self.stylename = source_styles[source] or "default"
		self.default_style = self.stylename
		self.last_style = styles[self.default_style]
		self.prev_node = false
		clear_prev_text(self)
		self.string = str

		-- precreate -> posing -> start showing
		self.string = modify_text(self.string)
		precreate_text(self)
		update_text_pos(self)
		appear_text(self)
		return true
	end
end


function M.new(self, template_name)
	local printer = setmetatable({}, {__index = M})
	printer.parent = self
	init(printer, template_name)
	return printer
end


function M.clear(self)
	clear_prev_text(self)
end


function M.update(self, dt)
	self.node_parent_pos = gui.get_position(self.node_parent)
	self.parent_size = gui.get_size(self.node_parent)

	if self.is_print then
		self.write_timer = self.write_timer - dt
		if self.write_timer <= 0 then
			print_next(self)
		end
	end

	if self.shake_time > 0 then
		update_shake(self, dt)
	end
end


function M.final(self)
	clear_prev_text(self)
	self.is_print = false
	self.shake_time = -1
end


function M.play_sound(name)
	-- this function is called whenever a symbol is printed
end


function M.add_styles(styles_new)
	for k, v in pairs(styles_new) do
		styles[k] = v
	end
end


function M.add_source_style(source, style)
	source_styles[source] = style
end


function M.add_word_style(word, style)
	word_styles[word] = style
end


return M
