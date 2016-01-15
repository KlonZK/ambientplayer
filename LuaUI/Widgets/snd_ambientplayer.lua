include("keysym.h.lua")

local versionNum = '0.642'

function widget:GetInfo()
  return {
    name      = "Ambient Sound Player & Editor",
    desc      = "v"..(versionNum),
    author    = "Klon",
    date      = "dez 2014 - jan 2016",
    license   = "GNU GPL, v2 or later",
    layer     = -1,
    enabled   = false,
  }
end


-------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------
-- CONSTANTS & SHORTCUTS
-------------------------------------------------------------------------------------------------------------------------

local PlaySound = Spring.PlaySoundFile
local PlayStream = Spring.PlaySoundStream
--local GetMouse = Spring.GetMouseState
--local TraceRay = Spring.TraceScreenRay
--local IsMouseMinimap = Spring.IsAboveMiniMap
--local GetGroundHeight = Spring.GetGroundHeight
--local GetModKeys = Spring.GetModKeyState

-- widget cant light
--local MapLight = Spring.AddMapLight
--local ModelLight = Spring.AddModelLight
--local UpdateMapLight = Spring.UpdateMapLight
--local UpdateModelLight = Spring.UpdateModelLight

local random=math.random

local vfsInclude = VFS.Include
local vfsExist = VFS.FileExists
local spLoadSoundDefs = Spring.LoadSoundDef

local VFSMODE = VFS.RAW_FIRST

local PATH_LUA = LUAUI_DIRNAME
local PATH_CONFIG = 'Configs/'
local PATH_WIDGET = 'Widgets/'
local PATH_UTIL = 'Utilities/'
local PATH_MODULE = 'Modules/'

local FILE_MODULE_IO = 'snd_ambientplayer_io.lua'
local FILE_MODULE_GUI = 'snd_ambientplayer_gui.lua'
local FILE_MODULE_DRAW = 'snd_ambientplayer_draw.lua'

local MAPCONFIG_FILENAME = 'ambient_mapconfig.lua'
local SOUNDS_ITEMS_DEF_FILENAME = 'ambient_sounds_templates.lua'
local SOUNDS_INSTANCES_DEF_FILENAME = 'ambient_sounds_instances.lua'
local EMITTERS_FILENAME = 'ambient_emitters.lua'
local TMP_ITEMS_FILENAME = 'ambient_tmp_items.lua'
local TMP_INSTANCES_FILENAME = 'ambient_tmp_instances.lua' -- should be in i/O
local LOG_FILENAME = 'ambient_log.txt' -- "



-------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------
-- PACKAGE
-------------------------------------------------------------------------------------------------------------------------

local logfile
local _log = [[]]
local spEcho = Spring.Echo

-- should start dumping if it gets too long
-- also might want to do boolean->string here as it gets too annoying
function Echo(s, keepline)
	spEcho('<ape>: '..s)
	_log = _log..(keepline and '' or '\n')..s
	if controls and controls.log then controls.log:SetText(_log) end
	if logfile then logfile:write((keepline and '' or '\n')..s) end
end

local config = {}
config.path_sound = 'Sounds/Ambient/'
config.path_read = 'Sounds/Ambient/'
config.path_map = nil
-- config.mapX
-- config.mapZ

local SOUNDITEM_PROTOTYPE = {
	-- sounditem stats
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
	length_real = 0, -- this should be ignored for purpose of playback, unless length_loop isnt set
	rnd = 0,
	length_loop = 1, -- not sure how this works right now but it should be plainly the length of the loop...
	delay = 1, -- should be just once
}

local sounditems = {
	templates = {},
	instances = {},
	default = SOUNDITEM_PROTOTYPE,
}

-- these should automatically fill files with values too
setmetatable(sounditems.templates, {
	__newindex = function (t, k, v)
		rawset(t, k, v)
		setmetatable(t[k], {__index = SOUNDITEM_PROTOTYPE})
	end
})

-- actually these should fall back to the template (which should now possible as they store a reference?)
setmetatable(sounditems.instances, {
	__newindex = function (t, k, v)
		rawset(t, k, v)
		setmetatable(t[k], {__index = SOUNDITEM_PROTOTYPE})
	end
})

-- are these used?
local tracklist_controls = {}
local emitters_controls = {}

local emitters = {
	--	[e<string>] = {
	--		pos = {x, y, z},
	--		gl = {delta, u, v},
	--		sounds = { --< INDEXED TABLE WILL FAIL HORRIBLY IF THINGS GET REMOVED OUT OF ORDER
	--			[j] = {
	--				item = <sounditem>
	--				generated = <boolean> -- this is not needed anymore
	--				timer = <number> --there are different timers, one counts the time until playback, one counts during playback until end
	--				...
	--			},
	-- 		},
	--		isPlaying = false,
	--	},
}

-- look up sounds by name or reference
setmetatable(emitters, {
	__newindex = function(t, k, v)
		rawset (t, k, v)
		if not t[k].sounds then t[k].sounds = {} end
		if not t[k].gl then
			t[k].gl = {}
			t[k].gl.delta = math.random(60)
			t[k].gl.u = math.random(60)
			t[k].gl.v = math.random(60)
		end
		--if not t[k].script then t[k]['script'] = 'function run() end'
		setmetatable(t[k].sounds, {
			__index = function(st, trk)
				--for _k, _v in pairs(st) do
				--	Echo("\nst: ".._k.."--".. tostring(_v))
				--end
				if type(trk) == 'string' then
					--Echo("searching emitter for item:"..trk)
					for i = 1, #st do
						--for k, v in pairs(st) do
						--	Echo(k, v)
						--end
						--Echo("\n--->"..st[i].item.."--"..type(st[i].item))
						if st[i].item == trk then return st[i] end --ill just assume they will both be strings for now
					end
				end
				return nil
			end
		})
	end
})

--emitters.global = {pos = {}} --sounds = {}, gl = {delta = math.random(60), u = math.random(60), v = math.random(60)}}

options = {}



-------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------
-- MODULES
-------------------------------------------------------------------------------------------------------------------------

settings = {paths = {}, browser = {}, display = {}, interface = {}}

local common = {pairs = pairs, ipairs = ipairs, type = type, string = string, tostring = tostring, tonumber = tonumber,
	setmetatable = setmetatable, getfenv = getfenv, setfenv = setfenv, rawset = rawset, rawget = rawget, assert = assert,
		os = os, math = math, io = io, table = table, next = next, error = error, select = select,
			widget = widget, Echo = Echo, options = options, config = config, settings = settings,
				sounditems = sounditems, emitters = emitters, Spring = Spring}

-- SetupGUI() builds controls so we can't import keys yet
Echo ("Loading modules...")

local i_o = {PATH_LUA = PATH_LUA, PATH_CONFIG = PATH_CONFIG, TMP_ITEMS_FILENAME = TMP_ITEMS_FILENAME,
				TMP_INSTANCES_FILENAME = TMP_INSTANCES_FILENAME, LOG_FILENAME = LOG_FILENAME,
					MAPCONFIG_FILENAME = MAPCONFIG_FILENAME, EMITTERS_FILENAME = EMITTERS_FILENAME,
						SOUNDS_ITEMS_DEF_FILENAME = SOUNDS_ITEMS_DEF_FILENAME,
							SOUNDS_INSTANCES_DEF_FILENAME = SOUNDS_INSTANCES_DEF_FILENAME}
for k, v in pairs(common) do i_o[k] = v end

do
	local file = PATH_LUA..PATH_MODULE..FILE_MODULE_IO
	if vfsExist(file, VFSMODE) and vfsInclude(file, i_o, VFSMODE) then
		Echo("I/O module successfully loaded")

	else
		Echo("failed to load I/O module")
	end
end

local draw = {}
for k, v in pairs(common) do draw[k] = v end
do
	local file = PATH_LUA..PATH_MODULE..FILE_MODULE_DRAW
	if vfsExist(file, VFSMODE) and vfsInclude(file, draw, VFSMODE) then
		Echo("DRAW module successfully loaded")
	else
		Echo("failed to load DRAW module")
	end
end

local unitools = {getfenv = getfenv, string = string, math = math}

do
	local file = PATH_LUA..PATH_UTIL..'unicode.lua'
	if vfsExist(file, VFSMODE) then
		unitools = vfsInclude(file, unitools, VFSMODE)
		if unitools then Echo("unicode utils loaded")
		else Echo("failed to load unicode utils") end
	else
		Echo("could not find unicode utils")
	end
end

local gui = {tracklist_controls = tracklist_controls, emitters_controls = emitters_controls, UpdateMarkerList = draw.UpdateMarkerList,
				DrawIcons = draw.DrawIcons, DrawCursorToWorld = draw.DrawCursorToWorld, draw = draw, i_o = i_o, 
					KEYSYMS = KEYSYMS, VFS = VFS, unitools = unitools}
for k, v in pairs(common) do gui[k] = v end

do
	local file = PATH_LUA..PATH_MODULE..FILE_MODULE_GUI
	if vfsExist(file, VFSMODE) then
		gui = vfsInclude(file, gui, VFSMODE)
		if gui then Echo("GUI module successfully loaded")
		else Echo("failed to load GUI module") end
	else
		Echo("could not find gui module")
	end
	-- load console here if wanted or if chili fails
end




-------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------
-- Epic Menu Options
-------------------------------------------------------------------------------------------------------------------------
options_path = 'Settings/Audio/Ambient Sound'
options_order = {'verbose', 'autosave', 'autoreload', 'checkrate', 'volume', 'autoplay'}

options.checkrate = {
	name = "Update frequency",
	type = 'number',
	value = 1,
	min = 1,
	max = 30,
	step = 1,
	path = "Settings/Audio/Ambient Sound",
}
options.volume = {
	name = "Volume",
	type = 'number',
	value = 1,
	min = 0.1,
	max = 2,
	step = 0.1,
	path = "Settings/Audio/Ambient Sound",
}
options.autoplay = {
	name = "Autoplay",
	type = 'bool',
	value = true,
	path = "Settings/Audio/Ambient Sound",
}
options.verbose = {
	name = "Verbose",
	type = 'bool',
	value = true,
	path = "Settings/Audio/Ambient Sound/Editor",
}
options.autosave = {
	name = "Autosave",
	type = 'bool',
	value = true,
	path = "Settings/Audio/Ambient Sound/Editor",
}
options.autoreload = {
	name = "Auto Reload",
	type = 'bool',
	value = true,
	path = "Settings/Audio/Ambient Sound/Editor",
}


--[[
settings.interface.dragtime = {
	name = "Seconds until drag starts",
	type = 'number',
	value = 0.5,
	min = 0.1,
	max = 2,
	step = 1,
	path = "Ambient Sound Editor",
}--]]


settings.display = {true, 5, 1, 1, 1, 0.25, 0.55, 2.5}
settings.interface = {150, 0.15, 0.3}




-------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------
-- LOCALS
-------------------------------------------------------------------------------------------------------------------------

local secondsToUpdate = 0.1
local gameStarted = Spring.GetGameFrame() > 0
local inited = false
local needReload = false

-------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------
-- LOCAL FUNCTIONS
-------------------------------------------------------------------------------------------------------------------------

local function DoPlay(trk, vol, ename)
	local e = emitters[ename]
	local item = sounditems.templates[trk] or sounditems.instances[trk]
	if not item then
		Echo("item "..tostring(trk).." not found!")
		return false
	else
		--local tr = item
		-- if (tracklist.tracks[tr].generated) then	tr = tracklist.tracks[tr].file	end	 -- is this used?
		if (PlaySound(trk, vol, e.pos.x, e.pos.y, e.pos.z)) then
			if (options.verbose.value) then
				Echo("playing "..trk.." at volume: "..string.format("%.2f", vol))
				if (e.pos.x) then Echo("at Position: "..e.pos.x..", "..e.pos.y..", "..e.pos.z) end -- should format this looks bad with decimals
			end
			--Echo(type(e.sounds))
			--Echo (e.sounds[item].endTimer)
			if e.sounds[trk] then
				e.sounds[trk].endTimer = item.length_real
				e.sounds[trk].isPlaying = true
				if gui then
					EmitterInspectionWindow.instances[ename].layout.list[trk].activeIcon:Refresh()
				end	
			end
			--Echo("length: "..sounditems.instances[item].length)

			return true
		end
		Echo("playback of "..tr.." failed, not an audio file?")
		return false
	end
end

--
function AddItemToEmitter(e, iname) -- <string, string> !!!
	--assert(type(item) == 'table')
	local item
	local name
	local template

	if sounditems.templates[iname] then
		item = sounditems.templates[iname]
		name = "$"..e.."$ "..iname
		template = iname
	end
	if sounditems.instances[iname] then -- this needs testing
		assert(not item, "identical item names in templates/instance tables")
		item = sounditems.instances[iname]
		local _, endprefix = string.find(iname, "[%$].*[%$%s]")
		Echo(endprefix)
		name = "$"..e.."$ "..iname:sub(endprefix + 1) -- remove old emitter tag
		template = item.template
	end

	while (sounditems.instances[name]) do name = name.."_" end -- add any number of _ at the end for duplicates

	sounditems.instances[name] = {}
	local newItem = sounditems.instances[name]
	for k, v in pairs(item) do newItem[k] = v end
	newItem.template = template

	local es = emitters[e].sounds; es[#es + 1] = {}
	--local newSound = es[#es]

	es[#es].item = name -- !
	es[#es].startTimer = newItem.delay
	es[#es].endTimer = 0
	es[#es].isPlaying = false

	-- newItem.maxdist = newItem.maxdist < 100000 and newItem.maxdist or 100000 -- this is bad, should not have to set it here
	-- newItem.emitter = e -- needed?

	needReload = true
	controls.emitterslist[e].label:UpdateTooltip()
	Echo("added <"..es[#es].item..">")
	return true
end

-- this needs a look at
local function RemoveItemFromEmitter(e, item)
	if not sounditems.instances[item] then
		Echo("a sounditem with that name is not in use")
		return false
	end

	assert(sounditems.instances[item] and emitters[e].sounds[item]) -- to make sure we didnt fuck up earlier when adding

	sounditems.instances[item] = nil
	emitters[e].sounds[item] = nil
end


local function RemoveItemFromList(item)
	if not sounditems.templates[item] then
		Echo("a sounditem with that name is not registered")
		return false
	end

	sounditems.instances[item] = nil
	for e = 1, #emitters do
		emitters[e].sounds[item] = nil
	end
end


function SpawnEmitter(name, x, z, y)-- yoffset)
	--local p
	--if not MouseOnGUI() then _, p = Spring.TraceScreenRay(mx,mz,true)
	--else return end
	if (emitters[name]) then Echo("an emitter with that name already exists") return false end

	--yoffset = yoffset or 0
	--p[2] = p[2] + yoffset
	name = name or math.floor(x)..", "..math.floor(z)..", "..math.floor(y)

	-- __newindex should build our tables
	emitters[name] = {}
	--emitters[name].gl = {delta = math.random(60), u = math.random(60), v = math.random(60)}
	emitters[name].pos = {x = math.floor(x), y = math.floor(y), z = math.floor(z)}

	--emitters[name].light = MapLight(eLightTable)
end



-------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------
-- INPUT LISTENERS AND AUXILIARY
-------------------------------------------------------------------------------------------------------------------------



-- fuck you you-know-who
local function MouseOnGUI()
	--local mz_inv = math.abs(screen0.height - mz)
	return IsMouseMinimap(mx or 0, mz or 0) or MouseOver(mx, mz_inv)--screen0.hoveredControl --or screen0.focusedControl
end

-------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------
-- GUI
-------------------------------------------------------------------------------------------------------------------------
-- $\luaui\modules\snd_ambientplayer_gui.lua

function widget:IsAbove(...)
	return gui and (not Spring.IsGUIHidden()) and gui.IsAbove(...)
end

function widget:GetTooltip(...)
	return gui and (not Spring.IsGUIHidden()) and gui.GetTooltip(...)
end

function widget:KeyPress(...)
	return gui and (not Spring.IsGUIHidden()) and gui.KeyPress(...)
end

function widget:TextInput(...)
	return gui and (not Spring.IsGUIHidden()) and gui.TextInput(...)
end

function widget:MousePress(...)
	return gui and (not Spring.IsGUIHidden()) and gui.MousePress(...)
end

function widget:MouseRelease(...)
	return gui and (not Spring.IsGUIHidden()) and gui.MouseRelease(...)
end

function widget:MouseWheel(...)
	return gui and (not Spring.IsGUIHidden()) and gui.MouseWheel(...)
end

function widget:MouseMove(...)
	return gui and (not Spring.IsGUIHidden()) and gui.MouseMove(...)
end



-------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------
-- UPDATE/MISC
-------------------------------------------------------------------------------------------------------------------------

function RequestReload()
	needReload = true
end



-- this is actually wasteful
-- also needs to poll all the windows to be really safe : /


function widget:Update(dt)
	if not (gameStarted) then return end
	if gui then
		UpdateGUI(dt)
	end

	if (needReload and options.autoreload.value) then ReloadSoundDefs() needReload = false end
	if (secondsToUpdate>0) then	secondsToUpdate = secondsToUpdate-dt return
	else secondsToUpdate = options.checkrate.value
	end

	if not (options.autoplay.value) then return end
	for e, params in pairs (emitters) do
		local hasRunningTracks = false
		for i = 1, #params.sounds do
		local trk = params.sounds[i]
		local item = trk.item
			if item then -- remove extra nil check eventually
				trk.endTimer = trk.endTimer - options.checkrate.value
				if trk.rnd and trk.rnd > 0 then
					trk.startTimer = trk.startTimer - options.checkrate.value -- this seems inaccurate
					if (trk.startTimer < 0) then
						trk.startTimer = 0
						if (random(trk.rnd) == 1) then
							DoPlay(item, options.volume.value, e) --< this should pass nils if pos.* doesnt exist
							trk.startTimer  = item.length_loop
							--trk.endTimer = item.length
							--Echo("length: "..item.length)
						end
					end
				end
				if trk.endTimer > 0 then
					hasRunningTracks = true
					--trk.isPlaying = true
				else
					hasRunningTracks = hasRunningTracks
					trk.isPlaying = false
					--if EmitterInspectionWindow.instances[e] then
						if gui then 
							EmitterInspectionWindow.instances[e].layout.list[item].activeIcon:Refresh()
						end
					--end
				end
				-- hasRunningTracks = trk.endTimer > 0 and true or hasRunningTracks
			end
		end
		params.isPlaying = hasRunningTracks
		--if params.isPlaying then Echo(e.." is playing") end
	end
end




-------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------
-- I/O
-------------------------------------------------------------------------------------------------------------------------
-- $\luaui\modules\snd_ambientplayer_io.lua

-------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------
-- DRAW
-------------------------------------------------------------------------------------------------------------------------
-- $\luaui\modules\snd_ambientplayer_draw.lua

function widget:DrawWorld() --?
	gui.DrawWorld()
end

-- may want this to render sound icons when dragging?
--function widget:DrawScreen()
	--if drag._type.spawn then DrawCursor(mx, mz, 10, 10, 10) end
--end

-------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------
-- INIT
-------------------------------------------------------------------------------------------------------------------------

function widget:GetConfigData()
	Echo("exporting widget config...")
	return settings
end

function widget:SetConfigData(data)
	Echo("importing widget config...")
	if type(data) == 'table' then
		for k, v in pairs(data) do
			settings[k] = v
		end
	end
	--WG.music_volume = settings.music_volume or 0.5
end


function widget:Initialize()

	gui.DoPlay = DoPlay
	gui.drag = drag

	local cpath = PATH_LUA..PATH_CONFIG
	local upath = PATH_LUA..PATH_UTIL

	--setfenv(SetupGUI, gui)
	Echo("Building GUI...")
	gui.SetupGUI()
	Echo("done", true)

	for k, v in pairs(gui) do
		--widget[k] = widget[k] or v
		if not widget[k] then
			widget[k] = v
			Echo("added key '"..k.."' to globals")
		end
	end
	for k, v in pairs(draw) do
		--widget[k] = widget[k] or v
		if not widget[k] then
			widget[k] = v
			Echo("added key '"..k.."' to globals")
		end
	end
	for k, v in pairs(i_o) do
		--widget[k] = widget[k] or v
		if not widget[k] then
			widget[k] = v
			Echo("added key '"..k.."' to globals")
		end
	end

	-- put this stuff into io

	Echo ("Loading local config...")
	if vfsExist(cpath..MAPCONFIG_FILENAME, VFSMODE) then
		local opt = vfsInclude(cpath..MAPCONFIG_FILENAME, nil, VFSMODE)
		if opt then
			for k, v in pairs(opt) do config[k] = v or config[k] end
			Echo("done", true)
		else
			Echo("local config was empty, using defaults", true)
		end
--		if (opt.words) then
--			for k, t in pairs(opt.words) do	words[k] = t or words[k] end
--		end
	else Echo("could not open config file, using defaults", true)
	end

	Echo ("Loading templates...")
	if vfsExist(cpath..SOUNDS_ITEMS_DEF_FILENAME, VFSMODE) then
		if not spLoadSoundDefs(cpath..SOUNDS_ITEMS_DEF_FILENAME) then
			Echo("failed to load templates, check format\n '"..cpath..SOUNDS_ITEMS_DEF_FILENAME.."'")
		end
		local list = vfsInclude(cpath..SOUNDS_ITEMS_DEF_FILENAME, nil, VFSMODE)
		if not list.Sounditems then
			Echo("templates file was empty", true)
		else
			local i = 0
			for s, params in pairs(list.Sounditems) do i = i + 1; sounditems.templates[s] = params end
			Echo ("found "..i.." sounditems", true)
		end
	else
		Echo("file not found\n '"..cpath..SOUNDS_ITEMS_DEF_FILENAME.."'")
	end

	Echo ("Loading sounds...")
	if vfsExist(cpath..SOUNDS_INSTANCES_DEF_FILENAME, VFSMODE) then
		if not spLoadSoundDefs(cpath..SOUNDS_INSTANCES_DEF_FILENAME) then
			Echo("failed to load sounds in use, check format\n '"..cpath..SOUNDS_INSTANCES_DEF_FILENAME.."'")
		end
		local list = vfsInclude(cpath..SOUNDS_INSTANCES_DEF_FILENAME, nil, VFSMODE)
		if (list.Sounditems == nil) then
			Echo("sounds file was empty", true)
		else
			local i = 0
			for s, params in pairs(list.Sounditems) do
				i = i + 1
				sounditems.instances[s] = params
				--sounditems.instances[s].endTimer = 0
			end
			Echo ("found "..i.." sounds", true)
		end
	else
		Echo("file not found\n '"..cpath..SOUNDS_INSTANCES_DEF_FILENAME.."'")
	end

	Echo ("Loading emitters...")
	if vfsExist(cpath..EMITTERS_FILENAME, VFSMODE) then
		local tmp = vfsInclude(cpath..EMITTERS_FILENAME, nil, VFSMODE) -- or emitters ?
		if tmp then
			local i = 0
			for e, params in pairs(tmp) do
				i = i + 1
				emitters[e] = params
				params.isPlaying = nil
				for _, v in ipairs(params.sounds) do
					v.endTimer = 0
					-- ...
				end
			end
			Echo ("found "..i.." emitters", true)
		else Echo ("emitters file was empty", true)
		end
	end
	if not emitters.global then emitters.global = {pos = {}} end

	Echo("updating map config...")
	if not (config.path_map) then config.path_map = 'maps/'..Game.mapName..'.sdd/' end
	config.mapX = Game.mapSizeX
	config.mapZ = Game.mapSizeZ

	if not (config.path_spring) or #VFS.DirList(config.path_spring) == 0 then
		Echo("searching spring folder...")
		if VFS.FileExists('infolog.txt', VFSMODE) then
			config.path_spring = i_o.GetSpringDir()
		end
	end


	--logfile = io.open(config.path_map..PATH_LUA..PATH_CONFIG..LOG_FILENAME, 'w')
	logfile = io.open(LOG_FILENAME, 'w')
	if not logfile then
		Echo("could not open logfile")
	elseif logfile:write(_log) then
		Echo("written backlog")
	end

	inited=true --?
	Echo("Updating GUI...")
	UpdateGUI()
	Echo("Init done!")


end


function widget:GameStart()
	gameStarted = true
	-- if at this point a directory for the map doesnt exist, i could make one
	Echo ("The map directory is assumed to be "..config.path_map.."\nif that is not correct, please type /ap.def map maps/<your map folder>/")
end

function widget:Shutdown()
	Echo("shutting down...")
	if logfile then logfile:close() end
end



-------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------
-- CONSOLE
-------------------------------------------------------------------------------------------------------------------------

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
						get = function () return config.path_sound end,
						set = function (s) config.path_sound = s return true end,
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


local function ParseInput(s)
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
				Echo("illegal argument(s) - lone bracket")
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


local function Invoke(args)

	-- needs adaption to emitters etc
	if (args[1] == "set") then

		if (args[2]) then
		-- disallow editing non-existant items, to avoid creating bogus items

			if not (SOUNDITEM_TEMPLATE[args[2]]) then
				Echo("unrecognized property")
				return false
			else

				if (args[3]) then

					if not (tracklist.tracks[args[3]]) then
						Echo("cannot find target!")
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
								Echo("only true/false allowed for this value")
								return false
							end

						elseif (tipe == "number") then
							local number = tonumber(args[4])
							if (number) then
								tracklist.tracks[args[3]][args[2]]=number
							else
								Echo("not a number")
								return false
							end
						end
						Echo("param: "..args[2].." target: "..args[3].." set to: "..tostring(tracklist.tracks[args[3]][args[2]]))
						return true

					else
						Echo("no value specified")
						Echo("param: "..args[2].." target: "..args[3].." is: "..tostring(tracklist.tracks[args[3]][args[2]]))
						return false
					end

				else
					Echo("no target specified")
					return false
				end

			end

		else
			Echo("no arguments specified")
			return false
		end
		return false
	end

	-- play a sounditem, by name
	if (args[1] == "play") then
		if (args[2]) then
			local vol
			if (args[3]) then vol = tonumber(args[3])	end
				vol=vol or options.volume.value
				local p = {x,y,z}
				if (tracklist.tracks[args[2]]) then
					if (tracklist.tracks[args[2]].emitter) then
						p = emitters[tracklist.tracks[args[2]].emitter].pos
					end
				end
				return DoPlay(args[2], vol, p.x, p.y, p.z)
		else
			Echo("specify a track")
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
			Echo("specify a file in "..config.path_read)
			return false
		end
	end

	-- echo whole playlist or display single item properities
	if (args[1] == "list") then
		i = 2
		while (args[i]) do
			local n = tonumber(args[i]) or args[i] --Echo(type(n))
			if (tracklist.tracks[n]) then
				Echo("---"..args[i].."---")
				for param, value in pairs(tracklist.tracks[n]) do
					Echo(tostring(param).." : "..tostring(value))
				end
			elseif (emitters[n]) then
				if not (args[i] == index) then
					--local n = tonumber(args[i]) or args[i] Echo(type(n))
					local e = emitters[n]
					Echo(tostring(e)..": "..(e.pos.x or "none")..", "..(e.pos.y or "none")..", "..(e.pos.z or "none"))
					for track, param in pairs(e.playlist) do
						Echo("- "..track.." length: "..tracklist.tracks[track].length_real)
					end
				else
					Echo("Index: ".. emitters.index)
				end
			else
				Echo("no such item or emitter: "..args[i])
			end
			i = i + 1
		end	if (i>2) then return true end

		Echo("-----sounditems-----")
		for track, params in pairs (tracklist.tracks) do
			if not (params.emitter)	then Echo(track.." - "..(params.length_real).."s") end
		end
		Echo("-----emitters-----")
		for e, tab in pairs (emitters) do
			if not (e == "index") then
				Echo(tostring(e)..": "..(tab.pos.x or "none")..", "..(tab.pos.y or "none")..", "..(tab.pos.z or "none"))
				for track, param in pairs(tab.playlist) do
						Echo("- "..track.." length: "..tracklist.tracks[track].length_real)
				end
			end
		end
		return true
	end

	if (args[1] == "dir") then
		if not (args[2]) then
			Echo("you must specify a path")
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
			Echo("*dir*")
			if (pattern == "%." or pattern == ".+%.") then
				if (string.match(text, "[%.]")) then Echo(dir.." - "..text) end
			else
				if (string.match(text, pattern)) then Echo(dir.." - "..text) end
			end
		end
		for file, text in pairs(files) do
			Echo("*file*")
			if (pattern == "%." or pattern == ".+%.") then
				if not (string.match(text, "[%.]")) then Echo(file.." - "..text) end
			else
				if (string.match(text, pattern)) then Echo(file.." - "..text) end
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
				Echo("type must be: e..., p..., o...")
				Echo("(emitters, playlist, options)")
				return false
			end
			return true
		else
			Echo("saving all to write dir...")
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
		else
			for k, v in pairs(getfenv()) do
			Spring.Echo(tostring(k))
		end
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
							Echo ("track "..args[i].." already present in "..args[2])
						end
					else
						Echo ("no such track: "..args[i])
					end
				i = i + 1
				end
			else
				Echo ("no such emitter")
			end
		end
		return
	end

	if (args[1] == "reload") then
		ReloadSoundDefs()
		return
	end
	Echo("not a valid command")

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



--function widget:Shutdown()
--	if (config.autosave) then Save() end
--end





--[[
	-- if the player will announce titles when playing
	if (args[1] == "verbose") then
		config.verbose = not (config.verbose)
		if (config.verbose) then
			Echo("verbose on")
		else
			Echo("verbose off")
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
			Echo("set ambient volume "..string.format("%.2f",config.ambientVolume))
			return true
		end
		Echo("not a number")
		return false
	end

	-- pause playlist
	if (args[1] == "hold") then
		options.autoplay = not (options.autoplay)
		if (options.autoplay) then
			Echo("play")
		else
			Echo("hold")
		end
		return true
	end

	if (args[1] == "show") then
		config.showEmitters = not config.showEmitters
		return
	end

--]]