local function New<A,B>(Struct : A, Impl : B) 
	Impl.__index = Impl 
	return setmetatable(Struct,Impl) :: A & B
end

return New