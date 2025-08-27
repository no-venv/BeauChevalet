--!native
--!strict
-- a render thread
-- each render thread has it's own framebuffer + canvas
type void = nil;
local ROOT = script:FindFirstAncestor("BeauChevalet");
local ACTOR = script:GetActor();
local CURRENT_CAMERA = workspace.Camera
local VIEWPORT : Vector2 = CURRENT_CAMERA.ViewportSize // Vector2.new(1,1); -- why would you represent a screen resolution as a float???
local RENDER_VIEWPORT : Vector2 = Vector2.zero
local MODULES = require(ROOT.Modules);
local PIPELINE = require(ROOT.Pipeline);
local POST_PROCESSING = require(ROOT.PostProcessing);
local DEBUG_PRINT = MODULES.DebugPrint;
local COLOR_SIM_THRES : number = 1/100;
local SKY_COLOR : Color3 = Color3.new();
local FLOOR = math.floor;
local CEIL = math.ceil;
local CLOCK = os.clock;
local VEC_NONE = Vector3.zero;
local clamp = math.clamp;
local MAX_RAYCAST_DISTANCE : number = 500;
local actor_height_start : number = 0;
local actor_height_end : number = 0;
local width : number = VIEWPORT.X;
local canvas : MODULES.Canvas;
local post_processing_queue : MODULES.Canvas;
local row_buffer : MODULES.Canvas;
local row_buffer_depth_normal : MODULES.DepthNormalBuffers;
local depth_normal_buffer : MODULES.DepthNormalBuffers;

@native local function GET_PIXEL(x : number,y : number) : (number,number,number)
	x = x < 0 and 0 or x >= canvas.x and canvas.x - 1 or x;
	y = y < 0 and 0 or y >= canvas.y and canvas.y - 1 or y;
	return canvas:get_pixel(x,y);
end

@native local function GET_DEPTH(x : number, y : number) : (number)
	x = x < 0 and 0 or x >= depth_normal_buffer.x and depth_normal_buffer.x - 1 or x;
	y = y < 0 and 0 or y >= depth_normal_buffer.y and depth_normal_buffer.y - 1 or y;
	local _,_,_,depth = depth_normal_buffer:get_pixel(x,y);
	return depth
end

@native local function GET_NORMAL(x : number, y : number) : (number,number,number)
	x = x < 0 and 0 or x >= depth_normal_buffer.x and depth_normal_buffer.x - 1 or x;
	y = y < 0 and 0 or y >= depth_normal_buffer.y and depth_normal_buffer.y - 1 or y;
	local nr,ng,nb = depth_normal_buffer:get_pixel(x,y);
	return nr,ng,nb;
end

@native local function raycast(x : number, y : number, canvas_y : number, pipeline_table : PIPELINE.ReturnType) : void
	local ray : Ray = CURRENT_CAMERA:ViewportPointToRay(x,y);
	local direction : Vector3 = ray.Direction * MAX_RAYCAST_DISTANCE;
	local raycast : RaycastResult? = workspace:Raycast(ray.Origin,direction);
	
	local depth : number = raycast and raycast.Distance / MAX_RAYCAST_DISTANCE or 1;
	local normal : Vector3 = raycast and raycast.Normal or VEC_NONE;
	local color : Color3 = raycast and (raycast.Instance::BasePart).Color or SKY_COLOR;
	
	pipeline_table.x = x;
	pipeline_table.y = y;
	pipeline_table.r = color.R;
	pipeline_table.g = color.G;
	pipeline_table.b = color.B;
	pipeline_table.normalized_depth = depth;
	pipeline_table.direction = direction;
	pipeline_table.raycast = raycast;
	pipeline_table.normal = normal;

	for _, pipeline_modules in PIPELINE.functions do
		pipeline_modules(pipeline_table);
		pipeline_table.r = clamp(pipeline_table.r,0,1);
		pipeline_table.g = clamp(pipeline_table.g,0,1);
		pipeline_table.b = clamp(pipeline_table.b,0,1);

	end
	
	canvas:put_pixel(x,canvas_y,pipeline_table.r,pipeline_table.g,pipeline_table.b);
	depth_normal_buffer:put_pixel(x,canvas_y,pipeline_table.normal.X,pipeline_table.normal.Y,pipeline_table.normal.Z,pipeline_table.normalized_depth)
	return
end

@native local function distance(r1 : number, g1 : number, b1 : number, r2 : number, g2 : number, b2 : number)
	local cr = r1 - r2;
	local cg = g1 - g2;
	local cb = b1 - b2;
	return (cr * cr + cg * cg + cb * cb) / 3.0;
end

@native local function lerprgb(r1 : number, g1 : number, b1 : number, r2 : number, g2 : number, b2 : number, t :number) : (number,number,number)
	local r : number = r1 + ((r2 - r1) * t);
	local g : number = g1 + ((g2 - g1) * t);
	local b : number = b1 + ((b2 - b1) * t);
	return r,g,b;
end

@native local function render()
	
	-- pipeline render pass
	
	local height : number = 0
	local pipeline_result : PIPELINE.ReturnType = {
		x = 0;
		y = 0;
		r = 0;
		g = 0;
		b = 0;
		normal = VEC_NONE;
		normalized_depth = 0;
		direction = VEC_NONE;
		raycast = nil;
	}
	
	local compare : {{number}} = {};
	local last_r : number = 0;
	local last_g : number = 0;
	local last_b : number = 0;
	local last_nx : number = 0
	local last_ny : number = 0;
	local last_nz : number = 0;
	local last_depth : number = 0;
	
	local check_next_height : boolean = false;
	local check_next_width  : boolean = false;
	local skip_x  : boolean = false;
	local max_thread_height : number = (actor_height_end - actor_height_start)
	local max_safe_height : number = max_thread_height -  ((max_thread_height - 1) % 3)
	local last_ran_time : number = CLOCK()
	
	for y = actor_height_start, actor_height_end - 1 do
		
		local odd_height = height % 3 ~= 0
		local above_safe_height = height < max_safe_height
		local below_safe_height = height >= max_safe_height
		
		if odd_height and above_safe_height then -- every odd row
			check_next_height = true
			height +=1
			continue
		end
		
		for x = 0, width - 1 do	
			
			local odd_width = x % 3 ~= 0

			if (CLOCK() - last_ran_time) >= 1.0 then 
				-- prevent task scheduler from killing the script due to long calcuations
				task.wait();
				last_ran_time = CLOCK();
			end
			
			if odd_width and above_safe_height then 
				check_next_width = check_next_height and true or false;
				continue;
			end
			
			if odd_width and below_safe_height then
				skip_x = true;
				continue;
			end

			raycast(x,y,height,pipeline_result);

			if not check_next_height and above_safe_height then
				row_buffer:put_pixel(x,0,pipeline_result.r,pipeline_result.g,pipeline_result.b)
				row_buffer_depth_normal:put_pixel(x,0,pipeline_result.normal.X,pipeline_result.normal.Y,pipeline_result.normal.Z,pipeline_result.normalized_depth)
			end

			if skip_x then
				local d = distance(last_r,last_g,last_b,pipeline_result.r,pipeline_result.g,pipeline_result.b)

				if d <= COLOR_SIM_THRES then
					
					canvas:put_pixel(x - 1,height,pipeline_result.r,pipeline_result.g,pipeline_result.b)
					canvas:put_pixel(x - 2,height,last_r,last_g,last_b)
					
					depth_normal_buffer:put_pixel(x - 1, height, pipeline_result.normal.X,pipeline_result.normal.Y,pipeline_result.normal.Z,pipeline_result.normalized_depth)
					depth_normal_buffer:put_pixel(x - 2, height,last_nx,last_ny,last_nz,last_depth)

					last_r,last_g,last_b = pipeline_result.r,pipeline_result.g,pipeline_result.b
					last_nx,last_ny,last_nz,last_depth 
						= pipeline_result.normal.X,pipeline_result.normal.Y,pipeline_result.normal.Z,pipeline_result.normalized_depth

				else
					last_r,last_g,last_b = pipeline_result.r,pipeline_result.g,pipeline_result.b
					last_nx,last_ny,last_nz,last_depth 
						= pipeline_result.normal.X,pipeline_result.normal.Y,pipeline_result.normal.Z,pipeline_result.normalized_depth

					raycast(x - 1, y,height,pipeline_result)
					raycast(x - 2, y,height,pipeline_result)
				
				end

				skip_x = false
				continue
			end
			
			if check_next_width then
				
				-- check the 4 colors of each pixel
				--[[		
					[(x-3,y-3)] [(x-2,y-3)] [(x-1,y-3)] [(x-0,y-3)]
					[(x-3,y-2)] [(x-2,y-2)] [(x-1,y-2)] [(x-0,y-2)]
					[(x-3,y-1)] [(x-2,y-1)] [(x-1,y-1)] [(x-0,y-1)]
					[(x-3,y-0)] [(x-2,y-0)] [(x-1,y-0)] [(x-0,y-0)]
				]]			
				
				local top_left_r,top_left_g,top_left_b = row_buffer:get_pixel(x - 3,0);
				local top_right_r,top_right_g,top_right_b = row_buffer:get_pixel(x,0);			
				local bottom_left_r,bottom_left_g,bottom_left_b = last_r,last_g,last_b
				local bottom_right_r,bottom_right_g,bottom_right_b = pipeline_result.r,pipeline_result.g,pipeline_result.b
				
				local top_left_nx,top_left_ny,top_left_nz,top_left_depth = row_buffer_depth_normal:get_pixel(x - 3,0);
				local top_right_nx,top_right_ny,top_right_nz,top_right_depth = row_buffer_depth_normal:get_pixel(x,0);
				local bottom_left_nx,bottom_left_ny,bottom_left_nz,bottom_left_depth = last_nx,last_ny,last_nz,last_depth;
				local bottom_right_nx,bottom_right_ny,bottom_right_nz,bottom_right_depth 
					= pipeline_result.normal.X,pipeline_result.normal.Y,pipeline_result.normal.Z,pipeline_result.normalized_depth
							
				
				row_buffer:put_pixel(x - 3,0,last_r,last_g,last_b)
				row_buffer:put_pixel(x,0,bottom_right_r,bottom_right_g,bottom_right_b)
				row_buffer_depth_normal:put_pixel(x - 3,0, last_nx,last_ny,last_nz,last_depth)
				row_buffer_depth_normal:put_pixel(
					x,0,pipeline_result.normal.X,pipeline_result.normal.Y,pipeline_result.normal.Z,pipeline_result.normalized_depth
				)	

				compare = {
					-- (top left to top right)
					{	x - 3, height - 3, x , height - 3, 
						top_left_r ,top_left_g ,top_left_b, 
						top_right_r,top_right_g, top_right_b,
						
						top_left_nx ,top_left_ny,top_left_nz ,top_left_depth,
						top_right_nx,top_right_ny,top_right_nz,top_right_depth,
						0
					};
					-- (top right to bottom right)
					{	x, height - 3, x , height, 
						top_right_r   ,top_right_g   ,top_right_b,
						bottom_right_r,bottom_right_g,bottom_right_b,
						
						top_right_nx   ,top_right_ny   ,top_right_nz   ,top_right_depth,
						bottom_right_nx,bottom_right_ny,bottom_right_nz,bottom_right_depth,
						0
					};
					-- (bottom right to bottom left)
					{	x, height, x - 3, height,  
						bottom_right_r ,bottom_right_g ,bottom_right_b,
						bottom_left_r  ,bottom_left_g  ,bottom_left_b,
						
						bottom_right_nx,bottom_right_ny,bottom_right_nz,bottom_right_depth,
						bottom_left_nx ,bottom_left_ny ,bottom_left_nz ,bottom_left_depth,
						0
					};
					-- (bottom left to top left)
					{
						x - 3, height, x - 3, height - 3, 
						bottom_left_r ,bottom_left_g ,bottom_left_b,
						top_left_r    ,top_left_g    ,top_left_b,
						
						bottom_left_nx ,bottom_left_ny ,bottom_left_nz ,bottom_left_depth,
						top_left_nx    ,top_left_ny    ,top_left_nz    ,top_left_depth,
						0
					};
					-- (top left to bottom right)
					{
						x - 3, height - 3, x, height, 
						top_left_r ,top_left_g ,top_left_b,
						bottom_right_r ,bottom_right_g ,bottom_right_b, 
						
						top_left_nx    ,top_left_ny    ,top_left_nz    ,top_left_depth,
						bottom_right_nx,bottom_right_ny,bottom_right_nz,bottom_right_depth,
						0
					};
					-- (top right to bottom left)
					{
						x, height - 3, x - 3, height, 
						top_right_r ,top_right_g ,top_right_b, 
						bottom_left_r ,bottom_left_g ,bottom_left_b ,
						
						top_right_nx   ,top_right_ny   ,top_right_nz   ,top_right_depth,
						bottom_left_nx ,bottom_left_ny ,bottom_left_nz ,bottom_left_depth,
						1
					}
				}
				
				for _, pixel in compare do
					local x1,y1 = pixel[1],pixel[2]
					local x2,y2 = pixel[3],pixel[4]
					local r1,g1,b1 = pixel[5],pixel[6],pixel[7]
					local r2,g2,b2 = pixel[8],pixel[9],pixel[10]
					local nx1,ny1,nz1,d1 = pixel[11],pixel[12],pixel[13],pixel[14]
					local nx2,ny2,nz2,d2 = pixel[15],pixel[16],pixel[17],pixel[18]
					local flip_diag = pixel[19] == 1
					
					local mx,my = (x1+x2)/2, (y1+y2)/2
					local x3,y3 = FLOOR(mx),FLOOR(my)
					local x4,y4 = CEIL(mx),CEIL(my)
					
					if flip_diag then
						y3 +=1
						y4 -=1
					end
								
					--local height_offset = height - my
					local d = distance(r1,g1,b1,r2,g2,b2)
					
					if d <= COLOR_SIM_THRES then
						--- this slightly increased visual quailty
						local r3,g3,b3 = lerprgb(r1,g1,b1,r2,g2,b2,.25)
						local r4,g4,b4 = lerprgb(r1,g1,b1,r2,g2,b2,.75)

						canvas:put_pixel(x3,y3,r3,g3,b3)
						canvas:put_pixel(x4,y4,r4,g4,b4)

						depth_normal_buffer:put_pixel(x3,y3,nx1,ny1,nz1,d1)
						depth_normal_buffer:put_pixel(x4,y4,nx2,ny2,nz2,d2)

					else
						
						local mx,my = x3,y3
						local height_offset = height - my
						raycast(mx,y - height_offset,my,pipeline_result);
						
						
						mx,my = x4,y4
						height_offset = height - my
						raycast(mx,y - height_offset,my,pipeline_result);
					
					end		
	
				end
				
				-- set last_r, etc back
				last_r = bottom_right_r;
				last_g = bottom_right_g;
				last_b = bottom_right_b;
				last_nx = bottom_right_nx;
				last_ny = bottom_right_ny;
				last_nz = bottom_right_nz;
				last_depth = bottom_right_depth;
				check_next_width = false;
			else
				last_r = pipeline_result.r;
				last_g = pipeline_result.g;
				last_b = pipeline_result.b;
				last_nx = pipeline_result.normal.X;
				last_ny = pipeline_result.normal.Y;
				last_nz = pipeline_result.normal.Z;
				last_depth = pipeline_result.normalized_depth;
			end
				
		end
		
		check_next_height = false;
		check_next_width = false;
		skip_x = false;
		height += 1;
	end
	
	local old_canvas : buffer
	if #POST_PROCESSING.functions > 0 then
		
		local result : POST_PROCESSING.ReturnType = {
			x = 0;
			y = 0;
			r = 0;
			g = 0;
			b = 0;
			global_y = 0;
			global_screen_size = VIEWPORT;
			local_screen_size = RENDER_VIEWPORT;
			get_pixel = GET_PIXEL;
			get_depth = GET_DEPTH;
			get_normal = GET_NORMAL;
		}		
		
		height = 0

		for y = actor_height_start, actor_height_end - 1 do
			
			result.y = height;
			result.global_y = y;

			for x = 0, width - 1 do	

				local r,g,b = canvas:get_pixel(x,height)

				result.r = r;
				result.g = g;
				result.b = b;
				result.x = x;

				for  _,post_processing_modules in POST_PROCESSING.functions do
					post_processing_modules(result)
					result.r = clamp(result.r,0,1)
					result.g = clamp(result.g,0,1)
					result.b = clamp(result.b,0,1)

				end	
				
				post_processing_queue:put_pixel(x,height,result.r,result.g,result.b);

			end
			height +=1

		end
		old_canvas = canvas.pixels
		canvas.pixels = post_processing_queue.pixels
	end
	
	task.synchronize()
	script.Parent.render_completed:Fire()
	canvas:draw()
	return
end

ACTOR:BindToMessage("init",function(height_start : number, height_end : number,same_color_thres : number, raycast_dist : number) : void
	local height = height_end - height_start;
	canvas = MODULES.Canvas:New(VIEWPORT.X,height,Enum.ResamplerMode.Pixelated);
	post_processing_queue = MODULES.Canvas:New(VIEWPORT.X,height,Enum.ResamplerMode.Pixelated);
	depth_normal_buffer = MODULES.DepthNormalBuffers:New(VIEWPORT.X,height,Enum.ResamplerMode.Pixelated);
	row_buffer = MODULES.Canvas:New(VIEWPORT.X,1,Enum.ResamplerMode.Pixelated);
	row_buffer_depth_normal = MODULES.DepthNormalBuffers:New(VIEWPORT.X,1,Enum.ResamplerMode.Pixelated);
	
	canvas.gui.Parent = game.StarterGui;
	(canvas.gui:FindFirstChildWhichIsA("Frame")::Frame).Position = UDim2.new(0,0,0,height_start);
	actor_height_start = height_start;
	actor_height_end = height_end;
	MAX_RAYCAST_DISTANCE = raycast_dist;
	COLOR_SIM_THRES = same_color_thres;
	RENDER_VIEWPORT = Vector2.new(VIEWPORT.X,height)
	return;
end)

ACTOR:BindToMessageParallel("render",render)
script.Parent.thread_init_complete:Fire()