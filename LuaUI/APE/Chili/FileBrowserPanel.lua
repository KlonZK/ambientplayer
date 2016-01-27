--//=============================================================================
----------------------------------------a stereotypical file browser ------------
-- supports custom path links and file filtering
-- kind-of relies on a editbox to insert pathes outside the current root dir 
-- (otherwise is restricted to the vfs or any custom link that was added beforehand)

--//=============================================================================

-- this is one file or folder entry
--[[
{
	path = <string>,
	name =  <string>,
	tooltip = <string>,
	icon = <icon>, -- defaults to file/folder icon	
	OnClick = <{function,...}> 
	OnSelect = <function> 
	
}
--]]

--//=============================================================================

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


--//=============================================================================

FileBrowserPanel = DragDropLayoutPanel:Inherit{
	fileFilter = {}, -- {<string> = <image file> or false}
	-- list = {}
}

local this = FileBrowserPanel
local inherited = this.inherited


--//=============================================================================

function FileBrowserPanel:AddFolder(data, idx)
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
			padding = {0, 2, 0, 0},					
			selectable = data.OnSelect and true,
			OnSelect = data.OnSelect, -- highlighting of elements should be class feature
			OnClick = data.OnClick,
		}
	)
end


function FileBrowserPanel:AddFile(data, idx)
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
			padding = {0, 2, 0, 0},					
			selectable = data.OnSelect and true,
			OnSelect = data.OnSelect, -- highlighting of elements should be class feature
			OnClick = data.OnClick,
		}
	)		
end	

	
function FileBrowserPanel:AddUserPaths()
	for i, v in pairs(settings.paths) do
		if type(v) == 'string' then
			self:AddFolder({path = v, name = v, icon = icons.NEWFOLDER_ICON, tooltip = 'right click to remove', 
				OnClick = {default_folder_remove}})					
		end
	end			
end


function FileBrowserPanel:AddHardLinks()			
	self:AddFolder({name = 'Spring', path = settings.general.spring_dir, icon = icons.SPRING_ICON,
		tooltip = 'the spring home directory.\n\nthis path is the real location of your spring engine and is not to be confused with the vfs root directory.\n\n'
			..'\255\255\255\0'..(settings.general.spring_dir or '')..'\255\255\255\255',	OnClick = {default_folder},
	})			
	self:AddFolder({name = 'VFS root', path = '', icon = icons.SPRING_ICON,
		tooltip = 'root of the virtual file system. equals ".", "./", "/" and the empty string. \n\nwidgets can only write into the virtual file system, ie. subfolders of the spring directory.\n\nall write paths must be specified relative to the vfs root, not as absolute paths, eg. \n\n \255\255\255\0\'/sounds/ambient/\'\n\n\255\255\255\255instead of\n\n\255\255\255\0\'C:/someplace/.../sounds/ambient/\'\255\255\255\255\n\nnormally, the widget handles this process.\n\n\255\255\150\0if you find that you are unable to save into your working directory with this widget, try running spring with the --write-dir command line parameter pointing to the spring directory\255\255\255\255',
			OnClick = {default_folder},
	})
	if config.path_map then
		self:AddFolder({name = config.mapname, path = config.path_map, icon = icons.MAP_ICON,
			tooltip = 'the working directory for this map.\n\n'..colors.yellow_09:Code()..config.path_map,
				OnClick = {default_folder},
		})
	end			
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
end


function FileBrowserPanel:AddCurrentDir()
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
end

