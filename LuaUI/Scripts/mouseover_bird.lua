local random = math.random
local xdist = 512
local zdist = 512
local timer = 300

GameFrame = function(_, frame)	
	if timer > 0 then
		timer = timer - 1
		return
	end	
	local mx, mz, bl, _, br = Spring.GetMouseState()
	if br or bl or bm then		
		local _, mc = Spring.TraceScreenRay(mx, mz, true)
		if mc then		
			if math.abs(mc[1] - e.pos.x) < xdist and math.abs(mc[3] - e.pos.z) < zdist then
				if not e.isPlaying then
					play(e.sounds[random(3)].item, options.volume.value, e.name)
					timer = 300
				end	
			end
		end
	end
	return false
end

return getfenv()