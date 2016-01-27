--//=============================================================================	
------------------------------------------- Text Box with Button Functionality --

ClickyTextBox = MouseOverTextBox:Inherit{
	classname = 'clickytextbox',	
}

local this = ClickyTextBox
local inherited = this.inherited
	
	
--//=============================================================================
	
function ClickyTextBox:MouseDown(...)
	local btn = select(3,...)	
	if not btn == 3 then return nil end
	self.state.pressed = true
	self.inherited.MouseDown(self, ...)
	self:Invalidate()
	return self
end


function ClickyTextBox:MouseUp(...)
	local btn = select(3,...)
	if not btn == 3 then return nil end
	if (self.state.pressed) then
		self.state.pressed = false
		self.inherited.MouseUp(self, ...)
		self:Invalidate()
		return self
	end
end

