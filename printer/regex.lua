local M = {}

local temp_style = nil


local function replace_func(a, b, c)
	b = "{" .. temp_style .. "}" .. b .. "{/}"
	if a then
		b = a .. b
	end
	if c then
		b = b .. c
	end
	return b
end


local function start_func(a, b)
	return replace_func(nil, a, b)
end


function M.replace_all_with_style(str, word, style)
	if not str:match(word) then
		-- dont process, if not match
		return str
	end
	local match_line = "([^%x{}])(" .. word .. ")([^%x{}])"
	local start_line = "^(" .. word .. ")([^%x{}])"
	local end_line = "([^%x{}])(" .. word .. ")$"

	temp_style = style
	str = str:gsub(match_line, replace_func)
	str = str:gsub(start_line, start_func)
	str = str:gsub(end_line, replace_func)
	temp_style = nil
	return str
end

return M