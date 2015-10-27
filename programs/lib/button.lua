local rect = require "rectangle"
local unicode = require "unicode"
local event = require "event"
local computer = require "computer"

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

local buttons = {}
local function ButtonReleaseHandler( button, ... )
	button.timer = nil
	button.status = STATUS_ENABLED
	button:redraw()
end

local function ButtonPressHandler( button, ... )
	button.action()

	button.status = STATUS_BLINK
	button:redraw()

	button.timer = event.timer( button.design.blink_time, function() ButtonReleaseHandler( button ) end )
end

local function ButtonHandler( ... )
	local e = { ... }

	if ( #buttons > 0 and e[1] == "touch" and e[5] == 0 ) then
		for i=1, #buttons, 1 do
			if ( rect.PointInRect(e[3], e[4], buttons[i].rectangle) ) then
				if ( buttons[i].status == STATUS_ENABLED ) then
					ButtonPressHandler( buttons[i], ... )
				end

				break
			end
		end
	end
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

function buttonAPI.stop()
	buttons = {}
	event.ignore( "touch", ButtonHandler )
end

function buttonAPI.start()
	event.listen( "touch", ButtonHandler )
end

function buttonAPI.create(gpu, rectangle, text, action, design, status)
	button = {}

	button.gpu 		 = gpu
	button.rectangle = rectangle
	button.design 	 = design or default_design
	button.text 	 = text or default_text
	button.action 	 = action or default_action
	button.status    = status or STATUS_ENABLED
	button.id        = 0

	function button:redraw()
		self.gpu.setBackground( self.design[self.status].bg )
		self.gpu.setForeground( self.design[self.status].fg )
		self.gpu.fill( self.rectangle.sx, self.rectangle.sy, self.rectangle.width, self.rectangle.height, self.design[self.status].char )

		for i = 1, #self.text, 1 do
			local textX, textY = alignTextToCenterRect(self.rectangle, self.text[i])
			self.gpu.set( textX, textY-#self.text+i, self.text[i] )
		end
	end

	function button:destroy()
		table.remove( buttons, button.id )
	end

	table.insert( buttons, button ); button.id = #buttons
	return button
end

return buttonAPI
