local m = {} -- the module

local ustring = {} -- table to index equivalent string.* functions

-- TsT <tst2005@gmail.com>
-- License: MIT

m._VERSION	= "utf8string 1.0.0"
m._URL		= "https://github.com/tst2005/lua-utf8string"
m._LICENSE	= 'MIT <http://opensource.org/licenses/MIT>'

-- my custom type for Unicode String
local utf8type = "ustring"

local typeof = assert(type)
local tostring = assert(tostring)

local sgmatch = assert(string.gmatch or string.gfind) -- lua 5.1+ or 5.0
local string_find = assert(string.find)
local string_sub = assert(string.sub)
local string_byte = assert(string.byte)

local table_concat = table.concat

local utf8_object

local function utf8_sub(uobj, i, j)
        assert(i, "bad argument #2 to 'sub' (number expected, got no value)")
	if i then assert(type(i) == "number") end
	if j then assert(type(j) == "number") end

	if i == 0 then
		i = 1
	elseif i < 0 then
		i = #uobj+i+1
	end

	if j and j < 0 then
		j = #uobj+j+1
	end

	local b = i <= 1 and 1 or uobj[i-1]+1
	local e = j and uobj[j]
	-- create an new utf8 object from the original one (do not "parse" it again)
	local rel = uobj[i-1] or 0 -- relative position
	local new = {}
	for x=i,j,1 do
		new[#new+1] = uobj[x] -rel
	end
	new.rawstring = string_sub(uobj.rawstring, b, assert( type(e)=="number" and e))
	new.usestring = uobj.usestring
	return utf8_object(new)
end

local function utf8_typeof(obj)
	local mt = getmetatable(obj)
	return mt and mt.__type or typeof(obj)
end

local function utf8_is_object(obj)
	return not not (utf8_typeof(obj) == utf8type)
end

local function utf8_tostring(obj)
	if utf8_is_object(obj) then
		return obj.rawstring
	end
	return obj
	--return tostring(obj)
end

local function utf8_clone(self)
	if not utf8_is_object(self) then
		error("it is not a ustring object ! what to do for clonning ?", 2)
	end
	local o = {
		rawstring = self.rawstring,
		usestring = self.usestring,
	}
	return utf8_object(o)
end

--local function utf8_is_uchar(uchar)
--	return (uchar:len() > 1) -- len() = string.len()
--end

--        %z = 0x00 (\0 not allowed)
--        \1 = 0x01
--      \127 = 0x7F
--      \128 = 0x80
--      \191 = 0xBF

-- parse a lua string to split each UTF-8 sequence to separated table item
local function private_string2ustring(unicode_string)
	assert(typeof(unicode_string) == "string", "unicode_string is not a string?!")

	local e = 0 -- end of found string
	local o = {}
	while true do
		-- FIXME: how to drop invalid sequence ?!
		local b
		b, e = string_find(unicode_string, "[%z\1-\127\194-\244][\128-\191]*", e+1)
		if not b then break end
		o[#o+1] = e
	end
	o.rawstring = unicode_string
	o.usestring = #unicode_string == #o
	return utf8_object(o)
end

local function private_contains_unicode(str)
	return not not str:find("[\128-\193]+")
end

local function utf8_auto_convert(unicode_string, i, j)
	assert(typeof(unicode_string) == "string", "unicode_string is not a string: ", typeof(unicode_string))
	local obj, containsutf8 = private_string2ustring(unicode_string)
	--if private_contains_unicode(unicode_string) then
	--	obj = private_string2ustring(unicode_string)
	--else
	--	obj = unicode_string
	--end
	return (i and obj:sub(i,j)) or obj
end

local function utf8_op_concat(obj1, obj2)
--	local h
--	local function sethand(o) h = getmetatable(o).__concat end
--	if not pcall(sethand, obj1) then pcall(sethand, obj2) end
--	if h then return h(obj1, obj2) end
	return utf8_auto_convert( tostring(obj1) .. tostring(obj2) )
end

local floor = table.floor
local string_char = utf8_char
local table_concat = table.concat

-- http://en.wikipedia.org/wiki/Utf8
-- http://developer.coronalabs.com/code/utf-8-conversion-utility
local function utf8_onechar(unicode)
        if unicode <= 0x7F then return string_char(unicode) end

        if (unicode <= 0x7FF) then
                local Byte0 = 0xC0 + floor(unicode / 0x40)
                local Byte1 = 0x80 + (unicode % 0x40)
                return string_char(Byte0, Byte1)
        end

        if (unicode <= 0xFFFF) then
                local Byte0 = 0xE0 +  floor(unicode / 0x1000) -- 0x1000 = 0x40 * 0x40
                local Byte1 = 0x80 + (floor(unicode / 0x40) % 0x40)
                local Byte2 = 0x80 + (unicode % 0x40)
                return string_char(Byte0, Byte1, Byte2)
        end

        if (unicode <= 0x10FFFF) then
                local code = unicode
                local Byte3= 0x80 + (code % 0x40)
                code       = floor(code / 0x40)
                local Byte2= 0x80 + (code % 0x40)
                code       = floor(code / 0x40)
                local Byte1= 0x80 + (code % 0x40)
                code       = floor(code / 0x40)
                local Byte0= 0xF0 + code

                return string_char(Byte0, Byte1, Byte2, Byte3)
        end

        error('Unicode cannot be greater than U+10FFFF!', 3)
end


local function utf8_char(...)
        local r = {}
        for i,v in ipairs({...}) do
                if type(v) ~= "number" then
                        error("bad argument #"..i.." to 'char' (number expected, got "..type(v)..")", 2)
                end
                r[i] = utf8_onechar(v)
        end
        return table_concat(r, "")
end
--for _, n in ipairs{12399, 21560, 12356, 12414, 12377} do print(utf8char(n)) end
--print( lua53_utf8_char( 12399, 21560, 12356, 12414, 12377 ) )


local function utf8_byte(obj, i, j)
	local i = i or 1
	local j = j or i -- FIXME: 'or i' or 'or -1' ?
	local uobj
	assert(utf8_is_object(obj), "ask utf8_byte() for a non utf8 object?!")
--	if not utf8_is_object(obj) then
--		uobj = utf8_auto_convert(obj, i, j)
--	else
	uobj = obj:sub(i, j)
--	end
	return string_byte(tostring(uobj), 1, -1)
end

-- FIXME: what is the lower/upper case of Unicode ?!
-- FIXME: optimisation? the parse is still the same (just change the rawstring ?)
local function utf8_lower(uobj) return utf8_auto_convert( tostring(uobj):lower() ) end
local function utf8_upper(uobj) return utf8_auto_convert( tostring(uobj):upper() ) end

-- FIXME: use the already parsed info to generate the reverse info...
local function utf8_reverse(uobj)
	if uobj.usestring then
		return utf8_auto_convert(uobj.rawstring:reverse())
	end

	local rawstring = uobj.rawstring
	local tmp = {}
	local e = uobj[#uobj] -- the ending position of uchar
--	local last_value = e
--	local o = {} -- new ustring object
	for n=#uobj-1,1,-1 do
		local b = uobj[n] -- the beginning position of uchar
		tmp[#tmp+1] = string_sub(rawstring, b+1, e) -- the uchar
--		o[#o+1] = last_value-b+1
		e = b
	end
	tmp[#tmp+1] = string_sub(rawstring, 1, e)
--	o[#o+1] = last_value
--	o.rawstring = table_concat(tmp, "")
--	return utf8_object(o)
	return utf8_auto_convert(table_concat(tmp, ""))
end


local function utf8_rep(uobj, n)
	return utf8_auto_convert(uobj.rawstring:rep(n)) -- :rep() is the string.rep()
end

function utf8_object(uobj)
	local mt
	if not uobj then
		uobj = {}
		mt = {}
	else
		mt = getmetatable(uobj) or {}
	end
	mt.__index	= assert(ustring)
	mt.__concat	= assert(utf8_op_concat)
	mt.__tostring	= assert(utf8_tostring)
	mt.__type	= assert(utf8type)
--	mt.__call	= function(_self, a1)
--		if a1 == nil then
--			return utf8_clone(_self)
--		end
--		return _self
--	end
	return setmetatable(uobj, mt)
end


---- Standard Lua 5.1 string.* ----
ustring.byte	= assert(utf8_byte)
ustring.char	= assert(utf8_char)
ustring.dump	= assert(string.dump)
--ustring.find
ustring.format	= assert(string.format)
--ustring.gmatch
--ustring.gsub
ustring.len	= function(uobj) return #uobj end
ustring.lower	= assert(utf8_lower)
--ustring.match
ustring.rep	= assert(utf8_rep)
ustring.reverse	= assert(utf8_reverse)
ustring.sub	= assert(utf8_sub)
ustring.upper	= assert(utf8_upper)

---- custome add-on ----
ustring.type	= assert(utf8_typeof)
ustring.tostring = assert(utf8_tostring)
ustring.clone	= assert(utf8_clone)
--ustring.debugdump = function(self) return table.concat(self, " ") end

-- Add fonctions to the module
for k,v in pairs(ustring) do m[k] = v end

-- Allow to use the module directly to convert strings
local mt = {
	__call = function(_self, obj, i, j)
		if utf8_is_object(obj) then
			return (i and obj:sub(i,j)) or obj
		end
		local str = obj
		if typeof(str) ~= "string" then
			str = tostring(str)
		end
		return utf8_auto_convert(str, i, j)
	end
}

return setmetatable(m,mt)

-------------------------------------------------------------------------------
-- begin of the idea : http://lua-users.org/wiki/LuaUnicode
--
-- for uchar in sgmatch(unicode_string, "([%z\1-\127\194-\244][\128-\191]*)") do
--
--local function utf8_strlen(unicode_string)
--	local _, count = string.gsub(unicode_string, "[^\128-\193]", "")
--	return count
--end
-- http://www.unicode.org/reports/tr29/#Grapheme_Cluster_Boundaries
