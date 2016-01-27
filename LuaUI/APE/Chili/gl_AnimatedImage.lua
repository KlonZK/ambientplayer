--//=============================================================================
------------------------------------------- Custom Draw Control Image --------------------------------------------
-- this is little more than a container for a custom draw control. unsure if this is needed at all


gl_AnimatedImage = Chili.Control:Inherit{
	classname = 'gl_animatedimage',
	defaultWidth  = 64,
	defaultHeight = 64,
	padding = {0,0,0,0},
	color = {1,1,1,1},		
	keepAspect = true;
	OnClick  = {},
}

local this = gl_AnimatedImage
local inherited = this.inherited

--//=============================================================================	
	
function gl_AnimatedImage:IsActive()
	local onclick = self.OnClick
	if (onclick and onclick[1]) then
		return true
	end
end

	
--//=============================================================================	

function gl_AnimatedImage:HitTest()
	return self:IsActive() and self
end


function gl_AnimatedImage:MouseDown(...)		
	return Control.MouseDown(self, ...) or self:IsActive() and self
end


function gl_AnimatedImage:MouseUp(...)
	return Control.MouseUp(self, ...) or self:IsActive() and self
end


function gl_AnimatedImage:MouseClick(...)
	return Control.MouseClick(self, ...) or self:IsActive() and self
end


