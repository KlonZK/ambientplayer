--//=============================================================================
-------------------------------------------- Emitter Inspection Window Prototype ------------------------------------
-- each emitter can own one instance of this window to inspect its properties		

EmitterInspectionWindow = InstancedWindow:Inherit{
	classname = 'emitterinspectionwindow',
}

local this = EmitterInspectionWindow
local inherited = this.inherited


--//=============================================================================	
	
function EmitterInspectionWindow:New(key)
	local obj = {
		emitter = key,
		parent = screen0,
		x = "50%",
		y = "50%",				
		caption = "Details",
		textColor = colors.grey_08,
		draggable = true,
		resizable = false,
		dragUseGrip = true,
		clientWidth = 300,
		clientHeight = 250,
		visible = false,
	}
	
	obj = self.inherited.New(self, obj)			
	
	local scriptBtn = Button:New{
		parent = obj,
		x = 4,
		y = 4,
		--x = -28,
		--y = -28,
		tooltip = emitters[key].script and (emitters[key].script..colors.green_1:Code().."\n\n(right-cliok to remove)") or 'Add Script File',
		clientWidth = 18,
		clientHeight = 18,
		caption = '',
		padding = {6,6,6,6},
		margin = {2,2,2,2},
		OnClick = {
			function(self, ...)
				local btn = select(3,...)
				if btn == 3 and emitters[key].script then
					widget.RemoveScript(key)
					self.tooltip = 'Add Script File'
				else
					if self.hasPopup then
						self.hasPopup:Discard()
						self.hasPopup = false
					else								
						self.hasPopup = ScriptBrowserPopup(emitters[key], self)
					end
				end
				-- self.tooltip = emitters[key].script and emitters[key].script or 'Add Script File'
			end,
		},	
	}
	Image:New {
		parent = scriptBtn,
		width = "100%",
		height = "100%",
		file = icons.LUA_ICON,
		padding = {0,0,0,0},
		margin = {0,0,0,0}
	}			
	local varsBtn = Button:New{
		parent = obj,
		x = 36,
		y = 4,
		--x = -28,
		--y = -28,
		tooltip = "Script Parameters",
		clientWidth = 18,
		clientHeight = 18,
		caption = '',
		padding = {6,6,6,6},
		margin = {2,2,2,2},
		OnClick = {
			function(self, ...)
				if self.hasPopup then
					self.hasPopop:Discard()
					self.hasPopup = false
				elseif widget.scripts[key] then
					self.hasPopup = ScriptParamsPopup(emitters[key], self)						
				else
					Echo(key.." has no script")
				end	
			end,					
		},	
	}
	Image:New {
		parent = varsBtn,
		width = "100%",
		height = "100%",
		file = icons.PROPERTIES_ICON,
		padding = {0,0,0,0},
		margin = {0,0,0,0}
	}			
	
	local closeBtn = Button:New{
		parent = obj,
		x = -28,
		y = 4,				
		tooltip = 'Close',
		clientWidth = 14,
		clientHeight = 14,
		caption = '',
		padding = {8,8,8,8},
		margin = {2,2,2,2},
		OnClick = {
			function(self)
				self.parent:Hide()
				self.parent.layout:DeselectAll()
				self.parent.layout.visible = false
			end,
		},	
	}
	Image:New {
		parent = closeBtn,
		width = "100%",
		height = "100%",
		file = icons.CLOSE_ICON,
		padding = {0,0,0,0},
		margin = {0,0,0,0}
	}
	local closeallBtn =	Button:New{					
		parent = obj,
		x = -60,
		y = 4,				
		tooltip = 'Close All',
		clientWidth = 16,
		clientHeight = 16,
		caption = '',
		padding = {7,7,7,7},
		margin = {2,2,2,2},
		OnClick = {
			function(self)
				for _, window in pairs(EmitterInspectionWindow.instances) do 
					window:Hide()
					window.layout:DeselectAll()
					window.layout.visible = false
				end
			end,
		},
	}	
	Image:New {
		parent = closeallBtn,
		width = "100%",
		height = "100%",
		file = icons.CLOSEALL_ICON,
		padding = {0,0,0,0},
		margin = {0,0,0,0}
	}	
	local label = Label:New{
		parent = obj,
		y = 20,				
		width = 300,				
		align = 'center',		
		caption = key,
		textColor = colors.yellow_09,
		Refresh = function(self)
			if not self.caption == self.parent.emitter then 
				self.caption = parent.emitter
				self:Invalidate()
			end
			return false						
		end,
	}
	local scrlPanel = ScrollPanel:New{
		parent = obj,
		y = 40,
		clientWidth = 300 - 8,
		clientHeight = 250 - 90,				
		scrollPosX = -16,
		horizontalScrollbar = false,
		verticalScrollbar = true,
		verticalSmartScroll = false,	
		scrollbarSize = 6,
		padding = {5,10,5,10},
		Refresh = function(self)
			for _, c in pairs(self.children) do
				return c.Refresh and c:Refresh() or false
			end
		end,				
	}	
	local layout = DragDropLayoutPanel:New{							
		parent = scrlPanel,
		-- allowDropItems = 'sounds', --impl needs cutting the real names from the strings and check template tags
			-- this can be done before or after
		allowDropItems = 'sounds',
		allowDragItems = 'sounds',
		clientWidth = 300,
		clientHeight = 250,
		--maxWidth = 300,
		minWidth = 292,
		minHeight = 160,
		orientation = 'vertical',				
		selectable = true,		
		multiSelect = true,
		itemPadding = {6,2,6,2},
		itemMargin = {0,0,0,0},
		autosize = true,
		align = 'left',
		columns = 4,
		left = 0,
		centerItems = false,
		list = {},				
		ReceiveDragItems = function(self, drag)
			local sel = drag.items[1].selectedItems
			local list = drag.items[1].children
			local e = self.emitter
			local add = widget.AddItemToEmitter 
			for k, v in pairs(sel) do
				if v then
					add(e, list[k].refer)
				end
			end
			self:Refresh()
			if obj.hidden then obj:Show() end
		end,
		Refresh = function(self)
			--Echo("refreshing layout")
			self.emitter = obj.emitter					
			local e = emitters[self.emitter]
			if not e then 
				obj:Dispose()
				return false
			end
			local list = self.list
			local hasValidLayout = true
			for i = 1, #e.sounds do
				--Echo("sounds")
				local sound = e.sounds[i]
				local iname = sound.item
				local item = sounditems.instances[iname]
				
				if not list[iname] then
					list[iname] = {}
					local _, endprefix = string.find(iname, "[%$].*[%$%s]")
					local txt_normal = colors.yellow_09:Code()..string.sub(iname, 0, endprefix)
						..colors.white_1:Code()..string.sub(iname, endprefix + 1)
					local txt_selected = colors.yellow_09:Code()..string.sub(iname, 0, endprefix)
						..colors.green_1:Code()..string.sub(iname, endprefix + 1)	
					list[iname].label = MouseOverTextBox:New{
						refer = iname,
						width = obj.width - 140,
						parent = self,
						align = 'left',
						text = txt_normal,
						fontsize = 10,
						textColor = colors.white_09,
						--textColorNormal = colors.white_09,
						--textColorSelected = colors.green_1,								
						backgroundColor = colors.grey_02,
						borderColor = colors.grey_03,
						padding = {0, 6, 0, 0},
						selectable = true,					
						OnSelect = function(self, idx, select) 						
							--self.backgroundColor, self.backgroundFlip = self.backgroundFlip, self.backgroundColor
							--self.borderColor, self.borderFlip = self.borderFlip, self.borderColor
							if select then 
								--self.font:SetColor(self.textColorSelected)							
								self:SetText(txt_selected)
							else 
								--self.font:SetColor(self.textColorNormal) 
								self:SetText(txt_normal)
							end
							self:UpdateLayout()									
							self:Invalidate()
						end,								
						OnMouseOver = {
							function(self) 													
								local _, endprefix = string.find(iname, "[%$].*[%$%s]")
								local ttip = colors.yellow_09:Code()..string.sub(iname, 0, endprefix)
									..colors.white_1:Code()..string.sub(iname, endprefix + 1).."\n\n"
										..(item.file_local and colors.orange_06:Code() or colors.green_1:Code())
											..item.file..colors.white_1:Code().."\n\n"										
								for k, _ in pairs(sounditems.default) do											
									if k ~= 'file' then												
										ttip = ttip..k..": "..tostring(item[k]).."\n"
									end
								end
								self.tooltip=ttip
							end,
						},
					}
					list[iname].editBtn = Image:New {
						refer = iname,								
						parent = self,
						file = icons.PROPERTIES_ICON,
						width = 20,
						height = 20,
						tooltip = 'Edit',
						color = colors.grey_879, 
						OnClick = { -- this needs a look at
							function(self,...)									
								local w = window_properties
								if w.refer then w:Confirm() end
								w.refer = self.refer
								w:Refresh()
								w:Show()									
							end,
						},											
					}
					list[iname].playBtn = Image:New {
						refer = iname,
						refer2 = key,
						parent = self,
						file = icons.PLAYSOUND_ICON,
						width = 20,
						height = 20,
						tooltip = self.emitter == 'global' and 'Play' or 'Play at Location',
						color = colors.green_06,
						margin = {-6,0,0,0},
						OnClick = { -- hope e exists at this point?
							function(self)										
								return DoPlay(iname, options.volume.value, self.refer2)
							end,
						},
					}
					list[iname].activeIcon = Image:New {
						refer = sound,
						parent = self,
						file = icons.MUSIC_ICON,
						width = 18,
						height = 18,
						tooltip = 'not currently playing',
						color = {0.3,0.5,0.7,0.0},
						activeColor = {0.5,0.8,0.9,0.9},
						inactiveColor = {0.3,0.5,0.7,0.0},
						margin = {-6,1,0,1},
						--padding = {0, 0, 0, 0},
						OnClick = {},
						Refresh = function(self)
							self.color = sound.isPlaying and self.activeColor or self.inactiveColor
							self:Invalidate()
						end,
					}							
					-- what about animated play button
					hasValidLayout = false
				end								
			end							
			for k, t in pairs(list) do
				if not e.sounds[k] then
					t.label:Dispose()
					t.editBtn:Dispose()
					t.playBtn:Dispose()
					hasValidLayout = false
				end
			end
			-- if not hasValidLayout then self:Invalidate()
			return not hasValidLayout
		end,
	}
	obj.Refresh = function(self)
		--Echo("refreshing")
		local key = self.emitter
		local e = emitters[key]
		if not e then 
			Echo("emitter "..key.." no longer exists, disposing of window")
			self:Dispose() 
			return
		end	
		
		label:Refresh()
		layout:Refresh()								
	end
	obj.layout = layout
	obj:Refresh()			
	obj:Hide()
	return obj
end
