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
		sounds = {
			[1] = {item = 'center_wind_mighty_1'},
			[2] = {item = 'center_wind_mighty_2'},
		},
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
		sounds = {
			[1] = {item = 'rn1_brook_3'},
		},
		pos = {
			x = 3446,
			y = -84,
			z = 2826,
		},
	},	
	sw1 = {
		sounds = {
			[1] = {item = 'sw1_pigeon_1_mono'},
		},
		pos = {
			x = 3604,
			y = 386,
			z = 5715,
		},		
	},
	sw3 = {
		sounds = {
			[1] = {item = 'sw3_brook_1'},			
			[2] = {item = 'sw3_owls_3_mono'},
			[3] = {item = 'sw3_wind_mighty_1'},
			[4] = {item = 'sw3_wind_soft_1'},
			[5] = {item = 'sw3_wind_soft_2'},
		},
		pos = {
			x = 2483,
			y = 408,
			z = 3364,
		},
	},	
}
return Emitters