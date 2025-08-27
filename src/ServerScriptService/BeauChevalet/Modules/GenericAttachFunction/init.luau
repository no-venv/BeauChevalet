--!native
--!strict
type void = nil;

type Impl<T> = {
	LoadModules : (self : GenericAttachFunction<T>, modules : {ModuleScript}) -> GenericAttachFunction<T>;
	Attach : (self : GenericAttachFunction<T>, func : (T) -> void) -> void;
}

type Struct<T> = {
	modules : {ModuleScript};
	functions : {(T) -> T};
}

export type GenericAttachFunction<T> = Impl<T> & Struct<T>;

local GenericAttachFunction = {} :: GenericAttachFunction<any>;
local constructor = {};
local new = require(script.New);
function GenericAttachFunction:LoadModules(modules)

	if not modules then
		return self
	end
	
	self.modules = modules
	return self
end
function GenericAttachFunction:Attach(func)
	-- hook to clamp the pixel values
	table.insert(self.functions,func)
	return nil;
end

function constructor:New()
	
	local self : Struct<any> = {
		functions = {};
		modules = {};
	}
	
	return new(self,GenericAttachFunction :: Impl<any>);
end

return constructor;