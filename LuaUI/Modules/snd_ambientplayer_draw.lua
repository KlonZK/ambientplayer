------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
--		file : snd_ape_draw.lua												--
--		desc : gl module for ambient sound editor										--
--		author : Klon (based on spotter.lua by metuslucidium, TradeMark, CarRepairer)	--
--		date : "24.7.2015",																--
--		license : "GNU GPL, v2 or later",												--
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------
local math = widget.math
local pairs = widget.pairs

local options = options
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

local GetGroundHeight = widget.Spring.GetGroundHeight

local circleDivs = 65 -- how precise circle? octagon by default
local innersize = 0.8 -- circle scale compared to unit radius
local outersize = 2.0 -- outer fade size compared to circle scale (1 = no outer fade)

local emitMarker
local emitMarker_Highlight


local function MakeEmitterMarkerList(red, green, blue, alpha_inner, alpha_outer)
	local r, g, b = red, green, blue		
	local alpha, fadealpha = alpha_inner, alpha_outer	
	-- body 	
	local circlePoly = glCreateList(function()
		-- inner:
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
	
	-- rings
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
	end)
	return circlePoly
end


function UpdateMarkerList()	
	emitMarker = MakeEmitterMarkerList(options.color_red.value, options.color_green.value, options.color_blue.value,
		options.color_alpha_inner.value, options.color_alpha_outer.value)
	emitMarker_Highlight = MakeEmitterMarkerList(options.color_red.value, options.color_green.value, options.color_blue.value, 
		options.color_alpha_inner.value * options.color_highlightfactor.value,
			options.color_alpha_outer.value * options.color_highlightfactor.value)		
end


function DrawEmitters(highlightEmitter) -- highlightEmitter should be global to the environment
	if not emitMarker then UpdateMarkerList() end
	
	if options.showemitters.value then	
		for e, params in pairs(emitters) do			
			local pos = params.pos
			if pos.x then
				local list, linealpha -- should be options.alpha_*
				if highlightEmitter == e then
					list = emitMarker_Highlight
					linealpha = 1
				else
					list = emitMarker
					linealpha = 0.5
				end					
				glColor(1,1,1,1)
				glDepthTest(true)										
				glPush()					
					glTranslate(pos.x,pos.y,pos.z)
					glPolygonOffset(-10000, -2)
					glScale(options.emitter_radius.value, 1, options.emitter_radius.value)						
					glCallList(list)
				glPop()
				local gy = GetGroundHeight(pos.x, pos.z)		
				if pos.y >  gy then							
					glDepthMask(true)
					glPush()						
						glBeginEnd(GLLINES, function()
							glColor(options.color_red.value, options.color_green.value, options.color_blue.value, linealpha)
							--gl.Translate(pos.x,pos.y,pos.z)
							glVertex(pos.x, pos.y, pos.z)
							glVertex(pos.x, gy, pos.z)
						end)
					glPop()
					glColor(1,1,1,1)
					glDepthMask(false)						
				end					
				glDepthTest(false)					
			end			
		end
	end
end

return true