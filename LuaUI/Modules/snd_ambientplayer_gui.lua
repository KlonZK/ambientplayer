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

local gl = widget.gl

local GetMouse = Spring.GetMouseState
local TraceRay = Spring.TraceScreenRay
local IsMouseMinimap = Spring.IsAboveMiniMap
local GetGroundHeight = Spring.GetGroundHeight
local GetModKeys = Spring.GetModKeyState
local GetTimer = Spring.GetTimer
local DiffTimers = Spring.DiffTimers

local C_Control
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
local ImageArray


--local color2incolor
--local incolor2color

local PATH_ICONS = "Images/AmbientSoundEditor/"
local icons = {}
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


local mx, mz, mz_inv
local mcoords
local modkeys = {}
local hoveredEmitter
local hoveredControl -- might want to include windows here so its all in one place? need to do the hittest tho, then
local dragDropDeamon

local drag = {
	items = {},
	data = {},
	typ = {},			
	started = false,
	cb = nil,
}

local callbacks = {}
local function cbTimer(length, func, args)
	local cb = {length = length, func = func, args = args, start = GetTimer()}
	callbacks[#callbacks + 1] = cb
	return cb
end


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
	
	-- chili utils
	
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
	
	local function _DrawTextureAspect(x,y,w,h ,tw,th, flipy)
		local twa = w/tw
		local tha = h/th

		local aspect = 1
		if (twa < tha) then
			aspect = twa
			y = y + h*0.5 - th*aspect*0.5
			h = th*aspect
		else
			aspect = tha
			x = x + w*0.5 - tw*aspect*0.5
			w = tw*aspect
		end

		local right  = math.ceil(x+w)
		local bottom = math.ceil(y+h)
		x = math.ceil(x)
		y = math.ceil(y)

		gl.TexRect(x,y,right,bottom,false,flipy)
	end
	
	------------------------------------------- swap image array ----------------------------------------------------- 
		
	ImageArray = Chili.Image:Inherit{
		classname = 'imagearray',
		files = {},		
		currentFile = false,
		DrawControl = function(self, ...)
			if self.currentFile then
				gl.Color(self.color)
				if self.keepAspect then
					Chili.TextureHandler.LoadTexture(0,self.currentFile,self)
					local texInfo = gl.TextureInfo(self.currentFile) or {xsize=1, ysize=1}
					local tw,th = texInfo.xsize, texInfo.ysize
					_DrawTextureAspect(self.x,self.y,self.width,self.height, tw,th, self.flip)
				else
					Chili.TextureHandler.LoadTexture(0,self.currentFile,self)
					gl.TexRect(self.x,self.y,self.x+self.width,self.y+self.height,false,self.flip)
				end
				gl.Texture(0,false)
			end
		end,	
		SetImage = function(self, img)
			if img and type(img) == 'number' then
				self.currentFile = self.files[img]
				--Echo("set image to"..img)
			else
				self.currentFile = false
			end			
			self:Invalidate()
		end,
	}
	
	
	------------------------------------------- filtered Drag & Drop Layout Panel ------------------------------------
	-- drag is controlled externally by chili and the widgets main module, this panel simply checks for mouse over status
	-- secondly, it asks child components for permission before selecting them 
	
	DragDropLayoutPanel = Chili.LayoutPanel:Inherit{
		classname = 'dragdroplayoutpanel',
		hitTestAllowEmpty = true,
		allowDragItems = false,
		allowDropItems = false,
		--shared_Selection = nil,
		--shared_ActivePanel = nil,
		New = function(self, obj)
			obj = LayoutPanel.New(self, obj)
			obj.selectedItems = {}
			return obj
		end,		
		MouseUp = function(self, x, y, button, mods)
			Echo("layout caught release")
			Echo(x)
			Echo(y)
			Echo(button)
			--Echo("hit "..screen0:HitTest(x,y).name)
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
		end,
		MouseDown = function(self, x, y, button, mods)
			Echo("layout caught press")
			Echo(x)
			Echo(y)
			Echo(button)
			local clickedChild = C_Control.MouseDown(self,x, y, button, mods)
			if clickedChild then Echo("child: "..clickedChild.name) end
			if self.allowDragItems then
				Echo("sent to deamon "..dragDropDeamon.name)
				if dragDropDeamon.MouseDown then Echo("has func") end
				return dragDropDeamon:MouseDown(x, y, button, mods, clickedChild or self)
			end			
			if (clickedChild) then
				return clickedChild
			end
			if (not self.selectable) then return end
			return self
		end,
		
		
		MouseClick = function(self, x, y, button, mods)
		
		end,
		MouseDblClick = function(self, x, y, button, mods)
			Echo("catch")
			local clickedChild = C_Control.MouseDown(self,x,y,button,mods)
			if (clickedChild) then
				Echo("123")
				return clickedChild
			end

			if (not self.selectable) then return end

			local cx,cy = self:LocalToClient(x,y)
			local itemIdx = self:GetItemIndexAt(cx,cy)

			if (itemIdx>0) then
				self:CallListeners(self.OnDblClickItem, itemIdx)
				return self
			end
		end,		
		
		
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
				if c and c.OnSelect then
					c:OnSelect(index, state)
				else
					Echo("child at index "..tostring(index).." does not exist.")
				end
			end,
		},
		DeselectItem = function(self, itemIdx)
			if (not self.selectedItems[itemIdx]) then
				return
			end
			self.selectedItems[itemIdx] = nil
			--self._lastSelected = itemIdx
			self:CallListeners(self.OnSelectItem, itemIdx, false)
			self:Invalidate()
		end,
		ToggleItem = function(self, itemIdx)
			local newstate = not self.selectedItems[itemIdx]
			self.selectedItems[itemIdx] = newstate
			if newstate then self._lastSelected = itemIdx end
			self:CallListeners(self.OnSelectItem, itemIdx, newstate)
			self:Invalidate()
		end,
		MultiRectSelect = function (self, item1, item2, append)
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
		end,
	}
	
	
	----------------------------------------a stereotypical file browser ---------------------------------------------
	-- supports custom path links and file filtering
	-- kind-of relies on a editbox to insert pathes outside the current root dir 
	-- (otherwise is restricted to the vfs or any custom link that was added beforehand)
	
	--[[
	{
		path = <string>,
		name =  <string>, -- defaults to path
		tooltip = <string>, -- custom for hardlinks, "right-click to remove" for others
		icon = <icon>, -- defaults to folder icon
		isHard = <boolean>, -- wether or not this can be removed by right click on the icon
		OnClick = <{function,...}> -- defaults to default_folder
		OnSelect = <function> -- defaults to nil
		
	}
	--]]
	local default_folder = function(self, ...)
		local btn = select(3,...)
		if btn == 1 then
			local box = self.parent.editbox
			self.parent.path = self.refer
			self.parent:Refresh()
			if box then -- at this point this control doesnt exist anymore
				box:SetText(self.refer)
			end			
		end	
	end	
	local default_folder_remove = function(self, ...)
		local btn = select(3,...)
		if btn == 1 then
			local box = self.parent.editbox
			self.parent.path = self.refer
			self.parent:Refresh()
			if box then -- at this point this control doesnt exist anymore
				box:SetText(self.refer)
			end			
		elseif btn == 3 then
			settings.paths[self.refer] = nil			
			self.parent:Refresh()
		end
	end
	
	FileBrowserPanel = DragDropLayoutPanel:Inherit{
		fileFilter = {}, -- {<string> = <image file> or false}
		AddFolder = function(self, data, idx)
			table.insert(self.list, idx or (#self.list + 1), 
				Image:New{
					parent = self,
					file = data.icon or icons.NEWFOLDER_ICON,
					width = 12, height = 12,
					tooltip = data.tooltip,
					refer = data.path,					
					OnClick = data.OnClick,
				}
			)
			table.insert(self.list, idx and (idx + 1) or (#self.list + 1), 
				ClickyTextBox:New{
					parent = self,
					--autosize = true,
					clientWidth = self.clientWidth,
					fontsize = 10,
					textColor = colors.grey_08,
					refer = data.path,
					text = data.name,
					selectable = data.OnSelect and true,
					OnSelect = data.OnSelect, -- highlighting of elements should be class feature
					OnClick = data.OnClick,
				}
			)
		end,
		AddFile = function(self, data, idx)
			table.insert(self.list, idx or (#self.list + 1), 
				Image:New{
					parent = self,
					file = data.icon or icons.FILE_ICON,
					width = 12, height = 12,
					tooltip = data.tooltip,
					refer = data.path,
					OnClick = data.OnClick,
				}
			)
			table.insert(self.list, idx and (idx + 1) or (#self.list + 1), 
				MouseOverTextBox:New{
					parent = self,
					--autosize = true,
					clientWidth = self.clientWidth,
					fontsize = 10,
					textColor = colors.grey_08,
					refer = data.path,
					text = data.name,
					selectable = data.OnSelect and true,
					OnSelect = data.OnSelect, -- highlighting of elements should be class feature
					OnClick = data.OnClick,
				}
			)
			
		end,		
		AddUserPaths = function(self)
			for i, v in pairs(settings.paths) do
				if type(v) == 'string' then
					self:AddFolder({path = v, name = v, icon = icons.NEWFOLDER_ICON, tooltip = 'right click to remove', 
						OnClick = {default_folder_remove}})					
				end
			end			
		end,
		AddHardLinks = function(self)			
			self:AddFolder({name = 'SPRING', path = settings.general.spring_dir, icon = icons.SPRING_ICON,
				tooltip = 'the spring home directory.\n\nthis path is the real location of your spring engine and is not to be confused with the vfs root directory.\n\n'
					..'\255\255\255\0'..(config.path_spring or '')..'\255\255\255\255',	OnClick = {default_folder},
			})			
			self:AddFolder({name = '$VFS_ROOT', path = '', icon = icons.SPRING_ICON,
				tooltip = 'root of the virtual file system. equals ".", "./", "/" and the empty string. \n\nwidgets can only write into the virtual file system, ie. subfolders of the spring directory.\n\nall write paths must be specified relative to the vfs root, not as absolute paths, eg. \n\n \255\255\255\0\'/sounds/ambient/\'\n\n\255\255\255\255instead of\n\n\255\255\255\0\'C:/someplace/.../sounds/ambient/\'\255\255\255\255\n\nnormally, the widget handles this process.\n\n\255\255\150\0if you find that you are unable to save into your working directory with this widget, try running spring with the --write-dir command line parameter pointing to the spring directory\255\255\255\255',
					OnClick = {default_folder},
			})
			self:AddFolder({name = '..', icon = icons.UNDO_ICON, 
				OnClick = {function(self, ...)
					local btn = select(3,...)
					if btn == 1 then
						local path = self.parent.path
						if #path > 0 then
							local lastchar = string.sub(path, -1)
							if not (lastchar == '\/' or lastchar == '\\') then
								path = path..'\/'
							end					
							local a,b,remain = string.find(path, '[^\/\\]+[\/\\]$') -- "([^\/\\]+)$"							
							remain = string.sub(path, 1, a - 1)
							if remain then
								local box = self.parent.editbox
								self.parent.path = remain
								self.parent:Refresh()					
								if box then
									box:SetText(remain)
								end	
							end	
						end	
					end					
				end,
				}	
			})
		end,
		AddCurrentDir = function(self)
			--local filter = '*.wav
			local dirs, files = VFS.SubDirs(self.path), VFS.DirList(self.path)				
				
			for i = 1, #dirs do
				local _,_,dirname = string.find(dirs[i], "([^\/\\]+)[\/\\]$")
				self:AddFolder({path = dirs[i], name = dirname, icon = icons.FOLDER_ICON, OnClick = {default_folder}})			
			end					
			for i = 1, #files do				
				local matchesFilter -- this is suboptimal
				for f, icon in pairs(self.fileFilter) do
					matchesFilter = matchesFilter or string.find(files[i], f) and icon
				end				
				--local ending = string.find(files[i], "ogg$") or string.find(files[i], "wav$")
				if matchesFilter or not settings.browser.showSoundsOnly then
					local _,_,filename = string.find(files[i], "([^\/\\]+)$")
					self:AddFile({path = files[i], name = filename, icon = matchesFilter, --OnClick = {},
						OnSelect = function(self, idx, select)							
							if select then 
								self.legit = matchesFilter
								self.font:SetColor(matchesFilter and colors.green_1 or colors.red_1)
							else 
								self.legit = nil
								self.font:SetColor(colors.grey_08) 
							end
							self:Invalidate()
						end,
					})					
				end			
			end
			return #dirs > 0 or #files > 0
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
			self._interactedTime = GetTimer()
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

			self._interactedTime = GetTimer()
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
		hitTestAllowEmpty = true,
		--HitTest = function(self, x, y)
		--	return false
			--return self.visible and C_Control:HitTest(x, y)
		--end,
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
		end,
	}
	
	
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
		OnClick = {function(self) 
			if drag.started and button == 3 then
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
		tooltip = 'extract map archive',
		OnClick = {function(self)
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
		tooltip = 'restart spring now',
		OnClick = {function(self)
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
			Echo("refreshing...")
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
				Echo(drag.cb.args[2].name)
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
				Echo("second down")
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
			Echo("grabbing input")
			return self
		end,
		MouseMove = function(self, x, y, dx, dy, button)
			Echo("move")			
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
			Echo("cb")					
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
	
	Echo("setting up chili classes")	
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
		
	if #callbacks > 0 then
		local timer = GetTimer()
		for k, cb in pairs(callbacks) do
			if DiffTimers(timer, cb.start, true) > cb.length then				
				if not cb.cancel then
					cb.func(unpk(cb.args, 1))
				end	
				table.remove(callbacks, k)
			end
		end
	end
	
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
			Echo(key == KEYSYMS.RETURN and "drag ended" or "drag dropped")							
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
			e.pos.y = (e.pos.y + diff) > gh and (e.pos.y + diff)  or 0					
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
