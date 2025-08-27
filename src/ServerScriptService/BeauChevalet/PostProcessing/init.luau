--!strict
local ROOT = script:FindFirstAncestor("BeauChevalet")

export type ReturnType = {
	r : number; -- modifiable color r
	g : number; -- modifiable color g
	b : number; -- modifiable color b
	x : number; -- local x coordinate for the thread's framebuffer
	y : number; -- local y coordinate for the thread's framebuffer
	global_y : number; -- global y coordinate, otherwise known as the current y position of the viewport screen size
	local_screen_size : Vector2; -- current thread's framebuffer screen size
	global_screen_size : Vector2;  -- current viewport screen size
	get_pixel : (x : number,y : number) -> (number,number,number); -- function to get the r,g,b values in the normal buffer
	get_normal : (x : number, y : number) -> (number,number,number); -- function to get the x,y,z values in the normal buffer
	get_depth : (x : number,y : number) -> number; -- function to get the depth value in the depth buffer
	
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