--!native
--!strict

local SKY : Color3 = script.color.Value
local SKY_OFFSET : number = script.sky_offset.Value
local AMBIENT_INFLUENCE : number = script.ambient_influence.Value
local VIEWPORT_RESOLUTION_Y = workspace.CurrentCamera.ViewportSize.Y
require(script.Parent):Attach(function(a0): nil 

	if not a0.raycast then
		local sky_gradient = 1 - (a0.y / VIEWPORT_RESOLUTION_Y) * SKY_OFFSET
		a0.r = SKY.R * sky_gradient
		a0.g = SKY.G * sky_gradient
		a0.b = SKY.B * sky_gradient
	else
		a0.r += SKY.R * AMBIENT_INFLUENCE 
		a0.g += SKY.G * AMBIENT_INFLUENCE 
		a0.b += SKY.B * AMBIENT_INFLUENCE 
	end
	

	return	
end)
return nil