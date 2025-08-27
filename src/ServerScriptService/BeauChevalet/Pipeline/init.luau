--!strict
local ROOT = script:FindFirstAncestor("BeauChevalet")

export type ReturnType = {
	r : number; -- modifiable color r
	g : number; -- modifiable color g
	b : number; -- modifiable color b
	x : number; -- x coordinate of the raycast
	y : number; -- y coordinate of the raycast
	raycast : RaycastResult?; -- raycast result, always verify that `a0.raycast` is not `nil`, otherwise your shader will not work.
	direction : Vector3; -- raycast direction
	normal : Vector3; -- raycast direction
	normalized_depth :number; -- normalized depth, 0 is close, 1 is far
}

local AttachFunction = require(ROOT.Modules.GenericAttachFunction);
local presets : {ModuleScript} = script:GetChildren();

task.defer(function()
	for _,preset : ModuleScript in presets do
		
		if not preset:IsA("ModuleScript") then
			continue
		end
		
		local loaded_preset = require(preset) :: AttachFunction.GenericAttachFunction<any>;
		
		for _,module : ModuleScript in loaded_preset.modules do
			local _ = require(module) :: unknown;
		end

	end
end)

return AttachFunction:New() :: AttachFunction.GenericAttachFunction<ReturnType>;