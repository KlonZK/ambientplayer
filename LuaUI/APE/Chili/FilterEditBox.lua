--//=============================================================================	
------------------------------------------- Edit Box with optional Input Filter -
-- derived controls may implement a InputFilter method, which receives a single utf8 character as an argument
-- and must return a 'true' if the character is allowed input (?)
-- also knows a few tricks:
-- calls self:OnTab(), self:Discard(), self:Confirm() on tab, escape, enter 
-- the latter of the 2 automatically remove focus

--//=============================================================================

FilterEditBox = Chili.EditBox:Inherit{
	classname = 'FilterEditBox',
	allowUnicode = true,
	cursorColor = {0,1.3,1,0.7},
}

local this = FilterEditBox
local inherited = this.inherited


--//=============================================================================

function FilterEditBox:Update(...)
	Chili.Control.Update(self, ...)
	if self.state.focused then
		self:RequestUpdate()
		if (os.clock() >= (self._nextCursorRedraw or -math.huge)) then
			self._nextCursorRedraw = os.clock() + 0.1 --10FPS
		end
	end	
	self:Invalidate()
end


--//=============================================================================

function FilterEditBox:KeyPress(key, mods, isRepeat, label, unicode, ...)
	local cp = self.cursor
	local txt = self.text
	if key == KEYSYMS.RETURN then
		if self.Confirm then self:Confirm() end
		self.state.focused = false
		screen0.focusedControl = nil
		return false
	elseif key == KEYSYMS.ESCAPE then				
		if self.Discard then self:Discard() end
		self.state.focused = false
		screen0.focusedControl = nil
		return false
	elseif key == KEYSYMS.BACKSPACE then --FIXME use Spring.GetKeyCode("backspace")
		self.text, self.cursor = unitools.Utf8BackspaceAt(txt, cp)
	elseif key == KEYSYMS.DELETE then
		self.text   = unitools.Utf8DeleteAt(txt, cp)
	elseif key == KEYSYMS.LEFT then
		self.cursor = unitools.Utf8PrevChar(txt, cp)
	elseif key == KEYSYMS.RIGHT then
		self.cursor = unitools.Utf8NextChar(txt, cp)
	elseif key == KEYSYMS.HOME then
		self.cursor = 1
	elseif key == KEYSYMS.END then
		self.cursor = #txt + 1
	elseif key == KEYSYMS.TAB then
		if self.OnTab then return self:OnTab() end				
	else
		local utf8char = unitools.UnicodeToUtf8(unicode)
		if (not self.allowUnicode) then
			local success
			success, utf8char = pcall(string.char, unicode)
			if success then
				success = not utf8char:find("%c")
			end
			if (not success) then
				utf8char = nil
			end
		end

		if utf8char then
			self.text = txt:sub(1, cp - 1) .. utf8char .. txt:sub(cp, #txt)
			self.cursor = cp + utf8char:len()
		--else
		--	return false
		end
		
	end
	self._interactedTime = Spring.GetTimer()
	--inherited.KeyPress(self, key, mods, isRepeat, label, unicode, ...)
	self:UpdateLayout()
	self:Invalidate()
	return self
end


function FilterEditBox:TextInput(utf8char, ...)			
	local unicode = utf8char
	if (not self.allowUnicode) then
		local success
		success, unicode = widget.pcall(string.char, utf8char)
		if success then
			success = not unicode:find("%c")
		end
		if (not success) then
			unicode = nil
		end
	end

	if unicode and (not self.InputFilter or self.InputFilter(unicode)) then
		local cp  = self.cursor
		local txt = self.text
		self.text = txt:sub(1, cp - 1) .. unicode .. txt:sub(cp, #txt)
		self.cursor = cp + unicode:len()
	--else
	--	return false
	end

	self._interactedTime = Spring.GetTimer()
	--self.inherited.TextInput(utf8char, ...)
	self:UpdateLayout()
	self:Invalidate()
	return self
end

