--//=============================================================================

local function _DrawTextureAspect(x,y,w,h ,tw,th, flipy)
	local twa = w/tw
	local tha = h/th

	local aspect = 1
	if (twa < tha) then
		aspect = twa
		y = y + h*0.5 - th*aspect*0.5
		h = th*aspect
	else
		aspect = tha
		x = x + w*0.5 - tw*aspect*0.5
		w = tw*aspect
	end

	local right  = math.ceil(x+w)
	local bottom = math.ceil(y+h)
	x = math.ceil(x)
	y = math.ceil(y)

	gl.TexRect(x,y,right,bottom,false,flipy)
end

	
--//=============================================================================

ImageArray = Chili.Image:Inherit{
	classname = 'imagearray',
	files = {},		
	currentFile = false,
}	

local this = ImageArray
local inherited = this.inherited
	
--//=============================================================================
	
function ImageArray:DrawControl(...)	
	if self.currentFile then
		gl.Color(self.color)
		if self.keepAspect then
			Chili.TextureHandler.LoadTexture(0,self.currentFile,self)
			local texInfo = gl.TextureInfo(self.currentFile) or {xsize=1, ysize=1}
			local tw,th = texInfo.xsize, texInfo.ysize
			_DrawTextureAspect(self.x,self.y,self.width,self.height, tw,th, self.flip)
		else
			Chili.TextureHandler.LoadTexture(0,self.currentFile,self)
			gl.TexRect(self.x,self.y,self.x+self.width,self.y+self.height,false,self.flip)
		end
		gl.Texture(0,false)
	end
end
	
	
function ImageArray:SetImage(img)
	if img then
		self.currentFile = self.files[img]		
	else
		self.currentFile = false
	end			
	self:Invalidate()
end

