-- Emitters for positional sounds. Entries in the sounds tables must be indexed.

local Emitters = {
	
	global = {
		isPlaying = false,
		gl = {
			delta = 30,
			u = 1,
			v = 44,
		},
		pos = {
			x = false,
			y = false,
			z = false,
		},
		sounds = {},
	},
	
}
return Emitters