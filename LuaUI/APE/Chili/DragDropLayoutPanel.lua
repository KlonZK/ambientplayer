--//=============================================================================
------------------------------------------- filtered Drag & Drop Layout Panel ---
-- drag is controlled mainly by the drag&drop deamon control, this panel type just provides an interface
-- allowDragItems / allowDropItems control if and which type of data can be transfered, values are string
-- controls of this class need to implement a "ReceiveDragItems" method which gets called when a drag arrives
-- draggable children need a "selectable" flag

--//=============================================================================

local function ExpandRect(rect,margin)
	return {
		rect[1] - margin[1],              --//left
		rect[2] - margin[2],              --//top
		rect[3] + margin[1] + margin[3], --//width
		rect[4] + margin[2] + margin[4], --//height
	}
end

local function AreRectsOverlapping(rect1,rect2)
	return
		(rect1[1] <= rect2[1] + rect2[3]) and
		(rect1[1] + rect1[3] >= rect2[1]) and
		(rect1[2] <= rect2[2] + rect2[4]) and
		(rect1[2] + rect1[4] >= rect2[2])
end

	
--//=============================================================================
	
DragDropLayoutPanel = Chili.LayoutPanel:Inherit{
	classname = 'dragdroplayoutpanel',
	
	hitTestAllowEmpty = true,
	allowDragItems = false,
	allowDropItems = false,
	
	OnSelectItem = {
		function(self, index, state)
			local c = self.children[index]
			if c and c.OnSelect then
				c:OnSelect(index, state)
			else
				Echo("child at index "..tostring(index).." does not exist.")
			end
		end,
	},
}

local this = DragDropLayoutPanel
local inherited = this.inherited


--//=============================================================================

function DragDropLayoutPanel:New(obj)
	obj = Chili.LayoutPanel.New(self, obj)
	obj.selectedItems = {}
	return obj
end
		

--//=============================================================================	
	
DragDropLayoutPanel.OnSelectItem = {
	function(self, index, state)
		local c = self.children[index]
		if c and c.OnSelect then
			c:OnSelect(index, state)
		else
			Echo("child at index "..tostring(index).." does not exist.")
		end
	end,
}


--//=============================================================================	

function DragDropLayoutPanel:DeselectItem(itemIdx)
	if (not self.selectedItems[itemIdx]) then
		return
	end
	self.selectedItems[itemIdx] = nil
	--self._lastSelected = itemIdx
	self:CallListeners(self.OnSelectItem, itemIdx, false)
	self:Invalidate()
end
	
	
function DragDropLayoutPanel:ToggleItem(itemIdx)
	local newstate = not self.selectedItems[itemIdx]
	self.selectedItems[itemIdx] = newstate
	if newstate then self._lastSelected = itemIdx end
	self:CallListeners(self.OnSelectItem, itemIdx, newstate)
	self:Invalidate()
end
	
	
function DragDropLayoutPanel:MultiRectSelect(item1, item2, append)
  --// note: this functions does NOT update self._lastSelected!

  --// select all items in the convex hull of those 2 items
	local cells = self._cells
	local itemPadding = self.itemPadding

	local cell1,cell2 = cells[item1],cells[item2]

	local convexHull = {
		math.min(cell1[1],cell2[1]),
		math.min(cell1[2],cell2[2]),
	}
	convexHull[3] = math.max(cell1[1]+cell1[3],cell2[1]+cell2[3]) - convexHull[1]
	convexHull[4] = math.max(cell1[2]+cell1[4],cell2[2]+cell2[4]) - convexHull[2]

	local oldSelected = {} 
	for k, v in pairs(self.selectedItems) do
		oldSelected[k] = v
	end
	self.selectedItems = append and self.selectedItems or {}			
	
	for i=1,#cells do
		local cell  = cells[i]
		local cellbox = ExpandRect(cell,itemPadding)
		if (AreRectsOverlapping(convexHull,cellbox)) then
			self.selectedItems[i] = true					
		end
	end			
	
	if (not append) then								
		for itemIdx,selected in pairs(oldSelected) do
			if (selected)and(not self.selectedItems[itemIdx]) then
				self:CallListeners(self.OnSelectItem, itemIdx, false)
			end
		end
	end			
	
	for itemIdx,selected in pairs(self.selectedItems) do
		if (selected)and(not oldSelected[itemIdx]) then
			self:CallListeners(self.OnSelectItem, itemIdx, true)
		end
	end				
	
	self:Invalidate()
end


--//=============================================================================		
	
function DragDropLayoutPanel:MouseUp(x, y, button, mods)
	local clickedChild = C_Control.MouseDown(self,x,y,button,mods)
	if (clickedChild) then
		return clickedChild
	end
	if (not self.selectable) then return end			
	
	if (button==3) then
		self:DeselectAll()
		return self
	end
	if not self.children or #self.children < 1 then return end -- wonder why it never crashed before?
	local cx,cy = self:LocalToClient(x,y)
	local itemIdx = self:GetItemIndexAt(cx,cy)
	
	-- we need to check here if the child exists, some operations may steal it from under our nose
	if (itemIdx>0) and self.children[itemIdx] and self.children[itemIdx].selectable then
		if (self.multiSelect) then
			if (mods.shift and mods.ctrl) then
				self:MultiRectSelect(itemIdx,self._lastSelected or 1, true)
			elseif (mods.shift) then
				self:MultiRectSelect(itemIdx,self._lastSelected or 1)
			elseif (mods.ctrl) then
				self:ToggleItem(itemIdx)
			else
				self:SelectItem(itemIdx)
			end
		else
			self:SelectItem(itemIdx)
		end
	end
end


function DragDropLayoutPanel:MouseDown(x, y, button, mods)
	local clickedChild = C_Control.MouseDown(self,x, y, button, mods)
	--if clickedChild then Echo("child: "..clickedChild.name) end
	if self.allowDragItems then
		--Echo("sent to deamon "..dragDropDeamon.name)
		--if dragDropDeamon.MouseDown then Echo("has func") end
		return dragDropDeamon:MouseDown(x, y, button, mods, clickedChild or self)
	end			
	if (clickedChild) then
		return clickedChild
	end
	if (not self.selectable) then return end
	return self
end
	
	
function DragDropLayoutPanel:MouseClick(x, y, button, mods)	
	-- needed for hittest?
end


function DragDropLayoutPanel:MouseDblClick(x, y, button, mods)	
	local clickedChild = C_Control.MouseDown(self,x,y,button,mods)
	if (clickedChild) then
		--Echo("123")
		return clickedChild
	end

	if (not self.selectable) then return end

	local cx,cy = self:LocalToClient(x,y)
	local itemIdx = self:GetItemIndexAt(cx,cy)

	if (itemIdx>0) then
		self:CallListeners(self.OnDblClickItem, itemIdx)
		return self
	end
end	

-- not sure if used	
function DragDropLayoutPanel:IsMouseOver(mx, my) 		
	local ca = self.parent.clientArea
	local x, y = self.parent:LocalToScreen(ca[1], ca[2])
	local w, h = ca[3], ca[4]
	return self.visible and (mx > x and mx < x + w) and (my > y and my < y + h) 	
end
	

	