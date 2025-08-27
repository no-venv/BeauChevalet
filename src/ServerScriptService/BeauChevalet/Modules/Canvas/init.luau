--!native
--!strict

type void = nil

type Impl = {
	put_pixel : (self : Canvas, x : number, y : number, r : number, g : number, b : number) -> void;
	get_pixel : (self : Canvas, x : number, y : number) -> (number,number,number);
	draw : (self : Canvas) -> void;
}
type Struct = {
	editable_image : EditableImage;
	gui : ScreenGui;
	pixels : buffer;
	x : number;
	y : number;
	vector2_size : Vector2;
}

export type Canvas  = Impl & Struct;

local Canvas = {} :: Canvas;
local constructor = {};
local WRITEU8 = buffer.writeu8
local READU8 = buffer.readu8
local new = require(script.New);
local AssetService = game:GetService("AssetService")
local function getIndex(x : number, y : number,width :number, channel : number)
	return ((width * channel * (y) + (x) * channel));
end


function Canvas:put_pixel(x,y,r,g,b)
	
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
	
	local r = READU8(pixel_buffer, pixel_index) / 255;
	local g = READU8(pixel_buffer, pixel_index + 1) / 255;
	local b = READU8(pixel_buffer, pixel_index + 2) / 255;
	
	return r,g,b;
end

function Canvas:draw()
	self.editable_image:WritePixelsBuffer(Vector2.zero,self.vector2_size,self.pixels);
	return;
end

function constructor:New(x : number, y :number, resampling : Enum.ResamplerMode)
	
	if x > 1024 or y > 1024 then
		error("supported size of 1024x1024");
	end
	
	
	local screengui = Instance.new("ScreenGui");
	local container = Instance.new("Frame");
	
	screengui.IgnoreGuiInset = true;
	container.Size = UDim2.new(0,x,0,y);
	container.Transparency = 1;
	container.BorderSizePixel = 0;
	container.ClipsDescendants = false;
	container.Parent = screengui
	
	local imagelabel = Instance.new("ImageLabel");
	local editable_image = AssetService:CreateEditableImage({Size = Vector2.new(x,y)});

	imagelabel.BorderSizePixel = 0;
	imagelabel.Transparency = 1;
	imagelabel.Size = UDim2.new(1,0,1,0);
	imagelabel.ResampleMode = resampling;
	imagelabel.ScaleType = Enum.ScaleType.Fit;
	imagelabel.ImageContent = Content.fromObject(editable_image)
	imagelabel.Parent = container;
	
	local self : Struct = {
		editable_image = editable_image,
		gui = screengui,
		pixels =  buffer.create(x*y*4),
		x = x,
		y = y,
		vector2_size = Vector2.new(x,y)
	};
	
	buffer.fill(self.pixels,0,255,x*y*4)
	
	return new(self,Canvas);
end


return constructor