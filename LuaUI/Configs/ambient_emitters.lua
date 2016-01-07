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
			x = 4631,
			y = 2496,
			z = 3608,
		},
		sounds = {
			[1] = {
				endTimer = -36,
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
		isPlaying = false,
		gl = {
			delta = 49,
			u = 35,
			v = 9,
		},
		pos = {
			x = 5570,
			y = 425,
			z = 1026,
		},
		sounds = {},
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
			delta = 3.2499980926514,
			u = 33.179943084717,
			v = 45.200099945068,
		},
		pos = {
			x = 4461.50390625,
			y = 219.005859375,
			z = 2386.6391601563,
		},
		sounds = {
			[1] = {
				endTimer = 52,
				isPlaying = false,
				item = "$test$ brook_4",
				startTimer = 1,
			},
			[2] = {
				endTimer = -17,
				isPlaying = false,
				item = "$test$ brook_2",
				startTimer = 1,
			},
			[3] = {
				endTimer = -17,
				isPlaying = false,
				item = "$test$ brook_1",
				startTimer = 1,
			},
		},
	},
}
return Emitters