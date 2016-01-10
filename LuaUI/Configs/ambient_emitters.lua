-- Emitters for positional sounds. Entries in the sounds tables must be indexed.

local Emitters = {
	center = {
		isPlaying = false,
		gl = {
			delta = 26,
			u = 47,
			v = 39,
		},
		pos = {
			x = 4556.390625,
			y = 2454.412109375,
			z = 3541.6264648438,
		},
		sounds = {
			[1] = {
				endTimer = -577,
				isPlaying = false,
				item = "$center$ wind_mighty_3",
				startTimer = 1,
			},
		},
	},
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
	ne1 = {
		isPlaying = true,
		gl = {
			delta = 15.55004119873,
			u = 57.539836883545,
			v = 49.800117492676,
		},
		pos = {
			x = 5570,
			y = 425,
			z = 1026,
		},
		sounds = {
			[1] = {
				endTimer = 21,
				isPlaying = false,
				item = "$ne1$ songbird_4",
				startTimer = 1,
			},
			[2] = {
				endTimer = -263,
				isPlaying = false,
				item = "$ne1$ songbird_3",
				startTimer = 1,
			},
			[3] = {
				endTimer = -123,
				isPlaying = false,
				item = "$ne1$ alarmbird",
				startTimer = 1,
			},
			[4] = {
				endTimer = -48,
				isPlaying = false,
				item = "$ne1$ crow_1_noise",
				startTimer = 1,
			},
		},
	},
	rn1 = {
		isPlaying = false,
		gl = {
			delta = 58,
			u = 28,
			v = 49,
		},
		pos = {
			x = 3446,
			y = -84,
			z = 2826,
		},
		sounds = {},
	},
	sw1 = {
		isPlaying = false,
		gl = {
			delta = 54,
			u = 19,
			v = 55,
		},
		pos = {
			x = 3604,
			y = 386,
			z = 5715,
		},
		sounds = {},
	},
	sw3 = {
		isPlaying = false,
		gl = {
			delta = 6,
			u = 2,
			v = 10,
		},
		pos = {
			x = 2483,
			y = 408,
			z = 3364,
		},
		sounds = {},
	},
	test = {
		isPlaying = true,
		gl = {
			delta = 46.749572753906,
			u = 34.579936981201,
			v = 38.600074768066,
		},
		pos = {
			x = 4434.1938476563,
			y = 219.14819335938,
			z = 2368.4323730469,
		},
		sounds = {
			[1] = {
				endTimer = -577,
				isPlaying = false,
				item = "$test$ brook_4",
				startTimer = 1,
			},
			[2] = {
				endTimer = 7,
				isPlaying = false,
				item = "$test$ brook_2",
				startTimer = 1,
			},
			[3] = {
				endTimer = -577,
				isPlaying = false,
				item = "$test$ brook_1",
				startTimer = 1,
			},
		},
	},
}
return Emitters