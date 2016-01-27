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

gl = widget.gl

local GetMouse = Spring.GetMouseState
local TraceRay = Spring.TraceScreenRay
local IsMouseMinimap = Spring.IsAboveMiniMap
local GetGroundHeight = Spring.GetGroundHeight
local GetModKeys = Spring.GetModKeyState
local GetTimer = Spring.GetTimer
local DiffTimers = Spring.DiffTimers

local callbacks = callbacks
local cbTimer = cbTimer

--[[
--local C_Control
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
--]]

--[[
local MouseOverWindow
local DragDropLayoutPanel
local FilterEditBox
local MouseOverTextBox
local ClickyTextBox
local gl_AnimatedImage
local ImageArray
--]]

--local color2incolor
--local incolor2color

local PATH_ICONS = "Images/AmbientSoundEditor/"
icons = {}
-- these dont really have to be locals? as images are just loaded once
icons.SETTINGS_ICON = PATH_LUA..PATH_ICONS..'settings.png'
icons.HELP_ICON = PATH_LUA..PATH_ICONS..'questionmark.png'
icons.CONSOLE_ICON = PATH_LUA..PATH_ICONS..'speechbubble_icon.png'
icons.PLAYSOUND_ICON = PATH_LUA..PATH_ICONS..'vol.png'
icons.PROPERTIES_ICON = PATH_LUA..PATH_ICONS..'properties_button.png'
--icons.PLAYER_CONTROLS_ICON = PATH_LUA..'Images/Commands/Bold/'..'drop_beacon.png'
icons.CLOSE_ICON = PATH_LUA..PATH_ICONS..'close.png'
icons.CLOSEALL_ICON = PATH_LUA..PATH_ICONS..'closeall.png'
icons.CONFIRM_ICON = PATH_LUA..PATH_ICONS..'arrow_green.png'
icons.UNDO_ICON = PATH_LUA..PATH_ICONS..'undo.png'
icons.COGWHEEL_ICON = PATH_LUA..PATH_ICONS..'cogwheel.png'
icons.SAVE_ICON = PATH_LUA..PATH_ICONS..'disc_save_2.png'
icons.LOAD_ICON = PATH_LUA..PATH_ICONS..'disc_load_2.png'
icons.MUSIC_ICON = PATH_LUA..PATH_ICONS..'music.png'
icons.SPRING_ICON = PATH_LUA..PATH_ICONS..'spring_logo.png'
icons.FILE_ICON = PATH_LUA..PATH_ICONS..'file.png'
icons.FOLDER_ICON = PATH_LUA..PATH_ICONS..'folder.png'
icons.NEWFOLDER_ICON = PATH_LUA..PATH_ICONS..'folder_add.png'
icons.MUSICFOLDER_ICON = PATH_LUA..PATH_ICONS..'folder_music.png'
icons.ZIP_ICON = PATH_LUA..PATH_ICONS..'present.png'
icons.LUA_ICON = PATH_LUA..PATH_ICONS..'lua.png'
icons.MAP_ICON = PATH_LUA..PATH_ICONS..'earth.png'

colors = {
	Code = function(c)
		local floor = math.floor
		local char = string.char
		if c and type(c) == 'table' then
			return '\255'..char(floor(c[1]*255))..char(floor(c[2]*255))..char(floor(c[3]*255))			
		end
		return '\255'..char(1)..char(1)..char(1)
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
	none = {0, 0, 0, 0},
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

--[[
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
--]]

--local editbox_mapfolder
--local editbox_soundfolder
--local buttonimage_mapfolder
--local buttonimage_soundfolder

--local window_inspect
--local label_inspect



--local drag


local mx, mz, mz_inv
local mcoords
local modkeys = {}
local hoveredEmitter
local hoveredControl -- might want to include windows here so its all in one place? need to do the hittest tho, then
--local dragDropDeamon

local drag = {
	items = {},
	data = {},
	typ = {},			
	started = false,
	cb = nil,
}

local tooltipTimer = settings.interface[3]
local worldTooltip = ''
local function updateTooltip()
	local tooltip_help = colors.green_1:Code().."right-click: inspect\n"
		..colors.green_1:Code().."left-click + drag: move\n"
			..colors.green_1:Code().."shift + wheel (+ctrl/alt): adjust height"
	if hoveredEmitter then
		local e = emitters[hoveredEmitter]		
		worldTooltip = colors.yellow_09:Code().."Emitter: "..hoveredEmitter..colors.white_1:Code().."\n("..
			"X: "..string.format("%.0f", e.pos.x)..", "..
				"Z: "..string.format("%.0f", e.pos.z)..", "..
					"Y: "..string.format("%.0f", e.pos.y)..")\n "
					
		for i = 1, #e.sounds do					
			worldTooltip = worldTooltip.."\n"..(e.sounds[i].item)
		end
		worldTooltip = worldTooltip.."\n \n"..tooltip_help		
	end
end

----------------------------------------------------------------------------------------------------------------------
------------------------------------------------ CHILI SUBCLASSES ----------------------------------------------------
----------------------------------------------------------------------------------------------------------------------

local function DeclareClasses()
	
	local VFS = widget.VFS
	local mode = widget.VFSMODE
	local path_chili = 'luaui/ape/chili/'
	local files = {'ImageArray.lua', 'DragDropLayoutPanel.lua', 'FileBrowserPanel.lua', 'FilterEditBox.lua',
		'MouseOverTextBox.lua', 'ClickyTextBox.lua', 'gl_AnimatedImage.lua', 'MouseOverWindow.lua', 'InstancedWindow.lua',
			'EmitterInspectionWindow.lua',
	}
		
		
	for _, f in ipairs(files) do
		assert (VFS.FileExists(path_chili..f, mode))
		VFS.Include(path_chili..f, mode)
	end
end



----------------------------------------------------------------------------------------------------------------------
	
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
--------------------------------------------------- GUI CONTROLS -----------------------------------------------------
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------

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
		allowDragItems = 'sounds',
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
		name = 'spawnbutton',		
		x = 10,
		y = -52,
		parent = window_main,		
		-- tooltip = colors.green_1:Code()..'spawn new emitter and place it on the map, cancel with '..colors.blue_579:Code()..'ESC'..colors.green_1:Code()..' or '..colors.blue_579:Code()..'right-click'..colors.green_1:Code()..'\n\npress shift and turn the mousewheel to adjust height(use shift + ctrl/alt make it go faster/slower)\n\nyou can also do this later: hover over an emitter on the map, press shift and any of the modkeys and turn the mousewheel\n\nyou can drag around emitters on the map with left-drag. inspect them with right-click',
		tooltip = colors.green_1:Code()..'spawn new emitter and place it on the map, cancel with '..colors.blue_579:Code()..'ESC'..colors.green_1:Code()..' or '..colors.blue_579:Code()..'right-click'..colors.green_1:Code()..'.\n\npress '..colors.blue_579:Code()..'SHIFT'..colors.green_1:Code()..' and turn the mousewheel to adjust height(use '..colors.blue_579:Code()..'SHIFT + CTRL/ALT'..colors.green_1:Code()..' to make it go faster/slower).\n\nyou can also do this later: hover over an emitter on the map, press '..colors.blue_579:Code()..'SHIFT'..colors.green_1:Code()..' and any of the modkeys and turn the mousewheel\n\nyou can drag around emitters on the map with '..colors.blue_579:Code()..'left-drag'..colors.green_1:Code()..'. inspect them with '..colors.blue_579:Code()..'right-click'..colors.green_1:Code()..'.',
		clientWidth = 30,
		clientHeight = 30,
		caption = '',
		OnClick = {function(self, ...) 
			local btn = select(3,...)
			if drag.started and btn == 3 then
				drag.started = false
				--drag.cb = nil
				drag.items = {}
				drag.data = {}
				drag.typ = {}
			else
				drag.started = true
				drag.typ.spawn = true
				drag.data.hoff = 0
			end
			--dragDropDeamon:StartDragItems(self)
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
				controls.browser.layout_files.editbox.text = (config.path_map or '')..config.path_sound
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
		parent = screen0,
		dockable = true,
		parentWidgetName = widget:GetInfo().name,		
		tooltip = 'Open APE Main Window',
		x = -50,
		y = 100,		
		clientWidth = 30,
		clientHeight = 30,
		caption = '',
		cb = nil,
		MouseDown = function(self, x, y, button, mods)			
			self.cb = cbTimer(settings.interface[2] * 1000, self.DragCallin, {self})
			self.state.pressed = true
			C_Control.MouseDown(self, x, y, button, mods)
			self:Invalidate()
			return self
			--return Button.MouseDown(self, x, y, button, mods)
		end,
		MouseUp = function(self, x, y, button, mods)
			if self.state.pressed then
				if self.cb then
					self.cb.cancel = true				
				end
				self.cb = nil
				self.state.pressed = false
				if self.dragging then					
					self.dragging = false
					return false
				end				
				C_Control.MouseUp(self, x, y, button, mods)
				self:Invalidate()
				return self
			end			
			--return Button.MouseUp(self, x, y, button, mods)
		end,
		DragCallin = function(self)			
			self:SetPos(mx - self.width / 2, mz_inv - self.height / 2)
			self.dragging = true
		end,
		OnClick = {function(self) 
				if self.dragging then					
					self.dragging = false
					return false
				end	
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
	--[[
	button_import = Button:New {
		x = -242,
		y = -32,
		parent = window_main,		
		tooltip = 'Import Playlist from older Version',
		clientWidth = 12,
		clientHeight = 12,
		caption = '',
		OnClick = {function() i_o.ImportPlaylist() end},
		children = {
			Image:New {
				width = "100%",
				height = "100%",				
				file = icons.LOAD_ICON,
			},
		}
	}--]]
	
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
				if settings.browser.autoLocalize and config.path_map then
					-- we still need to check here if the file already exists in the local folder
					-- and if so, we dont need to use file_local / _external
					local target_fullpath = config.path_map..config.path_sound..v.box.refer2
					--if k ~= fullpath then
					success = i_o.BinaryCopy(k, target_fullpath)
					--end	
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
			Echo("generated "..n - errors.." templates") --?
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
					local pathbox = controls.browser.layout_files.editbox
					local legit = #VFS.SubDirs(pathbox.text) > 0 
						or #VFS.DirList(pathbox.text) > 0		
					pathbox.legit = legit
					pathbox.font:SetColor(legit and colors.green_1 or colors.red_1)	
					if legit and not settings.paths[pathbox.text] then
						-- we storing a double reference for this, so we can both use indizes and lookup by name
						-- we cant just use pairs later because an options table contains all kinds of crap
						settings.paths[pathbox.text] = true
						--settings.paths[#settings.paths + 1] = pathbox.text
						controls.browser.layout_files:Refresh()
					end
				end
			end,
		},		
	}
	
	local label_path = FilterEditBox:New {
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
	controls.browser.layout_files = FileBrowserPanel:New {
		name = 'browser_layout_files',
		parent = controls.browser.scroll_files,
		editbox = label_path,
		allowDragItems = 'files',
		minWidth = 230,
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
		fileFilter = {
			["wav$"] = icons.MUSIC_ICON,
			["ogg$"] = icons.MUSIC_ICON,
		},
		Refresh = function(self)
			self.path = self.path or config.path_map..config.path_sound			
			local list = self.list
			for i = 1, #list do
				list[i]:Dispose()
				list[i]:Invalidate()
				list[i] = nil
			end	
			self:AddUserPaths()
			self:AddHardLinks()
			local legit = self:AddCurrentDir()
			
			self:Invalidate()
			return legit -- this is false for empty folders, sadly. not sure what to do about it
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
		name = 'browser_layout_templates',
		parent = controls.browser.scroll_templates,
		allowDropItems = 'files',
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
		ReceiveDragItems = function(self, drag)
			local sel = drag.items[1].selectedItems
			local items = drag.items[1].children
			local list = self.list
			for i, selected in pairs(sel) do
				if selected and items[i].legit and not list[items[i].refer] then
					local ending = string.find(items[i].text, "%.ogg$") or string.find(items[i].text, "%.wav$")					
					local name = string.sub(items[i].text, 1, ending - 1)
					
					list[items[i].refer] = {
						button = Image:New {
							parent = controls.browser.layout_templates,
							file = icons.CLOSE_ICON,
							width = 12,
							height = 12,							
							tooltip = 'remove from selection',
							refer = items[i].refer,
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
							refer = items[i].refer,							
							refer2 = items[i].text,
							tooltip = items[i].refer,
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
		tooltip = 'When this is enabled, APE will try to copy the files into your working directory once your close this window.\n\nNote that internally, the old file & location will be used until the next time you run spring.\n\n'..colors.orange_06:Code().."Note also that due to engine limitations, files outside the spring directory cannot be copied in this way.\n\nYou can still use them while you are working on your map, but you will need to copy them manually into the sounds/ambient folder inside your working directory.\n\nAPE will localize path names used internally when you finish working on your map." ,
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
			[2] = 'Display',
			[3] = 'Interface',
			[4] = 'Setup',
			--[5] = 'Misc',
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
				self.panels[tab].layout:Refresh()
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
			Refresh = function(self)
				for _, c in ipairs(self.children) do
					if c.Refresh then 
						c:Refresh()
					end
				end
			end,
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
					-- if i == 2 then widget.GetDrag().timer = self.value end						
				end
			},
		}
	end
	
	panels['Setup'].layout.columns = 2
	-- working dir field
	MouseOverTextBox:New {
		parent = panels['Setup'].layout,
		text = ' Working Directory:',
		fontsize = 11,
		textColor = colors.yellow_09,
		width = 110,
		tooltip	= 'the working directory for this particular map. by default, APE sets this to maps/<mapname>.sdd, but you can chose any name you want.\n\nnote that this folder must be inside your springs write-directory and should be specified as a relative path.',
	}	
	Image:New {
		parent = panels['Setup'].layout,
		file = false,
		width = 12,
		height = 12,		
	}	
	controls.settings.box_workingDir = FilterEditBox:New {
		parent = panels['Setup'].layout,
		text = config.path_map or '',
		fontsize = 11,
		width = 380,
		textColor = colors.green_1,
		backgroundColor = colors.grey_01,
		borderColor = colors.grey_05,
		borderColor2 = colors.grey_035,
		legit = true,
		Refresh = function(self)
			self.legit = i_o.TestWorkingDir(self.text) or i_o.TestWorkingDir(self.text..'/')
			self.font:SetColor(self.legit and colors.green_1 or colors.red_1)
			self:Invalidate()			
		end,
		Confirm = function(self)			
			if string.sub(self.text, -1) ~= '\\' and string.sub(self.text, -1) ~= '\/' then
				self.text = self.text..'/'
			end
			self:Refresh()
			if not self.legit then
				ConfirmDialog("setup working directory in this folder:\n"..self.text,
					function(path) config.path_map = path; i_o.SetupWorkingDir(); self:Refresh() end, {self.text}, 
						self.Discard, {self})
			end
		end,
		Discard = function(self)
			self.text = config.path_map
			self:Refresh()
		end,
		KeyPress = function(self, ...)
			FilterEditBox.KeyPress(self, ...)
			self:Refresh()
		end,
		TextInput = function(self, ...)
			FilterEditBox.TextInput(self, ...)
			self:Refresh()
		end,
		OnFocusUpdate = {function(self)			
			if self.state.focused then
				self:Refresh()
			else
				self:Confirm()
			end			
		end,
		},	
	}
	Image:New {
		parent = panels['Setup'].layout,
		file = icons.LOAD_ICON,
		width = 20,
		height = 20,
		margin = {6,-2,0,0},
		tooltip = 'extract map archive\n\n'..colors.red_1:Code().."(not implemented yet)",
		OnClick = {function(self)
			do return end
			window_browser_map:Invalidate()
			window_browser_map:Show()
			controls.browser_map.layout:Refresh()			
			end,
		},
	}
	-- write dir field
	MouseOverTextBox:New {
		parent = panels['Setup'].layout,
		text = ' Read-Write Directory:',
		fontsize = 11,
		textColor = colors.yellow_09,
		width = 160,
		margin = {0, 20, 0, 0},
		tooltip	= 'The directory widgets are allowed to write into.\n\nThis should be the same as your spring folder in order for APE to access all necessary files and folders and save its data in the right places.\n\nAPE can restart the game with the the write-dir set to this location for you. you can also run spring with the --write-dir "yourpath" command line argument. "yourpath" must be a location inside your spring folder or the spring folder itself.',
	}
	Image:New {
		parent = panels['Setup'].layout,
		file = false,
		width = 12,
		height = 12,
	}	
	local box_writeDir = FilterEditBox:New {
		parent = panels['Setup'].layout,
		text = settings.general.write_dir,
		fontsize = 11,
		width = 380,
		textColor = colors.green_1,
		backgroundColor = colors.grey_01,
		borderColor = colors.grey_05,
		borderColor2 = colors.grey_035,
		legit = true,
		Refresh = function(self)
			self.legit = i_o.TestDirIsNotEmpty(self.text)
			self.font:SetColor(self.legit and colors.green_1 or colors.red_1)			
		end,
		Confirm = function(self)			
			if string.sub(self.text, -1) ~= '\\' and string.sub(self.text, -1) ~= '\/' then
				self.text = self.text..'/'
			end
			self:Refresh()
			if not self.legit then
				ConfirmDialog("write-dir (requires restart):\n"..self.text,
					function(path) settings.general.write_dir = path; self:Refresh() end, {self.text}, 
						self.Discard, {self})
			end
		end,
		Discard = function(self)
			self.text = settings.general.write_dir
			self:Refresh()
		end,
		KeyPress = function(self, ...)
			FilterEditBox.KeyPress(self, ...)
			self:Refresh()
		end,
		TextInput = function(self, ...)
			FilterEditBox.TextInput(self, ...)
			self:Refresh()
		end,
		OnFocusUpdate = {function(self)			
			if self.state.focused then
				self:Refresh()
			else
				self:Confirm()
			end			
		end,},		
	}	
	Image:New {
		parent = panels['Setup'].layout,
		file = icons.SPRING_ICON,
		width = 17,
		height = 17,
		margin = {7,2,0,0},
		tooltip = 'restart spring now\n\n'..colors.red_1:Code().."(not implemented yet)",
		OnClick = {function(self)
				do return end
				if box_writeDir.legit then
					--[[
					local script = i_o.GetStartScript()
					Echo(script)
					ConfirmDialog("restart spring with --write-dir:\n"..box_writeDir.text,
						function(path) 
							Spring.Restart('--write-dir '..'"'..path.."--config "..settings.general.spring_dir, script) 
						end,
						{box_writeDir.text})
					--]]	
				end
			end,
		},
	}
	
	-- spring dir field
	MouseOverTextBox:New {
		parent = panels['Setup'].layout,
		text = ' Spring Home Directory:',
		fontsize = 11,
		textColor = colors.yellow_09,
		width = 160,
		margin = {0, 20, 0, 0},
		tooltip	= 'Springs home directory on your machine. It is not strictly necessary for this to be known to the widget.',
	}
	Image:New {
		parent = panels['Setup'].layout,
		file = false,
		width = 12,
		height = 12,		
	}	
	local box_springDir = MouseOverTextBox:New {
		parent = panels['Setup'].layout,
		text = settings.general.spring_dir,
		fontsize = 11,
		width = 360,
		textColor = colors.green_1,
		backgroundColor = colors.grey_01,
		borderColor = colors.grey_05,
		borderColor2 = colors.grey_035,
		margin = {0, 6, 0, 0},
		OnClick = {},
	}
	Image:New {
		parent = panels['Setup'].layout,
		file = false,
		width = 12,
		height = 12,		
	}
	
	
	------------------------------------------ map browser popup -----------------------------
	controls.browser_map = {}
	window_browser_map = Window:New{
		parent = screen0,
		x = "30%",
		y = "30%",
		width = 300,
		height = 420,
		resizable = false,
		caption = "Extract Map Archive", -- or just set working dir?
		textColor = colors.grey_08,
	}
	local label_map_path
	controls.browser_map.scroll = ScrollPanel:New {
		parent = window_browser_map,	
		y = 20,
		padding = {5,5,5,5},
		clientWidth = 250,
		clientHeight = 290,
		scrollPosX = -16,
		verticalSmartScroll = true,	
		scrollbarSize = 6,
	}
	controls.browser_map.layout = FileBrowserPanel:New {
		name = 'browser_layout_map',
		parent = controls.browser_map.scroll,
		--editbox = label_map_path,		
		minWidth = 230,
		autosize = true,
		resizable = false,
		draggable = false,
		centerItems = false,
		selectable = true,
		multiSelect = false,
		align = 'left',
		columns = 2,
		itemPadding = {3,2,3,2},
		itemMargin = {0,0,0,0},
		list = {},		
		fileFilter = {
			["7z$"] = icons.ZIP_ICON,
			["zip$"] = icons.ZIP_ICON,
			["sd7$"] = icons.ZIP_ICON,
			["sdz$"] = icons.ZIP_ICON,
		},
		Refresh = function(self)
			--Echo("refreshing...")
			self.path = self.path or 'maps/'	
			local list = self.list
			for i = 1, #list do				
				list[i]:Dispose()
				list[i]:Invalidate()
				list[i] = nil
			end	

			self:AddUserPaths()
			self:AddHardLinks()
			local legit = self:AddCurrentDir()			
			
			--self.visible = true
			self:Invalidate()
			
			return legit -- this is false for empty folders, sadly. not sure what to do about it
		end,
	}
	controls.browser_map.destination_editbox = FilterEditBox:New{
		parent = window_browser_map,
		y = -60,
		x = 4,
		width = 250,
		fontsize = 11,
		backgroundColor = colors.grey_01,
		borderColor = colors.grey_035,
		borderColor2 = colors.grey_02,
		textColor = colors.orange_06, -- anything to check for here?
		text = '<destination folder>',
		
	}
	controls.browser_map.editbox_destination = Checkbox:New{
		parent = window_browser_map,
		y = -28,
		x = 6,
		width = 180,		
		caption = 'use this folder as working dir',
		fontsize = 11,
		textColor = colors.yellow_09,
	}
	controls.browser_map.button_confirm = Image:New{
		parent = window_browser_map,
		file = icons.CONFIRM_ICON,
		x = -30,
		y = -30,
		width = 20,
		height = 20,
		tooltip = 'extract',				
		OnClick = {
			function(self,...)
				-- need to check if folder is legit?				
				
				local file = controls.browser_map.layout.children[controls.browser_map.layout._lastSelected].refer
				local folder = controls.browser_map.editbox_destination
				local success = i_o.ExtractToFolder(file, folder)
				--window_browser_map:Hide()
				--window_name	= nil; box = nil						
			end
		},	
		
	}
	controls.browser_map.button_discard = Image:New{
		parent = window_browser_map,
		file = icons.CLOSE_ICON,
		x = -60,
		y = -30,
		width = 20,
		height = 20,
		tooltip = 'cancel',
		color = {0.8,0.3,0.1,0.7}, --
		OnClick = {
			function(self,...)
				window_browser_map:Hide()				
			end
		},

	}	
	
	containers.browser_map = window_browser
	window_browser_map:Hide()
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
		local tooltip_help_templates = colors.green_1:Code().."\n\nSelect any number of items and drag with your mouse to add them to an emitter.\n\nRight-click to deselect, use "..colors.blue_579:Code().."SHIFT"..colors.green_1:Code().." and/or "..colors.blue_579:Code().."CTRL"..colors.green_1:Code().." to select multiple."
	
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
					selectable = true,
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
					OnSelect = function(self, idx, select) 						
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
					if em then
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
					end
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
						--local mx, mz_inv = widget.GetMouseScreenCoords()
						if btn == 3 then
							local window = EmitterInspectionWindow.instances[self.refer]
							if window.visible then
								--Echo("was visible")
								window:Hide()				
								window:Invalidate()				
								window.layout.visible = false -- silly but layout panels never hide
							else
								--Echo("was hidden")
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
		
		-- emitters tab	
		for e, params in pairs(emitters) do
			if not controls.emitterslist[e] then 
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


----------------------------------------------------------------------------------------------------------------------
--------------------------------------------- DRAG/DROP DEAMON------------------------------------------------
----------------------------------------------------------------------------------------------------------------------

local function GetDeamon()
	return ImageArray:New{		
		name = "dragdropdeamon",
		parent = screen0,
		width = 30,
		height = 30,		
		--color = colors.none,
		files = {
			[1] = icons.SAVE_ICON,
			[2] = icons.MUSIC_ICON,
		},
		color = {1, 1, 1, 1},
		HitTest = function(self, ...)
			return drag.started and self
		end,
		MouseUp = function(self, x,  y, button, mods)
			local target
			if drag.started then
				if hoveredControl and hoveredControl.allowDropItems and drag.typ[hoveredControl.allowDropItems] then					
					target = hoveredControl					
				elseif drag.typ.sounds and hoveredEmitter then
					target = EmitterInspectionWindow.instances[hoveredEmitter].layout					
				end
			else
				drag.cb.cancel = true
				--Echo(drag.cb.args[2].name)
				local sx, sy = self:LocalToScreen(x, y)
				local tx, ty = drag.cb.args[2]:ScreenToLocal(sx, sy)				
				--return drag.data.source:MouseUp(tx, ty, button, mods)
				return drag.cb.args[2]:MouseUp(tx, ty, button, mods)
			end
			if target and target ~= drag.items[1] then
				target:ReceiveDragItems(drag)
			end
			drag.items = {}
			drag.data = {}
			drag.typ = {}
			drag.started = false			
			self:SetImage(false)
			return --target or false -- this should set focus if theres a target that can have focus
		end,
		MouseDown = function(self, x,  y, button, mods, source)
			if drag.started then
				--Echo("second down")
				return (drag.typ.spawn or drag.typ.emitter) and false or self
			end
			if button ~= 1 then return source end
			-- we need to check here if the source is a child rather than the panel. if so, we just pass the event back.
			-- the panel only sends this reference if the child listens to mouse button events
			-- right now, these cant be dragged
			if not source.allowDragItems then -- simple. could also use this tag to allow drag for clickable children, but then we need to claim input first and send the release to the source later
				return source:MouseDown(x,  y, button, mods, source)
			end
			drag.cb = cbTimer(settings.interface[2] * 1000, self.StartDragItems, {self, source})
			--Echo("grabbing input")
			return self
		end,
		MouseMove = function(self, x, y, dx, dy, button)
			--Echo("move")			
			if drag.started then				
				local sx, sy = self:LocalToScreen(x, y)				
				self:SetPos(sx, sy)			
			end			
		end,
		MouseWheel = function(self, up, value)
			-- i could probably route these to the hovered control and still keep the input by just returning self after
			return self
		end,
		StartDragItems = function(self, source)
			--Echo("cb")					
			drag.started = true			
			drag.typ[source.allowDragItems] = true
			--drag.data.source = source
			drag.items[1] = source
			self:SetImage(drag.typ['files'] and 1 or 2)
			self:SetPos(mx, mz_inv)			
		end,
	}
end


-----------------------------------------------------------------------------------------------------------------------
---------------------------------------------- INIT & UPDATE ----------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------


local function Distance(sx, sz, tx, tz)
	local dx = sx - tx
	local dz = sz - tz	
	return math.sqrt(dx*dx + dz*dz)
end

local function unpk(args, i)		
	if args and args[i] then
		return args[i], unpk(args, i + 1)
	else
		return nil
	end		
end

function SetupGUI()		
	Chili = widget.WG.Chili
	if (not Chili) then		
		Echo("<ambient gui> Chili not found")
		return false
	end
	
	
	screen0 = Chili.Screen0

	C_Control = Chili.Control
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
	
	Echo("declaring chili classes")	
	DeclareClasses()
	Echo("setting up controls")
	DeclareControls()
	Echo("injecting functions")
	DeclareFunctionsAfter()
	Echo("setting up drag/drop deamon")
	dragDropDeamon = GetDeamon()
	dragDropDeamon:Show()
	--Echo(dragDropDeamon.name)
	tabbar_settings:Select('Setup')
	---window_chili:Show()
	
	local mwWindow = Window:New{
		parent = screen0,
		x = 520, y = 780,
		width = 200,
		height = 100,		
	}
	mwLabel = Label:New {
		parent = mwWindow,
		caption = '',
		fontsize = 12,
		y = 20,
	}
	hvLabel = Label:New {
		parent = mwWindow,
		caption = '',
		fontsize = 12,
		y = 35,
	}
	mwWindow:Show()	
end


-------------------------------------------------------------





function UpdateGUI(dt)
	
	mx, mz = GetMouse()
	mz_inv = math.abs(screen0.height - mz)
	_, mcoords = TraceRay(mx, mz, true)
	modkeys.alt ,modkeys.ctrl, modkeys.space, modkeys.shift = GetModKeys()
	hoveredControl = screen0:HitTest(mx, mz_inv) -- this does not care for windows atm
		

	if settings.display[1] and (not hoveredControl or hoveredControl.name == 'dragdropdeamon') then
		local dist = 100000000
		local nearest
		for e, params in pairs(emitters) do
			if params.pos.x then 
				if mcoords then
					local dst = Distance(mcoords[1], mcoords[3], params.pos.x, params.pos.z)
					if dst < dist then
						dist = dst
						nearest = e						
					end
				end
			end
		end
		if nearest and dist < settings.interface[1] then
			hoveredEmitter = nearest
			if not worldTooltip then tooltipTimer = tooltipTimer - dt end
		else
			hoveredEmitter = nil
			worldTooltip = nil
			tooltipTimer = settings.interface[3]
		end
	else
		hoveredEmitter = nil
	end
	
	layout_main_templates:Refresh()

	for _, window in pairs(inspectionWindows) do window:Refresh() end
	
	if window_main.visible then
		button_emitters_anim:Invalidate()
	else
		button_show_anim:Invalidate()
	end	
		
	local c, d 
	if mcoords then
		c, d = mcoords[1], mcoords[3]
	else
		c, d = 1, 1
	end

	local mww = hoveredControl
	mwLabel:SetCaption("hv local: "..(mww and (mww.name or 'something') or 'none'))
	mwLabel:Invalidate()
	local hv = Chili.UnlinkSafe(Chili.Screen0.hoveredControl) 
	hvLabel:SetCaption("hv screen: "..(hv and (hv.name or 'something') or 'none'))
	hvLabel:Invalidate()
end


function DrawWorld()	
	draw.DrawEmitters(hoveredEmitter, containers.emitterslist.highlightEmitter)	
	if drag.typ.spawn then
		local p = mcoords or select(2,TraceRay(mx,mz,true))
		if not p then return end
		p[2] = p[2] + (drag.data.hoff or 0)
		DrawCursorToWorld(p[1], p[3], p[2], settings.display[2], settings.display[2], settings.display[2])
	end
end



-----------------------------------------------------------------------------------------------------------------------
---------------------------------------------- CALLINS ----------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------

function IsAbove(x, y)	
	return hoveredEmitter and not hoveredControl	
end


function GetTooltip(x, y)
	if not worldTooltip then
		if tooltipTimer > 0 then return end
		updateTooltip()
		tooltipTimer = settings.interface[3]
	end	
	return worldTooltip
end


function KeyPress(...)
	if not Chili then return false end
	if drag.started then	
		local key = select(1, ...)		
		if drag.typ.spawn and (key == KEYSYMS.RETURN or key == KEYSYMS.ESCAPE) then			
			if key == KEYSYMS.RETURN then				
				local p = mcoords or select(2,TraceRay(mx,mz,true))
				if not p then return false end
				SpawnDialog(p[1], p[3], GetGroundHeight(p[1],p[3]) + drag.data.hoff)
			end			
			drag.items = {}
			drag.data = {}
			drag.typ = {}
			drag.started = false							
			--Echo(key == KEYSYMS.RETURN and "drag ended" or "drag dropped")							
		end
		return true -- im just gonna keep all the inputs for safety
	end	
	local focusedControl = Chili.UnlinkSafe(Chili.Screen0.focusedControl)       
	if focusedControl and focusedControl.classname == 'FilterEditBox' then		
		focusedControl:KeyPress(...)
		return true
    end	
end


function TextInput(...)
	if not Chili then return false end
	local focusedControl = Chili.UnlinkSafe(Chili.Screen0.focusedControl)
	if drag.started then
		return true -- im just gonna keep all the inputs for safety
	end
	if focusedControl and focusedControl.classname == 'FilterEditBox' then
		return (not not focusedControl:TextInput(...))
    end	
end


function MousePress(x, y, button, mods)
	if drag.started then
		return drag.typ.spawn and button ~= 2 or false
	elseif hoveredEmitter then
		if button ~= 3 then			
			local e = emitters[hoveredEmitter]
			drag.started = true
			drag.typ.emitter = true			
			drag.items[1] = e
			drag.items[2] = hoveredEmitter -- we need the name, too
			drag.data.hoff = e.pos.y - GetGroundHeight(e.pos.x, e.pos.z)
		end
		return true
	end
	return false
end


-- events related to other types of drags should never arrive here				
function MouseRelease(x, y, button)
	if button == 3 then	
		if hoveredEmitter and not drag.started then
			local w = EmitterInspectionWindow.instances[hoveredEmitter]
			if w.visible then				
				w:Hide(); w:Invalidate(); w.layout.visible = false -- silly but layout panels never hide
			else				
				w:Refresh(); w:Show(); w.layout.visible = true
				local xp = mx > (screen0.width / 2) and (mx - w.width) or mx
				local yp = mz_inv > (screen0.height / 2) and (mz_inv - w.height) or mz_inv
				w:SetPos(xp, yp)
			end	
			return
		--elseif drag.typ.spawn then drop -- this is implicit
		end
	elseif drag.typ.spawn then
		local p = mcoords or select(2,TraceRay(mx,mz,true))
		if not p then return end
		SpawnDialog(p[1], p[3], GetGroundHeight(p[1],p[3]) + drag.data.hoff)			
	elseif drag.typ.emitter then
		controls.emitterslist[drag.items[2]].label:UpdateTooltip()
	end	
	-- this 
	drag.started = false
	drag.items = {}
	drag.data = {}
	drag.typ = {}	
	--drag.cb = false	--idk
end


function MouseWheel(up, value)	
	if modkeys.shift then
		if drag.typ.spawn then
			drag.data.hoff = drag.data.hoff + value * (modkeys.alt and 1 or(modkeys.ctrl and 100 or 10))
			drag.data.hoff = drag.data.hoff < 0 and 0 or drag.data.hoff			
		elseif hoveredEmitter then			
			local e = emitters[hoveredEmitter]
			local diff = value * (modkeys.alt and 1 or(modkeys.ctrl and 100 or 10))
			local gh = GetGroundHeight(e.pos.x, e.pos.z)			
			e.pos.y = (e.pos.y + diff) > gh and (e.pos.y + diff)  or gh					
			if drag.typ.emitter then
				drag.data.hoff = (drag.data.hoff + diff) > 0 and (drag.data.hoff + diff) or 0				
			end			
			updateTooltip()
			controls.emitterslist[hoveredEmitter].label:UpdateTooltip()
		end
		return true
	end
end

	
function MouseMove(...)	
	if drag.typ.emitter then
		if mcoords then
			drag.items[1].pos.x = mcoords[1]
			drag.items[1].pos.z = mcoords[3]
			drag.items[1].pos.y = mcoords[2] + drag.data.hoff
			updateTooltip()
			controls.emitterslist[drag.items[2]].label:UpdateTooltip()
			return true
		end
	end
end

function GetMouseWorldPosition()
	return mcoords[1], mcoords[2], mcoords[3]
end

--[[
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
end--]]


-- fuck you you-know-who
--[[
local function MouseOnGUI()
	--local mz_inv = math.abs(screen0.height - mz)
	return IsMouseMinimap(mx or 0, mz or 0) or MouseOver(mx, mz_inv)--screen0.hoveredControl --or screen0.focusedControl
end--]]



---------------------------------------------------------------------------------------------------------------------
------------------------------------------------- POPUPS ------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------

function ConfirmDialog(querystring, callback_confirm, args_confirm, callback_discard, args_discard)
	local window_query = Window:New {
		parent = screen0,
		x = "50%",
		y = "40%",
		--clientWidth = 160,
		clientHeight = 60,
		caption = "Are you sure?",
		resizable = false,
		autosize = true,
		KeyPress = function(self, key, ...)
			if key == KEYSYMS.RETURN then
				self:Confirm()
			elseif key == KEYSYMS.ESCAPE then
				self:Discard()
			end
			return true
		end,
		Confirm = function(self)
			if callback_confirm then					
				callback_confirm(unpk(args_confirm, 1))
			end	
			self:Dispose()		
		end,
		Discard = function(self)
			if callback_discard then
				callback_discard(unpk(args_discard, 1))
			end	
			self:Dispose()
		end,
	}--window_query.width = window_query.font:GetTextWidth(querystring) + 20
	local label = Label:New {
		parent = window_query,
		y = 8,
		caption = querystring,
		align = 'center',
		fontsize = 11,
		textColor = colors.yellow_09,
	}label.width = label.font:GetTextWidth(querystring)	
	Image:New {
		parent = window_query,
		file = icons.CLOSE_ICON,
		x = (window_query.width / 2) - 30,
		y = 40,
		width = 20,
		height = 20,
		tooltip = 'cancel',
		color = {0.8,0.3,0.1,0.7},
		OnClick = {			
			function(self)
				window_query:Discard()
			end,	
		},
	}
	Image:New {
		parent = window_query,
		file = icons.CONFIRM_ICON,
		x = window_query.width / 2 + 10,
		y = 40,
		width = 20,
		height = 20,
		tooltip = 'accept',				
		OnClick = {
			function(self)
				window_query:Confirm()
			end,	
		},					
	}
	cbTimer(1, function() -- we need to cheat chili a bit and delay the focus change by 1 millisecond
		window_query:Invalidate()
		window_query:Show()
		window_query.state.focused = true
		screen0.focusedControl = window_query	
		end, {}
	)
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
end


function ScriptBrowserPopup(e, source)	
	local window_browser_script = Window:New{
		parent = screen0,
		x = "30%",
		y = "30%",
		width = 290,
		height = 380,
		resizable = false,
		caption = "Load Script File", -- or just set working dir?
		textColor = colors.grey_08,
	}
	local label_script_path
	local browser_script_scroll = ScrollPanel:New {
		parent = window_browser_script,	
		y = 20,
		padding = {5,5,5,5},
		clientWidth = 250,
		clientHeight = 290,
		scrollPosX = -16,
		verticalSmartScroll = true,	
		scrollbarSize = 6,
	}
	local browser_script_layout = FileBrowserPanel:New {
		--name = 'browser_layout_map',
		parent = browser_script_scroll,
		--editbox = label_map_path,		
		minWidth = 230,
		autosize = true,
		resizable = false,
		draggable = false,
		centerItems = false,
		selectable = true,
		multiSelect = false,
		align = 'left',
		columns = 2,
		itemPadding = {3,2,3,2},
		itemMargin = {0,0,0,0},
		list = {},		
		fileFilter = {
			["lua$"] = icons.LUA_ICON,
		},
		Refresh = function(self)
			--Echo("refreshing...")
			self.path = self.path or (config.path_map and config.path_map.."luaui/scripts" or "luaui/scripts")	
			local list = self.list
			for i = 1, #list do				
				list[i]:Dispose()
				list[i]:Invalidate()
				list[i] = nil
			end	

			self:AddUserPaths()
			self:AddHardLinks()
			local legit = self:AddCurrentDir()			
			
			--self.visible = true
			self:Invalidate()
			
			return legit -- this is false for empty folders, sadly. not sure what to do about it
		end,
	}
	local browser_script_checkbox = Checkbox:New{
		parent = window_browser_script,
		y = -24,
		x = 6,
		width = 60,
		checked = true,		
		caption = 'localize',
		tooltip = 'select this option to copy the file into the scripts folder of your working directory',
		fontsize = 11,
		textColor = colors.yellow_09,
	}
	local browser_script_button_confirm = Image:New{
		parent = window_browser_script,
		file = icons.CONFIRM_ICON,
		x = -30,
		y = -26,
		width = 20,
		height = 20,
		tooltip = 'accept',				
		OnClick = {
			function(self,...)
				--local success = true
				-- need to check if folder is legit?				
				local fileAndPath = browser_script_layout.children[browser_script_layout._lastSelected].refer
				local file = browser_script_layout.children[browser_script_layout._lastSelected].text
				if browser_script_checkbox.checked then					
					--local t = config.path_map..PATH_SCRIPT..file
					--success = i_o.BinaryCopy(fileAndPath, t, true)
					fileAndPath = i_o.CopyScriptFile(fileAndPath, file)
					--fileAndPath = t
				end
				if fileAndPath then	
					if e.script then
						widget.RemoveScript(e.name)						
					end
					e.script = fileAndPath
					i_o.LoadEmitterScript(e, fileAndPath)
					source.hasPopup = false
					source.tooltip = (file..colors.green_1:Code().."\n\n(right-cliok to remove)") or 'Add Script File',
					window_browser_script:Hide()
				else
					Echo("unable to copy script file. try using the file externally and copy it later.")
				end

			end
		},	
		
	}
	local browser_script_button_discard = Image:New{
		parent = window_browser_script,
		file = icons.CLOSE_ICON,
		x = -60,
		y = -26,
		width = 20,
		height = 20,
		tooltip = 'cancel',
		color = {0.8,0.3,0.1,0.7}, --
		OnClick = {
			function(self,...)
				source.hasPopup = false
				window_browser_script:Hide()				
			end
		},
	}
	browser_script_layout:Refresh()
	window_browser_script:Show()
	return window_browser_script
end


function ScriptParamsPopup(e, source)
	local script = widget.scripts[e.name]
	assert (script, "tried to edit script params for "..e.name.." but e has no script!")
	local window_params_script = Window:New{
		parent = screen0,
		x = "30%",
		y = "30%",
		width = 290,
		height = 380,
		resizable = false,
		caption = "Script Vars", -- or just set working dir?
		textColor = colors.grey_08,
	}	
	local params_script_scroll = ScrollPanel:New {
		parent = window_params_script,	
		y = 20,
		padding = {5,5,5,5},
		clientWidth = 250,
		clientHeight = 290,
		scrollPosX = -16,
		verticalSmartScroll = true,	
		scrollbarSize = 6,
	}
	local params_script_layout = LayoutPanel:New {
		parent = params_script_scroll,
		minWidth = 230,
		autosize = true,
		resizable = false,
		draggable = false,
		centerItems = false,
		selectable = true,
		multiSelect = false,
		align = 'left',
		columns = 2,
		itemPadding = {3,2,3,2},
		itemMargin = {0,0,0,0},
		list = {},
		Refresh = function(self)
			local n = 0
			if script.params and type(script.params) == 'table' then				
				local list = self.list
				for k, v in pairs(script.params) do					
					n = n + 1
					local typ = type(v)
					MouseOverTextBox:New{parent = self, clientWidth = 160, fontsize = 11, textColor = colors.yellow_09,
						padding = {0, 2, 0, 0}, text = k, tooltip = "Type: "..typ, OnClick = {function() end},}
					if typ == 'boolean' then
						Checkbox:New{
							parent = self,
							checked = v,
							width = 50,
							fontsize = 11,
							textColor = v and colors.green_1 or colors.red_1,		
							caption = v and 'true' or 'false',
							OnChange = {function(self, state)
								--local state = not self.checked
								if state then 
									self.font:SetColor(colors.green_1)
									self.caption = 'true'
								else
									self.font:SetColor(colors.red_1)
									self.caption = 'false'
								end
								self:Invalidate()
								script.params[k] = state
							end,},
						}
					elseif typ == 'table' then
						local offset = 20
						Label:New{parent = self, fontsize = 11, textColor = colors.grey_08, caption = 'table',} -- dummy for layout						
						if #v > 0 then
							for i = 0, #v do
							end
						else
							for _k, _v in pairs(v) do
							end
						end
					elseif typ == 'userdata' then
						MouseOverTextBox:New{parent = self, clientWidth = 50, fontsize = 11, textColor = colors.red_1,
							 text = 'userdata'}						
					else
						FilterEditBox:New{
							parent = self,
							width = 50,
							height = 14,
							--padding = {0, 1, 0, 1},
							fontsize = 11,
							textColor = colors.grey_08,
							borderColor = colors.grey_035,
							borderColor2 = colors.grey_02,
							backgroundColor = colors.grey_01,
							text = tostring(v),							
						}
					end
				end
			end	
			if n == 0 then
				self.columns = 1
				Label:New{parent = self, width = self.width, textColor = colors.yellow_09,	fontsize = 11,
					caption = "script has no variable parameters."}
				Label:New{parent = self, width = self.width, textColor = colors.yellow_09,	fontsize = 11,
					caption = "add a 'params' table to the file, "}
				Label:New{parent = self, width = self.width, textColor = colors.yellow_09,	fontsize = 11,
					caption = "or return a table as the second value."}						
			end
		
		end,
	}
	
	local params_script_button_confirm = Image:New{
		parent = window_params_script,
		file = icons.CONFIRM_ICON,
		x = -30,
		y = -26,
		width = 20,
		height = 20,
		tooltip = 'accept',	
	}	
	local params_script_button_discard = Image:New{
		parent = window_params_script,
		file = icons.CLOSE_ICON,
		x = -60,
		y = -26,
		width = 20,
		height = 20,
		tooltip = 'cancel',
		color = {0.8,0.3,0.1,0.7}, --
	}	
	params_script_layout:Refresh()
	window_params_script:Show()
	return window_params_script	
	
end

--

local gui = getfenv()
gui.EmitterInspectionWindow = EmitterInspectionWindow
gui.controls = controls
gui.containers = containers
gui.colors = colors


	
return gui

