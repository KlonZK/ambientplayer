--[[
TODO:
- add emitters, emitters graphical representation, figure out how tracks and emitters work together VvV
- implement adding sound items to emitters v
- implement batch loading, adding, editing vv-
- restructure? v
- slash words and vars 
- build writable tables for options v
- save options, playlist, emitters support (good target for own file) V
- remake initialize() to account for list files v?
- find out how to find out about file sizes and lengths
- find out how to create folders 
- implement log
- disallow track names with only numbers

- emit zones
- mutex groups
- chili support
--]]

local versionNum = '0.25'

function widget:GetInfo()
  return {
    name      = "Ambient Player",
    desc      = "v"..(versionNum).." a very basic ambient sound mixer",
    author    = "Klon",
    date      = "dez 2014",
    license   = "GNU GPL, v2 or later",
    layer     = -1,
    enabled   = true,
  }
end	

--------------------------------------------------------------------------------
-- Epic Menu Options
--------------------------------------------------------------------------------

options_path = 'Settings/Audio/Ambient Sound'
options_order = {}
options = {
	settingslabel = {name = "settingslabel", type = 'label', value = "General Settings", path = options_path},
	checkrate = {
		name = "Update frequency",
        type = 'number',
        value = 1,
        min = 1,
        max = 30,
        step = 1,
        path = "Settings/Audio/Ambient Sound",
	},
	volume = {
		name = "Volume",
        type = 'number',
        value = 1,
        min = 0.1,
        max = 2,
        step = 0.1,
        path = "Settings/Audio/Ambient Sound",
	},
	autoplay = {
		name = "Autoplay",
        type = 'bool',
        value = true,
        path = "Settings/Audio/Ambient Sound",
	},
	verbose = {
		name = "Verbose",
        type = 'bool',
        value = true,
        path = "Settings/Audio/Ambient Sound/Editor",
	},
	autosave = {
		name = "Autosave",
        type = 'bool',
        value = true,
        path = "Settings/Audio/Ambient Sound/Editor",
	},
	autoreload = {
		name = "Auto Reload",
        type = 'bool',
        value = true,
        path = "Settings/Audio/Ambient Sound/Editor",
	},
	showemitters = {
		name = "Show Emitters",
        type = 'bool',
        value = true,
        path = "Settings/Audio/Ambient Sound/Editor",
	},
}	

	

local config = {
	path_sounds = 'Sounds/Ambient/',
	path_read = 'Sounds/Ambient/',
	path_map = nil,
}



--------------------------------------------------------------------------------
-- CONSTANTS,SHORTCUTS&TEMPLATES
--------------------------------------------------------------------------------

local PlaySound = Spring.PlaySoundFile
local PlayStream = Spring.PlaySoundStream
local random=math.random

-- except those arent actually constants?
local OPTIONS_FILENAME = 'ambient_options.lua'
local SOUNDDEF_FILENAME = 'ambient_sounddefs.lua'
local EMITTERS_FILENAME = 'ambient_emitters.lua'
local SAVETABLE_FILENAME = 'ambient_savetable.lua'
local TMP_FILENAME = 'ambient_tmp.lua'
local LOG_FILENAME = 'ambient_log.txt'

local PATH_LUA = LUAUI_DIRNAME
local PATH_CONFIG = 'Configs/'
local PATH_WIDGET = 'Widgets/'
local PATH_UTIL = 'Utilities/'

local SOUNDDEF_HEADER = [[--Sounditem definitions in the format of gamedata sounds.lua plus some additional parameters used by the widget.]].."\n"
local OPTIONS_HEADER = [[--Config file. Words contains user-defined string variables]].."\n"
local EMITTERS_HEADER = [[--Emitters for positional sounds. Each sounditem will be unique for every emitter, if created by the widget.]].."\n"

local SOUNDITEM_TEMPLATE = {
	-- sounditem stats
	file = "",
	gain = 1.0,
	pitch = 1.0,
	pitchMod = 0.0,
	gainMod = 0.05,
	priority = 0,
	maxconcurrent = 2, 
	maxdist = math.huge, 
	preload = true,
	in3d = true,
	rolloff = 0,
	dopplerscale = 0,
	-- widget stats
	length = "?",
	emitter = false, 
	rnd = 0,	
	minlooptime = 1,
	onset = 1,
	
}
local TMPVALUES_TEMPLATE = {
	timeframe = 1,
	generated=true,	
}
local EMITTER_TEMPLATE = {	
	pos = {
			x = 0,
			y = 0,
			z = 0,
		},
	playlist = {}, -- this would actually be a great place to store timeframe
	
	--mods = {},	
}



--------------------------------------------------------------------------------
-- VARS
--------------------------------------------------------------------------------

local secondsToUpdate = 0.1
local gameStarted = Spring.GetGameFrame() > 0
local inited = false

local tracklist = {
	tracks = {},
	tmpvalues = {},
	}

local emitters = {
	index = 1,
	global = {
		pos = {
				x=false,
				y=false,
				z=false,
			},
		playlist = {},
	},
}


local logfile = [[]]
local mx, my
local needReload = false

local SaveTable, MakeSortedTable, CompareKeys, valueTypes, keyTypes, encloseKey, encloseStr, keyWordSet, keyWords, saveTables, indendtString


--------------------------------------------------------------------------------
-- INIT
--------------------------------------------------------------------------------

function widget:Initialize()

	local cpath = PATH_LUA..PATH_CONFIG
	local upath = PATH_LUA..PATH_UTIL

	--if VFS.FileExists(cpath..LOG_FILENAME, VFS.RAW_FIRST) then
	--	log = log..VFS.Include(cpath..LOG_FILENAME, nil, VFS.RAW_FIRST)

	
	if VFS.FileExists(cpath..OPTIONS_FILENAME, VFS.RAW_FIRST) then
		local options = VFS.Include(cpath..OPTIONS_FILENAME, nil, VFS.RAW_FIRST)
		if (options.config) then
			for k, v in pairs(options.config) do config[k] = v or config[k]	end
		end
		if (options.words) then	
			for k, t in pairs(options.words) do	words[k] = t or words[k] end
		end
	else Echo("<ambient player>: no config found, using defaults")
	end	
		
	if VFS.FileExists(cpath..SOUNDDEF_FILENAME, VFS.RAW_FIRST) then
		if (Spring.LoadSoundDef(cpath..SOUNDDEF_FILENAME)) then
		else Echo("<ambient player>: failed to load sounddefs")		
		end
		
		local list = VFS.Include(cpath..SOUNDDEF_FILENAME, nil, VFS.RAW_FIRST)			
		if (list.Sounditems == nil) then Echo("<ambient player>: sounddef file was empty")			
		else
			tracklist.tracks=list.Sounditems
			for track, params in pairs (tracklist.tracks) do
				tracklist.tmpvalues[track] = {timeframe = params.onset, generated = false}
				--params.timeframe=secondsToUpdate+params.offset
				--params.generated=false
			end
		end		
	else
		Echo("<ambient player>: no sounddefs found")
		tracks = {}		
	end
	
	if VFS.FileExists(cpath..EMITTERS_FILENAME, VFS.RAW_FIRST) then
		emitters = VFS.Include(cpath..EMITTERS_FILENAME, nil, VFS.RAW_FIRST) or emitters
		-- if editmode
		Spring.SendCommands("clearmapmarks")
		for e, t in pairs(emitters) do
			if not(e == 'index') then
				if (t.pos.x) then
					pstring = t.pos.x..", "..t.pos.z..", "..t.pos.y
					Spring.MarkerAddPoint(t.pos.x,t.pos.y,t.pos.z,"(emitter "..e.."): "..pstring,true)
				end
			end			
		end
	end	
	
	if VFS.FileExists(upath..SAVETABLE_FILENAME, VFS.RAW_FIRST) then			
		SaveTable, MakeSortedTable, CompareKeys, valueTypes, keyTypes, encloseKey, encloseStr, keyWordSet, keyWords, saveTables, indendtString
			= VFS.Include(upath..SAVETABLE_FILENAME, nil, VFS.RAW_FIRST)		
		Echo("<ambient player>: loaded savetable.lua")
	else Echo("<ambient player>: failed to load savetable.lua")
	end
	
	if not (config.path_map) then	config.path_map= 'maps/'..Game.mapName..'.sdd/' end
	inited=true --?
end


function widget:GameStart()
	gameStarted = true	
	Echo ("The map directory is assumed to be "..config.path_map.."\nif that is not correct, please type /ap.def map maps/<your map folder>/")	
end

--function widget:Shutdown()	
--	if (config.autosave) then Save() end
--end



--------------------------------------------------------------------------------
-- UPDATE/MISC
--------------------------------------------------------------------------------

function Echo(s)
	Spring.Echo(s)	
	logfile = logfile.."\n"..s
end


function widget:Update(dt) 	
	if not (gameStarted) then return end
	mx,my = Spring.GetMouseState()
	if (needReload and options.autoreload) then ReloadSoundDefs() needReload = false end		
	if (secondsToUpdate>0) then	secondsToUpdate=secondsToUpdate-dt return
	else secondsToUpdate=updateIntervalSeconds
	end
	
	if not (options.autoplay) then return end
	for e, t in pairs (emitters) do
		if not (e == 'index') then		
			for track, _ in pairs(t.playlist) do				
				local trk = tracklist.tracks[track]				
				local tmp = tracklist.tmpvalues[track]
				if (trk.rnd > 0) then					
					tmp.timeframe=tmp.timeframe-updateIntervalSeconds
					if (tmp.timeframe < 0) then
						tmp.timeframe = 0
						if (random(trk.rnd) == 1) then						
							DoPlay(track, options.volume, t.pos.x, t.pos.y, t.pos.z)
							tmp.timeframe=trk.minlooptime
						end
					end
				end
			end
		end	
	end
end	


function DoPlay(track, vol, x, y, z) 
	if not (tracklist.tracks[track]) then Echo("<ambient player>: track "..tostring(track).." not found!") return false
	else
		local tr=track
		if (tracklist.tracks[tr].generated) then	tr=tracklist.tracks[tr].file	end		
		if (PlaySound(tr, vol, x or nil, y or nil, z or nil)) then
			if (options.verbose) then
				Echo("<ambient player>: playing "..track.." at volume: "..string.format("%.2f", vol))
				if (x) then Echo("at Position: "..x..", "..y..", "..z) end
			end
			return true		
		end	
		Echo("<ambient player>: playback of "..track.." failed, not an audio file?")
		return false
	end
end


function AddItemToEmitter(e, item)
	local name = tostring(e).."_"..tostring(item)
	tracklist.tracks[name]={}	
	tracklist.tmpvalues[name]={}	
	for k, v in pairs(tracklist.tracks[item]) do
		tracklist.tracks[name][k] = v		
	end
	tracklist.tmpvalues[name].generated = true
	tracklist.tmpvalues[name].timeframe = tracklist.tracks[name].onset
	tracklist.tracks[name].emitter=e --this could produce some trouble along the way for numbers#
	tracklist.tracks[name].maxdist=100000 --this is required to be less than +inf for positional audio
	emitters[e].playlist[name] = true
	needReload = true
	return true
end


function SpawnEmitter(name, yoffset)
	local p
	yoffset = yoffset or 0
	if (Spring.IsAboveMiniMap(mx, my)) then return 
	else _, p = Spring.TraceScreenRay(mx,my,true)		
	end	
	local pstring = math.floor(p[1])..", "..math.floor(p[3])..", "..math.floor(p[2]).." + "..math.floor(yoffset)	
	if not (name) then
		name = tostring(emitters.index)
		emitters.index = emitters.index + 1
	end		
	
	if (emitters[name]) then Echo("<ambient player>: that name is already taken") return false end
	p[2] = p[2] + yoffset

	local e = {}
	e.pos = {x = math.floor(p[1]), y = math.floor(p[2]), z = math.floor(p[3])}
	e.playlist = {}
	emitters[name]=e
	Spring.MarkerAddPoint(p[1],p[2],p[3],"(emitter "..name.."): "..pstring,true)
end




--------------------------------------------------------------------------------
-- CONSOLE
--------------------------------------------------------------------------------

local words = {
		["utl"] = 	{
						get = function () return PATH_UTIL end,
						set = function (s) PATH_UTIL = s return true end,
					},
		["wdg"] = 	{
						get = function () return PATH_WIDGET end,
						set = function (s) PATH_WIDGET = s return true end,
					},		
		["cfg"] =	{
						get = function () return PATH_CONFIG end,
						set = function (s) PATH_CONFIG = s return true end,
					},
		["snd"] =	{
						get = function () return config.path_sounds end,
						set = function (s) config.path_sounds = s return true end,
					},
		["ui"] =	{
						get = function () return PATH_LUA end,
						set = function (s) PATH_LUA = s return true end,
					},	
		["map"] =	{
						get = function () return config.path_map end,
						set = function (s) config.path_map = s return true end,
					},
		["rd"] =	{
						get = function () return config.path_read end,
						set = function (s) config.path_read = s return true end,
					},
		}	

		
words.get = function(wrd)
	local word = wrd:sub(2) -- cut off the $
	if (word == "") then return wrd end
	if (words[word]) then
		if (words[word].get) then return words[word].get()
		else return words[word]
		end
	else
		return wrd
	end
end		


words.set = function(word, s)
	if (word == "") then return false end
	if (words[word]) then
		if (words[word].set) then return words[word].set(s)
		else words[word]=s return true
		end
	else
		words[word] = s
		return true
	end
end		


function widget:TextCommand(command)		
	if (command:sub(1,3)== "ap.") then	
		local args = ParseInput(" "..command:sub(4))
		if (args) then
			for k, v in pairs(args) do
				Echo(k.."> "..v)
			end
		Invoke(args)
		end		
	end			
end


function ParseInput(s)	
	local i = 1
	local args = {}
	
	s = string.gsub (s, "(%$%w+)", words.get) -- words encapsulated in other words will not get resolved	
	
	repeat
		local sq, eq = string.find (s, "[%{].-[%}]")  --supercede other brackets & quotes
		if not  (sq or eq) then
		sq, eq = string.find (s, "[%(%[].-[%)%]]")	--supercedes quote block
		end
		if not (sq or eq) then
			sq, eq = string.find (s, "[\"\'].-[\"\']")	-- is a block :)
		end
		if (sq or eq) then --<< never happens
			if (sq and eq) then
				--while (s:sub(sq,sq) == " ") do sq = sq + 1 end
				local ss = s:sub(1, sq - 1)	-- get all arguments before the block
				for a in string.gmatch(ss, "%s+(%S+)") do 
					args[i] = a
					i = i + 1
				end
				args[i] = s:sub(sq + 1 , eq -1) -- get the argument in the block
				i = i + 1
				s = s:sub(eq + 1)
				--sq = string.find (s, "[\'\"%(%[]")	 
			else
				Echo("<ambient player>: illegal argument(s) - lone bracket")
				return {}
			end
		else break end	
	until (false)
	
	for a in string.gmatch(s, "%s+(%S+)") do
		Echo(a)
		args[i] = a
		i = i +1
	end
	return args
end	


function Invoke(args)
	
	-- needs adaption to emitters etc
	if (args[1] == "set") then

		if (args[2]) then 
		-- disallow editing non-existant items, to avoid creating bogus items
		
			if not (SOUNDITEM_TEMPLATE[args[2]]) then
				Echo("<ambient player>: unrecognized property")
				return false
			else
			
				if (args[3]) then
								
					if not (tracklist.tracks[args[3]]) then
						Echo("<ambient player>: cannot find target!")
						return false
					end
					
					if (args[4]) then
					
						--local tipe = type(tracks[args[3]][args[2]])
						local tipe = type(SOUNDITEM_TEMPLATE[args[2]]) --read from the template instead
						--Echo("parameter of type: "..tipe)						
						if (tipe == "string") then
							tracklist.tracks[args[3]][args[2]]=tostring(args[4])
							
						elseif (tipe == "boolean") then
							if (args[4] == "true") then 
								tracklist.tracks[args[3]][args[2]]=true
							elseif (args[4] == "false") then
								tracklist.tracks[args[3]][args[2]]=false
							else
								Echo("<ambient player>: only true/false allowed for this value")
								return false
							end
							
						elseif (tipe == "number") then
							local number = tonumber(args[4])
							if (number) then
								tracklist.tracks[args[3]][args[2]]=number
							else
								Echo("<ambient player>: not a number")
								return false
							end							
						end						
						Echo("param: "..args[2].." target: "..args[3].." set to: "..tostring(tracklist.tracks[args[3]][args[2]]))
						return true
						
					else
						Echo("<ambient player>: no value specified")
						Echo("param: "..args[2].." target: "..args[3].." is: "..tostring(tracklist.tracks[args[3]][args[2]]))
						return false
					end
					
				else
					Echo("<ambient player>: no target specified")
					return false
				end
				
			end	
			
		else
			Echo("<ambient player>: no arguments specified")
			return false
		end
		return false
	end
	
	-- play a sounditem, by name
	if (args[1] == "play") then								
		if (args[2]) then			
			local vol
			if (args[3]) then vol = tonumber(args[3])	end
				vol=vol or options.volume							
				local p = {x,y,z}
				if (tracklist.tracks[args[2]]) then
					if (tracklist.tracks[args[2]].emitter) then						
						p = emitters[tracklist.tracks[args[2]].emitter].pos						
					end
				end
				return DoPlay(args[2], vol, p.x, p.y, p.z)							
		else
			Echo("<ambient player>: specify a track")
			return false
		end
	end
	
	-- load a single sound file from the read folder and generate a table entry for it
	-- if no name for the entry was specified, it will use that files name after a '$'
	-- file can then by accessed by that name, and that name only
	-- arguments:
	-- file/*: mandatory
	-- name to use in the playlist: optional, defaults to filename	
	if (args[1] == "load") then		
		if (args[2]) then
			if (args[2] == "*") then				
				local files = VFS.DirList(config.path_read)
				local f
				local l = config.path_read:len()
				for file, text in pairs(files) do
					f = text:sub(l+1)
					LoadFromFile(config.path_read, f, nil, args[3])			
				end
				return
			end
			if (args[3]) then return LoadFromFile(config.path_read, args[2], args[3])			
			end	
		else
			Echo("<ambient player>: specify a file in "..config.path_read)
			return false
		end		
	end
	
	-- echo whole playlist or display single item properities
	if (args[1] == "list") then		
		i = 2
		while (args[i]) do
			local n = tonumber(args[i]) or args[i] --Echo(type(n))
			if (tracklist.tracks[n]) then
				Echo("<ambient player>: ---"..args[i].."---")
				for param, value in pairs(tracklist.tracks[n]) do
					Echo(tostring(param).." : "..tostring(value))
				end
			elseif (emitters[n]) then
				if not (args[i] == index) then
					--local n = tonumber(args[i]) or args[i] Echo(type(n))
					local e = emitters[n]
					Echo(tostring(e)..": "..(e.pos.x or "none")..", "..(e.pos.y or "none")..", "..(e.pos.z or "none"))
					for track, param in pairs(e.playlist) do
						Echo("- "..track.." length: "..tracklist.tracks[track].length)
					end					
				else
					Echo("Index: ".. emitters.index)
				end
			else			 
				Echo("<ambient player>: no such item or emitter: "..args[i])
			end	
			i = i + 1			
		end	if (i>2) then return true end
		
		Echo("<ambient player>: -----sounditems-----")
		for track, params in pairs (tracklist.tracks) do
			if not (params.emitter)	then Echo(track.." - "..(params.length).."s") end			
		end
		Echo("<ambient player>: -----emitters-----")
		for e, tab in pairs (emitters) do
			if not (e == "index") then
				Echo(tostring(e)..": "..(tab.pos.x or "none")..", "..(tab.pos.y or "none")..", "..(tab.pos.z or "none"))
				for track, param in pairs(tab.playlist) do
						Echo("- "..track.." length: "..tracklist.tracks[track].length)
				end
			end
		end
		return true
	end
	
	if (args[1] == "dir") then		
		if not (args[2]) then
			Echo("<ambient player>: you must specify a path")
			return false
		end
		
		local pattern = "."
		if (args[3]) then
				pattern = string.gsub (args[3], "[%.%*]", {["."] = "%.", ["*"] = ".+" })
				--if (pattern == "%." or pattern == ".+%.") then pattern = "[^%.]" end
		end
				
		local path=args[2]			
		if not (path:sub(-1) == ('/' or '\\')) then	path=path..'/'	end		
		
		local files = VFS.DirList(path)
		local subdirs = VFS.SubDirs(path)		
		
		Echo ("----- "..path.." -----")		
		for dir, text in pairs(subdirs) do
			if (pattern == "%." or pattern == ".+%.") then
				if (string.match(text, "[%.]")) then Echo(text) end
			else
				if (string.match(text, pattern)) then Echo(text) end
			end	
		end
		for file, text in pairs(files) do
			if (pattern == "%." or pattern == ".+%.") then
				if not (string.match(text, "[%.]")) then Echo(text) end
			else
				if (string.match(text, pattern)) then Echo(text) end
			end	
		end
		return true
	end
	
	
	if (args[1] == "save") then		
		if (args[2]) then --type
			if (string.match (args[2], "^[e]")) then
				Save(3)		
			elseif (string.match (args[2], "^[o]")) then
				Save(1)
			elseif (string.match (args[2], "^[p]")) then
				Save(2)
			else
				Echo("<ambient player>: type must be: e..., p..., o...")
				Echo("(emitters, playlist, options)")
				return false
			end			
			return true			
		else
			Echo("<ambient player>: saving all to write dir...")
			Save(0)
		end	
		return false	
	end
	
	--defunct
	if (args[1] == "map") then
		if (args[2]) then
			if VFS.MapArchive(args[2]) then
				Echo("success") 
				return true
			end				
		end
		Echo("failure")
		return false
	end
	
	if (args[1] == "env") then
		if (args[2]) then
			Echo("\n-------"..args[2].."--------")
			--local file = io.open("G.txt", "w")
			---[[
			local G = getfenv()
			local i = 0
			if not (G[args[2]]) then return end
			for k, v in pairs(G[args[2]]) do
				--file:write("key: "..k.." str:"..tostring(k).." val"..tostring(v).."\n")
				--if not (type(k) == 'table') then
				Echo (tostring(k))
				--end
				i=i +1
				if (i==10000) then break end
			end
			--]]
			--Echo(words.get("$read"))
			--file:close()
		end	
	end

	if (args[1] == "do") then
		if (args[2]) then
			loadstring(args[2])()
		end
		return
	end
		
	if (args[1] == "def") then
		if (args[2]) then
			if (args[3]) then
				return words.set(args[2], args[3])				
			end		
		else
			Echo ("----- ".."defines".." -----")	
			for k,v in pairs(words) do 
				if (type(v) == 'table') then
					Echo('$'..k.." -> "..v.get())
				elseif (type(v) ~= 'function') then
					Echo('$'..k.." -> "..v)
				end
				
			end
		end
		return
	end
	
	if (args[1] == 'spawn') then
		SpawnEmitter(args[2], tonumber(args[3]))
		return
	end
	
	if (args[1] == 'add') then
		if (args[2]) then
		local n = tonumber(args[2]) or args[2] --Echo(type(n))
			if (emitters[n]) then
				local i = 3
				if (args[3] == '*') then
					for track,params in pairs(tracklist.tracks) do
						--AddItemToEmitter(args[2], track) --this sucks, use generated tag to avoid duplicates?						
						args[i] = track
						i = i +1
					end
					i = 3					
				end
				
				while (args[i]) do
					if (tracklist.tracks[args[i]]) then
						if not (emitters[n].playlist[args[i]]) then
							AddItemToEmitter(n, args[i])							
						else
							Echo ("<ambient player>: track "..args[i].." already present in "..args[2])
						end
					else
						Echo ("<ambient player>: no such track: "..args[i])
					end
				i = i + 1	
				end				
			else
				Echo ("<ambient player>: no such emitter")
			end
		end
		return
	end
	
	if (args[1] == "reload") then
		ReloadSoundDefs()
		return
	end
	Echo("<ambient player>: not a valid command")	
	
end



--------------------------------------------------------------------------------
-- I/O
--------------------------------------------------------------------------------

function ReloadSoundDefs()	
	local rpath = PATH_LUA..PATH_CONFIG
	local wpath = config.path_map..rpath	
	
	if not (Save(2, wpath, TMP_FILENAME)) then return end
	if not (Spring.LoadSoundDef(rpath..TMP_FILENAME)) then Echo("<ambient player>: failed to load sounddefs") return false end
	
	list = VFS.Include(rpath..TMP_FILENAME, nil, VFS.RAW_FIRST)			
	if (list.Sounditems == nil) then Echo("<ambient player>: sounddef file was empty")			
	else
		tracklist.tracks=list.Sounditems
		for track, params in pairs (tracklist.tracks) do			
			if not (tracklist.tmpvalues[track]) then 
				tracklist.tmpvalues[track] = {timeframe = params.onset, generated = false} --should never happen
				Echo("THIS SHALL NEVER HAPPEN!")
			end
				--params.timeframe=secondsToUpdate+params.offset
				--params.generated=false
		end
	end		
end


function LoadFromFile(folder, file, name, nametag)		
	Echo("<ambient player>: loading "..folder..file.." ...")
	if VFS.FileExists(folder..file) then
		local ending=file:sub(-4,-1)
		if not (ending=='.ogg' or ending =='.wav') then	Echo("<ambient player>: must be *.wav or *.ogg file!") return false	end

		local shortname = name or (file:sub(1,-5))
		
		if (tracklist.tracks[shortname] ~= nil) then Echo("<ambient player>: a sounditem with that name already exists!") return false		
		else 		
			if not (PlaySound(folder..file, 0)) then -- preload the file and generate sounditem?
					-- should just force reload instead i would think
					Echo("<ambient player>: unable to load file. not a soundfile?")
					return false
			end 		
			
			tracklist.tracks[shortname]={}
			tracklist.tmpvalues[shortname]={}
			for param, value in pairs (SOUNDITEM_TEMPLATE) do tracklist.tracks[shortname][param] = value end		
			tracklist.tmpvalues[shortname].timeframe = tracklist.tracks[shortname].onset
			tracklist.tmpvalues[shortname].generated = true
			tracklist.tracks[shortname].file=folder..file			
			Echo("<ambient player>: added playlist entry: "..shortname)
		end							
	else Echo("<ambient player>: file not found!") return false end
	Echo("<ambient player>: loaded "..file.." successfully!")
	needReload = true
end


function Save(list, path, file) 
	
	path = path or config.path_map..PATH_LUA..PATH_CONFIG
	list = list or 0
	
	if (list == 0 or list == 1) then --options
		file = file or OPTIONS_FILENAME
		local options = {config = config}
		local w = {}
		for k, v in pairs(words) do
			if not (type(v) == 'table') then w.k = v end
		end
		options.words = w
		if (WriteTable(options, path..file, 'Options', OPTIONS_HEADER)) then Echo("<ambient player>: saved options to "..path..file)
		else Echo("<ambient player>: failed to save options") return false end
		file = nil
	end	
	
	if (list == 0 or list == 2) then --playlist	
		file = file or SOUNDDEF_FILENAME
		local gentracks = {}
		for item, params in pairs(tracklist.tmpvalues) do
			if (params.generated) then gentracks[item]=true params.generated=false end
		end
	
		local dumdum = {}
		dumdum.Sounditems = tracklist.tracks		
		if (WriteTable(dumdum, path..file, 'Sounds', SOUNDDEF_HEADER)) then	Echo("<ambient player>: saved sounddefs to "..path..file)
		else Echo("<ambient player>: failed to save sounddefs") return false end
		for item, params in pairs(tracklist.tmpvalues) do
			if (gentracks[item]) then params.generated=true	end
		end
		file = nil		
	end	
	
	if (list == 0 or list == 3) then --emitters
		file = file or EMITTERS_FILENAME
		if (WriteTable(emitters, path..file, 'Emitters', EMITTERS_HEADER)) then	Echo("<ambient player>: saved emitters to "..path..file)
		else Echo("<ambient player>: failed to save emitters") return false	end
		file = nil
	end
	return true
end


function WriteTable(t, filename, tname, header)

	if not (filename) then Echo("<ambient player>: you must specify a file") return false end
	
	Echo("<ambient player>: saving "..filename.." ...")
	local file = io.open(filename, 'w')
	
	if (file == nil) then Echo("<ambient player>: failed to open "..filename) return false end
	
	if (header) then file:write(header..'\n') end
	
	file:write('local '..tname..' = ')
	SaveTable(t, file, '')
	file:write('}\nreturn '..tname)
	
	file:close()
	Echo("<ambient player>: done!")
	return true
end



	--[[
	-- if the player will announce titles when playing
	if (args[1] == "verbose") then
		config.verbose = not (config.verbose)
		if (config.verbose) then
			Echo("<ambient player>: verbose on")
		else 
			Echo("<ambient player>: verbose off")
		end
		return true
	end
	
	-- general volume control
	if (args[1] == "vol") then	
		local number = tonumber(args[2])
		if (number) then			
			if (number < 0) then config.ambientVolume = 0
			elseif (number > 2) then config.ambientVolume = 2
			else config.ambientVolume=number
			end
			Echo("<ambient player>: set ambient volume "..string.format("%.2f",config.ambientVolume))
			return true
		end
		Echo("<ambient player>: not a number")
		return false
	end	

	-- pause playlist
	if (args[1] == "hold") then
		options.autoplay = not (options.autoplay)
		if (options.autoplay) then
			Echo("<ambient player>: play")
		else 
			Echo("<ambient player>: hold")
		end
		return true
	end

	if (args[1] == "show") then
		config.showEmitters = not config.showEmitters
		return
	end

	--]]
