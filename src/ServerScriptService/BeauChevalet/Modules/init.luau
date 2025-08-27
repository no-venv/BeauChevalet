local Modules = {
	Canvas =  require(script.Canvas);
	DepthNormalBuffers = require(script.DepthNormalBuffers);
	DebugPrint = require(script.DebugPrint);
	PlayModeWarn = require(script.PlayModeWarn);
	ThreadsApi = require(script.ThreadsAPI);
	Version = require(script.Version);
}

local Canvas = require(script.Canvas)
local DepthNormalBuffers = require(script.DepthNormalBuffers)
export type Canvas = Canvas.Canvas
export type DepthNormalBuffers = DepthNormalBuffers.Canvas
return Modules