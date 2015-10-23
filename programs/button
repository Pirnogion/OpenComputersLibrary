local rect = require "rectangle"
local unicode = require "unicode"
local event = require "event"

--CONST--
local STATUS_ENABLED = 0
local STATUS_DISABLED = 5
local STATUS_BLINK = 10

--UTILS--
local function alignTextToCenterRect(rectangle, text)
	local x = rectangle.sx + rectangle.width/2 - unicode.len(text)/2
	local y = rectangle.sy + rectangle.height/2

	return x, y
end

--Default settings
local default_design = {
	blink_time = 0.2,

	[STATUS_ENABLED] = {
		bg = 0x00ff00,
		fg = 0xffffff,
		char = ' '
	},

	[STATUS_DISABLED] = {
		bg = 0xffffff,
		fg = 0,
		char = ' '
	},

	[STATUS_BLINK] = {
		bg = 0xff0000,
		fg = 0,
		char = ' '
	}
}

local default_text = {' '}

local default_action = function()
	--nothing
end

--BUTTON API--
local buttonAPI = {}

function buttonAPI.create(gpu, rectangle, text, action, design, status)
	button = {}

	button.gpu 		 = gpu
	button.rectangle = rectangle
	button.design 	 = design or default_design
	button.text 	 = text or default_text
	button.action 	 = action or default_action
	button.status    = status or STATUS_ENABLED

	function button:redraw()
		self.gpu.setBackground( self.design[self.status].bg )
		self.gpu.setForeground( self.design[self.status].fg )
		self.gpu.fill( self.rectangle.sx, self.rectangle.sy, self.rectangle.width, self.rectangle.height, self.design[self.status].char )

		for i = 1, #self.text, 1 do
			local textX, textY = alignTextToCenterRect(self.rectangle, self.text[i])
			self.gpu.set( textX, textY-#self.text+i, self.text[i] )
		end
	end

	function button:handler(e, callback)
		if ( self.timer and self.status == STATUS_BLINK ) then
			self.timer = nil
			self.status = STATUS_ENABLED
			self:redraw()
		end
		if ( e[1] == "touch" and e[5] == 0 ) then
			if ( self.status == STATUS_ENABLED ) then
				if ( rect.PointInRect(e[3], e[4], self.rectangle) ) then
					self.action()

					self.status = STATUS_BLINK
					self:redraw()

					self.timer = event.timer( self.design.blink_time, callback )
					callback(self.timer, self)
				end
			end
		end
	end

	return button
end

return buttonAPI
