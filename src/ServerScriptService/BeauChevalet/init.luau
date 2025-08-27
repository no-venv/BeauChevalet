--!strict
-- BeauChevalet
-- beautiful easel
-- create your own raytraced art quicky
-- made by a cool lady ┗(^o^　)┓

type void = nil;
type BeauChevalet = {
	init : (self : BeauChevalet, threads : number, same_color_thres : number?, raycast_dist : number?) -> void;
	render_frame : (self : BeauChevalet) -> number;
};

local BeauChevalet = {} :: BeauChevalet;
local MODULES = require(script.Modules);
local RENDER_THREADS = MODULES.ThreadsApi
local VIEWPORT : Vector2;
local booted = false;
local play_mode_warn = MODULES.PlayModeWarn:init();
function BeauChevalet:init(threads,same_color_thres,raycast_dist)
	if booted then
		warn("BeauChevalet has been already initialized")
		return
	end
	--starts up the BeauChevalet singleton, can only be called once!
	assert(threads,"BeauChevalet has been initialized without a render_threads argument.")
	same_color_thres = (same_color_thres or 1) / 100
	raycast_dist = raycast_dist or 500
	RENDER_THREADS:init(threads,VIEWPORT.Y,same_color_thres :: number,raycast_dist :: number)
	booted = true
	return
end

function BeauChevalet:render_frame()
	if not booted then
		warn("BeauChevalet has not been initialized with :init")
		return 0
	end
	local t = os.clock()
	RENDER_THREADS:render()
	return os.clock() - t
end

MODULES.Version:check()
VIEWPORT = workspace.Camera.ViewportSize

if VIEWPORT.X <= 1 then
	while true do
		workspace.Camera:GetPropertyChangedSignal("ViewportSize"):Wait()
		VIEWPORT = workspace.Camera.ViewportSize
		if VIEWPORT.X > 1  then
			break
		end
	end
end

play_mode_warn:Disconnect()

return BeauChevalet