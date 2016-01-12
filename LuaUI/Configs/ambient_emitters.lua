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
				endTimer = -40,
				isPlaying = false,
				item = "$center$ wind_mighty_3",
				startTimer = 1,
			},
		},
	},
	center_hill = {
		isPlaying = false,
		gl = {
			delta = 35,
			u = 15,
			v = 58,
		},
		pos = {
			x = 6121,
			y = 477,
			z = 4073,
		},
		sounds = {},
	},
	e_shrooms = {
		isPlaying = false,
		gl = {
			delta = 54,
			u = 32,
			v = 10,
		},
		pos = {
			x = 7759,
			y = 265,
			z = 3705,
		},
		sounds = {},
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
		sounds = {
			[1] = {
				endTimer = -31,
				isPlaying = false,
				item = "$global$ frogs_birds_concert_4",
				startTimer = 1,
			},
			[2] = {
				endTimer = -31,
				isPlaying = false,
				item = "$global$ owls_4_mono",
				startTimer = 1,
			},
			[3] = {
				endTimer = -31,
				isPlaying = false,
				item = "$global$ swamp_2",
				startTimer = 1,
			},
			[4] = {
				endTimer = -21,
				isPlaying = false,
				item = "$global$ nightingale_1_mono",
				startTimer = 1,
			},
			[5] = {
				endTimer = -21,
				isPlaying = false,
				item = "$global$ woodpigeon_mono",
				startTimer = 1,
			},
			[6] = {
				endTimer = -21,
				isPlaying = false,
				item = "$global$ squak_2",
				startTimer = 1,
			},
			[7] = {
				endTimer = -21,
				isPlaying = false,
				item = "$global$ bubble",
				startTimer = 1,
			},
			[8] = {
				endTimer = -21,
				isPlaying = false,
				item = "$global$ wind_soft_1",
				startTimer = 1,
			},
			[9] = {
				endTimer = -21,
				isPlaying = false,
				item = "$global$ wind_mighty_1",
				startTimer = 1,
			},
			[10] = {
				endTimer = -21,
				isPlaying = false,
				item = "$global$ pigeon_1_mono",
				startTimer = 1,
			},
			[11] = {
				endTimer = -21,
				isPlaying = false,
				item = "$global$ owls_3_mono",
				startTimer = 1,
			},
			[12] = {
				endTimer = -21,
				isPlaying = false,
				item = "$global$ songbird_3",
				startTimer = 1,
			},
		},
	},
	ne1 = {
		isPlaying = false,
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
				endTimer = -40,
				isPlaying = false,
				item = "$ne1$ songbird_4",
				startTimer = 1,
			},
			[2] = {
				endTimer = -40,
				isPlaying = false,
				item = "$ne1$ songbird_3",
				startTimer = 1,
			},
			[3] = {
				endTimer = -40,
				isPlaying = false,
				item = "$ne1$ alarmbird",
				startTimer = 1,
			},
			[4] = {
				endTimer = -40,
				isPlaying = false,
				item = "$ne1$ crow_1_noise",
				startTimer = 1,
			},
		},
	},
	ne_geo = {
		isPlaying = false,
		gl = {
			delta = 50,
			u = 52,
			v = 35,
		},
		pos = {
			x = 8351,
			y = 17,
			z = 876,
		},
		sounds = {},
	},
	ne_idols = {
		isPlaying = false,
		gl = {
			delta = 42,
			u = 56,
			v = 31,
		},
		pos = {
			x = 5523,
			y = 616,
			z = 66,
		},
		sounds = {},
	},
	ne_shrooms = {
		isPlaying = false,
		gl = {
			delta = 7,
			u = 14,
			v = 37,
		},
		pos = {
			x = 8848,
			y = 195,
			z = 1869,
		},
		sounds = {},
	},
	nw_river_peak = {
		isPlaying = false,
		gl = {
			delta = 29,
			u = 56,
			v = 53,
		},
		pos = {
			x = 1352,
			y = 664,
			z = 1184,
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
	se_peak = {
		isPlaying = false,
		gl = {
			delta = 21,
			u = 55,
			v = 56,
		},
		pos = {
			x = 8901,
			y = 776,
			z = 6573,
		},
		sounds = {},
	},
	se_river_slope = {
		isPlaying = false,
		gl = {
			delta = 41,
			u = 9,
			v = 56,
		},
		pos = {
			x = 7430,
			y = -103,
			z = 5994,
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
	sw2 = {
		isPlaying = false,
		gl = {
			delta = 19,
			u = 45,
			v = 8,
		},
		pos = {
			x = 1615,
			y = 389,
			z = 5235,
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
	sw4 = {
		isPlaying = false,
		gl = {
			delta = 52,
			u = 56,
			v = 4,
		},
		pos = {
			x = 2335,
			y = 485,
			z = 5957,
		},
		sounds = {},
	},
	sw_geo = {
		isPlaying = false,
		gl = {
			delta = 35,
			u = 17,
			v = 4,
		},
		pos = {
			x = 832,
			y = 41,
			z = 6400,
		},
		sounds = {},
	},
	sw_idols = {
		isPlaying = false,
		gl = {
			delta = 21,
			u = 48,
			v = 41,
		},
		pos = {
			x = 3854,
			y = 446,
			z = 7101,
		},
		sounds = {},
	},
	test = {
		isPlaying = false,
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
				endTimer = -40,
				isPlaying = false,
				item = "$test$ brook_4",
				startTimer = 1,
			},
			[2] = {
				endTimer = -40,
				isPlaying = false,
				item = "$test$ brook_2",
				startTimer = 1,
			},
			[3] = {
				endTimer = -40,
				isPlaying = false,
				item = "$test$ brook_1",
				startTimer = 1,
			},
		},
	},
}
return Emitters