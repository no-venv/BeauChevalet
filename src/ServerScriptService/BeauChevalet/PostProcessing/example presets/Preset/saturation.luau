require(script.Parent):Attach(function(a0): any 
	local h,s,v = Color3.new(a0.r,a0.g,a0.b):ToHSV()
	local color = Color3.fromHSV(h,s *.5,v)
	a0.r = color.R;
	a0.g = color.G;
	a0.b = color.B
	return
end)
return nil