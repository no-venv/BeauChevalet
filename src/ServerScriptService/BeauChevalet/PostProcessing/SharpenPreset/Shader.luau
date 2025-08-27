--!strict
--!native
local AMOUNT = 0.25
local NEIGHBOR = AMOUNT * -1
local CENTER = AMOUNT * 4 + 1
local function mult_rgb(r : number, g:number, b:number,mult : number) : (number,number,number)
	return r * mult, g * mult, b * mult
end
require(script.Parent):Attach(function(a0): nil 
	local sr,sg,sb = 0,0,0
	local r1,g1,b1 = a0.r,a0.g,a0.b -- center
	local r2,g2,b2 = a0.get_pixel(a0.x,a0.y - 1) -- up
	local r3,g3,b3 = a0.get_pixel(a0.x,a0.y + 1) -- down
	local r4,g4,b4 = a0.get_pixel(a0.x - 1,a0.y) -- left
	local r5,g5,b5 = a0.get_pixel(a0.x + 1,a0.y) -- right
	
	r1,g1,b1 = mult_rgb(r1,g1,b1,CENTER)
	r2,g2,b2 = mult_rgb(r2,g2,b2,NEIGHBOR)
	r3,g3,b3 = mult_rgb(r3,g3,b3,NEIGHBOR)
	r4,g4,b4 = mult_rgb(r4,g4,b4,NEIGHBOR)
	r5,g5,b5 = mult_rgb(r5,g5,b5,NEIGHBOR)
	
	sr += r1 + r2 + r3 + r4 + r5
	sg += g1 + g2 + g3 + g4 + g5
	sb += b1 + b2 + b3 + b4 + b5
	
	a0.r = sr;
	a0.g = sg;
	a0.b = sb;
	return
end)
return nil