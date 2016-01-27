--//=============================================================================	
------------------------------------------- Text Box with Tooltip Support -------
-- needs to implement OnClick as well if a tooltip is meant to show up (?)

--//=============================================================================	

MouseOverTextBox = Chili.TextBox:Inherit{
	classname = "mouseovertextbox",			
	OnClick = {
		function()
		end,
	},
}

local this = MouseOverTextBox
local inherited = this.inherited


--//=============================================================================	

function MouseOverTextBox:HitTest(x, y)
	return self
end

