--!native
--!strict

-- parse.lua
type Parse = {
	parse : (self : Parse, hex_string : string) -> {{number}};
}

local Parse = {} :: Parse

function Parse:parse(hex_string)

	local parsed_colors : {{number}} = {}

	for color in hex_string:gmatch("%x%x%x%x%x%x") do
		local from_hex_color = Color3.fromHex(color)
		table.insert(parsed_colors,{from_hex_color.R,from_hex_color.G,from_hex_color.B})
	end
	return parsed_colors
end


-- palette.lua
local PALETTE_CONFIG = require(script.Color)
local PALETTE = Parse:parse(PALETTE_CONFIG)
local HUGE = math.huge
local abs = math.abs
local function return_closest(r : number,g :number,b : number, pal : {{number}}) : (number,number,number)
	local shortest_distance = HUGE
	local returned_color_r = r
	local returned_color_g = g
	local returned_color_b = b

	for _,color2 in pal do
		local red_dif   = abs(r - color2[1])
		local green_dif = abs(g - color2[2])
		local blue_dif  = abs(b - color2[3])
		local distance = (
			    (red_dif * red_dif) +
				(green_dif * green_dif) +
				(blue_dif * blue_dif)	
		)

		if distance < shortest_distance then
			returned_color_r = color2[1]
			returned_color_g = color2[2]
			returned_color_b = color2[3]

			shortest_distance = distance
		end
	end

	return returned_color_r,returned_color_g,returned_color_b
end


require(script.Parent):Attach(function(a0): any 
	
	
	local r,g,b = return_closest(a0.r,a0.g,a0.b,PALETTE)
	
	a0.r = r;
	a0.g = g;
	a0.b = b;
	
	return
end)
return nil