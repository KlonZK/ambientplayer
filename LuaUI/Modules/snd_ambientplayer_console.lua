
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