--//=============================================================================
-------------------------------------------- Instanced Prototype-based Window ------------------------------------	
-- abstract class. provides infrastructure to create and store instances of the prototype defined in the subclasses'
-- constructor. retrieve instances by accessing any key in the subclasses' instances table


InstancedWindow = MouseOverWindow:Inherit{
	classname = 'instancedwindow',
}	

local this = InstancedWindow
local inherited = this.inherited
	
--//=============================================================================

function InstancedWindow:New(obj) -- not sure if needed
	self.inherited.New(self, obj)
	return obj
end

function InstancedWindow:Inherit(class)			
	class = self.inherited:Inherit(class) -- not sure why?
	class.instances = {}
	setmetatable(class.instances, {
		__mode = 'v',
		__index = function(t, k)
			if not rawget(t, k) then
				t[k] = class:New(k)
				containers[class.classname..k] = t[k]
				--rawset(t, k, class:new(key))
			end
			return t[k]
		end,
	})
	return class	
end

