--!strict
type void = nil
type Impl = {
	init : (self : Impl,void) -> RBXScriptConnection;
}

local PlayModeWarn = {} :: Impl
local GUI = script.PlayModeWarn
local PLAYER_SERVICE = game:GetService("Players")
function PlayModeWarn:init()
	return PLAYER_SERVICE.PlayerAdded:Connect(function(player: Player) 
		GUI:Clone().Parent = player.PlayerGui
		
	end)
end

return PlayModeWarn
