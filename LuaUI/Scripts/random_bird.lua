params = {
	minCycle = 60,
	maxCycle = 240,
	testtable = {"abc", "dfg", var1 = true, var2 = {}},
	minSX = 2,
	maxSX = 12,
	minSZ = 2,
	maxSZ = 12,
	minSY = 0,
	maxSY = 20,
	moretable = {"ijk", true, 123, key = "value",},
	miny = 1024,
	maxy = 8192,
	testbool = true,
	morebool = false,
	bool4 = true,
	bool1 = true,
	bool2 = true,
	bool3 = false,
	maxoutofmaprange = - 512,	
}

local random = math.random
local nextCycle = 60
local speed_x = 2
local speed_z = 2
local speed_y = 2

GameFrame = function(_, frame)		
	if not params.testbool then return end
	
	local minCycle = params.minCycle
	local maxCycle = params.maxCycle
	local minSX = params.minSX
	local maxSX = params.maxSX
	local minSZ = params.minSZ
	local maxSZ = params.maxSZ
	local minSY = params.minSY
	local maxSY = params.maxSY
	local miny = params.miny
	local maxy = params.maxy	
	local maxoutofmaprange = params.maxoutofmaprange
	
	local x = e.pos.x
	local z = e.pos.z
	local y = e.pos.y
	
	if (frame%nextCycle == 0) then
		speed_x = (random(2) == 1 and 1 or -1) * random(maxSX-minSX)
		speed_z = (random(2) == 1 and 1 or -1) * random(maxSZ-minSZ)
		speed_y = (random(2) == 1 and 1 or -1) * random(maxSY-minSY)
		nextCycle = minCycle + random(maxCycle-minCycle)
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