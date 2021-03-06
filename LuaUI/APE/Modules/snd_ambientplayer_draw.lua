------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
--		file : snd_ape_draw.lua												--
--		desc : gl module for ambient sound editor										--
--		author : Klon (based on spotter.lua by metuslucidium, TradeMark, CarRepairer)	--
--		date : "24.7.2015",																--
--		license : "GNU GPL, v2 or later",												--
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

local settings = settings
local emitters = emitters

local GL = widget.GL
local gl = widget.gl

local GLTRIANGLES 			 = GL.TRIANGLES
local GLQUADS				 = GL.QUADS
local GLLINES				 = GL.LINES

local glBeginEnd             = gl.BeginEnd
local glPush				 = gl.PushMatrix
local glPop					 = gl.PopMatrix
local glColor                = gl.Color
local glCreateList           = gl.CreateList
local glDeleteList           = gl.DeleteList
local glCallList			 = gl.CallList
local glDepthTest            = gl.DepthTest
local glDepthMask            = gl.DepthMask
local glLineWidth            = gl.LineWidth
local glPolygonOffset        = gl.PolygonOffset
local glVertex               = gl.Vertex
local glTranslate			 = gl.Translate
local glScale				 = gl.Scale
local glRotate				 = gl.Rotate

local GetGroundHeight = widget.Spring.GetGroundHeight

local circleDivs = 65 -- how precise circle? octagon by default
local innersize = 0.9 -- circle scale compared to unit radius
--local outersize = 2.0 -- outer fade size compared to circle scale (1 = no outer fade)
--local h = 0.001

local shellSizes = {1.0, 1.1, 1.2, 1.3, 1.4}

local emitMarker
local emitMarker_Highlight


local function MakeLists(red, green, blue, alpha_inner, alpha_outer)
	local r, g, b = red, green, blue		
	local alpha, fadealpha = alpha_inner, alpha_outer
	
	local polys = {}
	-- inner sphere:		
	polys[1] = glCreateList(function()		
		glBeginEnd(GLTRIANGLES, function()
			local radstep = (2.0 * math.pi) / circleDivs			
			for j = 0, 32 do					
				local b1 = (j * radstep)
				local b2 = ((j+1) * radstep)

				for i = 1, 65 do
					local a1 = (i * radstep)
					local a2 = ((i+1) * radstep)
					local a3 = ((i+0.5) * radstep)
					local a4 = ((i+1.5) * radstep)
					glColor(r, g, b, alpha)
					--glColor(r, g, b, fadealpha)
					--glColor(1,0,.5,1)	
					-- triangles standing on the edge
					glVertex(math.sin(a3) * math.sin(b1) * innersize, math.cos(b1) * innersize, math.cos(a3) * math.sin(b1) * innersize)
					glVertex(math.sin(a1) * math.sin(b2) * innersize, math.cos(b2) * innersize, math.cos(a1) * math.sin(b2) * innersize)
					glVertex(math.sin(a2) * math.sin(b2) * innersize, math.cos(b2) * innersize, math.cos(a2) * math.sin(b2) * innersize)
										
					-- triangles standing on the pin
					glVertex(math.sin(a3) * math.sin(b1) * innersize, math.cos(b1) * innersize, math.cos(a3) * math.sin(b1) * innersize)
					glVertex(math.sin(a4) * math.sin(b1) * innersize, math.cos(b1) * innersize, math.cos(a4) * math.sin(b1) * innersize)
					glVertex(math.sin(a2) * math.sin(b2) * innersize, math.cos(b2) * innersize, math.cos(a2) * math.sin(b2) * innersize)					
				end				
			end
		end)
	end)
	
	-- shells
	for shell = 1, 5 do
	polys[shell + 1] =
		glCreateList(function()			
			glBeginEnd(GLTRIANGLES, function()
				--glRotate(120, shell, shell*2, shell*3)
				local radstep = (2.0 * math.pi) / circleDivs			
				for j = 16, 16, 1 do
					local b1 = (j * radstep)
					local b2 = ((j+1) * radstep)

					for i = 1, 65 do
						local a1 = (i * radstep)
						local a2 = ((i+1) * radstep)
						local a3 = ((i+0.5) * radstep)
						local a4 = ((i+1.5) * radstep)
						glColor(r, g, b, fadealpha)
						--glColor(r, g, b, fadealpha)
						--glColor(1,0,.5,1)	
						-- triangles standing on the edge
						glVertex(math.sin(a3) * math.sin(b1) * shellSizes[shell], math.cos(b1) * shellSizes[shell], math.cos(a3) * math.sin(b1) * shellSizes[shell])
						glVertex(math.sin(a1) * math.sin(b2) * shellSizes[shell], math.cos(b2) * shellSizes[shell], math.cos(a1) * math.sin(b2) * shellSizes[shell])
						glVertex(math.sin(a2) * math.sin(b2) * shellSizes[shell], math.cos(b2) * shellSizes[shell], math.cos(a2) * math.sin(b2) * shellSizes[shell])
											
						-- triangles standing on the pin
						glVertex(math.sin(a3) * math.sin(b1) * shellSizes[shell], math.cos(b1) * shellSizes[shell], math.cos(a3) * math.sin(b1) * shellSizes[shell])
						glVertex(math.sin(a4) * math.sin(b1) * shellSizes[shell], math.cos(b1) * shellSizes[shell], math.cos(a4) * math.sin(b1) * shellSizes[shell])
						glVertex(math.sin(a2) * math.sin(b2) * shellSizes[shell], math.cos(b2) * shellSizes[shell], math.cos(a2) * math.sin(b2) * shellSizes[shell])					
					end				
				end
			end)
		end)
	end
	return polys
end

function UpdateMarkerList()	
	emitMarker = MakeLists(settings.display[3], settings.display[4], settings.display[5],
		settings.display[6], settings.display[7])
	emitMarker_Highlight = MakeLists(settings.display[3], settings.display[4], settings.display[5], 
		settings.display[6] * settings.display[8],
			settings.display[7] * settings.display[8])		
end

--local delta = 0
--local u = 0
--local v = 0
local dstep = (2.0 * math.pi) / 30

local function DrawList(list, delta, u, v, x, y, z, sx, sy, sz)			
	glPush()	
		glTranslate(x,y,z)
		--glPolygonOffset(-10000, -2)
		glScale(sx, sz, sy)
		glCallList(list[1])					
	glPop()
	glPush()
		glTranslate(x,y,z)
		glScale(sx, sz, sy)
		glRotate(6*(delta+u+v),1,1,-1)
		glCallList(list[2])
	glPop()
	glPush()
		glTranslate(x,y,z)
		glScale(sx, sz, sy)
		glRotate(6*(delta+v),-1,-1,0)
		glRotate(6*(delta+u),0,0,1)
		glCallList(list[3])
	glPop()
	glPush()
		glTranslate(x,y,z)
		glScale(sx, sz, sy)
		glRotate(6*(delta),0,0,1)
		glRotate(6*(u + delta),0,1,0)
		glRotate(6*(v + u),1,0,0)
		glCallList(list[4])
	glPop()
	glPush()
		glTranslate(x,y,z)
		glScale(sx, sz, sy)
		glRotate(6*(delta + u),0,0,1)
		glRotate(6*(u),0,1,0)
		glRotate(6*(v + v),1,0,0)
		glCallList(list[5])
		glPop() 
end




function DrawEmitters(hoveredEmitter, list_highlightEmitter) -- hoveredEmitter should be global to the environment

	if not emitMarker then UpdateMarkerList() end
	
	if settings.display[1] then	
		for e, params in pairs(emitters) do			
			
			-- this block needs to be removed when everything is set up, it is just a temp hack so i dont have to edit
			-- the config files manually right now
			if not params.gl then
				Echo("made gl table")
				params.gl = {}			
				params.gl.delta = math.random(60)
				params.gl.u = math.random(60)
				params.gl.v = math.random(60)				
			end			

			if params.isPlaying then
				--Echo("is playing")
				params.gl.delta = params.gl.delta > 60 and 0 or params.gl.delta + 0.05
				params.gl.u = params.gl.u > 60 and 0 or params.gl.u + 0.14
				params.gl.v = params.gl.v > 60 and 0 or params.gl.v + 0.2
			end	

			local delta = params.gl.delta
			local u = params.gl.u
			local v = params.gl.v
			
			local pos = params.pos
			if pos.x then
				local list, linealpha -- should be options.alpha_*
				if hoveredEmitter == e or list_highlightEmitter == e then
					list = emitMarker_Highlight
					linealpha = 1
				else
					list = emitMarker
					linealpha = 0.5
				end					
				glColor(1,1,1,1)
				glDepthTest(true)
				glDepthMask(true)
				DrawList(list, delta, u, v, pos.x, pos.y, pos.z, 
					settings.display[2], settings.display[2], settings.display[2])				
		
				local gy = GetGroundHeight(pos.x, pos.z)		
				if pos.y >  gy then							
					
					glPush()						
						glBeginEnd(GLLINES, function()
							glColor(settings.display[3], settings.display[4], settings.display[5], linealpha)
							--gl.Translate(pos.x,pos.y,pos.z)
							glVertex(pos.x, pos.y, pos.z)
							glVertex(pos.x, gy, pos.z)
						end)
					glPop()					
					glDepthMask(false)						
				end	
				glColor(1,1,1,1)
				glDepthTest(false)					
			end			
		end
	end
end

local delta = 0
local u = 0
local v = 0

function DrawIcons(x, y, sx, sz, sy, focus)
	local list = focus and emitMarker_Highlight or emitMarker
	
	delta = delta > 60 and 0 or delta + 0.05
	u = u > 60 and 0 or u + 0.14
	v = v > 60 and 0 or v + 0.2
	
	glDepthTest(true)
	glDepthMask(true)
	
	DrawList(list, delta, u, v, x, y, 0, sx, sy, sz)
	
	glDepthTest(false)
	glDepthMask(false)
end


function DrawCursorToWorld(x, z, y, sx, sz, sy)
	local list = emitMarker_Highlight
	
	glDepthTest(true)
	glDepthMask(true)
	
	DrawList(list, delta, u, v, x, y, z, sx, sy, sz)
	
	local gy = GetGroundHeight(x, z)		
	if y >  gy then		
		glPush()						
			glBeginEnd(GLLINES, function()
				glColor(settings.display[3], settings.display[4], settings.display[5], linealpha)
				--gl.Translate(pos.x,pos.y,pos.z)
				glVertex(x, y, z)
				glVertex(x, gy, z)
			end)
		glPop()					
		glDepthMask(false)						
	end	
	glColor(1,1,1,1)
	--glDepthTest(false)
	glDepthMask(false)	
end

return true

--[[
				glPush()					
					glTranslate(pos.x,pos.y,pos.z)					
					--glPolygonOffset(-10000, -2)
					glScale(settings.display[2], settings.display[2], settings.display[2])
					glCallList(list[1])					
				glPop()
				glPush()
					glTranslate(pos.x,pos.y,pos.z)
					glScale(settings.display[2], settings.display[2], settings.display[2])
					glRotate(6*(delta+u+v),1,1,-1)
					glCallList(list[2])
				glPop()
				glPush()
					glTranslate(pos.x,pos.y,pos.z)
					glScale(settings.display[2], settings.display[2], settings.display[2])
					glRotate(6*(delta+v),-1,-1,0)
					glRotate(6*(delta+u),0,0,1)
					glCallList(list[3])
				glPop()
				glPush()
					glTranslate(pos.x,pos.y,pos.z)
					glScale(settings.display[2], settings.display[2], settings.display[2])
					glRotate(6*(delta),0,0,1)
					glRotate(6*(u + delta),0,1,0)
					glRotate(6*(v + u),1,0,0)
					glCallList(list[4])
				glPop()
				glPush()
					glTranslate(pos.x,pos.y,pos.z)
					glScale(settings.display[2], settings.display[2], settings.display[2])
					glRotate(6*(delta + u),0,0,1)
					glRotate(6*(u),0,1,0)
					glRotate(6*(v + v),1,0,0)
					glCallList(list[5])
				glPop()	
--]]



--[[
glBeginEnd(GLTRIANGLES, function()
			local radstep = (2.0 * math.pi) / circleDivs
			for i = 1, circleDivs do
				local a1 = (i * radstep)
				local a2 = ((i+1) * radstep)
				glColor(r, g, b, alpha)
				glVertex(0, 0, 0)
				glColor(r, g, b, fadealpha)
				glVertex(math.sin(a1), 0, math.cos(a1))
				glVertex(math.sin(a2), 0, math.cos(a2))
			end
		end)
--]]


		--[[
		
		-- outer edge:
		glBeginEnd(GLQUADS, function()
			local radstep = (2.0 * math.pi) / circleDivs
			for i = 1, circleDivs do
				local a1 = (i * radstep)
				local a2 = ((i+1) * radstep)
				glColor(r, g, b, fadealpha)
				glVertex(math.sin(a1), 0, math.cos(a1))
				glVertex(math.sin(a2), 0, math.cos(a2))
				glColor(r, g, b, 0.0)
				glVertex(math.sin(a2) * outersize, 0, math.cos(a2) * outersize)
				glVertex(math.sin(a1) * outersize, 0, math.cos(a1) * outersize)
			end
		end)
	
	-- shellSizes
		glBeginEnd(GLQUADS, function()
			local radstep = (2.0 * math.pi) / (circleDivs - 1)
			
			for fade = 0.1,0.7,0.1 do				
				for i = 1, circleDivs-1 do
					local a1 = (i * radstep)
					local a2 = ((i+1) * radstep)
					local r = (fade * -1.5) + 1.6
					glColor(r, g, b, fade)
					glVertex(math.sin(a1) * (r), 0, math.cos(a1) * (r))
					glVertex(math.sin(a2) * (r), 0, math.cos(a2) * (r))
					glVertex(math.sin(a2) * (r + 0.02), 0, math.cos(a2) * (r + 0.02))
					glVertex(math.sin(a1) * (r + 0.02), 0, math.cos(a1) * (r + 0.02))
				end
			end
		end)
		--]]	