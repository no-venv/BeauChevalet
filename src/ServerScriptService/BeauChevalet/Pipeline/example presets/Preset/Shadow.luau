--shadow raycast shader
--!native
--!strict
local SUN_DIRECTION :Vector3 = game.Lighting:GetSunDirection()
require(script.Parent):Attach(function(a0): nil 
	
	if not a0.raycast then
		return
	end
	
	local is_shaded = workspace:Raycast(a0.raycast.Position + a0.raycast.Normal * 1e-4 ,SUN_DIRECTION * a0.raycast.Distance)
	
	if is_shaded then
		a0.r *=.77
		a0.g *=.77
		a0.b *=.77

	end

	return	
end)
return nil