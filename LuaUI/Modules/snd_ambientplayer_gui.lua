------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
--		file : snd_ape_gui.lua												--
--		desc : chili gui module for ambient sound editor								--
--		author : Klon 																	--
--		date : "24.7.2015",																--
--		license : "GNU GPL, v2 or later",												--
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------




local PATH_LUA = widget.LUAUI_DIRNAME

local settings = settings
local options = options
local config = config
local emitters = emitters
local sounditems = sounditems

local Image
local Button
local Checkbox
local Window
local Panel
local ScrollPanel
local LayoutPanel
local StackPanel
--local TreeView
--local Grid
local TabBar
local Trackbar
--local Node
local Label
local Line

local MouseOverWindow
local DragDropLayoutPanel
local FilterEditBox
local MouseOverTextBox
local ClickyTextBox
local gl_AnimatedImage


--local color2incolor
--local incolor2color

local icons = {}

-- these dont really have to be locals? as images are just loaded once
icons.SETTINGS_ICON = PATH_LUA..'Images/Epicmenu/settings.png'
icons.HELP_ICON = PATH_LUA..'Images/Epicmenu/questionmark.png'
icons.CONSOLE_ICON = PATH_LUA..'Images/speechbubble_icon.png'
icons.PLAYSOUND_ICON = PATH_LUA..'Images/Epicmenu/vol.png'
icons.PROPERTIES_ICON = PATH_LUA..'Images/properties_button.png'
--icons.PLAYER_CONTROLS_ICON = PATH_LUA..'Images/Commands/Bold/'..'drop_beacon.png'
icons.CLOSE_ICON = PATH_LUA..'Images/close.png'
icons.CLOSEALL_ICON = PATH_LUA..'Images/closeall.png'
icons.CONFIRM_ICON = PATH_LUA..'Images/arrow_green.png'
icons.UNDO_ICON = PATH_LUA..'Images/undo.png'
icons.COGWHEEL_ICON = PATH_LUA..'Images/cogwheel.png'
icons.SAVE_ICON = PATH_LUA..'Images/disc_save_2.png'
icons.LOAD_ICON = PATH_LUA..'Images/disc_load_2.png'
icons.MUSIC_ICON = PATH_LUA..'Images/music.png'
icons.SPRING_ICON = PATH_LUA..'Images/spring_logo.png'
icons.FILE_ICON = PATH_LUA..'Images/file.png'
icons.FOLDER_ICON = PATH_LUA..'Images/folder.png'
icons.NEWFOLDER_ICON = PATH_LUA..'Images/folder_add.png'
icons.MUSICFOLDER_ICON = PATH_LUA..'Images/folder_music.png'

local colors = {
	Code = function(c, r, g, b)
		local floor = math.floor
		local char = string.char
		if c and type(c) == 'table' then
			return '\255'..char(floor(c[1]*255))..char(floor(c[2]*255))..char(floor(c[3]*255))
		else			
			local r = r or 0
			local g = g or 0
			local b = b or 0
			return '\255'..char(floor(r*255))..char(floor(g*255))..char(floor(b*255))
		end
	end,
	blue_579 = {0.5, 0.7, 0.9, 0.9},	
	blue_579_6 = {0.5, 0.7, 0.9, 0.6},
	blue_579_4 = {0.5, 0.7, 0.9, 0.4},
	blue_07 = {0.7, 0.7, 0.8, 0.7},		
	green_1 = {0.4, 1.0, 0.1, 1.0},
	green_06 = {0, 0.6, 0.2, 0.9},
	red_1 = {1, 0.2, 0.1, 1.0},
	orange_06 = {1, 0.6, 0.0, 0.9},
	yellow_09 = {0.9, 0.9, 0, 0.9},
	white_1 = {1.0,1.0,1.0,1.0},
	white_09 = {0.9, 0.9, 0.9, 1},
	grey_879 = {0.8,0.7,0.9,0.9},
	grey_08 = {0.8, 0.8, 0.8, 0.7},
	grey_05 = {0.5,0.5,0.5,0.5},
	grey_035 = {0.35,0.35,0.35,0.5},
	grey_03 = {0.3, 0.3, 0.3, 0.5},
	grey_03_04 = {0.3,0.3,0.3,0.4},
	grey_02 = {0.2, 0.2, 0.2, 0.5},
	grey_01 = {0.1, 0.1, 0.1, 0.3},
}
for k, v in pairs(colors) do
	if type(v) ~= 'function' then
		setmetatable(v, {
			__index = colors, -- this allows colors.col:Code()
		})
	end
end


local HELPTEXT = [[generic info here]]

local inspectionWindows = {}
local containers = {}
local controls = {}	

-- attention needs to be paid what is added to containers
-- why am i using this?
setmetatable(controls, {
	__index = function(t, k)
		if containers[k] then rawset(t, k, {}) return t[k]
		else return nil end
	end	
})	


local window_main
local scroll_main_templates
local layout_main_templates
local button_console
local button_help
local button_settings

local window_console
local scroll_console
local MouseOverTextBox_console

local window_help
local scroll_help
local MouseOverTextBox_help

local window_settings
local tabbar_settings
local tabs_settings = {}

--local editbox_mapfolder
--local editbox_soundfolder
--local buttonimage_mapfolder
--local buttonimage_soundfolder

--local window_inspect
--local label_inspect



--local drag

----------------------------------------------------------------------------------------------------------------------
------------------------------------------------ CHILI SUBCLASSES ----------------------------------------------------
----------------------------------------------------------------------------------------------------------------------

local function DeclareClasses()

	------------------------------------------- filtered Drag & Drop Layout Panel ------------------------------------
	-- drag is controlled externally by chili and the widgets main module, this panel simply checks for mouse over status
	-- secondly, it asks child components for permission before selecting them 
	
	DragDropLayoutPanel = Chili.LayoutPanel:Inherit{
		classname = 'dragdroplayoutpanel',		
		IsMouseOver	= function(self, mx, my) 
			--Echo(mx.." - "..my)			
			local ca = self.parent.clientArea
			--if not ca then return nil end
			local x, y = self.parent:LocalToScreen(ca[1], ca[2])
			local w, h = ca[3], ca[4]
			--local x, y = self.parent:LocalToScreen(self.parent.x, self.parent.y)
			--local x, y = self:LocalToScreen(self.x, self.y)
			--local w, h = self.minHeight, self.minWidth
			--y = y + self.parent.padding[2]
			--h = h - self.parent.padding[4]
			--Echo(x.." : "..y)
			--return self.visible and (mx > x and mx < x + self.width) and (my > y and my < y + self.height) 
			return self.visible and (mx > x and mx < x + w) and (my > y and my < y + h) 
			--return self.visible and (mx > ca[1] and mx < ca[1] + ca[3]) and (my > ca[2] and my < ca[2] + ca[4]) 
		end,
		OnSelectItem = {
			function(self, index, state)								
				local c = self.children[index]				
				if c and c.AllowSelect then c:AllowSelect(index, state) end
			end,				
		},
		OnHide = function(...)
			inherited.OnHide(...)
			self.visible = false
		end,
	}
	
	
	------------------------------------------- Edit Box with optional Input Filter ----------------------------------
	-- also knows a few tricks:
	-- calls self:OnTab(), self:Discard(), self:Confirm() on tab, escape, enter 
	-- the latter of the 2 automatically remove focus
	
	
	FilterEditBox = Chili.EditBox:Inherit{
		classname = 'FilterEditBox',
		allowUnicode = true,
		cursorColor = {0,1.3,1,0.7},		
		--[[
		OnFocusUpdate = {
			function(self)
				self:Invalidate()
			end,	
		},--]]
		Update = function(self, ...)
			Chili.Control.Update(self, ...)
			if self.state.focused then
				self:RequestUpdate()
				if (os.clock() >= (self._nextCursorRedraw or -math.huge)) then
					self._nextCursorRedraw = os.clock() + 0.1 --10FPS
				end
			end	
			self:Invalidate()
		end,		
		KeyPress = function(self, key, mods, isRepeat, label, unicode, ...)
			local cp = self.cursor
			local txt = self.text
			if key == KEYSYMS.RETURN then
				if self.Confirm then self:Confirm() end
				self.state.focused = false
				screen0.focusedControl = nil
				return false
			elseif key == KEYSYMS.ESCAPE then				
				if self.Discard then self:Discard() end
				self.state.focused = false
				screen0.focusedControl = nil
				return false
			elseif key == KEYSYMS.BACKSPACE then --FIXME use Spring.GetKeyCode("backspace")
				self.text, self.cursor = unitools.Utf8BackspaceAt(txt, cp)
			elseif key == KEYSYMS.DELETE then
				self.text   = unitools.Utf8DeleteAt(txt, cp)
			elseif key == KEYSYMS.LEFT then
				self.cursor = unitools.Utf8PrevChar(txt, cp)
			elseif key == KEYSYMS.RIGHT then
				self.cursor = unitools.Utf8NextChar(txt, cp)
			elseif key == KEYSYMS.HOME then
				self.cursor = 1
			elseif key == KEYSYMS.END then
				self.cursor = #txt + 1
			elseif key == KEYSYMS.TAB then
				if self.OnTab then return self:OnTab() end				
			else
				local utf8char = unitools.UnicodeToUtf8(unicode)
				if (not self.allowUnicode) then
					local success
					success, utf8char = pcall(string.char, unicode)
					if success then
						success = not utf8char:find("%c")
					end
					if (not success) then
						utf8char = nil
					end
				end

				if utf8char then
					self.text = txt:sub(1, cp - 1) .. utf8char .. txt:sub(cp, #txt)
					self.cursor = cp + utf8char:len()
				--else
				--	return false
				end
				
			end
			self._interactedTime = widget.Spring.GetTimer()
			--inherited.KeyPress(self, key, mods, isRepeat, label, unicode, ...)
			self:UpdateLayout()
			self:Invalidate()
			return self
		end,		
		TextInput = function(self, utf8char, ...)			
			local unicode = utf8char
			if (not self.allowUnicode) then
				local success
				success, unicode = widget.pcall(string.char, utf8char)
				if success then
					success = not unicode:find("%c")
				end
				if (not success) then
					unicode = nil
				end
			end

			if unicode and not self.InputFilter or self.InputFilter(unicode) then
				local cp  = self.cursor
				local txt = self.text
				self.text = txt:sub(1, cp - 1) .. unicode .. txt:sub(cp, #txt)
				self.cursor = cp + unicode:len()
			--else
			--	return false
			end

			self._interactedTime = widget.Spring.GetTimer()
			--self.inherited.TextInput(utf8char, ...)
			self:UpdateLayout()
			self:Invalidate()
			return self
		end,
	}
	
	
	------------------------------------------- Text Box with Tooltip Support --------------------------------------------
	MouseOverTextBox = Chili.TextBox:Inherit{
		classname = "mouseovertextbox",
		HitTest = function(self, x,y)
			return self
		end,
	}
	
	
	------------------------------------------- Text Box with Button Functionality ---------------------------------
	ClickyTextBox = MouseOverTextBox:Inherit{
		classname = 'clickytextbox',		
		MouseDown = function(self,...)
		  local btn = select(3,...)
		  Echo(btn)		  
		  if not btn == 3 then return nil end
		  self.state.pressed = true
		  self.inherited.MouseDown(self, ...)
		  self:Invalidate()
		  return self
		end,
		MouseUp = function(self,...)
		  local btn = select(3,...)
		  Echo(btn)		  
		  if not btn == 3 then return nil end
		  if (self.state.pressed) then
			self.state.pressed = false
			self.inherited.MouseUp(self, ...)
			self:Invalidate()
			return self
		  end
		end,
	}
	
	
	------------------------------------------- Custom Draw Control Image --------------------------------------------
	gl_AnimatedImage = Chili.Control:Inherit{
		classname = 'gl_animatedimage',
		defaultWidth  = 64,
		defaultHeight = 64,
		padding = {0,0,0,0},
		color = {1,1,1,1},		
		keepAspect = true;
		OnClick  = {},
		this = gl_AnimatedImage,
		IsActive = function(self)
			local onclick = self.OnClick
			if (onclick and onclick[1]) then
				return true
			end
		end,
		HitTest = function(self)
			return self:IsActive() and self
		end,
		MouseDown = function(self, ...)		
			return Control.MouseDown(self, ...) or self:IsActive() and self
		end,
		MouseUp = function(self, ...)
			return Control.MouseUp(self, ...) or self:IsActive() and self
		end,
		MouseClick = function(self, ...)
			return Control.MouseClick(self, ...) or self:IsActive() and self
		end,
	}
	
	
	-------------------------------------------- Generic Window with MouseOver Hook ----------------------------------
	-- these windows will be used to prevent mouse events from passing through them into world space
	-- 
	
	MouseOverWindow = Chili.Window:Inherit{
		classname = 'mouseoverwindow',		
		IsMouseOver	= function(self, mx, my) 						
			local x, y = self.x, self.y -- for some odd reason LocalToScreen() breaks window coordinates			
			return self.visible and (mx > x and mx < x + self.width) and (my > y and my < y + self.height) 
		end,
	}	
	

	-------------------------------------------- Instanced Prototype-based Window ------------------------------------
	-- 
	
	InstancedWindow = MouseOverWindow:Inherit{
		classname = 'instancedwindow',
		New = function(self, obj) -- not sure if needed
			self.inherited.New(self, obj)
			return obj
		end,
		Inherit = function(self, class)			
			class = self.inherited:Inherit(class)
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
		end,
	}
	
	
	-------------------------------------------- Emitter Inspection Window Prototype ------------------------------------
	
	EmitterInspectionWindow = InstancedWindow:Inherit{
		classname = 'emitterinspectionwindow',
		New = function(self, key)
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
				clientWidth = 300,
				clientHeight = 250,
				--maxWidth = 300,
				minWidth = 292,
				minHeight = 160,
				orientation = 'vertical',				
				selectable = false,		
				multiSelect = false,
				itemPadding = {6,2,6,2},
				itemMargin = {0,0,0,0},
				autosize = true,
				align = 'left',
				columns = 4,
				left = 0,
				centerItems = false,
				list = {},
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
							local txt = colors.yellow_09:Code()..string.sub(iname, 0, endprefix)
								..colors.white_1:Code()..string.sub(iname, endprefix + 1)
							list[iname].label = MouseOverTextBox:New{
								refer = iname,
								width = obj.width - 140,
								parent = self,
								align = 'left',
								text = txt,
								fontsize = 10,
								textColor = colors.white_09,
								backgroundColor = colors.grey_02,
								borderColor = colors.grey_03,
								padding = {0, 6, 0, 0},
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
		end,
	}		
end

	

----------------------------------------------------------------------------------------------------------------------
--------------------------------------------------- GUI CONTROLS -----------------------------------------------------
----------------------------------------------------------------------------------------------------------------------


local function DeclareControls()
	---------------------------------------------------- main frame ------------------------------------------------
	
	window_main = MouseOverWindow:New {
		x = -336,
		y = 70,	
		dockable = false,
		parent = screen0,
		caption = "Ambient Sound Editor",
		textColor = colors.grey_08,
		draggable = true,
		resizable = false,
		dragUseGrip = true,
		clientWidth = 310,
		clientHeight = 480,		
	}	
	tabbar_main = TabBar:New {
		parent = window_main,
		x = 10,
		y = 20,
		clientWidth = 260,
		clientHeight = 20,		
		--textColor = {0.7,0.7,0.7,1},
		tabs = {
			[1] = 'Templates',
			[2] = 'Emitters',
			[3] = 'Files',
		},
		panels = {},
		OnChange = { 
			function(self, tab)		
				--Echo("onchange "..tostring(tab))
				if not self.panels[tab] then return false end
				for k, params in pairs(self.panels) do 					
					--local hidden = params.hidden -- fuck you, chili
					if not params.hidden then 
						self.panels[k]:SetVisibility(false)
						self.panels[k].layout.visible = false
					end
				end
				self.panels[tab]:SetVisibility(true)
				self.panels[tab].layout.visible = true	
				--Echo("setV")
				for i = 1, #self.children do
					local c = self.children[i]
					if c.caption == tab then
						c.font:SetColor(colors.green_1)
						c.backgroundColor = colors.grey_02 --{0.35,0.35,0.35,0.5}
						c.borderColor = colors.blue_579_6
						--c.borderColor = colors.grey_05 --{0.5,0.5,0.5,0.5}
						--c:Invalidate()
					else 
						c.font:SetColor(colors.grey_08)
						c.backgroundColor = colors.grey_01 --{0.2,0.2,0.2,0.5}
						c.borderColor = colors.blue_579_4
						--c.borderColor = colors.grey_03_04 --{0.3,0.3,0.3,0.4}
						--c:Invalidate()						
					end
				end				
			end
		},
	}
	--Echo("done core")
	local panels = tabbar_main.panels
	for i = 1, #tabbar_main.children do
		local c = tabbar_main.children[i]
		c.font:SetColor(colors.grey_08)
		c.borderColor = colors.blue_579_4
		--c.borderColor = colors.grey_03_04
		c.backgroundColor = colors.grey_01		
	end
	
	scroll_main_templates = ScrollPanel:New {
		x = 0,
		y = 40,
		clientWidth = 300,
		clientHeight = 360,
		parent = window_main,
		scrollPosX = -16,
		verticalSmartScroll = true,	
		scrollbarSize = 6,
		padding = {5,10,5,10},		
	}
	panels.Templates = scroll_main_templates
	layout_main_templates = DragDropLayoutPanel:New {		
		name = 'tracklist',
		parent = scroll_main_templates,
		orientation = 'vertical',		
		selectable = true,		
		multiSelect = true,
		maxWidth = 290,
		minWidth = 290,
		minHeight = 360,
		itemPadding = {6,2,6,2},
		itemMargin = {0,0,0,0},
		autosize = true,
		align = 'left',
		columns = 4,
		left = 0,
		centerItems = false,		
	}
	panels.Templates.layout = layout_main_templates
	scroll_main_emitters = ScrollPanel:New {
		x = 0,
		y = 40,
		clientWidth = 300,
		clientHeight = 360,
		parent = window_main,
		scrollPosX = -16,
		verticalSmartScroll = true,	
		scrollbarSize = 6,
		padding = {5,10,5,10},		
	}
	panels.Emitters = scroll_main_emitters
	layout_main_emitters = DragDropLayoutPanel:New {		
		name = 'emitters list',
		parent = scroll_main_emitters,
		orientation = 'vertical',		
		selectable = false,		
		multiSelect = false,
		maxWidth = 290,
		minWidth = 290,
		minHeight = 360,
		itemPadding = {6,2,6,2},
		itemMargin = {0,0,0,0},
		autosize = true,
		align = 'left',
		columns = 2,
		left = 0,
		centerItems = false,
	}
	panels.Emitters.layout = layout_main_emitters	
	scroll_main_files = ScrollPanel:New {
		x = 0,
		y = 40,
		clientWidth = 300,
		clientHeight = 360,
		parent = window_main,
		scrollPosX = -16,
		verticalSmartScroll = true,	
		scrollbarSize = 6,
		padding = {5,10,5,10},
	}
	panels.Files = scroll_main_files
	layout_main_files = DragDropLayoutPanel:New {		
		name = 'files list',
		parent = scroll_main_files,
		orientation = 'vertical',		
		selectable = true,		
		multiSelect = true,
		maxWidth = 290,
		minWidth = 290,
		minHeight = 360,
		itemPadding = {6,2,6,2},
		itemMargin = {0,0,0,0},
		autosize = true,
		align = 'left',
		columns = 4,
		left = 0,
		centerItems = false,
	}
	panels.Files.layout = layout_main_files
	tabbar_main:Select("Templates")

			
	button_emitters = Button:New {
		x = 10,
		y = -52,
		parent = window_main,		
		-- tooltip = colors.green_1:Code()..'spawn new emitter and place it on the map, cancel with '..colors.blue_579:Code()..'ESC'..colors.green_1:Code()..' or '..colors.blue_579:Code()..'right-click'..colors.green_1:Code()..'\n\npress shift and turn the mousewheel to adjust height(use shift + ctrl/alt make it go faster/slower)\n\nyou can also do this later: hover over an emitter on the map, press shift and any of the modkeys and turn the mousewheel\n\nyou can drag around emitters on the map with left-drag. inspect them with right-click',
		tooltip = colors.green_1:Code()..'spawn new emitter and place it on the map, cancel with '..colors.blue_579:Code()..'ESC'..colors.green_1:Code()..' or '..colors.blue_579:Code()..'right-click'..colors.green_1:Code()..'.\n\npress '..colors.blue_579:Code()..'SHIFT'..colors.green_1:Code()..' and turn the mousewheel to adjust height(use '..colors.blue_579:Code()..'SHIFT + CTRL/ALT'..colors.green_1:Code()..' to make it go faster/slower).\n\nyou can also do this later: hover over an emitter on the map, press '..colors.blue_579:Code()..'SHIFT'..colors.green_1:Code()..' and any of the modkeys and turn the mousewheel\n\nyou can drag around emitters on the map with '..colors.blue_579:Code()..'left-drag'..colors.green_1:Code()..'. inspect them with '..colors.blue_579:Code()..'right-click'..colors.green_1:Code()..'.',
		clientWidth = 30,
		clientHeight = 30,
		caption = '',
		OnClick = {function() 
			local drag = widget.GetDrag()
			if drag then
				drag._type.spawn = true
				drag.params.hoff = 0
				drag.started = true
				-- nothing else needed at this point.
			end			
		end,
		},
	}
	button_emitters_anim = gl_AnimatedImage:New {
		parent = button_emitters,
		width = "100%",
		height = "100%",
		DrawControl = function(self, ...)	
			if self.parent.state.hovered or self.state.hovered then
				DrawIcons(self.x + self.width / 2, self.y + self.height / 2, self.width /2.5, self.height/2.5, self.width/2.5, true)
			else
				DrawIcons(self.x + self.width / 2, self.y + self.height / 2, self.width /2.5, self.height/2.5, self.width/2.5)
			end
			
		end,
	}
	button_help = Button:New {
		x = -32,
		y = -32,
		parent = window_main,		
		tooltip = 'Help',
		clientWidth = 12,
		clientHeight = 12,
		caption = '',
		OnClick = {function() window_help:ToggleVisibility() end},
		children = {
			Image:New {
				width = "100%",
				height = "100%",				
				file = icons.HELP_ICON,
			},
		}
	}
	
	button_settings = Button:New {
		x = -74,
		y = -32,
		parent = window_main,		
		tooltip = 'Settings',
		clientWidth = 12,
		clientHeight = 12,
		caption = '',
		OnClick = {function() --< it is kinda hidden away here but should do.
			for c, params in pairs(controls.settings) do 
				if params.value then 
					params:SetValue(params.refer.value)
					params:Invalidate()
				end
				
			end
			window_settings:ToggleVisibility() 
		end},
		children = {
			Image:New {
				width = "100%",
				height = "100%",				
				file = icons.SETTINGS_ICON,
			}
		}	
	}
	button_save = Button:New {
		x = -116,
		y = -32,
		parent = window_main,		
		tooltip = 'Save Map Config',
		caption = '',
		--[[
		clientWidth = 20,
		clientHeight = 20,		
		padding = {6,6,6,6,},
		--]]
		clientWidth = 16,
		clientHeight = 16,		
		padding = {8,8,8,8,},
		
		OnClick = {function() --< it is kinda hidden away here but should do.
			i_o.SaveAll()
		end},
		children = {
			Image:New {
				width = "100%",
				height = "100%",				
				file = icons.SAVE_ICON,
			}
		}	
	}
	button_load = Button:New {
		x = -158,
		y = -32,
		parent = window_main,		
		tooltip = 'Load Sound Files',
		caption = '',
		--[[
		clientWidth = 20,
		clientHeight = 20,		
		padding = {6,6,6,6,},
		--]]
		clientWidth = 16,
		clientHeight = 16,		
		padding = {8,8,8,8,},
		
		OnClick = {function() --< it is kinda hidden away here but should do.
			window_browser:ToggleVisibility()
			if window_browser.visible then 
				controls.browser.label_path.text = (config.path_map or '')..config.path_sound
				controls.browser.layout_files:Refresh() 
				--controls.browser.layout_files.list.home_img.tooltip = 
				--	'spring home directory:\n\n\255\255\255\0'..(config.path_spring or '')..'\255\255\255\255'
			end
		end},
		children = {
			Image:New {
				width = "100%",
				height = "100%",				
				file = icons.LOAD_ICON,
			}
		}	
	}
	button_console = Button:New {
		x = -200,
		y = -32,
		parent = window_main,		
		tooltip = 'Message Log',
		clientWidth = 12,
		clientHeight = 12,
		caption = '',
		OnClick = {function() window_console:ToggleVisibility() end},
		children = {
			Image:New {
				width = "100%",
				height = "100%",				
				file = icons.CONSOLE_ICON,
			},
		}
	}	
	button_show = Button:New {
		x = -50,
		y = 130,
		parent = screen0,
		tooltip = 'Open APE Main Window',
		clientWidth = 30,
		clientHeight = 30,
		caption = '',
		OnClick = {function(self) 
				self:Hide()
				window_main:Show()
				window_main:Invalidate()
			end,
		},
	}
	button_show_anim = gl_AnimatedImage:New {
		parent = button_show,
		width = "100%",
		height = "100%",
		DrawControl = function(self, ...)	
			if self.parent.state.hovered or self.state.hovered then
				DrawIcons(self.x + self.width / 2, self.y + self.height / 2, self.width /2.5, self.height/2.5, self.width/2.5, true)
			else
				DrawIcons(self.x + self.width / 2, self.y + self.height / 2, self.width /2.5, self.height/2.5, self.width/2.5)
			end
			
		end,
	}	
	button_minimize = Button:New {
		x = -36,
		y = 0,
		parent = window_main,		
		tooltip = 'Close Window',
		clientWidth = 12,
		clientHeight = 12,
		caption = '',
		OnClick = {function(self) 
				window_main:Hide() 
				button_show:Show()
			end,
		},
		children = {
			Image:New {
				width = "100%",
				height = "100%",
				file = icons.CLOSE_ICON,
			},
		}
	}		
	
	window_main:Hide()
	containers.main = window_main
	containers.tracklist = layout_main_templates
	containers.emitterslist = layout_main_emitters
	containers.fileslist = layout_main_files
			
	---------------------------------------------------- log window ------------------------------------------------	
	window_console = MouseOverWindow:New {
		x = "25%",
		y = "5%",
		parent = screen0,
		caption = "Message Log",
		textColor = colors.grey_08,
		draggable = true,
		resizable = false,
		dragUseGrip = true,
		clientWidth = 600,
		clientHeight = 140,						
	}
	scroll_console = ScrollPanel:New {
		x = 0,
		y = 12,
		clientWidth = 600,
		clientHeight = 126,
		parent = window_console,
		scrollPosX = -16,
		horizontalScrollbar = false,
		verticalScrollbar = true,
		verticalSmartScroll = true,	
		scrollbarSize = 6,
		resizable = true,
		autosize = true,
	}
	MouseOverTextBox_console = MouseOverTextBox:New {
		x = 4,
		y = 0,
		autosize = true,
		parent = scroll_console,
		align = 'left',
		textColor = colors.yellow_09,
		textColorNormal = colors.yellow_09,
		textColorError = colors.red_1, -- not happening right now
		backgroundColor = colors.grey_02,
		borderColor = colors.grey_03,
		text = '',	
	}
	
	containers.console = window_console
	controls.log = MouseOverTextBox_console
	
	---------------------------------------------------- help window ------------------------------------------------

	window_help = MouseOverWindow:New {
		x = "20%",
		y = "7%",
		parent = screen0,
		caption = "Help",
		draggable = true,
		resizable = false,
		dragUseGrip = true,
		clientWidth = 400,
		clientHeight = 490,
		--backgroundColor = colors.grey_08,
		
	}
	scroll_help = ScrollPanel:New {
		x = 0,
		y = 12,
		clientWidth = 400,
		clientHeight = 384,
		parent = window_help,
		scrollPosX = -16,
		horizontalScrollbar = false,
		verticalScrollbar = true,
		verticalSmartScroll = true,	
		scrollbarSize = 6,
		resizable = true,
		autosize = true,
	}
	MouseOverTextBox_help = MouseOverTextBox:New {
		x = 4,
		y = 0,
		autosize = true,
		parent = scroll_help,
		align = 'left',
		textColor = colors.grey_08,
		backgroundColor = colors.grey_02,
		borderColor = colors.grey_03,
		text = HELPTEXT,
	}
	window_help:Hide()
	containers.help = window_help
	
	---------------------------------------------------- properties window ------------------------------------------------
	
		--[[
		file = "",
	gain = 1.0,
	pitch = 1.0,
	pitchMod = 0.0,
	gainMod = 0.05,
	priority = 0,
	maxconcurrent = 2, 
	maxdist = 1000000, -- +inf and math.huge break shit
	preload = true,
	in3d = true,
	rolloff = 0, -- not a good default
	dopplerscale = 0,
	-- widget stats
	length_real = 0,
	rnd = 0,
	length_loop = 1, -- length_loop is added? to the length on every loop...
	delay = 1, -- ...while delay just gets used once at start of game
	--]]	
	
	local props = {"length_real", "length_loop", "delay", "rnd", 
	"priority", "maxconcurrent", "maxdist", "rolloff", 
	"gain", "gainMod", "pitch", "pitchMod", "dopplerscale"}
	local tooltips = {
[[actual length of the track in seconds.

currently the widget is unable to obtain that information from the file, you may want to edit this manually.
 
some of the functionality of the player/editor requires this to be know, but it is not strictly necessary.

defaults to 1, unit is seconds]],
		
[[how many seconds have to pass before this sound will start playing again after playback has started. this may be longer or shorter than the actual length of the track.

note that setting this to 0 or very low values may produce undesireable results.		

note also that the number of simultaneous playbacks of the track is limited by the maxconcurrent setting.
		
defaults to length_real, unit is seconds]].."\n\n"..colors.orange_06:Code().."(this has nothing to do with the \"looptime\" option that spring sounditems can use. this widget never uses that and if you use it for any of the sounditems used by the widget, things will likely break.)"..colors.white_1:Code(),

[[time in seconds after game starts this sound may play for the very first time. does nothing otherwise.

defaults to 0, unit is seconds]],

[[this sound will on average play once this many seconds. 

1 means it will immediately play when its timer(length_loop) has reached zero,
0 means "never".

defaults to 0]],
		
[[how relevant this sound is compared to other sounds in the game. lower means less, values can be negative.

if there are too many sounds happening at once, less important ones will be pushed off the cliff.

you may want to keep looped sounds such as wind, water etc. at a relativly high priority. 

defaults to 0]],

[[how many simultaneous playbacks of this sound are allowed.

note that this is controlled by the engine and as such is independent from the length_real setting.

defaults to 2]],

[[if the camera is farther away from the location of playback than this, the sound will not be played at all.

consequently, when you are out of this range when the playback would start but later move close enough, you will not hear the sound.

similarly, if you leave the area later after the playback has started, it will not stop (albeit possibly become inaudible)

defaults to 100000, unit is elmos]].."\n\n"..colors.orange_06:Code().."(the side length of a 1x1 map square is 512 elmos.)"..colors.white_1:Code(),

[[how quickly the sound diminishes as you move further away from the source. 

higher means faster, values above 1.0 make the sound fade very, very quickly.

as opposed to maxdist, this will affect the loudness of the sounds while it is being played.

notice that currently the engine makes all sounds audible while zoomed out to the maximum.

defaults to 0]],		

[[loudness of the sound. 

defaults to 1]],
[[variation of loudness between individual playbacks. 

defaults to 0.05]],

[[speed of playback. 

defaults to 1]],

[[variation of speed between individual playbacks. 

defaults to 0]],

[[how much doppler effect should be applied to this sound for fast camera movements.

defaults to 0]],
	}
	
	controls.properties = {}
	
	window_properties = MouseOverWindow:New {
		x = "25%",
		y = "25%",
		parent = screen0,
		caption = "Properties",
		textColor = colors.grey_08,
		draggable = true,
		resizable = false,
		dragUseGrip = true,
		clientWidth = 400,
		clientHeight = 216,
		--backgroundColor = colors.grey_08,	
		controls_props = {},
	}
	controls.properties.file = MouseOverTextBox:New {
		textColor = colors.green_1,
		y = 16,
		x = 12,
		padding = {0,4,0,0},
		clientWidth = 380,
		clientHeight = 20,
		parent = window_properties,		
		text = '',
		fontSize = 10,
		tooltip = [[filename and path. notice that this can be an absolute path on your computer, but it needs to be a relative path inside the spring virtual file system (eg. '/maps/mymap.sdd/luaui/sounds/somesoundfile.ogg') if you want to distribute it.]],					
	}			
	local label_height = math.floor(controls.properties.file.font:GetTextWidth(controls.properties.file.text)/380) * 10

	layout_properties = LayoutPanel:New {		
		y = 32 + label_height,
		--name = 'layout',
		parent = window_properties,
		orientation = 'vertical',		
		selectable = false,		
		multiSelect = false,
		maxWidth = 400,
		minWidth = 400,
		itemPadding = {6,2,6,2},
		itemMargin = {0,0,0,0},
		autosize = true,
		align = 'left',
		columns = 6,
		left = 0,					
		centerItems = false,
		Refresh = function(self)
			local label_height = math.floor(controls.properties.file.font:GetTextWidth(controls.properties.file.text)/380) * 10
			self.y = 32 + label_height
			self:Invalidate()
		end,
	}
	
	for i, prop in ipairs(props) do					
		MouseOverTextBox:New { 
			--refer = i,			
			padding = {0,4,0,0},
			clientWidth = 80,
			parent = layout_properties,
			text = prop,
			fontSize = 11,
			tooltip = tooltips[i],		
		}
		controls.properties[i] =  FilterEditBox:New { 
			refer = prop,					
			refer2 = i,
			clientWidth = 44,
			clientHeight = 16,
			padding = {4,0,4,0},
			backgroundColor = {.1,.1,.1,.5},
			borderColor = {.3,.3,.3,.3},
			borderColor2 = {.4,.4,.4,.4},
			x = 10,
			parent = layout_properties,
			text = '', --type(item[prop] == 'number') and tostring(item[prop]) or 'default',
			fontSize = 10,
			InputFilter = function(unicode)
				return tonumber(unicode) or unicode == '.'
			end,
			OnTab = function(self)
				local target = controls.properties[(self.refer2 == #props and 1 or self.refer2 + 1)]
				self.state.focused = false
				target.state.focused = true
				screen0.focusedControl = target			
			end,
		}
		Image:New {					
			refer = i,
			parent = layout_properties,
			file = icons.COGWHEEL_ICON,
			margin = {0,0,10,0},
			width = 14,
			height = 14,
			tooltip = 'restore default/template value',
			color = {1,.9,.7,1}, --
			OnClick = {
				function(self,...)
					local v = window_properties.defaultItem[props[self.refer]]
					controls.properties[self.refer].text = type(v) == 'number' and tostring(v) or 'default'					
				end
			},
		}					
	end	
	controls.properties[0] = Checkbox:New {	
		parent = window_properties,					
		y = 182 + label_height,
		x = 12,
		width = 50,					
		--checked = true, --item.in3d,
		caption = "in3d",
		tooltip = 'exact effect unknown, presumably is required for sounds to be played locational.',
		fontSize = 11,
		padding = {0,4,0,10},			
		Refresh = function(self)
			local label_height = math.floor(controls.properties.file.font:GetTextWidth(controls.properties.file.text)/380) * 10
			self.y = 182 + label_height
			self:Invalidate()
		end,
	}	
	controls.properties.in3d_defaultBtn = Image:New {					
		--refer = i,
		parent = window_properties,
		file = icons.COGWHEEL_ICON,
		y = 184 + label_height,
		x = 70,
		width = 14,
		height = 14,
		tooltip = 'restore default/template value',
		color = {1,.9,.7,1}, --
		OnClick = {
			function(self,...)
				local v = window_properties.defaultItem.in3d
				if not controls.properties[0].checked == v then controls.properties[0]:Toggle() end
			end		
		},
		Refresh = function(self)
			local label_height = math.floor(controls.properties.file.font:GetTextWidth(controls.properties.file.text)/380) * 10
			self.y = 184 + label_height
			self:Invalidate()
		end,			
	}
	-- local button_discard = Image:New {
	Image:New {
		parent = window_properties,
		file = icons.CLOSE_ICON,
		x = 315,
		y = -30,
		width = 20,
		height = 20,
		tooltip = 'discard changes',
		color = {0.8,0.3,0.1,0.7}, --
		OnClick = {
			function(self,...)
				self.parent:Discard()
			end
		},					
	}	
	-- local button_confirm = Image:New {
	Image:New {
		parent = window_properties,
		file = icons.CONFIRM_ICON,
		x = 350,
		y = -30,
		width = 20,
		height = 20,
		tooltip = 'save changes',		
		OnClick = {
			function(self,...)
				self.parent:Confirm()
			end
		},					
	}

	
	
	
	window_properties:Hide()
	containers.properties = window_properties
	
	---------------------------------------------------- browser window ------------------------------------------------
	
	controls.browser = {}
	
	window_browser = MouseOverWindow:New {
		x = "25%",
		y = "25%",
		parent = screen0,
		caption = "Load Sound Files",
		textColor = colors.grey_08,
		draggable = true,
		resizable = false,
		dragUseGrip = true,
		clientWidth = 600,
		clientHeight = 400,
		autosize = false,
		--[[
		Refresh = function(self, ...) 
			controls.browser.layout_files:Refresh()
			local list = controls.browser.layout_templates.children
			for i = 1, #list do
				list[i]:Dispose()			
			end
			self:Invalidate()
		end,--]]
		Confirm = function(self)
			local templates = {}
			local errors = 0
			local n = 0
			for k, v in pairs(controls.browser.layout_templates.list) do
				n = n + 1
				local success
				if settings.browser.autoLocalize then
					success = i_o.BinaryCopy(k, config.path_map..config.path_sound..v.box.refer2)					
				end
				if success then
					templates[v.box.text] = {
						file = k, 
						file_local = config.path_map..config.path_sound..v.box.refer2
					}
				else
					if settings.browser.autoLocalize then Echo("failed to localize file:"..k) end
					templates[v.box.text] = {file = k,}
				end
				if sounditems.templates[v.box.text] then
					Echo("a template with the name "..v.box.text.." already exists, skipping...")
					templates[v.box.text] = nil
					success = false
				else 
					sounditems.templates[v.box.text] = templates[v.box.text]
					v.box:Dispose()
					v.button:Dispose()
					controls.browser.layout_templates.list[k] = nil
					controls.browser.layout_templates:Invalidate() -- this works?				
				end
				errors = success and errors or errors + 1
			end
			if settings.browser.autoLocalize then
				Echo("copied "..n.." files, "..errors.." errors")			
			end		
			Echo("generated "..n.." templates")
			i_o:ReloadSoundDefs()	
		end,
	}
	controls.browser.button_userpath = Image:New{
		parent = window_browser,
		file = icons.NEWFOLDER_ICON,
		x = 25,
		y = 18,
		width = 18,
		height = 18,
		tooltip = 'install a permanent link to this folder that will be stored in the editor configuration.\n\nuse this to remember the location of your sound collection, drive letters, mounts, etc...',
		OnClick = {
			function(self, ...)
				local btn = select(3,...)
				if btn == 1 then
					local legit = #VFS.SubDirs(controls.browser.label_path.text) > 0 
						or #VFS.DirList(controls.browser.label_path.text) > 0		
					controls.browser.label_path.legit = legit
					controls.browser.label_path.font:SetColor(legit and colors.green_1 or colors.red_1)	
					if legit and not settings.paths[controls.browser.label_path.text] then
						-- we storing a double reference for this, so we can both use indizes and lookup by name
						-- we cant just use pairs later because an options table contains all kinds of crap
						settings.paths[controls.browser.label_path.text] = true
						settings.paths[#settings.paths + 1] = controls.browser.label_path.text
						controls.browser.layout_files:Refresh()
					end
				end
			end,
		},		
	}
	
	controls.browser.label_path = FilterEditBox:New {
		parent = window_browser,
		x = 47,
		y = 16,
		clientWidth = 522,	
		draggable = false,
		resiziable = false,
		fontsize = 10,
		backgroundColor = {.1,.1,.1,.5},
		borderColor = {.4,.4,.4,.5},
		--textColor = {.8,.8,.8,.9},
		textColor = colors.green_1,
		text = '',
		legit = true,	
		Confirm = function(self,...) -- this probably triggers when its changed externally?			
			--self.text = #self.text < 1 and './' or self.text			
			--if not string.sub(self.text, -1) == '/' then self.text = self.text..'/' end
			controls.browser.layout_files.path = self.text
			self.legit = controls.browser.layout_files:Refresh()
			self.font:SetColor(self.legit and colors.green_1 or colors.red_1)
			--local dirs, files	= VFS.SubDirs(self.text), VFS.DirList(self.text)
			--if #dirs > 0 or #files > 0 then controls.browser.layout_files.path = self.text end			
		end,
		Discard = function(self,...)
			self.text = controls.browser.layout_files.path
		end,
	}	
	controls.browser.scroll_files = ScrollPanel:New {
		parent = window_browser,
		x = 25,
		y = 45,			
		padding = {5,5,5,5},
		clientWidth = 240,
		clientHeight = 290,
		scrollPosX = -16,
		verticalSmartScroll = true,	
		scrollbarSize = 6,		
	}	
	controls.browser.layout_files = DragDropLayoutPanel:New {
		parent = controls.browser.scroll_files,
		minWidth = 230,
		--maxWidth = 230,
		--clientWidth = 250,
		--clientHeight = 300,
		autosize = true,
		resizable = false,
		draggable = false,
		centerItems = false,
		selectable = true,
		multiSelect = true,
		align = 'left',
		columns = 2,
		itemPadding = {3,2,3,2},
		itemMargin = {0,0,0,0},
		list = {},		
		Refresh = function(self)
			self.path = self.path or config.path_map..config.path_sound			
			--Echo("path is: "..self.path)
			--self.list = self.list or {}
			local list = self.list
			for i = 1, #list do
				--Echo("disposing of index "..i)
				list[i]:Dispose()
				list[i]:Invalidate()
				list[i] = nil
			end	
			
			for i, v in ipairs(settings.paths) do
				if type(v) == 'string' then
					Echo("adding link: "..i.." : "..v)
					local label
					list[#list + 1] = Image:New {
						parent = controls.browser.layout_files,
						file = icons.NEWFOLDER_ICON,
						width = 12,
						height = 12,					
						tooltip = 'right click to remove',
						refer = v,
						OnClick = {
							function(self, ...)
								local btn = select(3,...)
								if btn == 1 then
									self.parent.path = self.refer
									self.parent:Refresh()					
									controls.browser.label_path:SetText(self.refer)
								elseif btn == 3 then													
									settings.paths[v] = nil
									table.remove(settings.paths, i)
									self.parent:Refresh()
								end
							end,
						},
					}		 
					list[#list + 1] = ClickyTextBox:New {
						parent = controls.browser.layout_files,
						clientWidth = 500, --226,	
						fontsize = 10,					
						textColor = {.8,.8,.8,.9},
						refer = v,
						text = v, --string.upper(k),
						OnClick = {function(self,...)
							local btn = select(3,...)
							if btn == 1 then
								self.parent.path = self.refer
								self.parent:Refresh()					
								controls.browser.label_path:SetText(self.refer)
							end
						end,
						},			
					}
				end
			end	
			
			--controls.browser.layout_files.list.home_img = Image:New {
			list[#list + 1] = Image:New { 
				parent = controls.browser.layout_files,
				file = icons.SPRING_ICON,
				width = 12,
				height = 12,
				tooltip = 'the spring home directory.\n\nthis path is the real location of your spring engine and is not to be confused with the vfs root directory.\n\n'
				..'\255\255\255\0'..(config.path_spring or '')..'\255\255\255\255',
				OnClick = {
					function(self, ...)
						local btn = select(3,...)
						if btn == 1 then
							self.parent.path = config.path_spring or ''
							self.parent:Refresh()					
							controls.browser.label_path:SetText(config.path_spring or '')
						end
					end,
				},
			}
			--controls.browser.layout_files.list.home = ClickyTextBox:New {
			list[#list + 1] = ClickyTextBox:New {	
				parent = controls.browser.layout_files,
				clientWidth = 500, --226,	
				fontsize = 10,					
				textColor = {.8,.8,.8,.9},
				text = '$SPRING',
				OnClick = {function(self,...)
					local btn = select(3,...)
					if btn == 1 then
					self.parent.path = config.path_spring or ''
					self.parent:Refresh()					
					controls.browser.label_path:SetText(config.path_spring or '')
					end
				end,
				},			
			}		
			--controls.browser.layout_files.list.vfs_img = Image:New {
			list[#list + 1] = Image:New {			
				parent = controls.browser.layout_files,
				file = icons.SPRING_ICON,
				width = 12,
				height = 12,
				tooltip = 'root of the virtual file system. equals ".", "./", "/" and the empty string. \n\nwidgets can only write into the virtual file system, ie. subfolders of the spring directory.\n\nall write paths must be specified relative to the vfs root, not as absolute paths, eg. \n\n \255\255\255\0\'/sounds/ambient/\'\n\n\255\255\255\255instead of\n\n\255\255\255\0\'C:/someplace/.../sounds/ambient/\'\255\255\255\255\n\nnormally, the widget handles this process.\n\n\255\255\150\0if you find that you are unable to save into your working directory with this widget, try running spring with the --write-dir command line parameter pointing to the spring directory\255\255\255\255',
				OnClick = {
					function(self, ...)
						local btn = select(3,...)
						if btn == 1 then
							self.parent.path = ''
							self.parent:Refresh()					
							controls.browser.label_path:SetText('')					
						end
					end,
				},
			}
			--controls.browser.layout_files.list.vfs = ClickyTextBox:New {
			list[#list + 1] = ClickyTextBox:New {	
				parent = controls.browser.layout_files,
				clientWidth = 500, --226,	
				fontsize = 10,					
				textColor = {.8,.8,.8,.9},
				text = '$VFS_ROOT',			
				OnClick = {function(self,...)
					local btn = select(3,...)
					if btn == 1 then
						self.parent.path = ''
						self.parent:Refresh()					
						controls.browser.label_path:SetText('')					
					end
				end,
				},			
			}
			--controls.browser.layout_files.list.sound_img = ClickyTextBox:New {
			list[#list + 1] = Image:New {
				parent = controls.browser.layout_files,
				file = icons.MUSICFOLDER_ICON,
				width = 12,
				height = 12,
				tooltip = 'the ambient sound folder inside the map directory, inside the vfs.\n\nall sounds the player will be using in the finished map will be stored here.\n\n'..
					'\255\255\255\0$VFS_ROOT/'..config.path_map..config.path_sound..'\255\255\255\255',
				OnClick = {function(self,...)
					self.parent.path = config.path_map..config.path_sound
					self.parent:Refresh()					
					controls.browser.label_path:SetText(config.path_map..config.path_sound)
				end,
				},				
			}
			--controls.browser.layout_files.list.sound = ClickyTextBox:New {
			list[#list + 1] = ClickyTextBox:New {
				parent = controls.browser.layout_files,
				clientWidth = 500, --226,	
				fontsize = 10,					
				textColor = {.8,.8,.8,.9},
				text = '$MAP/sounds/ambient',				
				OnClick = {function(self,...)
					self.parent.path = config.path_map..config.path_sound
					self.parent:Refresh()					
					controls.browser.label_path:SetText(config.path_map..config.path_sound)
				end,
				},
			}			
			--controls.browser.layout_files.list.back_img = Image:New {
			list[#list + 1] = Image:New {
				parent = controls.browser.layout_files,
				file = icons.UNDO_ICON,
				width = 12,
				height = 12,					
			}
			--controls.browser.layout_files.list.back = ClickyTextBox:New {
			list[#list + 1] = ClickyTextBox:New {
				parent = controls.browser.layout_files,
				clientWidth = 500, --226,	
				fontsize = 10,					
				textColor = {.8,.8,.8,.9},
				text = '..',
				OnClick = {function(self,...)
					local btn = select(3,...)
					if btn == 1 then
						local path = self.parent.path
						if #path > 0 then
							local lastchar = string.sub(path, -1)
							if not (lastchar == '\/' or lastchar == '\\') then
								path = path..'\/'
							end					
							local a,b,remain = string.find(path, '[^\/\\]+[\/\\]$') -- "([^\/\\]+)$"
							--Echo(path)
							remain = string.sub(path, 1, a - 1)
							if remain then
								self.parent.path = remain
								self.parent:Refresh()					
								controls.browser.label_path:SetText(remain)
							end	
						end	
					end
				end,
				},
			}			
			--local filter = '*.wav
			local dirs, files = VFS.SubDirs(self.path), VFS.DirList(self.path)				
				
			for i = 1, #dirs do
				--Echo(dirs[i])
				local _,_,dirname = string.find(dirs[i], "([^\/\\]+)[\/\\]$")
				list[#list + 1] = Image:New {
					parent = self,
					file = icons.FOLDER_ICON,
					width = 12,
					height = 12,					
				} 
				list[#list + 1] = ClickyTextBox:New {
					parent = self,
					clientWidth = 500, --226,	
					fontsize = 10,					
					textColor = {.8,.8,.8,.9},
					fulltext = dirs[i],
					text = dirname,
					OnClick = {function(self,...)
						local btn = select(3,...)
						if btn == 1 then
							self.parent.path = self.fulltext
							if not self.parent:Refresh() then
								Echo("empty or corrupt path "..self.fulltext)								
							else								
								controls.browser.label_path:SetText(self.fulltext)
							end
						end
					end,					
					},
				}
			end					
			for i = 1, #files do
				--Echo(files[i])
				local ending = string.find(files[i], "ogg$") or string.find(files[i], "wav$")
				if ending or not settings.browser.showSoundsOnly then -- this could be an option				 
					local _,_,filename = string.find(files[i], "([^\/\\]+)$")
					list[#list + 1] = Image:New {
						parent = self,
						file = ending and icons.MUSIC_ICON or icons.FILE_ICON,
						width = 12,
						height = 12,					
					} 
					list[#list + 1] = MouseOverTextBox:New {
						parent = self,
						clientWidth = 500, --226,	
						fontsize = 10,						
						textColor = {.8,.8,.8,.9},
						textColorSelected = colors.green_1,
						textColorForbidden = colors.red_1,
						textColorNormal = {.8,.8,.8,.9},
						fulltext = files[i],
						text = filename,	
						AllowSelect = function(self, idx, select)							
							if select then 
								self.legit = ending
								self.font:SetColor(ending and self.textColorSelected or self.textColorForbidden)
							else 
								self.legit = nil
								self.font:SetColor(self.textColorNormal) 
							end
							self:Invalidate()
						end,						
					}
				end			
			end				
			self:Invalidate()
			return #dirs > 0 or #files > 0 -- will this be false for empty folders?
		end,
	}
	--controls.browser.layout_files.list = {}	
	
		
	
	controls.browser.scroll_templates = ScrollPanel:New {
		parent = window_browser,
		x = 325,
		y = 45,		
		padding = {5,5,5,5},
		clientWidth = 240,
		clientHeight = 290,
		scrollPosX = -16,
		verticalSmartScroll = true,	
		scrollbarSize = 6,
	}
	controls.browser.layout_templates = DragDropLayoutPanel:New {		
		parent = controls.browser.scroll_templates,
		minWidth = 230,
		maxWidth = 520,
		minHeight = 280,
		--clientWidth = 250,
		--clientHeight = 300,	
		autosize = true,
		resizable = false,
		draggable = false,	
		centerItems = false,
		orientation = 'vertical',
		align = 'left',
		columns = 2,
		itemPadding = {3,2,3,2},
		itemMargin = {0,0,0,0},
		list = {},	
		AddTemplates = function(self, items)
			Echo("call")
			if not items then return end
			local list = self.list
			Echo("adding templates")
			for i = 1, #items do
				if items[i].legit and not list[items[i].fulltext] then
					local ending = string.find(items[i].text, "%.ogg$") or string.find(items[i].text, "%.wav$")					
					local name = string.sub(items[i].text, 1, ending - 1)
					
					list[items[i].fulltext] = {
						button = Image:New {
							parent = controls.browser.layout_templates,
							file = icons.CLOSE_ICON,
							width = 12,
							height = 12,							
							tooltip = 'remove from selection',
							refer = items[i].fulltext,
							color = colors.red_1,
						},					
						box = FilterEditBox:New {
							parent = controls.browser.layout_templates,
							clientHeight = 12,
							clientWidth = 500, --226,	
							fontsize = 10,					
							borderColor = {.2,.2,.2,.5},
							borderColor2 = {.2,.2,.2,.5},
							backgroundColor = {.1,.1,.1,.5},
							padding = {2,0,2,0},
							textColor = {.8,.8,.8,.9},
							text = name,
							refer = items[i].fulltext,							
							refer2 = items[i].text,
							tooltip = items[i].fulltext,
							InputFilter = function(unicode)
								return string.find(unicode, "[%w_-]")								
							end,
						},
					}
				end
			end
			self:Invalidate()
		end,
	}
	-- local button_discard = Image:New {
	Image:New {
		parent = window_browser,
		file = icons.CLOSE_ICON,
		x = -90,
		y = -45,
		width = 20,
		height = 20,
		tooltip = 'cancel',
		color = {0.8,0.3,0.1,0.7}, --
		OnClick = {
			function(self,...)
				self.parent:Hide()
			end
		},					
	}	
	-- local button_confirm = Image:New {
	Image:New {
		parent = window_browser,
		file = icons.CONFIRM_ICON,
		x = -45,
		y = -45,
		width = 20,
		height = 20,
		tooltip = 'add templates',		
		OnClick = {
			function(self,...)
				self.parent:Confirm()
			end
		},					
	}	
	Checkbox:New {
		parent = window_browser,
		x = 25,
		y = -46,
		width = 180,
		height = 20,		
		fontsize = 10,
		textColor = colors.grey_08,
		checked = settings.browser.showSoundsOnly,
		caption = 'show sound files only (.wav/.ogg)',
		OnChange = {function(self, checked) 
				settings.browser.showSoundsOnly = checked
				controls.browser.layout_files:Refresh()
			end
		},	
	}
	Checkbox:New {
		parent = window_browser,
		x = -275,
		y = -46,
		width = 100,
		height = 20,		
		fontsize = 10,
		textColor = colors.grey_08,
		checked = settings.browser.autoLocalize,
		caption = 'autolocalize files',
		tooltip = 'when this is enabled, selected files will be automatically copied into your maps\' sound folder once your close this window.\n\nnote that internally, the old file & location will be used until the next time you run spring.\n\nthis process may take some time.',
		OnChange = {function(self, checked) 
				settings.browser.autoLocalize = checked
				--controls.browser.layout_files:Refresh()
			end
		},	
	}
	
	window_browser:Hide()
	containers.browser = window_browser
	
	---------------------------------------------------- settings window ------------------------------------------------
	window_settings = MouseOverWindow:New {
		x = "25%",
		y = "25%",
		parent = screen0,
		caption = "Settings",
		textColor = colors.grey_08,
		draggable = true,
		resizable = false,
		dragUseGrip = true,
		clientWidth = 440,
		clientHeight = 210,
		autosize = true,
		--backgroundColor = colors.grey_08,
	}
	tabbar_settings = TabBar:New {
		parent = window_settings,
		x = 10,
		y = 20,
		clientWidth = 430,
		clientHeight = 20,		
		--textColor = {0.7,0.7,0.7,1},
		tabs = {
			[1] = 'Player',
			[2] = 'Files',
			[3] = 'Display',
			[4] = 'Interface',
			[5] = 'Misc',
		},
		panels = {},
		OnChange = { -- this gets called once on setup, automatically, same for all controls down the line
			function(self, tab)		
				if not self.panels[tab] then return false end
				for k, params in pairs(self.panels) do 					
					local hidden = params.hidden -- fuck you, chili
					if not hidden then self.panels[k]:SetVisibility(false) end
				end
				self.panels[tab]:SetVisibility(true)				
				for i = 1, #self.children do
					local c = self.children[i]
					if c.caption == tab then
						c.backgroundColor = colors.grey_035 --{0.35,0.35,0.35,0.5}
						c.borderColor = colors.grey_05 --{0.5,0.5,0.5,0.5}
						--c:Invalidate()
					else 
						c.backgroundColor = colors.grey_02 --{0.2,0.2,0.2,0.5}
						c.borderColor = colors.grey_03_04 --{0.3,0.3,0.3,0.4}					
					end
				end				
			end
		},
	}
	--Echo("done core")
	local panels = tabbar_settings.panels
	
	for i = 1, #tabbar_settings.children do
		--Echo("child "..i)
		p = tabbar_settings.children[i]
		p.backgroundColor = colors.grey_02
		p.borderColor = colors.grey_03_04
		p.font:SetColor(colors.blue_07)		
		c = tabbar_settings.children[i].caption
		--Echo("..done", true)
		panels[c] = ScrollPanel:New {
			name = 'tab_'..c,			
			y = 42,
			clientWidth = 440,
			clientHeight = 205,
			maxWidth = 440,
			minWidth = 440,
			minHeight = 205,
			maxHeight = 205,
			height = 200,
			horizontalScrollbar = false,
			verticalScrollbar = true,
			scrollbarSize = 6,		
		}
		window_settings:AddChild(panels[c])
		panels[c].layout = LayoutPanel:New {
			name = 'layout_'..c,
			autosize = true, --?
			x = 10,
			y = 10,
			maxWidth = 440,
			minWidth = 440,
			itemPadding = {2,2,2,2},
			itemMargin = {0,0,0,0},
			parent = panels[c],
			orientation = 'vertical',
			centerItems = false,
			columns = 1,	
			align = 'left',			
		}
		--Echo (panels[c].name)
	end						

	containers.settings = window_settings
	--Echo("display")
	local data_display = {
		[1] = {name = 'Show Emitters'},
		[2] = {name = "Sphere Radius", min = 25, max = 100, step = 1},
		[3] = {name = "Red", min = 0.0,	max = 1, step = 0.05, doUpdate = true},
		[4] = {name = "Green", min = 0.0, max = 1, step = 0.05, doUpdate = true},
		[5] = {name = "Blue", min = 0.0, max = 1, step = 0.05, doUpdate = true},
		[6] = {name = "Alpha Sphere", min = 0.0, max = 1, step = 0.05, doUpdate = true},
		[7] = {name = "Alpha Rings", min = 0.0, max = 1, step = 0.05, doUpdate = true},
		[8] = {name = "Highlight factor", min = 0.1, max = 5, step = 0.05, doUpdate = true},
	}
				
	Checkbox:New{
		parent = panels['Display'].layout,
		width = 100,
		checked = settings.display[1],
		caption = data_display[1].name,
		fontSize = 11,		
		margin = {2,12,2,12},
		textColor = colors.grey_08,
		OnChange = {function(self, checked)
				settings.display[1] = checked
			end
		},
	}		

	for i = 2, #data_display do
		local o = data_display[i]
		local label = Label:New{
			parent = panels['Display'].layout,
			--caption = o.name..": "..settings.display[i],
			fontSize = 11,
			textColor = colors.grey_08,			
		}
		local trackbar = Trackbar:New {
			parent = panels['Display'].layout,			
			width = 200,			
			min = o.min,
			max = o.max,
			step = o.step,
			value = settings.display[i],
			OnChange = o.doUpdate 
				and	{function(self)	
						settings.display[i] = self.value
						local str = i > 2 and string.format("%0.2f", self.value) or self.value
						label:SetCaption(o.name..": "..str)
						UpdateMarkerList()
					end}
				or {function(self) 
						settings.display[i] = self.value
						local str = i > 2 and string.format("%0.2f", self.value) or self.value
						label:SetCaption(o.name..": "..str)
					end}
			,
		}
	end

	--Echo("interface")
	local data_interface = {
		[1] = {name = 'Emitter Selection Radius', min = 50, max = 500, step = 25},
		[2] = {name = "Drag Timer", min = 0, max = 2, step = 0.01},
		[3] = {name = "Tooltip Timer", min = 0, max = 2, step = 0.01},
	}
	
	for i = 1, #data_interface do
		local o = data_interface[i]
		local str = i > 1 and string.format("%0.2f", settings.interface[i]).." seconds"
			or string.format("%0.0f", settings.interface[i]).." elmos"
		local label = Label:New{
			parent = panels['Interface'].layout,			
			fontSize = 11,
			textColor = colors.grey_08,			
		}
		local trackbar = Trackbar:New {
			parent = panels['Interface'].layout,
			width = 200,			
			min = o.min,
			max = o.max,
			step = o.step,
			value = settings.interface[i],
			OnChange = {function(self) 
					settings.interface[i] = self.value
					local str = i > 1 and string.format("%0.2f", self.value).." seconds" 
						or string.format("%0.0f", self.value).." elmos"
					label:SetCaption(o.name..": "..str)					
					if i == 2 then widget.GetDrag().timer = self.value end						
				end
			},
		}
	end
	
	-- autogenerate map folder / map subfolders?
	-- autolocalize files that are witihin the vfs?
	-- 
	
	
	
	
	--Echo(#tabs_settings['Display'].layout.children)
	
	--[[
	
	tabs_settings['Player'] =  Panel:New {		
		name = 'tab_player',		
		y = 42,
		maxWidth = 440,
		minWidth = 440,
		height = 200,
		parent = window_settings,		
		children = {Label:New{caption = "hello", x = 50, y = 50}},
	}
	tabs_settings['Files'] = Panel:New {
		name = 'tab_files',
		y = 42,
		maxWidth = 440,
		minWidth = 440,
		height = 200,
		parent = window_settings,		
		children = {Label:New{caption = "web", x = 50, y = 50}},
	}
	tabs_settings['Display'] = Panel:New {
		name = 'tab_display',
		y = 42,
		maxWidth = 440,
		minWidth = 440,
		height = 200,
		parent = window_settings,		
		children = {Label:New{caption = "weub", x = 50, y = 50}},
	}
	tabs_settings['Interface'] = Panel:New {
		name = 'tab_interface',
		y = 42,
		maxWidth = 440,
		minWidth = 440,
		height = 200,
		parent = window_settings,		
		children = {Label:New{caption = "wub wub", x = 50, y = 50}},
	}
	tabs_settings['Interface'] = Panel:New {
		name = 'tab_interface',
		y = 42,
		maxWidth = 440,
		minWidth = 440,
		height = 200,
		parent = window_settings,		
		children = {Label:New{caption = "wub wub", x = 50, y = 50}},
	}

			children = {
			Label:New {
				x = 0,
				y = 30,
				align = 'left',
				caption = 'Map folder: $spring/',
				textColor = {1,1,0,0.9},
			},
			Label:New {
				x = 0,
				y = 56,
				align = 'left',
				caption = 'Sounds folder: $map/',
				textColor = {1,1,0,0.9},
			},
		}
	--]]	
		

	window_settings:Hide()

	

end



----------------------------------------------------------------------------------------------------------------------
--------------------------------------------- POST-INIT CONTROL SETUP ------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
-- for one reason or another, the functions here have to be injected into existing controls after gui is setup


local function DeclareFunctionsAfter()

	--------------------------------------------------------------------------------------------------
	-- main frame
	layout_main_templates.Refresh = function(self) 
		local tooltip_help_templates = colors.green_1:Code().."\n\nselect any number of items, press "..colors.blue_579:Code().."SPACE "..colors.green_1:Code().."and drag with your mouse to add them to an emitter."
	
		local valid = true
		
		-- templates tab
		for item, params in pairs(sounditems.templates) do
		--local i = controls.tracklist and #controls.tracklist or 1 --< cant index the table properly if things get removed
			if not controls.tracklist['label_'..item] then -- make new controls for newly added items
				valid = false
				controls.tracklist['label_'..item] = MouseOverTextBox:New { --< should make custom clickie MouseOverTextBox for this
					refer = item,					
					clientWidth = 160,
					parent = layout_main_templates,
					align = 'left',
					text = item,
					fontSize = 10,
					textColor = colors.white_09,
					textColorNormal = colors.white_09,
					textColorSelected = colors.green_1,
					--backgroundColor = colors.grey_02,
					--backgroundFlip = {0.6,0.6,0.9,0.5},
					--borderColor = {0.3,0.3,0.3,0.5},
					--borderFlip = {0.7,0.7,1,0.5},							
					padding = {0, 6, 0, 0},
					OnMouseOver = {
						function(self)							
							local ttip = self.text.."\n\n"
									..(params.file_local and colors.orange_06:Code() or colors.green_1:Code())
										..params.file..colors.white_1:Code().."\n\n"										
							for k, _ in pairs(sounditems.default) do											
								if k ~= 'file' then												
									ttip = ttip..k..": "..tostring(params[k]).."\n"
								end
							end							
							self.tooltip = ttip..tooltip_help_templates
						end,
					},					
					AllowSelect = function(self, idx, select) 						
						--self.backgroundColor, self.backgroundFlip = self.backgroundFlip, self.backgroundColor
						--self.borderColor, self.borderFlip = self.borderFlip, self.borderColor
						if select then 
							self.font:SetColor(self.textColorSelected)							
						else 
							self.font:SetColor(self.textColorNormal) 
						end
						self:Invalidate()
					end,					
				}
				controls.tracklist['length_'..item] = MouseOverTextBox:New {
					refer = item,
					x = 204,
					clientWidth = 26,
					parent = layout_main_templates,
					align = 'right',
					text = ''..params.length_real,
					fontSize = 10,
					textColor = colors.white_09,
					backgroundColor = colors.grey_02,
					borderColor = colors.grey_03,
					padding = {0, 6, 0, 0},
					tooltip = [[The length of the item in seconds. As this information can't currently be obtained by the Widget, you may want to insert it manually.]],
					-- this needs a refresh function for playback
					--AllowSelect = function(self, idx, select) layout_main_templates.DeselectItem(idx) Echo("control: "..idx) end, -- block selection
				}
				controls.tracklist['editBtn_'..item] = Image:New {
					refer = item,
					parent = layout_main_templates,
					file = icons.PROPERTIES_ICON,
					width = 20,
					height = 20,
					tooltip = 'Edit',
					color = {0.8,0.7,0.9,0.9}, --					
					OnClick = {
						function(self,...)
							local w = window_properties
							if w.refer then w:Confirm() end
							w.refer = self.refer
							w:Refresh()
							w:Show()							
						end
					},
					--AllowSelect = function(self, idx, select) layout_main_templates.DeselectItem(idx) Echo("control: "..idx) end, -- block selection
				}
				controls.tracklist['playBtn_'..item] = Image:New {
					refer = item,
					parent = layout_main_templates,
					file = icons.PLAYSOUND_ICON,
					width = 20,
					height = 20,
					tooltip = 'Play',
					color = colors.green_06,
					margin = {-6,0,0,0},					
					OnClick = {
						function()
							DoPlay(item, options.volume.value, 'global') --< this probably shouldnt return anything
						end
					},
					--AllowSelect = function(self, idx, select) layout_main_templates.DeselectItem(idx) Echo("control: "..idx) end, -- block selection
				}
			else -- update controls for exisiting items (not a whole lot to do as of now)
				controls.tracklist['label_'..item].text = item
				controls.tracklist['length_'..item].text = params.length_real
			end				
		end
		for k, control in pairs(controls.tracklist) do				
			if not sounditems.templates[control.refer] then -- dispose of controls for items that were removed
				valid = false
				control:Dispose()
				controls.tracklist[k] = nil
			end
		end
		
		
		local function MakeEmitterListEntry(e) 			
			controls.emitterslist[e] = {}
			local set = controls.emitterslist[e]
			set.label = ClickyTextBox:New {
				refer = e,					
				clientWidth = 160,
				parent = layout_main_emitters,
				align = 'left',
				text = e,
				fontSize = 10,
				textColor = e == 'global' and colors.blue_579 or colors.yellow_09,
				textColorNormal = e == 'global' and colors.blue_579 or colors.yellow_09,
				textColorSelected = colors.green_1,	
				padding = {0, 6, 0, 0},				
				UpdateTooltip = function(self)
					local em = emitters[e]
					local ttip = colors.yellow_09:Code().."Emitter: "..e..colors.white_1:Code().."\n("
					if e == 'global' then
						ttip = ttip..'no position)\n'
					else
						ttip = ttip.."X: "..string.format("%.0f", em.pos.x)..", "..
							"Z: "..string.format("%.0f", em.pos.z)..", "..
								"Y: "..string.format("%.0f", em.pos.y)..")\n"
					end
					for i = 1, #em.sounds do					
						ttip = ttip.."\n"..(em.sounds[i].item)
					end
					self.tooltip = ttip.."\n \n"..colors.green_1:Code().."right-click: inspect"
				end,				
				OnMouseOver = {
					function(self)							
						--self:UpdateTooltip()
						self.font:SetColor(self.textColorSelected)
						--self.textColor = self.textColorSelected
						self.parent.highlightEmitter = e
						--self:Invalidate()
					end,
				},
				OnMouseOut = {
					function(self)
						--self:UpdateTooltip()
						self.font:SetColor(self.textColorNormal)
						--self.textColor = self.textColorNormal
						self.parent.highlightEmitter = nil
						--self:Invalidate()
					end,
				},
				OnClick = {
					function(self, _, _, btn)
						local mx, mz_inv = widget.GetMouseScreenCoords()
						if btn == 3 then
							local window = EmitterInspectionWindow.instances[self.refer]
							if window.visible then
								Echo("was visible")
								window:Hide()				
								window:Invalidate()				
								window.layout.visible = false -- silly but layout panels never hide
							else
								Echo("was hidden")
								window:Refresh()
								window:Show()
								window.layout.visible = true
								local main = window_main
								local xp = mx > (screen0.width / 2) and (main.x - window.width) or (main.x + main.width)
								local yp = mz_inv > (screen0.height / 2) and (mz_inv - window.height) or mz_inv
								window:SetPos(xp, yp)
								return
							end	
						end
					end,
				},
			}
			set.activeIcon = Image:New{
				refer = emitters[e],
				parent = layout_main_emitters,
				file = icons.MUSIC_ICON,
				width = 16,
				height = 16,
				tooltip = '',
				color = {0.3,0.5,0.7,0.0},
				OnClick = {function(self) end,},
				OnMouseOver = {
					function(self)
						if self.refer.isPlaying then
							local ttip = 'currently playing:\n\n'							
							for i = 1, #self.refer.sounds do
								local s = self.refer.sounds[i]
								if s.isPlaying then 
									ttip = ttip..s.item.."\n"
								end
							end
							self.tooltip = ttip
						else
							self.tooltip = 'not currently playing'
						end
					end,
				},				
			}
			set.label:UpdateTooltip()
		end
		
		if not controls.emitterslist.global then
			valid = false
			MakeEmitterListEntry('global')
		end
		
		-- emitters tab	
		for e, params in pairs(emitters) do
			if not controls.emitterslist[e] and e ~= 'global' then
				valid = false
				MakeEmitterListEntry(e)
			end
			if params.isPlaying then
				controls.emitterslist[e].activeIcon.color = {0.5,0.8,0.9,0.9}
				controls.emitterslist[e].activeIcon:Invalidate()
			else
				controls.emitterslist[e].activeIcon.color = {0.3,0.5,0.7,0.0}
				controls.emitterslist[e].activeIcon:Invalidate()
			end
		end
		for k, set in pairs(controls.emitterslist) do
			if not emitters[set.label.refer] then
				valid = false
				set.label:Dispose()
				-- ...
				controls.emitterslist[k] = nil
			end
		end
		
		if not valid then self:Invalidate() end	
	end
	
	
	
	-----------------------------------------------------------------------------------------------------
	-- properties window
	

	window_properties.Refresh = function(self, ...)		
		if self.refer then 			
			self.caption = self.refer
			local item
			if sounditems.templates[self.refer] then
				item = sounditems.templates[self.refer]
				self.defaultItem = sounditems.default
			elseif sounditems.instances[self.refer] then
				item = sounditems.instances[self.refer]
				--local _, endprefix = string.find(self.refer, "[%$].*[%$%s]")				
				--local template = string.sub(self.refer, endprefix + 1)				
				self.defaultItem = sounditems.templates[item.template]
				--if not self.defaultItem then Echo("no template:"..template) end
			else	
				Echo("Error: reference to non-existant item")
				self:Invalidate()				
				self:Hide()
				return
			end
			controls.properties.file:SetText(item.file)-- = item.file
			controls.properties.file.font:SetColor(item.file_external and colors.red_1 or colors.green_1)			
			controls.properties.file:Invalidate()
			layout_properties:Refresh()
			if not controls.properties[0].checked == item.in3d then controls.properties[0]:Toggle() end
			controls.properties[0]:Refresh()
			controls.properties.in3d_defaultBtn:Refresh()
			for i, control in ipairs(controls.properties) do
				local txt = item[control.refer]
				control.text = type(txt) == 'number' and tostring(txt) or 'default'				
			end
			self:Invalidate()
		else			
			self:Invalidate()
			self:Hide()
		end		
	end	
	window_properties.Confirm = function(self)
		local item = sounditems.templates[self.refer] or sounditems.instances[self.refer]
		if item then
			item.in3d = controls.properties[0].checked
			for i, control in ipairs(controls.properties) do
				item[control.refer] = tonumber(control.text)
			end			
		else
			Echo("Error: reference to non-existant item")			
		end		
		self.refer = nil
		self:Invalidate()
		self:Hide()
		widget.RequestReload()
	end
	window_properties.Discard = function(self)
		self.refer = nil
		self:Invalidate()
		self:Hide()
	end	
end




function SetupGUI()	
	
	Chili = widget.WG.Chili

	if (not Chili) then		
		Echo("<ambient gui> Chili not found")
		return false
	end

	
	screen0 = Chili.Screen0
	
	Image = Chili.Image
	Button = Chili.Button
	Checkbox = Chili.Checkbox
	Window = Chili.Window
	Label = Chili.Label
	Line = Chili.Line
	Panel = Chili.Panel
	ScrollPanel = Chili.ScrollPanel
	LayoutPanel = Chili.LayoutPanel
	StackPanel = Chili.StackPanel	
	Grid = Chili.Grid
	TabBar = Chili.TabBar
	Trackbar = Chili.Trackbar	
	color2incolor = Chili.color2incolor
	incolor2color = Chili.incolor2color
	
	Echo("setting up chili classes")	
	DeclareClasses()
	Echo("setting up controls")
	DeclareControls()
	Echo("injecting functions")
	DeclareFunctionsAfter()
	
	tabbar_settings:Select('Player')
	---window_chili:Show()
	
	local mwWindow = Window:New{
		parent = screen0,
		x = 500, y = 300,
		width = 200,
		height = 100,		
	}
	mwLabel = Label:New {
		parent = mwWindow,
		caption = '',
		fontsize = 12,
	}
	mwWindow:Show()
end



function UpdateGUI()
	--Echo("call")
	--editbox_mapfolder.text = config.path_map
	--editbox_soundfolder.text = config.path_sound
	
	layout_main_templates:Refresh()
	--inspectionWindows:RefreshAll()
	
	-- is there any reason why they have to refresh on every tick?
	-- maybe the counters? they could be frefreshed individually tho	
	for _, window in pairs(inspectionWindows) do window:Refresh() end
	--for _, tab in pairs(tabs_settings) do tab:Refresh() end
	if window_main.visible then
		button_emitters_anim:Invalidate()
	else
		button_show_anim:Invalidate()
	end	
	--local focusedControl = Chili.UnlinkSafe(Chili.Screen0.focusedControl)
	--local hoveredControl = Chili.UnlinkSafe(Chili.Screen0.hoveredControl)
	--local activeControl = Chili.UnlinkSafe(Chili.Screen0.activeControl)
	
	
	--label_focus:SetCaption(focusedControl and focusedControl.classname or 'none'); label_focus:Invalidate()
	--label_hover:SetCaption(hoveredControl and hoveredControl.classname or 'none'); label_hover:Invalidate()
	--label_active:SetCaption(activeControl and activeControl.classname or 'none'); label_active:Invalidate()
	--window_chili:Invalidate()	
	local c, d = widget.GetMouseScreenCoords() or 1,1
	local mww = MouseOver(c,d)
	mwLabel:SetCaption(mww and (mww.name or 'something') or 'none')
	mwLabel:Invalidate()
end




function MouseOver(mx, my)
	--Echo ("call")
	--for _, c in pairs(EmitterInspectionWindow.instances) do
	--	if c.visible and c.IsMouseOver and c:IsMouseOver(mx, my) then return c end
	--end
	for _, c in pairs(containers) do		
		if c.layout then -- should check scroll panels instead layout panels extent far beyond the bounds				
			if c.layout.IsMouseOver and c.layout:IsMouseOver(mx, my) then return c.layout end
		end		
		if c.IsMouseOver and c:IsMouseOver(mx, my) then return c end		
	end	
	return false
end

function KeyPress(...)
	if not Chili then return false end
	local focusedControl = Chili.UnlinkSafe(Chili.Screen0.focusedControl)       
	if focusedControl and focusedControl.classname == 'FilterEditBox' then				
		--return (not not focusedControl:KeyPress(...))
		focusedControl:KeyPress(...)
		return true
    end
end

function TextInput(...)
	if not Chili then return false end
	local focusedControl = Chili.UnlinkSafe(Chili.Screen0.focusedControl)
	if focusedControl and focusedControl.classname == 'FilterEditBox' then
		return (not not focusedControl:TextInput(...))
    end	
end

function SpawnDialog(px, pz, py)	
	local window_name = Window:New {
		parent = screen0,
		x = "50%",
		y = "40%",
		clientWidth = 160,
		clientHeight = 54,
		caption = 'choose name',
		resizable = false,
	}
	local box = FilterEditBox:New {
		parent = window_name,
		x = 10,
		y = 12,
		clientWidth = 140,
		text = '',
		backgroundColor = {.1,.1,.1,.5},
		borderColor = {.3,.3,.3,.3},
		borderColor2 = {.4,.4,.4,.4},
		InputFilter = function(unicode)
			return string.find(unicode, "[%w_-]")
			--if string.find(unicode, "%A%D") then return false end
			---return true
		end,
		Confirm = function(self)
			widget.SpawnEmitter(#self.text > 0 and self.text or nil , px, pz, py)
			window_name:Dispose()			
		end,
		Discard = function(self)
			window_name:Dispose()
		end,		
	}
	Image:New {
		parent = window_name,
		file = icons.CLOSE_ICON,
		x = 50,
		y = 34,
		width = 20,
		height = 20,
		tooltip = 'cancel',
		color = {0.8,0.3,0.1,0.7}, --
		OnClick = {
			function(self,...)
				window_name:Dispose()						
				--window_name	= nil; box = nil
			end
		},
	}
	Image:New {
		parent = window_name,
		file = icons.CONFIRM_ICON,
		x = 80,
		y = 34,
		width = 20,
		height = 20,
		tooltip = 'accept',				
		OnClick = {
			function(self,...)
				widget.SpawnEmitter(#box.text > 0 and box.text or nil , px, pz, py)
				window_name:Dispose()
				--window_name	= nil; box = nil						
			end
		},					
	}
	window_name:Show()
	box.state.focused = true
	screen0.focusedControl = box	
	--box:Update()
	--box:Invalidate()
	--box:SetFocus()
	
				--self.state.focused = false
				--target.state.focused = true
				--screen0.focusedControl = target	
end


--

local gui = getfenv()
gui.EmitterInspectionWindow = EmitterInspectionWindow
gui.controls = controls
gui.containers = containers
gui.colors = colors


	
return gui


	--[[
		prototype = {
			children = {
				Button:New{
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
						end,
					},
					children = {
						Image:New {
							width = "100%",
							height = "100%",
							file = icons.CLOSE_ICON,
							padding = {0,0,0,0},
							margin = {0,0,0,0}
						},
					},
				},
				Button:New{					
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
							end
						end,
					},
					children = {
						Image:New {
							width = "100%",
							height = "100%",
							file = icons.CLOSEALL_ICON,
							padding = {0,0,0,0},
							margin = {0,0,0,0}
						},
					},
				},
				Label:New{
					y = 20,				
					--caption = parent.refer, -- this could be the reason i did it the other way?
					width = 300,				
					align = 'center',		
					textColor = colors.yellow_09,
					Refresh = function(self)
						if not self.caption == self.parent.refer then 
							self.caption = parent.refer
							self:Invalidate()
						end
						return false						
					end,
				},
				ScrollPanel:New{
					y = 40,
					clientWidth = 300 - 8,
					clientHeight = 250 - 90,				
					scrollPosX = -16,
					horizontalScrollbar = false,
					verticalScrollbar = true,
					verticalSmartScroll = false,	
					scrollbarSize = 6,
					padding = {5,10,5,10},
					children = {
						DragDropLayoutPanel:New{							
							clientWidth = 300,
							clientHeight = 250,
							maxWidth = 300,
							minWidth = 0,
							orientation = 'vertical',				
							selectable = false,		
							multiSelect = false,
							itemPadding = {6,2,6,2},
							itemMargin = {0,0,0,0},
							autosize = true,
							align = 'left',
							columns = 3,
							left = 0,
							centerItems = false,
							list = {},
							Refresh = function(self)
								Echo("refreshing layout")
								self.refer = parent.parent.refer
								local e = emitters[self.refer]
								if not e then 
									parent.parent:Dispose()
									return false
								end
								local hasValidLayout = true
								for i = 1, #e.sounds do
									Echo("sounds")
									local sound = e.sounds[i]
									local iname = sound.iname
									
									if not list[iname] then
										list[iname] = {}
										local _, endprefix = string.find(iname, "[%$].*[%$%s]")
										local txt = colors.yellow_09:Code()..string.sub(iname, 0, endprefix)
											..colors.white_1:Code()..string.sub(iname, endprefix + 1)
										list[iname].label = MouseOverTextBox:New{
											refer = iname,
											width = parent.parent.width - 140,
											parent = self,
											align = 'left',
											text = txt,
											fontsize = 10,
											textColor = colors.white_09,
											backgroundColor = colors.grey_02,
											borderColor = colors.grey_03,
											OnMouseOver = {
												function(self) 													
													local _, endprefix = string.find(iname, "[%$].*[%$%s]")
													local ttip = colors.yellow_09:Code()..string.sub(iname, 0, endprefix)
														..'\255\125\230\255'..string.sub(iname, endprefix + 1)..colors.white_1:Code().."\n\n"													
													-- i need to check for local file here
													ttip = ttip..sounditems.instances[sound.item].file.."\n\n"
													for key, _ in pairs(sounditems.default) do 
														if not key == 'file' then
															ttip = ttip..key..": "..tostring(sounditems.instances[sound.item][key]).."\n" 
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
											tooltip = 'Sound Properties',
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
											parent = self,
											file = icons.PLAYSOUND_ICON,
											width = 20,
											height = 20,
											tooltip = 'Play at Location',
											color = colors.green_06,
											margin = {-6,0,0,0},
											OnClick = { -- hope e exists at this point?
												function()													
													return DoPlay(sound.item, options.volume.value, e)
												end,
											},
										}
										-- what about animated play button
										hasValidLayout = false
									end								
								end							
								for k, t in pairs(list) do
									if not e.sounds[k] then
										t.label:Dispose()
										t.editBtn:Dispose()
										t.playBtn:Dipose()
										hasValidLayout = false
									end
								end
								-- if not hasValidLayout then self:Invalidate()
								return not hasValidLayout
							end,
						},
					},
					Refresh = function(self)
						for _, c in pairs(self.children) do
							return c.Refresh and c:Refresh() or false
						end
					end,
				},
			},
			-- what needs to be done here?
			-- refresh this only when something changes, and once at start			
			Refresh = function(self)
				Echo("refreshing")
				local key = self.refer
				local e = emitters[key]
				if not e then 
					Echo("no e")
					self:Dispose() 
					return
				end				
				local needsUpdate = false
				for _, c in pairs(self.children) do
					needsUpdate = c.Refresh and c:Refresh() or false
				end
				-- do i even need to do this? children can udpate their layout just fine if they need to
				-- and stuff isnt moving around or anything
				Echo("refresh was ran")
				if needsUpdate then 
					self:Invalidate() 
					Echo("and updated")
				end
				
			end,
			-- this shouldnt be necessary, the table is weak and the key will not be accessed anymore if the emitter is dead
			-- UNLESS they key gets reused by another emitter, in which case the table points to a disposed window?
			-- not sure that can happen, the object will just be nil then i think?
			--Dispose = function(self, ...)
				-- EmitterInspectionWindows.instances[self.refer] = nil 				
				--self.inherited:Dipose()
			--end,
		}--]]
