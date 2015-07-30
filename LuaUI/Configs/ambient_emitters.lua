--Emitters for positional sounds. Each sounditem will be unique for every emitter, if created by the widget.

local Emitters = {
	global = {
		sounds = {},
		pos = {
			x = false,
			y = false,
			z = false,
		},
	},
	center = {
		sounds = {},
		pos = {
			x = 4631,
			y = 2496,
			z = 3608,
		},
	},	
	ne1 = {
		sounds = {},
		pos = {
			x = 5570,
			y = 425,
			z = 1026,
		},
	},		
	rn1 = {
		sounds = {},
		pos = {
			x = 3446,
			y = -84,
			z = 2826,
		},
	},	
	sw1 = {
		sounds = {},
		pos = {
			x = 3604,
			y = 386,
			z = 5715,
		},		
	},
	sw3 = {
		sounds = {},
		pos = {
			x = 2483,
			y = 408,
			z = 3364,
		},
	},	
}
return Emitters