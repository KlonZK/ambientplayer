--[[
TODO:
- add emitters, emitters graphical representation, figure out how tracks and emitters work together VVVv
- implement adding sound items to emitters Vv
- implement batch loading, adding, editing vv-
- restructure? vv
- slash words and vars 
- build writable tables for options Vv
- save options, playlist, emitters support (good target for own file) Vv
- remake initialize() to account for list files Vv
- find out how to find out about file sizes and lengths
- find out how to create folders 
- implement log V
- disallow track names with only numbers --why?
- split vv

- emit zones
- mutex groups
- chili support v
- allow emitters to run scripts?
- kill console or move it to module and use meta table for words

- make emitters hold actual items?
- track playing status of emitters using length, make animation play when playing
- 
- continue gui implementation, rework update function
--]]

--os.getenv("HOME")

local versionNum = '0.4!'

function widget:GetInfo()
  return {
    name      = "Ambient Sound Player & Editor",
    desc      = "v"..(versionNum),
    author    = "Klon",
    date      = "dez 2014",
    license   = "GNU GPL, v2 or later",
    layer     = -1,
    enabled   = true,
  }
end	


-------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------
-- CONSTANTS & SHORTCUTS
-------------------------------------------------------------------------------------------------------------------------

local PlaySound = Spring.PlaySoundFile
local PlayStream = Spring.PlaySoundStream
local GetMouse = Spring.GetMouseState 
local TraceRay = Spring.TraceScreenRay
local IsMouseMinimap = Spring.IsAboveMiniMap
local GetGroundHeight = Spring.GetGroundHeight
local GetModKeys = Spring.GetModKeyState

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
local SOUNDS_INUSE_DEF_FILENAME = 'ambient_sounds_inuse.lua'
local EMITTERS_FILENAME = 'ambient_emitters.lua'
local TMP_ITEMS_FILENAME = 'ambient_tmp_items.lua'
local TMP_INUSE_FILENAME = 'aambient_tmp_inuse.lua'
local LOG_FILENAME = 'ambient_log.txt'



-------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------
-- PACKAGE
-------------------------------------------------------------------------------------------------------------------------

local logfile = [[]]
local spEcho = Spring.Echo

-- should start dumping if it gets too long
-- also might want to do boolean->string here as it gets too annoying
function Echo(s)
	spEcho('<ape>: '..s)
	logfile = logfile.."\n"..s
	if controls and controls.log then controls.log:SetText(logfile) end
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
	length = 0,
	rnd = 0,
	minlooptime = 1, -- minlooptime is added? to the length on every loop...
	onset = 1, -- ...while onset just gets used once at start of game
}

local sounditems = {
	templates = {},
	inuse = {},
	default = SOUNDITEM_PROTOTYPE,
}

-- these should automatically fill files with values too
setmetatable(sounditems.templates, {
	__newindex = function (t, k, v)		
		rawset(t, k, v)
		setmetatable(t[k], {__index = SOUNDITEM_PROTOTYPE})
	end
}) 
		
setmetatable(sounditems.inuse, {
	__newindex = function (t, k, v)		
		rawset(t, k, v)
		setmetatable(t[k], {__index = SOUNDITEM_PROTOTYPE})
	end
}) 
	
-- are these used?
local tracklist_controls = {}
local emitters_controls = {}

local emitters = {
	--	e = { -- are they indexed now or what?
	--		pos = {x, y, z},
	--		sounds = { --< INDEXES TABLE WILL FAIL HORRIBLY IF THIGNS GET REMOVED. NEEDS COUNTERMEASURES OR CHANGE
	--			[j] = {	
	--				item = <sounditem>
	--				generated = <boolean> -- this is not needed anymore
	--				timer = <number> --there are different timers, one counts the time until playback, one counts during playback until end
	--				...
	--			},
	-- 		},
	--	},	
}

-- look up sounds by name or reference
setmetatable(emitters, {
	__newindex = function(t, k, v)				
		rawset (t, k, v)		
		if not t[k].sounds then t[k]['sounds'] = {} end	
		--if not t[k].script then t[k]['script'] = 'function run() end'
		setmetatable(t[k].sounds, {			
			__index = function(st, item)				
				if type(item) == 'string' then
					for i = 1, #st do						
						if st[i].item == item then return st[i].item end --ill just assume they will both be strings for now
					end
				end
				return nil
			end			
		})	
	end	
})

emitters.global = {pos = {}, sounds = {}}

options = {}



-------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------
-- MODULES
-------------------------------------------------------------------------------------------------------------------------

-- SetupGUI() builds controls so we can't import keys yet
Echo ("Loading modules...")	

local i_o = {widget = widget, Echo = Echo, options = options, config = config, sounditems = sounditems, emitters = emitters}
do				
	local file = PATH_LUA..PATH_MODULE..FILE_MODULE_IO
	if vfsExist(file, VFSMODE) and vfsInclude(file, i_o, VFSMODE) then
		Echo("i/o module successfully loaded")
	else
		Echo("failed to load i/o module")
	end
end

local gui = {widget = widget, Echo = Echo, options = options, config = config, sounditems = sounditems, emitters = emitters,
				tracklist_controls = tracklist_controls, emitters_controls = emitters_controls}
do				
	local file = PATH_LUA..PATH_MODULE..FILE_MODULE_GUI
	if vfsExist(file, VFSMODE) then
		gui = vfsInclude(file, gui, VFSMODE)		
		if gui then Echo("gui module successfully loaded")
		else Echo("failed to load gui module") end
	else
		Echo("could not find gui module")
	end
	-- load console here if wanted or if chili fails
end

local draw = {widget = widget, Echo = Echo, options = options, emitters = emitters}
do				
	local file = PATH_LUA..PATH_MODULE..FILE_MODULE_DRAW
	if vfsExist(file, VFSMODE) and vfsInclude(file, draw, VFSMODE) then
		Echo("draw module successfully loaded")
	else
		Echo("failed to load draw module")
	end
end


-------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------
-- Epic Menu Options
-------------------------------------------------------------------------------------------------------------------------

options_path = 'Settings/Audio/Ambient Sound'
options_order = {'color_red', 'color_green', 'color_blue', 'color_alpha_inner', 'color_alpha_outer', 'color_highlightfactor',
					'verbose', 'autosave', 'autoreload', 'showemitters', 'emitter_highlight_treshold', 'emitter_radius', 'dragtime', 					 
						'checkrate', 'volume', 'autoplay'}

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
options.showemitters = {
	name = "Show Emitters",
	type = 'bool',
	value = true,
	path = "Settings/Audio/Ambient Sound/Editor",
}
options.emitter_highlight_treshold = {
	name = "Emitter selection radius",
	type = 'number',
	value = 150,
	min = 50,
	max = 500,
	step = 25,
	path = "Settings/Audio/Ambient Sound/Editor",		
}
options.dragtime = {
	name = "Seconds until drag starts",
	type = 'number',
	value = 0.5,
	min = 0.1,
	max = 2,
	step = 1,
	path = "Settings/Audio/Ambient Sound/Editor",		
}	
options.emitter_radius = {
	name = "Radius of Emitter Aura",
	type = 'number',
	value = 5,
	min = 25,
	max = 100,
	step = 1,
	path = "Settings/Audio/Ambient Sound/Editor",		
}
options.color_red = {
	name = "Red",
	type = 'number',
	value = 1,
	min = 0.0,
	max = 1,
	step = 0.1,
	path = "Settings/Audio/Ambient Sound/Editor/Colors",	
	OnChange = function() UpdateMarkerList() end,	
}
options.color_green = {
	name = "Green",
	type = 'number',
	value = 1,
	min = 0.0,
	max = 1,
	step = 0.1,
	path = "Settings/Audio/Ambient Sound/Editor/Colors",		
	OnChange = function() UpdateMarkerList() end,
				
}
options.color_blue = {
	name = "Blue",
	type = 'number',
	value = 1,
	min = 0.0,
	max = 1,
	step = 0.1,
	path = "Settings/Audio/Ambient Sound/Editor/Colors",		
	OnChange = function() UpdateMarkerList() end,
}
options.color_alpha_inner = {
	name = "Alpha inner circle",
	type = 'number',
	value = 0.65,
	min = 0.0,
	max = 1,
	step = 0.05,
	path = "Settings/Audio/Ambient Sound/Editor/Colors",		
	OnChange = function() UpdateMarkerList() end,
}
options.color_alpha_outer = {
	name = "Alpha outer circle",
	type = 'number',
	value = 0.25,
	min = 0.0,
	max = 1,
	step = 0.05,
	path = "Settings/Audio/Ambient Sound/Editor/Colors",		
	OnChange = function() UpdateMarkerList() end,
}
options.color_highlightfactor = {
	name = "Emitter highlight factor",
	type = 'number',
	value = 1.5,
	min = 0.1,
	max = 5,
	step = 0.1,
	path = "Settings/Audio/Ambient Sound/Editor/Colors",		
	OnChange = function() UpdateMarkerList() end,
}
options.delay_drag = {
	name = "Drag Timer",
	type = 'number',
	value = 0.15,
	min = 0,
	max = 2,
	step = 0.05,
}
options.delay_tooltip = {
	name = "Tooltip Timer",
	type = 'number',
	value = 0.3,
	min = 0,
	max = 2,
	step = 0.05,
}


-------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------
-- LOCALS
-------------------------------------------------------------------------------------------------------------------------

local secondsToUpdate = 0.1
local gameStarted = Spring.GetGameFrame() > 0
local inited = false

local mx, mz
local mcoords
local needReload = false
local mouseOverEmitter

local drag = {
	objects = {},
	_type = {},
	params = {},
}
local dragObject
local dragType
--local DELAY_DRAG = 0.2 -- moved to options
local dragTimer = options.delay_drag.value
local dragStarted = false

--local DELAY_TOOLTIP = 0.4 -- moved to options
local tooltipTimer = options.delay_tooltip.value

local worldTooltip



-------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------
-- INPUT LISTENERS AND AUXILIARY
-------------------------------------------------------------------------------------------------------------------------

-- fuck you
local function MouseOnGUI()
	return IsMouseMinimap(mx or 0, mz or 0) or screen0.hoveredControl --or screen0.focusedControl
end


local function updateTooltip()
	if mouseOverEmitter then
		local e = emitters[mouseOverEmitter]		
		worldTooltip = "Emitter: "..mouseOverEmitter.."\n("..
			string.format("%.0f", e.pos.x)..", "..
				string.format("%.0f", e.pos.z)..", "..
					string.format("%.0f", e.pos.y)..")\n "
					
		for i = 1, #e.sounds do					
			worldTooltip = worldTooltip.."\n"..(e.sounds[i].item)
		end
		--worldTooltip:format("%.2f")
	end
end


function widget:IsAbove(x, y)	
	if mouseOverEmitter and not MouseOnGUI() then return true end	
	--if dragObject then return true end
end


function widget:GetTooltip(x, y)
	if not worldTooltip then
		if tooltipTimer > 0 then return end
		updateTooltip()
		tooltipTimer = options.delay_tooltip.value
	end
	
	--local e = emitters[mouseOverEmitter]	
	return worldTooltip
end


function widget:MousePress(x, y, button)	
	--if button == 4 or button == 5 then return false end
	if MouseOnGUI() then return false end
	if mouseOverEmitter then
		if button == 3 then return true end
		if button == 2 then 			
		end	
		if button == 1 then			
			local e = emitters[mouseOverEmitter]
			drag.objects[1] = e
			drag._type.emitter = true			
			drag.params.hoff = e.pos.y - GetGroundHeight(e.pos.x, e.pos.z)
			Echo("drag timer started")
			return true
		end			
	else		
	end	
	return false
end


function widget:MouseRelease(x, y, button)
	--Echo("release")
	if button == 3 then		
		if mouseOverEmitter then		
			if inspectionWindows[mouseOverEmitter].inspect then -- window already existed a moment ago
				--Echo("kill")
				inspectionWindows[mouseOverEmitter].inspect = nil -- kill it
			else
				--Echo("make")
				inspectionWindows[mouseOverEmitter].inspect = mouseOverEmitter -- make a new one
				inspectionWindows[mouseOverEmitter]:Show() -- refresh should be automatic lets just show it
				local xp = mx > (screen0.width / 2) and (mx - inspectionWindows[mouseOverEmitter].width) or mx
				local mz_inv = math.abs(screen0.height- mz) 
				local yp = mz_inv > (screen0.height / 2) and (mz_inv - inspectionWindows[mouseOverEmitter].height) or mz_inv		
				inspectionWindows[mouseOverEmitter]:SetPos(xp, yp)
				--Echo(type(mouseOverEmitter).." - "..type(inspectionWindows[mouseOverEmitter]))
			end
		end
	end		

	--if button == 4 or button == 5 then return false end
	
	dragTimer = options.delay_drag.value
	drag.objects[1] = nil
	drag._type.emitter = nil	
	drag.params.hoff = nil
	dragStarted = false
	Echo("drag ended")	
end


-- should rather do this when properities are open
function widget:MouseWheel(up, value)
	if not drag.objects[1] and mouseOverEmitter then
		local alt,ctrl,_,shift = GetModKeys()
		if not shift then return false end
		
		local e = emitters[mouseOverEmitter]
		local gh = GetGroundHeight(e.pos.x, e.pos.z)		
		local h = e.pos.y + value * (alt and 1 or(ctrl and 100 or 10))
		e.pos.y = h < gh and gh or h 
		updateTooltip()
		return true
	end
end


function widget:MouseMove(x, y, dx, dy, button)	
	if dragStarted then			
		if drag._type.emitter and mcoords then		
			drag.objects[1].pos.x = mcoords[1]
			drag.objects[1].pos.z = mcoords[3]
			drag.objects[1].pos.y = mcoords[2] + drag.params.hoff 	
			updateTooltip()	
			return true
		end
	end
end



-------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------
-- UPDATE/MISC
-------------------------------------------------------------------------------------------------------------------------

local function Distance(sx, sz, tx, tz)
	local dx = sx - tx
	local dz = sz - tz
	--Spring.Echo (dx.." - "..dz)
	return math.sqrt(dx*dx + dz*dz)
end

-- this is actually wasteful
-- also needs to poll all the windows to be really safe : /


function widget:Update(dt) 	
	if not (gameStarted) then return end
	
	UpdateGUI()
	mx, mz = GetMouse() --this is good.
	_, mcoords = TraceRay(mx, mz, true)
	
	if options.showemitters.value and not MouseOnGUI() then -- we dont want emitters to highlight if we are moving in the gui			
		local dist = 100000000
		local nearest
		--Echo("check")
		for e, params in pairs(emitters) do				
			if params.pos.x then -- they all have that no?				
				if mcoords then					
					local dst = Distance(mcoords[1], mcoords[3], params.pos.x, params.pos.z)
					if dst < dist then								
						dist = dst
						nearest = e
					end			
				end
			end
		end			
		if nearest and dist < options.emitter_highlight_treshold.value then		
			mouseOverEmitter = nearest
			if not worldTooltip then tooltipTimer = tooltipTimer - dt end
		else		
			mouseOverEmitter = nil			
			worldTooltip = nil
			tooltipTimer = options.delay_tooltip.value
		end
	else
		mouseOverEmitter = nil
	end
	--Echo (tostring(mouseOverEmitter))
	
	
	
	if drag.objects[1] and not dragStarted then		
		dragTimer = dragTimer - dt
		if dragTimer <= 0 then				
			dragStarted = true			
			--dragTimer = options.delay_drag
			Echo("drag started")
		end
	end
	
	if (needReload and options.autoreload.value) then ReloadSoundDefs() needReload = false end		
	if (secondsToUpdate>0) then	secondsToUpdate = secondsToUpdate-dt return
	else secondsToUpdate = options.checkrate.value
	end
	--Echo(tostring(MouseOnGUI))
	--Echo(mx..mz)
	
	if not (options.autoplay.value) then return end
	for e, params in pairs (emitters) do		
		for i = 1, #params.sounds do		
		local trk = params.sounds[i]
		local item = trk.item 
			if item and trk.rnd and trk.rnd > 0 then -- remove extra nil check eventually
				trk.timer = trk.timer - options.checkrate.value -- this seems inaccurate				
				if (trk.timer < 0) then
					trk.timer = 0
					if (random(trk.rnd) == 1) then
						DoPlay(item, options.volume.value, params.pos.x, params.pos.y, params.pos.z) --< this should pass nils if pos.* doesnt exist
						trk.timer  = item.minlooptime
					end
				end
			end	
		end	
	end
end	


local function DoPlay(item, vol, x, y, z) 
	if not (sounditems.templates[item] or sounditems.inuse[item]) then 
		Echo("item "..tostring(track).." not found!") 
		return false	
	else
		local tr = item
		-- if (tracklist.tracks[tr].generated) then	tr = tracklist.tracks[tr].file	end	 -- is this used?
		if (PlaySound(tr, vol, x, y, z)) then
			if (options.verbose.value) then
				Echo("playing "..tr.." at volume: "..string.format("%.2f", vol))
				if (x) then Echo("at Position: "..x..", "..y..", "..z) end -- should format this looks bad with decimals
			end
			return true		
		end	
		Echo("playback of "..tr.." failed, not an audio file?")
		return false
	end
end

-- need to pass actual item not just name
local function AddItemToEmitter(e, item)
	assert(type(item) == 'table')
	local name = tostring(e)..":"..tostring(item)
	if sounditems.inuse[name] then 
		Echo("a sounditem with that name already exists at this emitter")
		return false 
	end
	
	sounditems.inuse[name] = {}	
	local newItem = sounditems.inuse[name]	
	emitters[e].sounds[#emitters[e].sounds + 1] = {}
	local eS = emitters[e].sounds[#emitters[e].sounds + 1]
		
	for k, v in pairs(item) do
		newItem[k] = v		
	end
	
	eS.item = newItem
	eS.generated = true
	eS.timer = newItem.onset
	
	-- newItem.maxdist = newItem.maxdist < 100000 and newItem.maxdist or 100000 -- this is bad, should not have to set it here	
	-- newItem.emitter = e -- needed?
	
	needReload = true
	return true
end


local function RemoveItemFromEmitter(e, item)
	if not sounditems.inuse[item] then 
		Echo("a sounditem with that name is not in use")
		return false 
	end
	
	assert(sounditems.inuse[item] and emitters[e].sounds[item]) -- to make sure we didnt fuck up earlier when adding
	
	sounditems.inuse[item] = nil
	emitters[e].sounds[item] = nil
end


local function RemoveItemFromList(item)
	if not sounditems.templates[item] then
		Echo("a sounditem with that name is not registered")
		return false
	end
		
	sounditems.inuse[item] = nil
	for e = 1, #emitters do
		emitters[e].sounds[item] = nil
	end	
end


local function SpawnEmitter(name, yoffset)
	local p
	if not MouseOnGUI() then _, p = Spring.TraceScreenRay(mx,mz,true)
	else return end
	if (emitters[name]) then Echo("an emitter with that name already exists") return false end
	
	yoffset = yoffset or 0
	p[2] = p[2] + yoffset	
	if not (name) then name = (#emitters + 1).." - "..p[1]..", "..p[3]..", "..p[2] end		

	-- __newindex should build our tables
	emitters[name].pos = {x = math.floor(p[1]), y = math.floor(p[2]), z = math.floor(p[3])}	
	
	
	--emitters[name].light = MapLight(eLightTable)
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
	DrawEmitters(mouseOverEmitter)
end


-------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------
-- INIT
-------------------------------------------------------------------------------------------------------------------------

function widget:Initialize()

	gui.DoPlay = DoPlay
	
	local cpath = PATH_LUA..PATH_CONFIG
	local upath = PATH_LUA..PATH_UTIL

	--setfenv(SetupGUI, gui)
	Echo("Building GUI...")
	gui.SetupGUI()	

	for k, v in pairs(gui) do 
		--widget[k] = widget[k] or v
		if not widget[k] then
			widget[k] = v
			Echo("added key '"..k.."'to globals")
		end
	end
	for k, v in pairs(draw) do 
		--widget[k] = widget[k] or v
		if not widget[k] then
			widget[k] = v
			Echo("added key '"..k.."'to globals")
		end
	end
	for k, v in pairs(i_o) do 
		--widget[k] = widget[k] or v
		if not widget[k] then
			widget[k] = v
			Echo("added key '"..k.."'to globals")
		end
	end

	-- put this stuff into io
	
	Echo ("Loading local config...")
	if vfsExist(cpath..MAPCONFIG_FILENAME, VFSMODE) then
		local opt = vfsInclude(cpath..MAPCONFIG_FILENAME, nil, VFSMODE)
		if opt.config then
			for k, v in pairs(opt.config) do config[k] = v or config[k]	end			
		end
--		if (opt.words) then	
--			for k, t in pairs(opt.words) do	words[k] = t or words[k] end
--		end
	else Echo("could not open config file, using defaults")
	end	
	
	Echo ("Loading templates...")	
	if vfsExist(cpath..SOUNDS_ITEMS_DEF_FILENAME, VFSMODE) then
		if not spLoadSoundDefs(cpath..SOUNDS_ITEMS_DEF_FILENAME) then
			Echo("failed to load templates, check format\n '"..cpath..SOUNDS_ITEMS_DEF_FILENAME.."'")		
		end		
		local list = vfsInclude(cpath..SOUNDS_ITEMS_DEF_FILENAME, nil, VFSMODE)			
		if not list.Sounditems then 
			Echo("templates file was empty")
		else
			local i = 0
			for s, params in pairs(list.Sounditems) do i = i + 1; sounditems.templates[s] = params end
			Echo ("found "..i.." sounditems")
		end
	else
		Echo("file not found\n '"..cpath..SOUNDS_ITEMS_DEF_FILENAME.."'")		
	end
	
	Echo ("Loading sounds...")	
	if vfsExist(cpath..SOUNDS_INUSE_DEF_FILENAME, VFSMODE) then
		if not spLoadSoundDefs(cpath..SOUNDS_INUSE_DEF_FILENAME) then
			Echo("failed to load sounds in use, check format\n '"..cpath..SOUNDS_INUSE_DEF_FILENAME.."'")		
		end		
		local list = vfsInclude(cpath..SOUNDS_INUSE_DEF_FILENAME, nil, VFSMODE)			
		if (list.Sounditems == nil) then 
			Echo("sounds file was empty")
		else
			local i = 0
			for s, params in pairs(list.Sounditems) do i = i + 1; sounditems.inuse[s] = params end			
			Echo ("found "..i.." sounds")					
		end		
	else
		Echo("file not found\n '"..cpath..SOUNDS_INUSE_DEF_FILENAME.."'")		
	end
	
	Echo ("Loading emitters...")	
	if vfsExist(cpath..EMITTERS_FILENAME, VFSMODE) then
		local tmp = vfsInclude(cpath..EMITTERS_FILENAME, nil, VFSMODE) -- or emitters ?
		if tmp then
			local i = 0
			for e, params in pairs(tmp) do i = i + 1; emitters[e] = params end					
			Echo ("found "..i.." emitters")
		else Echo ("emitters file was empty")
		end	
	end	
	
	Echo("updating local config...")	
	if not (config.path_map) then config.path_map= 'maps/'..Game.mapName..'.sdd/' end
	config.mapX = Game.mapSizeX
	config.mapZ = Game.mapSizeZ
	inited=true --?
	Echo("Updating GUI...")
	UpdateGUI()
	Echo("Init done!")
end


function widget:GameStart()
	gameStarted = true
	Echo ("The map directory is assumed to be "..config.path_map.."\nif that is not correct, please type /ap.def map maps/<your map folder>/")	
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
						Echo("- "..track.." length: "..tracklist.tracks[track].length)
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
			if not (params.emitter)	then Echo(track.." - "..(params.length).."s") end			
		end
		Echo("-----emitters-----")
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