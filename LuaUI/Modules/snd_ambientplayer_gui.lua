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
local type = widget.type
local tostring = widget.tostring

local PATH_LUA = widget.LUAUI_DIRNAME

local options = options
local config = config
local emitters = emitters
local sounditems = sounditems

local Image
local Button
local Checkbox
local Window
local ScrollPanel
local LayoutPanel
local Grid
local StackPanel
local TreeView
local Node
local Label
local Line
local EditBox
local TextBox
local color2incolor
local incolor2color

local SETTINGS_ICON = PATH_LUA..'Images/Epicmenu/settings.png'
local HELP_ICON = PATH_LUA..'Images/Epicmenu/questionmark.png'
local CONSOLE_ICON = PATH_LUA..'Images/speechbubble_icon.png'
local PLAYSOUND_ICON = PATH_LUA..'Images/Epicmenu/vol.png'
local PROPERTIES_ICON = PATH_LUA..'Images/properties_button.png'
--local PLAYER_CONTROLS_ICON = PATH_LUA..'Images/Commands/Bold/'..'drop_beacon.png'

local HELPTEXT = [[generic info here]]


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
	EditBox = Chili.EditBox
	TextBox = Chili.TextBox
	ScrollPanel = Chili.ScrollPanel
	LayoutPanel = Chili.LayoutPanel
	Grid = Chili.Grid
	StackPanel = Chili.StackPanel
	TreeView = Chili.TreeView
	Node = Chili.TreeViewNode
	color2incolor = Chili.color2incolor
	incolor2color = Chili.incolor2color

	---------------------------------------------------- main frame ------------------------------------------------
	window_main = Window:New {
		x = '65%',
		y = '25%',	
		--dockable = false,
		parent = screen0,
		caption = "Ambient Sound Editor",
		draggable = true,
		resizable = true,
		dragUseGrip = true,
		clientWidth = 350,
		clientHeight = 540,
		backgroundColor = {0.8,0.8,0.8,0.9},		
	}
	label_overview = Label:New {
		x = 0,
		y = 20,
		clientWidth = 260,
		parent = window_main,
		align = 'center',
		caption = '-Track Overview-',
		textColor = {1,1,0,0.9},		
	}
	scroll_overview = ScrollPanel:New {
		x = 0,
		y = 40,
		clientWidth = 340,
		clientHeight = 420,
		parent = window_main,
		scrollPosX = -16,
		horizontalScrollbar = false,
		verticalScrollbar = true,
		verticalSmartScroll = true,	
		scrollbarSize = 6,
		padding = {5,10,5,10},
		--itemPadding = {5,10,5,10},
		--margin = {20,20,20,20},
		
	}	
	layout_overview = LayoutPanel:New {
		x = 0,
		y = 0,
		--clientWidth = 160,
		--clientHeight = 420,
		parent = scroll_overview,
		orientation = 'vertical',
		--orientation = 'left',
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
			function(...)
				Echo("wub")
			end	
		},
		--padding = {20,20,20,20},
		--margin = {20,20,20,20},		
	}	
	
	button_console = Button:New {
		x = 0,
		y = -32,
		parent = window_main,		
		tooltip = 'Message Log',
		clientWidth = 12,
		clientHeight = 12,
		caption = '',
		OnClick = {	function()
						window_console:ToggleVisibility()						
					end
					},
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
		tooltip = 'Halp!',
		clientWidth = 12,
		clientHeight = 12,
		caption = '',
		OnClick = {	function()
						window_help:ToggleVisibility()
					end
					},
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
		OnClick = {	function()
						window_settings:ToggleVisibility()
					end
					},
		children = {
			Image:New {
				width = "100%",
				height = "100%",				
				file = SETTINGS_ICON,
			}
		}	
	}
	
	---------------------------------------------------- emitters window ------------------------------------------------	
	
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
	}
	label_emitters = Label:New {
		x = 0,
		y = 20,
		clientWidth = 260,
		parent = window_emitters,
		align = 'center',
		caption = '-Emitters-',
		textColor = {1,1,0,0.9},		
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
	
	
	---------------------------------------------------- log window ------------------------------------------------	
	window_console = Window:New {
		x = "20%",
		y = "7%",
		parent = screen0,
		caption = "Message Log",
		draggable = true,
		resizable = false,
		dragUseGrip = true,
		clientWidth = 640,
		clientHeight = 140,
		backgroundColor = {0.8,0.8,0.8,0.9},				
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
	textbox_console = TextBox:New {
		x = 4,
		y = 0,
		autosize = true,
		parent = scroll_console,
		align = 'left',
		textColor = {0.9,0.9,0.0,0.9},
		backgroundColor = {0.2,0.2,0.2,0.5},
		borderColor = {0.3,0.3,0.3,0.5},
		text = logfile,	
	}
	
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
		backgroundColor = {0.8,0.8,0.8,0.9},
		
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
	textbox_help = TextBox:New {
		x = 4,
		y = 0,
		autosize = true,
		parent = scroll_help,
		align = 'left',
		textColor = {0.8,0.8,0.8,0.9},
		backgroundColor = {0.2,0.2,0.2,0.5},
		borderColor = {0.3,0.3,0.3,0.5},
		text = HELPTEXT,
	}
	window_help:Hide()
	
		---------------------------------------------------- settings window ------------------------------------------------
	window_settings = Window:New {
		x = "25%",
		y = "25%",
		parent = screen0,
		caption = "Settings",
		draggable = true,
		resizable = false,
		dragUseGrip = true,
		clientWidth = 450,
		clientHeight = 250,
		backgroundColor = {0.8,0.8,0.8,0.9},
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
	}	
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
		tooltip = [[The .sdd folder this map resides in. By default, the Widget will save all its data in the maps folder structure. If you are running from an archive, ...]],
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
		tooltip = [[Where our sound files are read from. Note that while you can load sound files from anywhere on your computer, you eventually need to put them here if you wish to incorporate them into your map.]],
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
	
	window_settings:Hide()
	
	---------------------------------------------------- inspect emitter window ------------------------------------------------
	window_inspect = Window:New {
		x = "50%",
		y = "50%",
		parent = screen0,
		caption = "Emitter Details",
		draggable = true,
		resizable = false,
		dragUseGrip = true,
		clientWidth = 300,
		clientHeight = 250,
		backgroundColor = {0.8,0.8,0.8,0.9},
		currentInspect = nil,
		panel = nil,
	}
	label_inspect = Label:New {
		x = 0,
		y = 20,
		parent = window_inspect,
		cation = '',
		width = window_inspect.clientWidth,
		--height = 20,
		align = 'center',		
		textColor = {1,1,0,0.9},
	}
		
	window_inspect:Hide()
end


function UpdateGUI()
	editbox_mapfolder.text = config.path_map
	editbox_soundfolder.text = config.path_sound
	
	for track, params in pairs(sounditems.templates) do
		
			--local name = params.name
			tracklist_controls['label'..track] = EditBox:New {
				x = 0,
				--y = 0,
				clientWidth = 200,
				--clientHeight = 16,
				parent = layout_overview,
				align = 'left',
				text =  track,
				fontSize = 10,
				textColor = {0.9,0.9,0.9,1},
				backgroundColor = {0.2,0.2,0.2,0.5},
				borderColor = {0.3,0.3,0.3,0.5},
				OnMouseOver = { function(self) 
									local ttip = self.text.."\n\n"--.."\n--------------------------------------------------------------\n\n"
									for key, _ in pairs(sounditems.default) do										
										ttip = ttip..key..": "..tostring(params[key]).."\n"										
									end
									--self:SetTooltip(ttip)
									self.tooltip=ttip
								end
							},
				OnChange = {function()
							params.name = self.text
							end
						},
			}
			tracklist_controls['length'..track] = EditBox:New {
				x = 204,
				clientWidth = 26,
				parent = layout_overview,
				align = 'right',
				text = ''..params.length,
				fontSize = 10,
				textColor = {0.9,0.9,0.9,1},
				backgroundColor = {0.2,0.2,0.2,0.5},
				borderColor = {0.3,0.3,0.3,0.5},
				tooltip = [[The length of the track in seconds. As this information can't currently be obtained by the Widget, you may want to insert it manually.]]
			}
						
			tracklist_controls['edit_image'..track] = Image:New {
				--x = 250,
				--y = 8,
				parent = layout_overview,
				file = PROPERTIES_ICON,				
				width = 20,
				height = 20,
				--margin = {0,0,0,-6},
				--padding = {0,0,0,-4},
				--clientWidth = 32,
				--clientHeight = 32,
				tooltip = 'Sounditem Properties',
				color = {0.8,0.7,0.9,0.9},
				--margin = {0,2,0,0},
				--caption = '',
				OnClick = {	function()
								
								--local p = {x,y,z}
								--return widget.DoPlay(track, options.volume.value, nil, nil, nil)		
							end
						},
			}
			tracklist_controls['play_image'..track] = Image:New {
				--x = 240,
				--y = 0,
				parent = layout_overview,
				file = PLAYSOUND_ICON,				
				width = 20,
				height = 20,
				tooltip = 'Play Sounditem',
				color = {0,0.8,0.2,0.9},
				--caption = '',
				margin = {-6,0,0,0},
				OnClick = {	function()
								--local p = {x,y,z}
								
								return DoPlay(track, options.volume.value, nil, nil, nil)		
							end
						},
			}
		--end	
	end	
end


function UpdateInspectionWindow(object)	
	-- Echo("call with "..object)
		
	if window_inspect.currentInspect and (window_inspect.currentInspect ~= object) then		
		Echo(window_inspect.currentInspect.." and "..object)
		window_inspect.panel:Dispose()
		window_inspect:Invalidate()
	end
	
	if emitters[object] then
		local e = emitters[object]
		window_inspect.currentInspect = object		
		label_inspect:SetCaption(object)
		window_inspect.panel = ScrollPanel:New {
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
		window_inspect.panel.layout = LayoutPanel:New {
			x = 0,
			y = 0,
			clientWidth = window_inspect.panel.width-20,
			clientHeight = window_inspect.panel.width-20,
			parent = window_inspect.panel,
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
		
		for i = 1, #e.sounds do
			local sound = e.sounds[i]
			for k, v in pairs(sound) do
				widget.tostring(v)
			end
			namebox = EditBox:New {
				--x = 0,				
				--autosize = true,
				width = window_inspect.panel.layout.width-86,
				--height = 12,
				parent = window_inspect.panel.layout,
				align = 'left',
				text =  sound.item or 'error: no item',
				fontSize = 10,
				textColor = {0.9,0.9,0.9,1},
				backgroundColor = {0.2,0.2,0.2,0.5},
				borderColor = {0.3,0.3,0.3,0.5},
				OnMouseOver = { function(self) 
									--local ttip = self.text.."\n\n"--.."\n--------------------------------------------------------------\n\n"
									--for param, val in pairs(params) do										
									--	if type(val) == 'boolean' then ttip = ttip..param..": "..(val and "true" or "false").."\n" 											
									--	else ttip = ttip..param..": "..val.."\n" 
									--	end
									--end
									--self:SetTooltip(ttip)
									--self.tooltip=ttip
								end
				},
			}					
			propsicon = Image:New {				
				parent = window_inspect.panel.layout,
				file = PROPERTIES_ICON,				
				width = 20,
				height = 20,				
				tooltip = 'Sound Properties',
				color = {0.8,0.7,0.9,0.9},				
				OnClick = {	function()
								--local p = {x,y,z}
								--return widget.DoPlay(track, options.volume.value, nil, nil, nil)		
							end
				},
			}
			playicon = Image:New {
				parent = window_inspect.panel.layout,
				file = PLAYSOUND_ICON,				
				width = 20,
				height = 20,
				tooltip = 'Play at Location',
				color = {0,0.8,0.2,0.9},				
				margin = {-6,0,0,0},
				OnClick = {	function()
								local px, py, pz = e.pos.x, e.pos.y, e.pos.z
								Echo(px.." "..py.." "..pz)
								return widget.DoPlay(sound.item, options.volume.value, px or nil, py or nil, pz or nil) -- pos is false for global emitter, for some silly reason. needs change
							end
				},
			}
		end
		
	end
	--window_inspect:Invalidate()
end


return true