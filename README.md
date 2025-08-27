`Mirrored from https://devforum.roblox.com/t/beauchevalet-fast-raycast-renders/`

<div align="center">

![RobloxScreenShot20241005_125755938|500x500](upload://tTDCwGqr6vjtoNsiLqfZQI5q4cH.jpeg)

</div>
<details>
  <summary>introduction & benchmarks</summary>
  
##  **introduction & benchmarks** 

BeauChevalet is a project i've been working on for the past 1-2 months, and i'm happy to share a functioning build of it.

the primary goal for BeauChevalet is for fast renders with raycasts at a resolution of 1024x1024, and well, i did the impossible :face_with_hand_over_mouth:



the following benchmarks demonstrates how fast can BeauChevalet can render scenes.

 these benchmarks has been conducted on a [i5-7300u](https://ark.intel.com/content/www/us/en/ark/products/97472/intel-core-i5-7300u-processor-3m-cache-up-to-3-50-ghz.html) with max clock speeds and with minimal processes running. BeauChevalet settings was set to default.

<div align="center">
GI TEST 64 SAMPLES

![RobloxScreenShot20241009_213342080|500x500](upload://mfpRmdnTzQ7qOj0YLOQH8jc2JPa.jpeg)


![GI TEST 64 SAMPLES|544x500](upload://fhKrrFB9BMpmjYkGm9MMIugqhAd.png)

CITY
![RobloxScreenShot20241009_222437098|500x500](upload://5ZnnOXdBIm2mhiEg65VmC7dDTj3.png)

![CITY|541x500](upload://r8YmAXGoYRHo8scqVFzIUAgiCE2.png)

GI BOX UNSHADED 

![RobloxScreenShot20241009_220551052|500x500](upload://7090tlSgJe6Q8sa6R6lz2GqxJ4H.png)
![SIMPLE GI BOX TEST|543x500](upload://9n40u4aXdSw6MynjHvUQYlN4exv.png)

</div>

</details>

<details>
  <summary>get started</summary>

## **get started**

[you can get BeauChevalet here](https://create.roblox.com/store/asset/129701135137689/BeauChevalet)

insert the module into a server script in `ServerScriptService`:

![image|273x87](upload://wHWSMkzjbPViRiGXdL8g6LKpAYm.png)

to use BeauChevalet, you only have to do the following:
```lua
local Renderer = require(script.BeauChevalet) -- change where you placed the BeauChevalet module
Renderer:init(32) -- 32 actors, please adjust for your system
print(Renderer:render_frame()) -- returns the number of seconds it took to render
```

to see your render, **make sure you use Run mode instead of Play mode, if you don't, you'll get a visual warning:**

![RobloxScreenShot20241010_190823313|690x247](upload://6R9rlEsYcwuMzKy8baV0zGUKTg0.png)


**also, please adjust the viewport resolution to a constant size no greater than 1024x1024 with the device emulation feature located in the "Test" section.**

you can adjust a few settings in the `init` method:
```lua
init : (self : BeauChevalet, threads : number, same_color_thres : number?, raycast_dist : number?) -> void;
```

- **threads**
the number of threads BeauChevalet will utilize. please be reasonable and do not use outrageous amounts. i recommend you use *less* threads (lower than 32) because more threads may interfere with with the algorithm that speeds up renders.

- **same_color_thres (optional)**
the threshold for determining if a color is similar, the acceptable values are in the range of 0 - 100, decimals are also acceptable.

  higher values means better performance, while lower values means higher picture quality. the default is 1.
- **raycast_dist  (optional)**
how far should BeauChevalet raycast. the default is 500.


BeauChevalet allows you to write your own shaders -- *with a limitation*:

> i have avoided doing any sort of communication between threads to ensure maximum performance, and as a consequence, **each thread cannot access another's framebuffer, this means some spatial shaders will not work correctly. this is not going to change.**

there are two types of shaders, the raycast shader and the fragment shader.

the raycast shader is intended to handle raycasts, you do all your raycast operations here. this can allow you to do reflections on objects, for example.

the fragment shader is intended for post processing, you have access to the color, normal and depth buffer. this can allow you to create an outline shader, for example.

**if you want to create a raycast shader, you first need to create a preset module.**
 - create the preset module under the "Pipeline" module
 - in the preset, insert the following:
```lua
-- this module is called "Preset", parented at "Pipeline"
return require(script.Parent):LoadModules{
}
```

`LoadModules` is responsible for loading each shader in the order you specify.

- create a new shader under the preset and insert the following:
```lua
-- this module is called "Shader", parented at "Preset"
--!native
return require(script.Parent):Attach(function(a0): nil 
   -- your shader code
	return
end)


```

the hierarchy should look like this:
![image|210x85](upload://xqrF1uXVttZc9Eoqapu2oK66iEl.png)


`a0` is a typed variable, it contains information about the current object that the  raycast hit:
```lua
--  a0 type
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

```

you modify the pixel values using the `a0.r`, `a0.g`, `a0.b` properties:
```lua
--!native
return require(script.Parent):Attach(function(a0): nil 
-- darken pixel by .5
    a0.r *= .5
    a0.g *= .5
    a0.b *= .5
	return
end)

```
- add the shader in the preset:
```lua
-- this module is called "Preset", parented at "Pipeline"
return require(script.Parent):LoadModules{
	script.Shader
}
```

if you have multiple shaders chained together,
```lua
return require(script.Parent):LoadModules{
	script.Shader;
	script.Shader2;
	script.Shader3;
}
```
then the  `a0.r`, `a0.g`, `a0.b` values will be passed down to the next shader.

 if `script.Shader` modifies the `a0.r`, `a0.g`, `a0.b` properties, then `script.Shader2` will also get the modified `a0.r`, `a0.g`, `a0.b` properties. 


**if you want to create a fragment shader, the same process applies, however, you place your preset module under the `PostProcessing` module.**

![image|221x77](upload://fWLXjaNeVH8lfhngqfwJTxLTY6T.png)


the `a0` return type for the fragment shader:
```lua

export type ReturnType = {
	r : number; -- modifiable color r
	g : number; -- modifiable color g
	b : number; -- modifiable color b
	x : number; -- local x coordinate for the thread's framebuffer
	y : number; -- local y coordinate for the thread's framebuffer
	global_y : number; -- global y coordinate, otherwise known as the current y position of the viewport screen size
	local_screen_size : Vector2; -- current thread's framebuffer screen size
	global_screen_size : Vector2;  -- current viewport screen size
	get_pixel : (number,number) -> (number,number,number); -- function to get the r,g,b values in the normal buffer
	get_normal : (number,number) -> (number,number,number); -- function to get the x,y,z values in the normal buffer
	get_depth : (number,number) -> number; -- function to get the depth value in the depth buffer
	
}
```

</details> 


<details>
  <summary>how i did it</summary>

## **how i did it**

### **exploiting spatial redundancy**

the optimization method i use relies on exploiting the spatial redundancy of pixels. this method assumes that neighboring pixels in a 4x4 block will have simliar pixel values. 

- raycast every 4th pixel in an evenly spaced grid
- examine each region, which is done by the following:

consider the:

- top left and top right pixel
- bottom left and bottom right pixel
- top left and bottom left pixel
- top right and bottom right pixel
- bottom left and top right pixel
- bottom right and top left pixel

does the following pixels have a similar color determined by a threshold? if so, then interpolate the missing pixels in-between them, otherwise raycast the missing pixels in-between them.

### **parallel luau**

parallel luau has dramatically decreased rendering times since each piece of the render can be worked on by individual threads.

i have avoided doing any sort of communication between threads to ensure maximum performance, and as a consequence, **each thread cannot access another's framebuffer, this means some spatial shaders will not work correctly. this is not going to change.**

### **buffers**
buffers has slightly decreased rendering times, probably because each component is represented by a `u8`, rather than a `f64`.

### **native code gen**
less overhead which improves performance.

</details>

hello! i've condensed this post into collapsible sections!
i hope you enjoy BeauChevalet!
