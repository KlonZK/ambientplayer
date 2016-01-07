------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
--		file : snd_ape_io.lua												--
--		desc : io module for ambient sound editor										--
--		author : Klon (savetable.lua by Dave Rodgers)									--
--		date : "25.7.2015",																--
--		license : "GNU GPL, v2 or later",												--
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

local io = widget.io
local pairs = widget.pairs
local ipairs = widget.ipairs
local math = widget.math
local error = widget.error
local table = widget.table
local next = widget.next
local string = widget.string
local tostring = widget.tostring
local type = widget.type

local VFSMODE = widget.VFSMODE

local vfsInclude = widget.VFS.Include
local vfsExist = widget.VFS.FileExists
local spLoadSoundDefs = widget.Spring.LoadSoundDef

--local PATH_LUA = widget.LUAUI_DIRNAME --x
--local PATH_CONFIG = PATH_CONFIG --x
--local PATH_WIDGET = widget.PATH_WIDGET
--local PATH_UTIL = widget.PATH_UTIL
--local PATH_MODULE = widget.PATH_MODULE

--local TMP_ITEMS_FILENAME = widget.TMP_ITEMS_FILENAME --x
--local TMP_INSTANCES_FILENAME =  widget.TMP_INSTANCES_FILENAME --x
--local MAPCONFIG_FILENAME = widget.MAPCONFIG_FILENAME
--local SOUNDS_ITEMS_DEF_FILENAME = widget.SOUNDS_ITEMS_DEF_FILENAME
--local SOUNDS_INSTANCES_DEF_FILENAME = widget.SOUNDS_INSTANCES_DEF_FILENAME
--local EMITTERS_FILENAME = widget.EMITTERS_FILENAME

--local LOG_FILENAME = widget.LOG_FILENAME 

local SOUNDS_ITEMS_HEADER = [[-- Sounditem definitions. same format as gamedata/sounds.lua 
-- these are individual sounds being used in emitters. for the table of sound item templates, see ambient_sounds_items.lua]].."\n"
local SOUNDS_INSTANCES_HEADER = [[-- Sounditem definitions. same format as gamedata/sounds.lua 
-- these are templates used by the editor. for the table of sound items being used by emitters, see ambient_sounds_instances.lua]].."\n"
local MAPCONFIG_HEADER = [[-- Map specific config options.
-- General config options are saved via epic menu or in ambient_options.lua]].."\n"
local OPTIONS_HEADER = [[-- General config. If you are using epic menu, you won't need this.
-- Map specific options are savid in ambient_mapconfig.]]
local EMITTERS_HEADER = [[-- Emitters for positional sounds. Entries in the sounds tables must be indexed.]].."\n"

local options = options
local config = config
local emitters = emitters
local sounditems = sounditems

--local LOG_FILENAME = LOG_FILENAME

local function Save(list, path, file) 	
	if (list == 0 or list == 1) then --options		
	end		
	if (list == 0 or list == 2) then --playlist	
		-- for console use
	end		
	if (list == 0 or list == 3) then --emitters	
	end
	return true
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 	savetable.lua, a human friendly table writer by Dave Rodges - Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local indentString = '\t'

local savedTables = {}

-- setup a lua keyword map
local keyWords = {
 "and", "break", "do", "else", "elseif", "end", "false", "for", "function",
 "if", "in", "local", "nil", "not", "or", "repeat", "return", "then", "true",
 "until", "while"
}

local keyWordSet = {}
for _,w in ipairs(keyWords) do
  keyWordSet[w] = true
end
keyWords = nil  -- don't need the array anymore


local function encloseStr(s)
  return string.format('%q', s)
end


local function encloseKey(s)
  local wrap = not (string.find(s, '^%a[_%a%d]*$'))
  if (not wrap) then
    if (string.len(s) <= 0) then wrap = true end
  end
  if (not wrap) then
    if (keyWordSet[s]) then wrap = true end
  end
    
  if (wrap) then
    return string.format('[%q]', s)
  else
    return s
  end
end


local keyTypes = {
  ['string']  = true,
  ['number']  = true,
  ['boolean'] = true,
}

local valueTypes = {
  ['string']  = true,
  ['number']  = true,
  ['boolean'] = true,
  ['table']   = true,
}


local function CompareKeys(kv1, kv2)
  local k1, v1 = kv1[1], kv1[2]
  local k2, v2 = kv2[1], kv2[2]

  local ktype1 = type(k1)
  local ktype2 = type(k2)
  if (ktype1 ~= ktype2) then
    return (ktype1 > ktype2)
  end

  local vtype1 = type(v1)
  local vtype2 = type(v2)
  if ((vtype1 == 'table') and (vtype2 ~= 'table')) then
    return false
  end
  if ((vtype1 ~= 'table') and (vtype2 == 'table')) then
    return true
  end

  return (k1 < k2)
end


local function MakeSortedTable(t)
  local st = {}
  for k,v in pairs(t) do
    if (keyTypes[type(k)] and valueTypes[type(v)]) then
      table.insert(st, { k, v })
    end
  end
  table.sort(st, CompareKeys)
  return st
end


local function SaveTable(t, file, indent)
  file:write('{\n')
  local indent = indent .. indentString
  
  local st = MakeSortedTable(t)
  
  for _,kv in ipairs(st) do
    local k, v = kv[1], kv[2]
    local ktype = type(k)
    local vtype = type(v)
    -- output the key
    if (ktype == 'string') then
      file:write(indent..encloseKey(k)..' = ')
    else
      file:write(indent..'['..tostring(k)..'] = ')
    end
    -- output the value
    if (vtype == 'string') then
      file:write(encloseStr(v)..',\n')
    elseif (vtype == 'number') then
      if (v == math.huge) then
        file:write('math.huge,\n')
      elseif (v == -math.huge) then
        file:write('-math.huge,\n')
      else
        file:write(tostring(v)..',\n')
      end
    elseif (vtype == 'boolean') then
      file:write(tostring(v)..',\n')
    elseif (vtype == 'table') then
      if (savedTables[v]) then
        error("table.save() does not support recursive tables")
      end
      if (next(v)) then
        savedTables[t] = true
        SaveTable(v, file, indent)
        file:write(indent..'},\n')
        savedTables[t] = nil
      else
        file:write('{},\n') -- empty table
      end
    end
  end
end

--------------------------------------------------------------------------------

local function WriteTable(t, filename, header, tname)
	local tname = tname or tostring(t) -- this sucks
	if not (filename) then Echo("file not found") return false end	
	Echo("writing "..filename.." ...")
	
	local file = io.open(filename, 'w')	
	if (file == nil) then Echo("failed to open "..filename) return false end	
	if (header) then file:write(header..'\n') end	
	file:write('local '..tname..' = ')
	SaveTable(t, file, '')
	file:write('}\nreturn '..tname)	
	file:close()
	
	Echo("done!", true)
	return true
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 	I/O FUNCTIONS
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function SaveAll()
	local wpath = config.path_map..PATH_LUA..PATH_CONFIG

	if not (WriteSoundDefs(wpath, SOUNDS_ITEMS_DEF_FILENAME, SOUNDS_INSTANCES_DEF_FILENAME, true)) then 
		Echo("failed to write sound defs: "..wpath) return false end
	if not (WriteEmittersDef(wpath, EMITTERS_FILENAME)) then
		Echo("failed to write emitters config") return false end
	if not (WriteLocalConfig(wpath, MAPCONFIG_FILENAME)) then
		Echo("failed to write map config") return false end	
	
	return true
end


-- do i have to load all of them if only one or a few need updating? tho its not a lot to do so i guess it doesnt matter?
-- these dont write tags from meta index. problem?
function ReloadSoundDefs()
	-- not sure they have to be different?
	local rpath = PATH_LUA..PATH_CONFIG
	local wpath = config.path_map..PATH_LUA..PATH_CONFIG
	
	Echo("caching...")
	if not (WriteSoundDefs(wpath, TMP_ITEMS_FILENAME, TMP_INSTANCES_FILENAME, true)) then 
		Echo("failed to write temp files at: "..wpath) return false end
	if not (spLoadSoundDefs(rpath..TMP_ITEMS_FILENAME)) then
		Echo("failed to load temp file: "..rpath..TMP_ITEMS_FILENAME) return false end
	if not (spLoadSoundDefs(rpath..TMP_INSTANCES_FILENAME)) then
		Echo("failed to load temp file: "..rpath..TMP_INSTANCES_FILENAME) return false end

	return true
	-- update should get called on frame/draw update. also not accessible from here
	--UpdateGUI()	
end


function LoadSoundFile(folder, file, name)		
	Echo("loading soundfile "..folder..file.." ...")
	if VFS.FileExists(folder..file) then
		-- this will generate sounditems with default values and they will not be overwritten runtime because they use the files name
		-- tho does this matter, when new sounditem is generated by reload? bogus sounditem will just hang around and do nothing
		-- internal sounditem name will be filename including ending?
		if not (PlaySound(folder..file, 0)) then Echo("unable to load file. only *.wav and *.ogg files") return false end
		local shortname = name or (file:sub(1,-5))
		
		if sounditems.templates[shortname] then 
			Echo("a sounditem with that name already exists.") 
			if name then return false end -- if ran from console
			while sounditems.templates[shortname] do
				shortname='_'..shortname
			end	
			Echo("entry will be named "..shortname)
		end		
		
		sounditems.templates[shortname] = {} -- meta table can handle defaults					
		sounditems.templates[shortname].file = file
		Echo("added sounditem: "..shortname)
							
	else Echo("file not found!") return false end
	Echo("loaded "..file.." successfully!")
	return true -- means: need reload
end


function WriteSoundDefs(path, itemsfile, instancesfile, silent)
	local Sounds = {Sounditems = sounditems.templates}		
	if (WriteTable(Sounds, path..itemsfile, SOUNDS_ITEMS_HEADER, 'Sounds')) then
		if not silent then Echo("saved sounditem definitions to "..path..file) end		
	else Echo("failed to save sounddefs :(") return false end
	
	Sounds = {Sounditems = sounditems.instances}		
	if (WriteTable(Sounds, path..instancesfile, SOUNDS_INSTANCES_HEADER, 'Sounds')) then
		if not silent then Echo("saved sounds to "..path..file) end
	else Echo("failed to save sounds :(") return false end
	
	return true
end


-- will this save sounditems as sounditems?
function WriteEmittersDef(path, file)
	if (WriteTable(emitters, path..file, EMITTERS_HEADER, 'Emitters')) then
		Echo("saved emitters to "..path..file)
	else Echo("failed to save emitters :(") return false end
	return true
end


function WriteLocalConfig(path, file)
	if (WriteTable(config, path..file, MAPCONFIG_HEADER, 'Config')) then
		Echo("saved local config to "..path..file)
	else Echo("failed to save local config :(") return false end
	return true
end

-- this seems unused
function WriteOptions(path, file)
	if (WriteTable(options, path..file, OPTIONS_HEADER, 'Options')) then
		Echo("saved local config to "..path..file)
	else Echo("failed to save local config :(") return false end	
	return true
end

return true