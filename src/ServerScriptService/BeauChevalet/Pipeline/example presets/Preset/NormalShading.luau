--normal shading raycast shader
--!native
--!strict
require(script.Parent):Attach(function(a0): nil 
	
	if not a0.raycast then
		return
	end
	
	local shading = (0.299 * a0.normal.X + 0.587 * a0.normal.Y + 0.114 * a0.normal.Z) * 0.5
	
	a0.r += a0.r * shading
	a0.g += a0.g * shading
	a0.b += a0.b * shading


	return	
end)
return nil