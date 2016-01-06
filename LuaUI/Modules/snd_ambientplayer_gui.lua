------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
--		file : snd_ape_gui.lua												--
--		desc : chili gui module for ambient sound editor								--
--		author : Klon 																	--
--		date : "24.7.2015",																--
--		license : "GNU GPL, v2 or later",												--
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------


local pairs = widget.pairs
local ipairs = widget.ipairs
local type = widget.type
local string = widget.string
local tostring = widget.tostring
local tonumber = widget.tonumber
local setmetatable = widget.setmetatable
local getfenv = widget.getfenv
local setfenv = widget.setfenv
local rawset = widget.rawset
local assert = widget.assert
local os = widget.os
local math = widget.math
local select = widget.select

local PATH_LUA = widget.LUAUI_DIRNAME

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
local FilterEditBox
local ClickyTextBox
--local color2incolor
--local incolor2color

-- these dont really have to be locals? as images are just loaded once
local SETTINGS_ICON = PATH_LUA..'Images/Epicmenu/settings.png'
local HELP_ICON = PATH_LUA..'Images/Epicmenu/questionmark.png'
local CONSOLE_ICON = PATH_LUA..'Images/speechbubble_icon.png'
local PLAYSOUND_ICON = PATH_LUA..'Images/Epicmenu/vol.png'
local PROPERTIES_ICON = PATH_LUA..'Images/properties_button.png'
--local PLAYER_CONTROLS_ICON = PATH_LUA..'Images/Commands/Bold/'..'drop_beacon.png'
local CLOSE_ICON = PATH_LUA..'Images/close.png'
local CLOSEALL_ICON = PATH_LUA..'Images/closeall.png'
local CONFIRM_ICON = PATH_LUA..'Images/arrow_green.png'
--local UNDO_ICON = PATH_LUA..'Images/undo.png'
local COGWHEEL_ICON = PATH_LUA..'Images/cogwheel.png'

local HELPTEXT = [[generic info here]]

local inspectionWindows = {}
local containers = {}
local controls = {}	

-- attention needs to be paid what is added to containers
setmetatable(controls, {
	__index = function(t, k)
		if containers[k] then rawset(t, k, {}) return t[k]
		else return nil end
	end	
})	

local WINDOW_INSPECT_PROTOTYPE
local BUTTON_CLOSE_INSPECT_PROTOTYPE
local BUTTON_CLOSEALL_INSPECT_PROTOTYPE
--local BUTTON_CLOSE_IMG_INSPECT_PROTOTYPE
local SCROLL_INSPECT_PROTOTYPE
local LAYOUT_INSPECT_PROTOTTYPE



local window_main
local scroll_main
local layout_main
local button_console
local button_help
local button_settings

local window_emitters -- unsure this will be used
local scroll_emitters

local window_console
local scroll_console
local ClickyTextBox_console

local window_help
local scroll_help
local ClickyTextBox_help

local window_settings
local tabbar_settings
local tabs_settings = {}

--local editbox_mapfolder
--local editbox_soundfolder
--local buttonimage_mapfolder
--local buttonimage_soundfolder

--local window_inspect
--local label_inspect

local col_green_1 = {0.4, 1, 0.1, 1}
local col_green_06 = {0, 0.6, 0.2, 0.9}
local col_yellow = {0.9, 0.9, 0, 0.9}
local col_white_09 = {0.9, 0.9, 0.9, 1}
local col_grey_08 = {0.8, 0.8, 0.8, 0.7}
local col_grey_02 = {0.2, 0.2, 0.2, 0.5}
local col_grey_03 = {0.3, 0.3, 0.3, 0.5}
local col_blue_07 = {0.7, 0.7, 0.8, 0.7}

--local drag

function ProxyHide(control) control:Hide() end
function ProxyShow(control) control:Show() end


local function DeclareControls()
	---------------------------------------------------- main frame ------------------------------------------------
	
	window_main = Window:New {
		x = '65%',
		y = '25%',	
		dockable = false,
		parent = screen0,
		caption = "Ambient Sound Editor",
		draggable = true,
		resizable = false,
		dragUseGrip = true,
		clientWidth = 350,
		clientHeight = 540,		
		children = {
			Label:New {
				x = 0,
				y = 20,
				clientWidth = 260,
				parent = window_main,
				align = 'center',
				caption = '-Track Overview-',
				textColor = col_yellow,		
			},
		},
	}
	scroll_main = ScrollPanel:New {
		x = 0,
		y = 40,
		clientWidth = 340,
		clientHeight = 420,
		parent = window_main,
		scrollPosX = -16,
		verticalSmartScroll = true,	
		scrollbarSize = 6,
		padding = {5,10,5,10},		
	}	
	layout_main = LayoutPanel:New {		
		name = 'tracklist',
		parent = scroll_main,
		orientation = 'vertical',		
		selectable = true,		
		multiSelect = true,
		maxWidth = 340,
		minWidth = 340,
		itemPadding = {6,2,6,2},
		itemMargin = {0,0,0,0},
		autosize = true,
		align = 'left',
		columns = 4,
		left = 0,
		centerItems = false,
		OnSelectItem = {
			function(self, index, state)								
				local c = self.children[index]				
				if c and c.AllowSelect then c:AllowSelect(index, state) end
				Echo("layout: "..index)
				--if c.refer then Echo(c.refer) end
				--for k,v in pairs(self.selectedItems) do
				--	Echo(k..", "..tostring(v))
				--end
			end				
		},
		IsMouseOver	= function(self, mx, my) 
			local x, y = self:LocalToScreen(self.x, self.y)
			Echo("test: "..mx..", "..my)
			Echo("against:  X:"..x.." X+W:"..(x + self.width).." Y:"..y.." Y+H:"..(y + self.height))
			return self.visible and (mx > x and mx < x + self.width) and (my > y and my < y + self.height) 
		end,

			--if self.visible and (mx > self.x and mx < self.x + self.width) and (my > self.y and my < self.y + self.height) 
			--	then return true end end,
		--OnMouseUp = {function(self,...) self.inherited.MouseDown(self,...) return self end},			
	}		
	button_console = Button:New {
		x = 0,
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
				file = CONSOLE_ICON,
			},
		}
	}
	
	button_help = Button:New {
		x = - 32,
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
				file = HELP_ICON,
			},
		}
	}
	
	button_settings = Button:New {
		x = - 74,
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
				file = SETTINGS_ICON,
			}
		}	
	}
	
	containers.main = window_main
	controls.tracklist = layout_main
	
	---------------------------------------------------- emitters window ------------------------------------------------	
	--[[
	window_emitters = Window:New {
		x = '25%',
		y = '25%',	
		--dockable = false,
		parent = screen0,
		caption = "Ambient Sound Editor",
		draggable = true,
		resizable = false,
		dragUseGrip = true,
		clientWidth = 300,
		clientHeight = 540,
		backgroundColor = {0.8,0.8,0.8,0.9},
		children = {
			Label:New{
				x = 0,
				y = 20,
				clientWidth = 260,
				parent = window_emitters,
				align = 'center',
				caption = '-Emitters-',
				textColor = {1,1,0,0.9},
			},
		},		
	}
	scroll_emitters = ScrollPanel:New {
		x = 0,
		y = 40,
		clientWidth = 300,
		clientHeight = 420,
		parent = window_emitters,
		scrollPosX = -16,
		horizontalScrollbar = false,
		verticalScrollbar = true,
		verticalSmartScroll = true,	
		scrollbarSize = 6,
		padding = {5,10,5,10},
		
	}	
	window_emitters:Hide()
	containers.emitters = window_emitters
	--]]
	
	---------------------------------------------------- log window ------------------------------------------------	
	window_console = Window:New {
		x = "25%",
		y = "5%",
		parent = screen0,
		caption = "Message Log",
		draggable = true,
		resizable = false,
		dragUseGrip = true,
		clientWidth = 640,
		clientHeight = 140,						
	}
	scroll_console = ScrollPanel:New {
		x = 0,
		y = 12,
		clientWidth = 640,
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
	ClickyTextBox_console = ClickyTextBox:New {
		x = 4,
		y = 0,
		autosize = true,
		parent = scroll_console,
		align = 'left',
		textColor = col_yellow,
		backgroundColor = col_grey_02,
		borderColor = col_grey_03,
		text = '',	
	}
	
	containers.console = window_console
	controls.log = ClickyTextBox_console
	
	---------------------------------------------------- help window ------------------------------------------------

	window_help = Window:New {
		x = "20%",
		y = "7%",
		parent = screen0,
		caption = "Help",
		draggable = true,
		resizable = false,
		dragUseGrip = true,
		clientWidth = 400,
		clientHeight = 490,
		--backgroundColor = col_grey_08,
		
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
	ClickyTextBox_help = ClickyTextBox:New {
		x = 4,
		y = 0,
		autosize = true,
		parent = scroll_help,
		align = 'left',
		textColor = col_grey_08,
		backgroundColor = col_grey_02,
		borderColor = col_grey_03,
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
		
defaults to length_real, unit is seconds]].."\n\n\255\255\150\0(this has nothing to do with the \"looptime\" option that spring sounditems can use. this widget never uses that and if you use it for any of the sounditems used by the widget, things will likely break.)\255\255\255\255",

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

defaults to 100000, unit is elmos]].."\n\n\255\255\150\0(the side length of a 1x1 map square is 512 elmos.)\255\255\255\255",

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
	
	window_properties = Window:New {
		x = "25%",
		y = "25%",
		parent = screen0,
		caption = "Properties",
		draggable = true,
		resizable = false,
		dragUseGrip = true,
		clientWidth = 400,
		clientHeight = 216,
		--backgroundColor = col_grey_08,	
		controls_props = {},
	}		
	controls.properties.file = ClickyTextBox:New {
		textColor = col_green_1,
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
		IsMouseOver	= function(self, mx, my) 
			local x, y = self:LocalToScreen(self.x, self.y)
			Echo("test: "..mx..", "..my)
			Echo("against:  X:"..x.." X+W:"..(x + self.width).." Y:"..y.." Y+H:"..(y + self.height))
			return self.visible and (mx > x and mx < x + self.width) and (my > y and my < y + self.height) 
			end,
			--if self.visible and (mx > self.x and mx < self.x + self.width) and (my > self.y and my < self.y + self.height) 
			--	then return true end end,
		--OnMouseUp = {function(self,...) self.inherited.MouseDown(self,...) return self end},
		Refresh = function(self)
			local label_height = math.floor(controls.properties.file.font:GetTextWidth(controls.properties.file.text)/380) * 10
			self.y = 32 + label_height
			self:Invalidate()
		end,
	}				
	--window_properties.layout = layout_properties
	
	
	
	for i, prop in ipairs(props) do					
		ClickyTextBox:New { 
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
		}
		Image:New {					
			refer = i,
			parent = layout_properties,
			file = COGWHEEL_ICON,
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
	controls.properties.in3_defaultBtn = Image:New {					
		--refer = i,
		parent = window_properties,
		file = COGWHEEL_ICON,
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
	local button_discard = Image:New {					
		parent = window_properties,
		file = CLOSE_ICON,
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
	local button_confirm = Image:New {					
		parent = window_properties,
		file = CONFIRM_ICON,
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
	
	---------------------------------------------------- settings window ------------------------------------------------
	window_settings = Window:New {
		x = "25%",
		y = "25%",
		parent = screen0,
		caption = "Settings",
		draggable = true,
		resizable = false,
		dragUseGrip = true,
		clientWidth = 440,
		clientHeight = 210,
		autosize = true,
		--backgroundColor = col_grey_08,
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
	}
	
	for i = 1, #tabbar_settings.children do
		p = tabbar_settings.children[i]
		p.backgroundColor = col_grey_02
		p.borderColor = col_grey_03
		p.font:SetColor(col_blue_07)
		
		c = tabbar_settings.children[i].caption
		--if not c == 'Player' then return end	
		Echo (c)
		
		tabs_settings[c] = ScrollPanel:New {
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
			--autosize = true,
			--Refresh = function(self)
				--if tabbar_settings.selected_obj == self then self:SetVisibility(true) else self:SetVisibility(false) end 
			--end,			
		}
		window_settings:AddChild(tabs_settings[c])
		tabs_settings[c].layout = LayoutPanel:New {
			name = 'layout_'..c,
			autosize = true, --?
			x = 10,
			y = 10,
			--clientWidth = 440,
			--clientHeight = 205,
			maxWidth = 440,
			minWidth = 440,
			itemPadding = {2,2,2,2},
			itemMargin = {0,0,0,0},
			parent = tabs_settings[c],
			orientation = 'vertical',
			centerItems = false,
			columns = 1,	
			align = 'left',
			--parent = tabs_settings[c],
		},
		Echo (tabs_settings[c].name)
	end						
		
	containers.settings = window_settings

	local se = options.showemitters
	controls.settings[se.name] = Checkbox:New{
		parent = tabs_settings['Display'].layout,
		width = 100,
		refer = se,
		value = se.value,
		caption = se.name,
		fontSize = 11,
		--padding = {22,22,2,22},
		margin = {2,12,2,12},
		textColor = col_grey_08,
		SetValue = function(self, val)
			if not self.checked == val then self:Toggle() end
		end,
		OnChange = {function(self, checked) -- this whole thing is a bit bad, maybe the update call should be different. consider memoize
				se.value = checked
			end
		},
	}	
	
	local order = {red = 2, blue = 3, green = 4, alpha_inner = 5, alpha_outer = 6, highlightfactor = 7}
	local items = {[1] = options.emitter_radius}
	--local i = 0	
	for o, params in pairs(options) do			
		if string.find(o, 'color') then local color = o:sub(7);	items[order[color]] = params end
	end
	for i = 1, #items do
		local o = items[i]
		Label:New{
			caption = o.name,
			fontSize = 11,
			textColor = col_grey_08,
			parent = tabs_settings['Display'].layout,
		}
		controls.settings[o.name] = Trackbar:New {
			refer = o,
			--name = 'test'..o.name,
			width = 200,				
			parent = tabs_settings['Display'].layout,
			min = o.min,
			max = o.max,
			value = o.value,
			step = o.step,
			OnChange = {function(self) -- this whole thing is a bit bad, maybe the update call should be different. consider memoize
					--setfenv(1, widget)
					o.value = self.value
					UpdateMarkerList() 
				end
			},				
		}
	end


	Echo(#tabs_settings['Display'].layout.children)
	
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

	
	---------------------------------------------------- inspect emitter window ------------------------------------------------
	WINDOW_INSPECT_PROTOTYPE = {
		x = "50%",
		y = "50%",
		--parent = screen0,
		caption = "Details",
		draggable = true,
		resizable = false,
		dragUseGrip = true,
		clientWidth = 300,
		clientHeight = 250,
		--backgroundColor = {0.8,0.8,0.8,0.9},
		inspect = nil,
		--Refresh = function(self) end,
	}	
	BUTTON_CLOSE_INSPECT_PROTOTYPE = {
		name = 'closebutton',
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
				self.listener.inspect = nil
				--self.listener():Refresh()				
			end
		},		
	}
	BUTTON_CLOSEALL_INSPECT_PROTOTYPE = {
		name = 'closeallbutton',
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
				for _, window in pairs(inspectionWindows) do window.inspect = nil end
			end
		},		
	}	
	LABEL_INSPECT_PROTOTYPE = {		
		name = 'label',
		y = 20,				
		caption = '',
		width = 300,				
		align = 'center',		
		textColor = col_yellow,
	}
	SCROLL_INSPECT_PROTOTYPE = {				
		y = 40,
		clientWidth = 300 - 8,
		clientHeight = 250 - 90,				
		scrollPosX = -16,
		horizontalScrollbar = false,
		verticalScrollbar = true,
		verticalSmartScroll = false,	
		scrollbarSize = 6,
		padding = {5,10,5,10},		
	}
	LAYOUT_INSPECT_PROTOTYPE =  {	
		name = 'layout',
		clientWidth = 300,
		clientHeight = 250, -- this was width too. ?
		maxWidth = 300,
		minWidth = 0, -- same here						
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
	}		
	--WINDOW_INSPECT_PROTOTYPE = Window:New(INSPECT_BUILDTABLE)
	--WINDOW_INSPECT_PROTOTYPE:Hide()
	--containers.inspect = window_inspect
end



local function DeclareFunctions()

	--------------------------------------------------------------------------------------------------
	-- main frame
	layout_main.Refresh = function(self) 
		local valid = true
		for item, params in pairs(sounditems.templates) do
		--local i = controls.main and #controls.main or 1 --< cant index the table properly if things get removed
			if not controls.main['label_'..item] then -- make new controls for newly added items
				valid = false
				controls.main['label_'..item] = ClickyTextBox:New { --< should make custom clickie ClickyTextBox for this
					refer = item,					
					clientWidth = 200,
					parent = layout_main,
					align = 'left',
					text = item,
					fontSize = 10,
					textColor = col_white_09,
					textColorNormal = col_white_09,
					textColorSelected = col_green_1,
					--backgroundColor = col_grey_02,
					--backgroundFlip = {0.6,0.6,0.9,0.5},
					--borderColor = {0.3,0.3,0.3,0.5},
					--borderFlip = {0.7,0.7,1,0.5},
					OnMouseOver = { 
						function(self)
							local ttip = "\255\80\255\50"..self.text.."\255\255\255\255\n\n"--.."\n--------------------------------------------------------------\n\n"
							for key, _ in pairs(sounditems.default) do ttip = ttip..key..": "..tostring(params[key]).."\n" end
							ttip = ttip..'\n(right-click to edit)'
							self.tooltip=ttip
						end
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
				controls.main['length_'..item] = ClickyTextBox:New {
					refer = item,
					x = 204,
					clientWidth = 26,
					parent = layout_main,
					align = 'right',
					text = ''..params.length_real,
					fontSize = 10,
					textColor = col_white_09,
					backgroundColor = col_grey_02,
					borderColor = col_grey_03,
					tooltip = [[The length of the item in seconds. As this information can't currently be obtained by the Widget, you may want to insert it manually.]],
					-- this needs a refresh function for playback
					--AllowSelect = function(self, idx, select) layout_main.DeselectItem(idx) Echo("control: "..idx) end, -- block selection
				}
				controls.main['editBtn_'..item] = Image:New {
					refer = item,
					parent = layout_main,
					file = PROPERTIES_ICON,
					width = 20,
					height = 20,
					tooltip = 'Sounditem Properties',
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
					--AllowSelect = function(self, idx, select) layout_main.DeselectItem(idx) Echo("control: "..idx) end, -- block selection
				}
				controls.main['playBtn_'..item] = Image:New {
					refer = item,
					parent = layout_main,
					file = PLAYSOUND_ICON,
					width = 20,
					height = 20,
					tooltip = 'Play',
					color = col_green_06,
					margin = {-6,0,0,0},
					OnClick = {
						function()
							DoPlay(item, options.volume.value, emitters.global) --< this probably shouldnt return anything
						end
					},
					--AllowSelect = function(self, idx, select) layout_main.DeselectItem(idx) Echo("control: "..idx) end, -- block selection
				}
			else -- update controls for exisiting items (not a whole lot to do as of now)
				controls.main['label_'..item].text = item
				controls.main['length_'..item].text = params.length_real
			end				
		end
		
		--if controls.main then
		for control, params in pairs(controls.main) do				
			if not sounditems.templates[params.refer] then -- dispose of controls for items that were removed
				valid = false
				controls.main[control]:Dispose()
				controls.main[control] = nil
			end
		end
		--end
		
		if not valid then self:Invalidate() end	
	end
	
	--------------------------------------------------------------------------------------------------
	-- inspection window
	
	WINDOW_INSPECT_PROTOTYPE.Refresh = function(self)
		local this = self -- userdata
		local name = self.name -- string :)
		
		-- could/should check for visibility here and only update then
		if self.inspect then
			--Echo("check")
			local valid = true
			local inspect = self.inspect -- string?
			--Echo(type(inspect))
			local label = self.label
			local layout = self.layout
			--Echo (layout.name)
			--Echo("check 2")
			if emitters[inspect] then
				local e = emitters[inspect]
				label:SetCaption(inspect)
				
				for i = 1, #e.sounds do
					local sound = e.sounds[i]
					local item = sound.item
					if not controls[name]['label_'..item] then
						valid = false						
						local _, endprefix = string.find(item, "[%$].*[%$%s]")
						local txt = '\255\230\255\100'..string.sub(item, 0, endprefix)
							..'\255\255\255\255'..string.sub(item, endprefix + 1)
						local t = {}
							t.name = 'label_'..item							
							t.refer = item
							t.width = this.width - 140
							t.parent = layout
							t.align = 'left'
							t.text = txt or 'error: no item' --< that shouldnt happen
							t.fontSize = 10
							t.textColor = col_white_09
							t.backgroundColor = col_grey_02
							t.borderColor = col_grey_03
							t.OnMouseOver = {
								function(self) 
									local _, endprefix = string.find(item, "[%$].*[%$%s]")
									local ttip = '\255\230\255\100'..string.sub(item, 0, endprefix)
										..'\255\125\230\255'..string.sub(item, endprefix + 1).."\255\255\255\255\n\n"
										
									--local ttip = "\255\125\230\255"..item.."\255\255\255\255\n\n"--.."\n--------------------------------------------------------------\n\n"
									for key, _ in pairs(sounditems.default) do ttip = ttip..key..": "..
											tostring(sounditems.instances[sound.item][key]).."\n" 
									end
									-- ttip = ttip..'\n(right-click to edit)' -- that is not true :/
									self.tooltip=ttip
								end
							}							
						controls[name]['label_'..item] = ClickyTextBox:New (t)						
						t = {}
							t.name = 'editBtn_'..item
							t.refer = item
							t.parent = layout
							t.file = PROPERTIES_ICON			
							t.width = 20
							t.height = 20			
							t.tooltip = 'Sound Properties'
							t.color = {0.8,0.7,0.9,0.9}				
							t.OnClick = {
								function(self,...)									
									local w = window_properties
									if w.refer then w:Confirm() end
									w.refer = self.refer
									w:Refresh()
									w:Show()									
								end
							}
						controls[name]['editBtn_'..item] = Image:New (t)
						t = {}
							t.name = 'playBtn_'..item
							t.refer = item
							t.parent = layout
							t.file = PLAYSOUND_ICON		
							t.width = 20
							t.height = 20
							t.tooltip = 'Play at Location'
							t.color = col_green_06
							t.margin = {-6,0,0,0}
							t.OnClick = {
								function()
									--local px, py, pz = e.pos.x, e.pos.y, e.pos.z									
									return DoPlay(sound.item, options.volume.value, e) -- pos is false for global emitter, for some silly reason. needs change
								end
							}									
						controls[name]['playBtn_'..item] = Image:New (t)
					else						
						local _, endprefix = string.find(item, "[%$].*[%$%s]")
						local txt = '\255\230\255\100'..string.sub(item, 0, endprefix)
							..'\255\255\255\255'..string.sub(item, endprefix + 1)
						controls[name]['label_'..item].text = txt						
					end				
				end
				
				for control, params in pairs(controls[name]) do				
					if not e.sounds[params.refer] then -- dispose of controls for items that were removed						
						params.refer = nil
						params:Dispose()
						controls[name][control] = nil
						valid = false
					end	
				end											
			elseif true then do end
			else --< if it is some kind of object that isnt meant to be here
				assert (false, "invalid or misplaced inspect object: "..type(object).." - "..tostring(object))
			end
		elseif self.visible then self:SetVisibility(false) end		
		
		if not valid then self:Invalidate() end
	end
	
	--------------------------------------------------------------------------------------------------
	-- settings window
	
	tabbar_settings.OnChange = {
			function(self, tab)		
				for k, params in pairs(tabs_settings) do 					
					local hidden = params.hidden -- fuck you, chili
					if not hidden then tabs_settings[k]:SetVisibility(false) end
				end
				tabs_settings[tab]:SetVisibility(true)
				
				for i = 1, #self.children do
					local c = self.children[i]
					if c.caption == tab then
						c.backgroundColor = {0.35,0.35,0.35,0.5}
						c.borderColor = {0.5,0.5,0.5,0.5}												
						--c:Invalidate()
					else 
						c.backgroundColor = {0.2,0.2,0.2,0.5}
						c.borderColor = {0.3,0.3,0.3,0.4}					
					end
				end				
			end
	}
	
	-----------------------------------------------------------------------------------------------------
	-- properties window
	

	window_properties.Refresh = function(self, ...)		
		if self.refer then 			
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
			controls.properties.file:Invalidate()
			layout_properties:Refresh()
			if not controls.properties[0].checked == item.in3d then controls.properties[0]:Toggle() end
			controls.properties[0]:Refresh()
			controls.properties.in3_defaultBtn:Refresh()
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
	
	
	--------------------------------------------------------------------------------------------------
	-- inspection windows shared handle	
	-- 
	
	-- this is misleading they dont actually dispose, but close. still might be useful
	--[[
	inspectionWindows.DisposeAll = function(self)
		for w, params in pairs(self) do
			if type(params) ~= 'function' then params.inspect = nil end --there should be a more elegant way to exclude these functions
			 -- windows without inspect selfdestruct
		end
	end
	inspectionWindows.RefreshAll = function(self)
		for w, params in pairs(self) do
			if type(params) ~= 'function' then params:Refresh() end -- same here
			
		end
	end	
	--]]
	setmetatable(inspectionWindows, {
		__mode = 'v',
		__index = function(t, k)		
			Echo("new inspection window - key: "..tostring(k).."("..type(k)..")")
			local function Copy(_t) -- recursive table copy. these prototypes only go 1 level deep atm
				local w = {}
				for _k, v in pairs(_t) do	
					if type(v) == 'table' then w[_k] = Copy(v) else w[_k] = v end
				end
				return w
			end					
			local wt = Copy(WINDOW_INSPECT_PROTOTYPE)
			wt.name = 'inspect_'..tostring(k)
			wt.refer = tostring(k)
			
			w = Window:New (wt)
			-- these will not go out of scope if local will they?
			local label = Label:New (Copy(LABEL_INSPECT_PROTOTYPE))			
			local btnA = Button:New (Copy(BUTTON_CLOSE_INSPECT_PROTOTYPE))		
			local btnB = Button:New (Copy(BUTTON_CLOSEALL_INSPECT_PROTOTYPE))
			local scroll = ScrollPanel:New (Copy(SCROLL_INSPECT_PROTOTYPE))
			local layout = LayoutPanel:New (Copy(LAYOUT_INSPECT_PROTOTYPE))
						
			screen0:AddChild(w)
			w:AddChild(label)
			w:AddChild(btnA)
			w:AddChild(btnB)
			btnA:AddChild(Image:New {width = "100%",	height = "100%", file = CLOSE_ICON, padding = {0,0,0,0}, margin = {0,0,0,0}})
			btnB:AddChild(Image:New {width = "100%",	height = "100%", file = CLOSEALL_ICON, padding = {0,0,0,0}, margin = {0,0,0,0}})
			w:AddChild(scroll)
			scroll:AddChild(layout)
			
			w.label = label -- userdata
			w.layout = layout -- userdata
			btnA.listener = w
			--w:Invalidate()
			containers[wt.name] = w
			--controls[wt.name] = {} -- this is built automatically
			w:Refresh()
			
			rawset(t, k, w)
			return t[k]		
		end,
	}) 
	
	--------------------------------------------------------------------------------------------------
	--------------------------------------------------------------------------------------------------
	--------------------------------------------------------------------------------------------------
	--------------------------------------------------------------------------------------------------
	
	--[[
	function Chili.ClickyTextBox:OnMouseDown(...)
		--self.state.pressed = true
		inherited.MouseDown(self, ...)
		--self:Invalidate()
		return self
	end
	
	function Chili.ClickyTextBox:OnMouseUp(...)
		--if (self.state.pressed) then
		--self.state.pressed = false
		inherited.MouseUp(self, ...)
		--self:Invalidate()
		return self
	end
	--]]
end




function SetupGUI()		
		
	Chili = widget.WG.Chili

	if (not Chili) then		
		Echo("<ambient gui> Chili not found")
		return false
	end
	--[[
	for k,v in pairs(Chili) do
		if type(v) == 'function' then Echo(k) end
	end

	Chili.TextInput = function(self,utf8, ...)
		Echo("called")
		if Spring.IsGUIHidden() then return false end		
		return Chili.Screen0:TextInput(utf8, ...)
		
	end
	Chili.widgetHandler:UpdateCallIn("TextInput") 
	--widget.widgetHandler:UpdateWidgetCallIn("TextInput", Chili)
	
	Chili.Object.OnTextInput = {}
	Chili.Object.TextInput = function(self,...)	
		--Echo("object")
		if (self:CallListeners(self.OnTextInput, ...)) then
			return self
		end
		return false
	end
	Chili.Screen.TextInput = function(self,...)
		--Echo("screen")
		local focusedControl = Chili.UnlinkSafe(self.focusedControl)
       -- Echo("1")
		if focusedControl then
				--Echo("focus")
                return (not not focusedControl:TextInput(...))				
        end
		--Echo("no focus")
        return (not not inherited:TextInput(...))
	end
	Chili.Control.TextInput = function(self,...)
		--Echo("control")
		return inherited.TextInput(self, ...)
	end
	Chili.EditBox.TextInput = function(self,...)
		--Echo("box")
		return inherited.TextInput(self, ...)
	end--]]
	
	
	
	screen0 = Chili.Screen0
	
	Image = Chili.Image
	Button = Chili.Button
	Checkbox = Chili.Checkbox
	Window = Chili.Window
	Label = Chili.Label
	Line = Chili.Line
	FilterEditBox = Chili.EditBox:Inherit{
		classname = 'FilterEditBox',
		allowUnicode = true,
		cursorColor = {0,1.3,1,0.7},
		--borderColor = {0.7,0.7,0.7,.5},
		--backgroundColor = {0.8, 0.8, 1.0, 0.4},
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
	
	
	ClickyTextBox = Chili.TextBox:Inherit{
		classname = "clickytextbox",
		HitTest = function(self, x,y)
			return self
		end,
		--[[
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
		OnClick = {function(self,...)
			local btn = select(3,...)
			if not btn == 3 then return nil end
		end,}--]]
	}
	Panel = Chili.Panel
	ScrollPanel = Chili.ScrollPanel
	LayoutPanel = Chili.LayoutPanel
	StackPanel = Chili.StackPanel
	--TreeView = Chili.TreeView
	Grid = Chili.Grid
	TabBar = Chili.TabBar
	Trackbar = Chili.Trackbar
	--Node = Chili.TreeViewNode
	color2incolor = Chili.color2incolor
	incolor2color = Chili.incolor2color
	
	--drag = getfenv().drag

	DeclareControls()
	DeclareFunctions()
	
	tabbar_settings:Select('Player')
end


function UpdateGUI()
	--Echo("call")
	--editbox_mapfolder.text = config.path_map
	--editbox_soundfolder.text = config.path_sound
	
	layout_main:Refresh()
	--inspectionWindows:RefreshAll()
	
	for _, window in pairs(inspectionWindows) do window:Refresh() end
	--for _, tab in pairs(tabs_settings) do tab:Refresh() end
	
end


function MouseOver(mx, my)
	--Echo ("call")
	for c, params in pairs(containers) do		
		--if params.noSelfHitTest then Echo(c.." has no self hit test") end
		local w = params		
		if params.visible and (mx > w.x and mx < w.x + w.width) and (my > w.y and my < w.y + w.height) then return containers[c] end
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


--

local gui = getfenv()
gui.inspectionWindows = inspectionWindows
gui.controls = controls
gui.containers = containers


	
return gui


--[[

	
	editbox_mapfolder = EditBox : New {
		x = 123,
		y = 26,
		clientWidth = 297,
		align = 'left',
		text = config.path_map,
		OnChange = 	{	function()
						config.path_map=text
						end
					},
		parent = window_settings,
		--fontSize = 10,
		textColor = {0.9,0.9,0.9,1},
		borderColor = {0.2,0.2,0.2,0.5},
		backgroundColor = {0.3,0.3,0.3,0.5},
		tooltip = The .sdd folder this map resides in. By default, the Widget will save all its data in the maps folder structure. If you are running from an archive, ...,
	}
	editbox_soundfolder = EditBox : New {
		x = 132,
		y = 52,
		clientWidth = 288,
		align = 'left',
		text = config.path_sound,
		OnChange = 	{	function()
							config.path_sound=text
						end
					},
		parent = window_settings,
		--fontSize = 10,
		textColor = {0.9,0.9,0.9,1},
		borderColor = {0.2,0.2,0.2,0.5},
		backgroundColor = {0.3,0.3,0.3,0.5},
		tooltip = Where our sound files are read from. Note that while you can load sound files from anywhere on your computer, you eventually need to put them here if you wish to incorporate them into your map.,
	}
	buttonimage_mapfolder = Image : New {
		x = 434,
		y = 30,
		parent = window_settings,
		file = SETTINGS_ICON,				
		width = 14,
		height = 14,
		tooltip = 'Reset to default',
		--color = {0,0.8,0.2,0.9},		
		OnClick = {	function()		
					config.path_map = 'maps/'..Game.mapName..'.sdd/'					
					end
				},				
	}
	buttonimage_soundfolder = Image : New {
		x = 434,
		y = 56,
		parent = window_settings,
		file = SETTINGS_ICON,				
		width = 14,
		height = 14,
		tooltip = 'Reset to default',
		--color = {0,0.8,0.2,0.9},		
		OnClick = {	function()		
					config.path_sound = 'Sounds/Ambient/'					
					end
				},				
	}		
	






	WINDOW_INSPECT_PROTOTYPE.button_close = Button:New{
		x = -32,
		y = 32,				
		tooltip = 'Close',
		clientWidth = 10,
		clientHeight = 10,
		caption = '',
		OnClick = {
			function() 
				window_inspect.inspect = nil
				window_inspect:Refresh()				
			end
		},
		children = {
			Image:New {
				width = "100%",
				height = "100%",				
				file = CLOSE_ICON,
			},
		},
	}
	WINDOW_INSPECT_PROTOTYPE.label = Label:New {
		x = 0,
		y = 20,
		parent = window_inspect,
		cation = '',
		width = window_inspect.clientWidth,
		--height = 20,
		align = 'center',		
		textColor = {1,1,0,0.9},
	}
	scroll_inspect = ScrollPanel:New {
		x = 0,
		y = 40,
		clientWidth = window_inspect.width - 38,
		clientHeight = window_inspect.height - 90,
		parent = window_inspect,
		scrollPosX = -16,
		horizontalScrollbar = false,
		verticalScrollbar = true,
		verticalSmartScroll = false,	
		scrollbarSize = 6,
		padding = {5,10,5,10},
		--autosize = true,
		--itemPadding = {5,10,5,10},
		--margin = {20,20,20,20},			
	}
	layout = LayoutPanel:New {
		x = 0,
		y = 0,
		clientWidth = window_inspect.panel.width-20,
		clientHeight = window_inspect.panel.width-20,
		parent = scroll_inspect,
		orientation = 'vertical',
		--orientation = 'left',
		selectable = false,		
		multiSelect = false,
		maxWidth = window_inspect.panel.width,
		minWidth = window_inspect.panel.width,
		itemPadding = {6,2,6,2},
		itemMargin = {0,0,0,0},
		autosize = true,
		align = 'left',
		columns = 3,
		left = 0,
		centerItems = false,	
	}	





OnMouseDown = { -- should set a cursor too!
						function(self,...)
							if drag.objects[1] then return nil end
							local selection = layout_main.selectedItems
							if selection and #selection > 0 then
								for i = 1, #selection do -- hope they are sorted, and only trues in here : /
									local sel = layout_main.children[i]
									drag.objects[i] = sel.refer --< this will crash for things that arent meant to be dragged
									drag.params.templates = true
									drag.params.source = layout_main
								end
							end
							drag._type.sounditems = true
							Echo("drag timer started")
							self.inherited.MouseDown(self,...)
							return self
						end	
					},
					OnMouseUp = {function(self,...) self.inherited.MouseDown(self,...) return self end},
					SetHighlight = function(self, select) 						
						if select then self.font:SetColor(self.textColorSelected)
						else self.font:SetColor(self.textColorNormal) end						
						self:Invalidate()
					end,



OnMouseDown = { -- should set a cursor too!
			function(self,...)
				Echo("layout")
				self.inherited.MouseDown(self,...)
				if drag.objects[1] then return nil end
				local selection = self.selectedItems
				if selection and #selection > 0 then
					for i = 1, #selection do -- hope they are sorted, and only trues in here : /
						local sel = self.children[i]
						assert (sel.refer, "selection "..tostring(sel).." missing item reference")
						drag.objects[i] = sel.refer --< this will crash for things that arent meant to be dragged
						drag.params.templates = true
						drag.params.source = layout_main
					end
				end
				drag._type.sounditems = true
				Echo("drag timer started")				
				return self
			end	
		},					
	--]]	