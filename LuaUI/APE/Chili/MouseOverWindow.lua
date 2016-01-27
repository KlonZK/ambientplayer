--//=============================================================================
-------------------------------------------- Generic Window with MouseOver Hook -
-- the IsMouseOver method seems to be unused as hitTestAllowEmpty does pretty much the same

MouseOverWindow = Chili.Window:Inherit{
	classname = 'mouseoverwindow',		
	hitTestAllowEmpty = true,
}

local this = MouseOverWindow
local inherited = this.inherited


--//=============================================================================

-- unused
IsMouseOver	= function(self, mx, my) 						
	local x, y = self.x, self.y -- for some odd reason LocalToScreen() breaks window coordinates			
	return self.visible and (mx > x and mx < x + self.width) and (my > y and my < y + self.height) 
end

