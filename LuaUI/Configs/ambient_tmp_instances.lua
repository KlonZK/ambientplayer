-- Sounditem definitions. same format as gamedata/sounds.lua 
-- these are templates used by the editor. for the table of sound items being used by emitters, see ambient_sounds_instances.lua

local Sounds = {
	Sounditems = {
		["$testname$ wind_mighty_3"] = {
			delay = 1,
			dopplerscale = 0,
			emitter = false,
			file = "maps/white_rabbit_v30.sdd/Sounds/Ambient/wind_mighty_3.ogg",
			gain = 1,
			gainMod = 0.050000000745058,
			in3d = true,
			length_loop = 1,
			length_real = 0,
			maxconcurrent = 2,
			maxdist = 1000000,
			pitch = 1,
			pitchMod = 0,
			preload = true,
			priority = 0,
			rnd = 0,
			rolloff = 0,
			template = "wind_mighty_3",
		},
	},
}
return Sounds