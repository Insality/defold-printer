local M = {}


function M.get_random_color()
	return vmath.vector4(math.random(1,255)/255, math.random(1,255)/255, math.random(1,255)/255, 1.0)
end


function M.hex2rgba(hex) -- normalized
    hex = string.gsub(hex, "#", "")
    local color
    local w = gui.get_color("printer/prefab").w
    if(string.len(hex) == 3) then
        color = vmath.vector4(tonumber("0x"..string.sub(hex, 1,1)) * 17, tonumber("0x"..string.sub(hex, 2,2)) * 17, tonumber("0x"..string.sub(hex, 3,3)) * 17, w)
    elseif(string.len(hex) == 6) then
        color = vmath.vector4(tonumber("0x"..string.sub(hex, 1,2)), tonumber("0x"..string.sub(hex, 3,4)), tonumber("0x"..string.sub(hex, 5,6)), w)
    end
    color.x = color.x / 255
    color.y = color.y / 255
    color.z = color.z / 255
    return color
end


return M