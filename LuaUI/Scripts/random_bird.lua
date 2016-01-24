local random = math.random
local nextCycle = 60
local speed_x = 1
local speed_z = 1
local speed_y = 1
local miny = 1024
local maxy = 8192
local maxoutofmaprange = - 512

GameFrame = function(_, frame)		
	
	local x = e.pos.x
	local z = e.pos.z
	local y = e.pos.y
	
	if (frame%nextCycle == 0) then
		speed_x = (random(2) == 1 and 1 or -1) * random(15)
		speed_z = (random(2) == 1 and 1 or -1) * random(15)
		speed_y = (random(2) == 1 and 1 or -1) * random(20)
		nextCycle = 60 + random(120)
	end
	
	local gh = Spring.GetGroundHeight(x, y, z)
	x = x + speed_x
	z = z + speed_z
	y = y + speed_y
	
	if x < -1 * maxoutofmaprange then x = -1 * maxoutofmaprange end
	if z < -1 * maxoutofmaprange then z = -1 * maxoutofmaprange end
	if y < gh + miny then y = gh + miny end
	if x > config.mapX + maxoutofmaprange then x = config.mapX + maxoutofmaprange end
	if z > config.mapZ + maxoutofmaprange then z = config.mapZ + maxoutofmaprange end
	if y > maxy then y = maxy end
	
	e.pos.x = x
	e.pos.z = z
	e.pos.y = y
end

return getfenv()