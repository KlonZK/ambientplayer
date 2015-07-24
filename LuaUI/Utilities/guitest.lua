function SetupGUI()
---------------------------------------------------- main frame ------------------------------------------------
local Chili
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
local screen0
local color2incolor
local incolor2color

Chili = WG.Chili
	Image = Chili.Image
	Button = Chili.Button
	Checkbox = Chili.Checkbox
	Window = Chili.Window
	Label = Chili.Label
	Line = Chili.Line
	EditBox = Chili.EditBox
	TextBox = Chili.TextBox
	screen0 = Chili.Screen0	
	ScrollPanel = Chili.ScrollPanel
	LayoutPanel = Chili.LayoutPanel
	Grid = Chili.Grid
	StackPanel = Chili.StackPanel
	TreeView = Chili.TreeView
	Node = Chili.TreeViewNode
	color2incolor = Chili.color2incolor
	incolor2color = Chili.incolor2color

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
		selectable = false,		
		multiSelect = false,
		maxWidth = 340,
		minWidth = 340,
		itemPadding = {6,2,6,2},
		itemMargin = {0,0,0,0},
		autosize = true,
		align = 'left',
		columns = 4,
		left = 0,
		centerItems = false,	
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