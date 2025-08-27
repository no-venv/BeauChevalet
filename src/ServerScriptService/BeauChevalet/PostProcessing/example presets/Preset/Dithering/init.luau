--!native 
--!strict
local BAYER_MATRIX = require(script.BayerMatrix)._4x4

require(script.Parent):Attach(function(a0): any 

	local grayscale = 0.299 * a0.r + 0.587 * a0.g + 0.114 * a0.b

	local i = a0.x % 4
	local j = a0.y % 4

	local dither_value = BAYER_MATRIX[i + 1][j + 1]
	dither_value = grayscale > dither_value and 1 or .8

	a0.r *= dither_value
	a0.g *= dither_value
	a0.b *= dither_value

	return
end)

return nil