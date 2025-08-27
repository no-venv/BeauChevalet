--!native
--!strict

type void = nil

type Impl = {
	put_pixel : (self : Canvas, x : number, y : number, r : number, g : number, b : number,a : number) -> void;
	get_pixel : (self : Canvas, x : number, y : number) -> (number,number,number,number);
}
type Struct = {
	pixels : buffer;
	x : number;
	y : number;
}

export type Canvas  = Impl & Struct;

local Canvas = {} :: Canvas;
local constructor = {};
local WRITEU8 = buffer.writeu8
local READU8 = buffer.readu8
local new = require(script.New);

local function getIndex(x : number, y : number,width :number, channel : number)
	return ((width * channel * (y) + (x) * channel));
end


function Canvas:put_pixel(x,y,r,g,b,a)
	
	if x < 0 or x >= self.x then
		error(`out of bounds at {x} {y}`)
	end
	
	if y < 0 or y >= self.y then
		error(`out of bounds at {x} {y}`)
	end
	
	local pixel_index = getIndex(x,y,self.x,4);
	local pixel_buffer = self.pixels;
	
	WRITEU8(pixel_buffer,pixel_index,    (r * 255) // 1);
	WRITEU8(pixel_buffer,pixel_index + 1,(g * 255) // 1);
	WRITEU8(pixel_buffer,pixel_index + 2,(b * 255) // 1);
	WRITEU8(pixel_buffer,pixel_index + 3,(a * 255) // 1);

	return;
end

function Canvas:get_pixel(x,y)
	
	if x < 0 or x >= self.x then
		error(`out of bounds at {x} {y}`)
	end
	
	if y < 0 or y >= self.y then
		error(`out of bounds at {x} {y}`)
	end
	
	local pixel_index = getIndex(x,y,self.x,4);
	local pixel_buffer = self.pixels;
	
	local r = READU8(pixel_buffer, pixel_index) / 255
	local g = READU8(pixel_buffer, pixel_index + 1) / 255
	local b = READU8(pixel_buffer, pixel_index + 2) / 255
	local a = READU8(pixel_buffer, pixel_index + 3) / 255
	return r,g,b,a;
end


function constructor:New(x : number, y :number, resampling : Enum.ResamplerMode)
	
	if x > 1024 or y > 1024 then
		error("supported size of 1024x1024");
	end
	
	
	local self : Struct = {
		pixels =  buffer.create(x*y*4),
		x = x,
		y = y,
	};
	
	--buffer.fill(self.pixels,0,255,x*y*4)
	
	return new(self,Canvas);
end


return constructor