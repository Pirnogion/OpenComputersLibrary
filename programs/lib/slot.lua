local event = require "event"
local unicode = require "unicode"

local rect = require "rectangle"

local STATUS_NOT_FRAME = 0
local STATUS_FRAME1    = 5
local STATUS_FRAME2    = 10

local MOUSE_CLICK_XPOS = 3
local MOUSE_CLICK_YPOS = 4
local MOUSE_BUTTON_PRESSED = 5
local LEFT_MOUSE_BUTTON = 0
local RIGHT_MOUSE_BUTTON = 1

-- UTILS --
local function restrictString(string, max_len, n, restrictLeft)
	if ( unicode.len(string) > max_len ) then
		if ( not restrictLeft ) then
			return unicode.sub(string, 1, max_len - unicode.len(n)*2 ) .. n
		else
			return n .. unicode.sub(string, unicode.len(string)-max_len+unicode.len(n)*2, unicode.len(string) )
		end
	end
	return string
end

local function alignCenterX( sx, width, string )
	return width/2 - unicode.len(string)/2 + sx
end

local slotAPI = {}

slotAPI.slots = {}
slotAPI.firstSelectedSlot = nil
slotAPI.secondSelectedSlot = nil
slotAPI.callback = nil

function slotAPI.handler(...)
	local event = {...}
	if ( not event ) then return nil end

	for i, slot in ipairs(slotAPI.slots) do
		if ( event[MOUSE_BUTTON_PRESSED] == LEFT_MOUSE_BUTTON and rect.PointInRect(event[MOUSE_CLICK_XPOS], event[MOUSE_CLICK_YPOS], slot.rect) ) then
			if ( slotAPI.firstSelectedSlot ~= slot ) then
				if ( slotAPI.firstSelectedSlot ) then
					slotAPI.firstSelectedSlot.status = STATUS_NOT_FRAME
					slotAPI.firstSelectedSlot:redrawOutline()
				end

				if (slotAPI.callback) then slotAPI.callback(i) end

				slot.status = STATUS_FRAME1
				slotAPI.firstSelectedSlot = slot
				slot:redrawOutline()
			end

			break
		end
	end
end

function slotAPI.init()
	event.listen("touch", slotAPI.handler)
end

function slotAPI.stop()
	slotAPI.slots = {}
	event.ignore("touch", slotAPI.handler)
end

function slotAPI.create(gpu, x, y, width, height, text, stackSize, maxStackSize, durability, maxDurability, status)
	slot = {}

	slot.gpu    = gpu
	slot.rect   = rect.CreateRectXYWH("", x, y, width, height)
	slot.status = status or STATUS_NOT_FRAME
	slot.id     = 0

	-- STACK INFO --
	slot.text = text or ' NO ITEM '
	slot.stackSize = stackSize or 0
	slot.maxStackSize = maxStackSize or 0
	slot.durability = durability or 0
	slot.maxDurability = maxDurability or 0

	-- DESIGN --
	slot.lt_corner = '┌'
	slot.rt_corner = '┐'
	slot.lb_corner = '┘'
	slot.rb_corner = '└'
	slot.h_line = '─'
	slot.v_line = '│'

	slot.fillchar = ' '

	slot.colorSheme =
	{
		bgcolor = 0x626262,
		fgcolor = 0xA6B0B6,
		bgmaxDurability = 0x424242,
		bgdurability = 0x00A81F,

		[STATUS_NOT_FRAME] =
		{
			bgcolor = 0x626262,
			fgcolor = 0xA6B0B6,
		},

		[STATUS_FRAME1] =
		{
			bgcolor = 0x626262,
			fgcolor = 0xA6B0B6,
		},

		[STATUS_FRAME2] =
		{
			bgcolor = 0x626262,
			fgcolor = 0xA6B0B6,
		},
	}

	function slot:redraw()
		gpu.setBackground(self.colorSheme.bgcolor)
		gpu.setForeground(self.colorSheme.fgcolor)
		gpu.fill( self.rect.sx, self.rect.sy, self.rect.width, self.rect.height, self.fillchar )

		if (self.maxStackSize and self.maxStackSize > 0) then
			local stackSizeInfo = tostring(self.stackSize) .. '/' .. tostring(self.maxStackSize)
			gpu.set(alignCenterX(self.rect.sx, self.rect.width, stackSizeInfo), self.rect.sy+self.rect.height/2-1, stackSizeInfo)
		end

		if (self.maxDurability and self.maxDurability > 0) then
			local durabilityLine = ((self.rect.width-2)*self.durability)/self.maxDurability

			gpu.setForeground(self.colorSheme.bgmaxDurability)
			gpu.fill( self.rect.sx+1, self.rect.ey-1, self.rect.width-2, 1, '▂' )

			gpu.setForeground(self.colorSheme.bgdurability)
			gpu.fill( self.rect.sx+1, self.rect.ey-1, durabilityLine, 1, '▂' )
		end
	end

	function slot:redrawOutline()
		local willDraw = self.status == STATUS_FRAME1 or self.status == STATUS_FRAME2

		gpu.setBackground( self.colorSheme[self.status].bgcolor )
		gpu.setForeground( self.colorSheme[self.status].fgcolor )

		gpu.fill( self.rect.sx, self.rect.sy, self.rect.width, 1, willDraw and self.h_line or self.fillchar )
		gpu.fill( self.rect.sx, self.rect.ey, self.rect.width, 1, willDraw and self.h_line or self.fillchar )

		gpu.fill( self.rect.sx, self.rect.sy, 1, self.rect.height, willDraw and self.v_line or self.fillchar )
		gpu.fill( self.rect.ex, self.rect.sy, 1, self.rect.height, willDraw and self.v_line or self.fillchar )

		gpu.set( self.rect.sx, self.rect.sy, willDraw and self.lt_corner or self.fillchar)
		gpu.set( self.rect.ex, self.rect.sy, willDraw and self.rt_corner or self.fillchar)
		gpu.set( self.rect.ex, self.rect.ey, willDraw and self.lb_corner or self.fillchar)
		gpu.set( self.rect.sx, self.rect.ey, willDraw and self.rb_corner or self.fillchar)

		local descr_cutted = restrictString( self.text, self.rect.width-2, '' )
		gpu.set(alignCenterX(self.rect.sx, self.rect.width, descr_cutted), self.rect.ey, descr_cutted)
	end

	function slot:redrawOutlineText( text )
		self.text = text
		local descr_cutted = restrictString( text, self.rect.width-2, '' )
		gpu.set(alignCenterX(self.rect.sx, self.rect.width, descr_cutted), self.rect.ey, descr_cutted)
	end

	function slot:destroy()
		table.remove( slotAPI.slots, slot.id )
	end

	table.insert( slotAPI.slots, slot ); slot.id = #slotAPI.slots
	return slot
end

return slotAPI
