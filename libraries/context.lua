local e = require "event"
local unicode = require "unicode"

--local context = {}
local g = require ("component").gpu
local s = require "serialization"

function createContext(context_content, gpu, x, y, design)
	local self = {}
	self.pixels_under_context = {}
	self.content = context_content
	self.draw_point = {['x'] = x, ['y'] = y}
	self.gpu = gpu

	self.default_design = {}
	self.default_design.width, self.default_design.height = 10, 10
	self.default_design.horizontal_indents = 2
	self.default_design.shadow = true
	self.default_design.blink_time = 0.2

	self.default_design.enabled_background = 0xffffff
	self.default_design.enabled_foreground = 0x000000

	self.default_design.disabled_background = 0xffffff
	self.default_design.disabled_foreground = 0xaaaaaa

	self.default_design.selected_background = 0x0000ff
	self.default_design.selected_foreground = 0x000000

	self.default_design.shadow_background = 0xaaaaaa
	self.default_design.delim_char = '—'

	if ( design ) then
		self.default_design = design
	end

	local maxLength = 0
	for _, item in pairs(context_content) do
		if ( item ) then
			maxLength = math.max( maxLength, unicode.len(item.name) )
		end
	end
	self.default_design.width, self.default_design.height = maxLength+self.default_design.horizontal_indents*2, #context_content

	function self.copyPixelsUnderContext(self)
		for y=self.draw_point.y, self.default_design.height+self.draw_point.y+1 do
			self.pixels_under_context[y] = {}
			for x=self.draw_point.x, self.default_design.width+self.draw_point.x+1 do
				self.pixels_under_context[y][x] = { self.gpu.get(x, y) }
			end
		end
	end

	function self.drawPixelsUnderContext(self)
		for y=self.draw_point.y, self.default_design.height+self.draw_point.y+1 do
			for x=self.draw_point.x, self.default_design.width+self.draw_point.x+1 do
				self.gpu.setBackground( self.pixels_under_context[y][x][3] )
				self.gpu.setForeground( self.pixels_under_context[y][x][2] )
				self.gpu.set( x, y, self.pixels_under_context[y][x][1] )
			end
		end
	end

	function self.drawShadow(self)
		self.gpu.setBackground(self.default_design.shadow_background)
		self.gpu.fill(self.draw_point.x+1, self.draw_point.y+self.default_design.height, self.default_design.width, 1, ' ')
		self.gpu.fill(self.draw_point.x+self.default_design.width, self.draw_point.y+1, 1, self.default_design.height, ' ')
	end

	function self.drawItem(self, num_item, item)
		if ( not item ) then
			self.gpu.setBackground( self.default_design.disabled_background )
			self.gpu.setForeground( self.default_design.disabled_foreground )
			self.gpu.fill(self.draw_point.x, self.draw_point.y+num_item, self.default_design.width, 1, self.default_design.delim_char)
		else
			if ( item.active ) then
				self.gpu.setBackground( self.default_design.enabled_background )
				self.gpu.setForeground( self.default_design.enabled_foreground )
			else
				self.gpu.setBackground( self.default_design.disabled_background )
				self.gpu.setForeground( self.default_design.disabled_foreground )
			end
			self.gpu.fill(self.draw_point.x, self.draw_point.y+num_item, self.default_design.width, 1, ' ')
			self.gpu.set(self.draw_point.x, self.draw_point.y+num_item, string.rep(' ', self.default_design.horizontal_indents) .. item.name)
		end
	end

	function self.blinkItem(self, selected_item, touch_y)
		self.gpu.setBackground( self.default_design.selected_background )
		self.gpu.setForeground( self.default_design.selected_foreground )
		self.gpu.fill(x, touch_y, self.default_design.width, 1, ' ')
		self.gpu.set(x, touch_y, string.rep(' ', self.default_design.horizontal_indents) .. selected_item.name)

		os.sleep( self.default_design.blink_time )

		self.gpu.setBackground( self.default_design.enabled_background )
		self.gpu.setForeground( self.default_design.enabled_foreground )
		self.gpu.fill(x, touch_y, self.default_design.width, 1, ' ')
		self.gpu.set(x, touch_y, string.rep(' ', self.default_design.horizontal_indents) .. selected_item.name)
	end

	function self.openContext(self)
		self:copyPixelsUnderContext()
		self:drawShadow()

		for numItem, item in pairs(self.content) do
			self:drawItem(numItem-1, item)
		end
	end

	function self.checkTouch(self, event)
		local numSelectedItem = event[4]-self.draw_point.y+1

		local selectedItem = self.content[numSelectedItem]
		local isEnabledItem = ( selectedItem ) and ( selectedItem.active == true )
		local clickOnContextFrame = ( event[3] > self.draw_point.x-1 ) and ( event[3] < self.draw_point.x+self.default_design.width )

		if ( event[1] == "touch" ) then
			if ( isEnabledItem and clickOnContextFrame ) then
				self:blinkItem(selectedItem, event[4])

				--Call function
				local calledFunction = selectedItem["function"]
				if ( calledFunction ) then
					calledFunction()
				end
			end
		end
	end

	function self.closeContext(self)
		self:drawPixelsUnderContext()
	end

	return self
end

--Example
local function pr()
	print("Opened!")
end

local content = {}
content[1] = {["name"] = "Open", ["function"] = pr, ["active"] = true}
content[2] = {["name"] = "Close", ["function"] = nil, ["active"] = true}
content[3] = false
content[4] = {["name"] = "Delete", ["function"] = nil, ["active"] = false}
content[5] = false

local t = { e.pull("touch") }

local menu = createContext(content, g, t[3], t[4])
menu:openContext()
menu:checkTouch({ e.pull() } )
menu:closeContext()

--return context
