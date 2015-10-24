local component = require "component"
local unicode = require "unicode"
local event = require "event"

local rect = require "rectangle"
local button = require "button"

local wifi = component.modem
local gpu = component.gpu

local running = true
local robot   = "7428dc80-98d3-4549-810a-1be9bb62d8d0"

--Colors--
local bgworkspace = 0xD6D6D6
local fgworkspace = 0xA6B0B6

local bgworld = 0x5E5E5E
local fgworld = 0xA6B0B6

local bgtoolbar   = 0x5E5E5E
local bgtoolbar_button_active = 0xD6D6D6
local bgtoolbar_button_inactive = 0x424242

local bgstatus_idle       = 0x00A81F
local bgstatus_processing = 0xff0000

local screenWidth, screenHeight = gpu.maxResolution()
gpu.setResolution( screenWidth, screenHeight )
wifi.open(1)

local function alignCenterX( sx, width, string )
	return width/2 - unicode.len(string)/2 + sx
end

local IDLE       = 0
local PROCESSING = 1
local status = IDLE

local function setStatus( status )
	local bgprev = gpu.getBackground()
	local fgprev = gpu.getForeground()

	gpu.setForeground( 0xffffff )

	if ( status == IDLE ) then
		gpu.setBackground( bgstatus_idle )
		gpu.fill( 145, 4, 15, 1, ' ' )
		gpu.set( 145, 4, "⏳║ ОЖИДАНИЕ" )
	elseif ( status == PROCESSING ) then
		gpu.setBackground( bgstatus_processing )
		gpu.fill( 145, 4, 15, 1, ' ' )
		gpu.set( 145, 4, "⏳║ ВЫПОЛЕНИЕ" )
	end
	gpu.setBackground( bgprev )
	gpu.setForeground( fgprev )
end

local UNEXPLORED     = 0
local EXPLORED       = 1
local DESTRUCTIBLE   = 2
local INDESTRUCTIBLE = 3
local ENTITY         = 4
local LIQUID         = 5
local PASSABLE       = 6
local REPLACEABLE    = 7
local worldGlyph =
{
	[UNEXPLORED] = '+',
	[EXPLORED] = ' ',
	[DESTRUCTIBLE] = '░',
	[INDESTRUCTIBLE] = '▓',
	[ENTITY] = '☻',
	[LIQUID] = '~',
	[PASSABLE] = '╬',
	[REPLACEABLE] = '?',
}

local PLAYER_FW  = 0
local PLAYER_RR  = 1
local PLAYER_BW  = 2
local PLAYER_LR  = 3
local playerDir =
{
	[0] = '▲',
	[1] = '►',
	[2] = '▼',
	[3] = '◄',
}

local detectStat =
{
	entity = ENTITY,
	solid = DESTRUCTIBLE,
	replaceable = REPLACEABLE,
	liquid = LIQUID,
	passable = PASSABLE,
	air = EXPLORED,
	[true] = EXPLORED,
}

local player = { x = 0, y = 0, dir = PLAYER_FW, layer = 0 }
local world =
{
	[0] = {},
}

local function addObject( objx, objy, objglyph, layer )
	table.insert( world[layer], { x = objx, y = objy, glyph = objglyph } )
end

local function addObjectAtLookPlayer( objglyph, layer, isBack )
	local direction = isBack and -1 or 1

	if ( player.dir == 0 ) then
		addObject( player.x, player.y-direction, objglyph, layer )
	elseif ( player.dir == 1 ) then
		addObject( player.x+direction, player.y, objglyph, layer )
	elseif ( player.dir == 2 ) then
		addObject( player.x, player.y+direction, objglyph, layer )
	elseif ( player.dir == 3 ) then
		addObject( player.x-direction, player.y, objglyph, layer )
	end
end

local function movePlayerAtLook( isBack )
	local direction = isBack and -1 or 1

	if ( player.dir == 0 ) then
		player.y = player.y - direction
	elseif ( player.dir == 1 ) then
		player.x = player.x + direction
	elseif ( player.dir == 2 ) then
		player.y = player.y + direction
	elseif ( player.dir == 3 ) then
		player.x = player.x - direction
	end
end

local function redrawWorkspace(sx, sy, layer)
	for i, obj in ipairs(world[layer]) do
		gpu.set( sx+obj.x, sy+obj.y, worldGlyph[obj.glyph] )
	end

	gpu.set( sx+player.x, sy+player.y, playerDir[player.dir] )
end

--Draw workspace
gpu.setBackground( bgworkspace )
gpu.setForeground( fgworkspace )
gpu.fill( 1, 1, screenWidth, screenHeight, ' ' )
gpu.fill( 1, 7, screenWidth, screenHeight-7, '+' )

gpu.setForeground( 0xffffff )
--Draw control panel
gpu.setBackground( bgtoolbar )
gpu.fill( 1, 1, screenWidth, 6, ' ' )

--Draw inset inactive
gpu.setBackground( bgtoolbar_button_inactive )
gpu.fill( 2, 1, 12, 6, ' ' )
gpu.set( alignCenterX(2, 12, "АВТО"), 3, "АВТО" )
gpu.set( alignCenterX(2, 12, "УПРАВЛЕНИЕ"), 4, "УПРАВЛЕНИЕ" )

--Draw inset active
gpu.setBackground( bgtoolbar_button_active )
gpu.fill( 15, 1, 12, 6, ' ' )
gpu.set( alignCenterX(15, 12, "РУЧНОЕ"), 3, "РУЧНОЕ" )
gpu.set( alignCenterX(15, 12, "УПРАВЛЕНИЕ"), 4, "УПРАВЛЕНИЕ" )

local buttonDesign = {
	blink_time = 0.2,

	[0] = {
		bg = bgtoolbar_button_inactive,
		fg = 0xffffff,
		char = ' '
	},

	[5] = {
		bg = 0xffffff,
		fg = 0,
		char = ' '
	},

	[10] = {
		bg = bgtoolbar_button_active,
		fg = 0xffffff,
		char = ' '
	}
}

local function zagluska()

end

local toolbarButtons = {}
local buttonRect = nil

------------------------------------------------------------------------------------------------
gpu.setBackground( bgtoolbar_button_inactive )
gpu.fill( 97, 2, 3, 1, ' ' )
gpu.set( alignCenterX(97, 3, "1"), 2, "▲" )

gpu.setBackground( bgtoolbar_button_active )
gpu.fill( 97, 3, 3, 2, ' ' )
gpu.set( alignCenterX(97, 3, "1"), 3, "▄" )
gpu.set( alignCenterX(97, 3, "1"), 4, "▀" )

gpu.setBackground( bgtoolbar_button_inactive )
gpu.fill( 97, 5, 3, 1, ' ' )
gpu.set( alignCenterX(97, 3, "1"), 5, "▼" )

gpu.setBackground( bgtoolbar_button_inactive )
gpu.fill( 111, 2, 3, 1, ' ' )
gpu.set( alignCenterX(111, 3, "1"), 2, "▲" )

gpu.setBackground( bgtoolbar_button_active )
gpu.fill( 111, 3, 3, 2, ' ' )
gpu.set( alignCenterX(111, 3, "1"), 3, "▄" )
gpu.set( alignCenterX(111, 3, "1"), 4, "▀" )

gpu.setBackground( bgtoolbar_button_inactive )
gpu.fill( 111, 5, 3, 1, ' ' )
gpu.set( alignCenterX(111, 3, "1"), 5, "▼" )

gpu.setBackground( bgtoolbar_button_inactive )
gpu.fill( 125, 2, 3, 1, ' ' )
gpu.set( alignCenterX(125, 3, "1"), 2, "▲" )

gpu.setBackground( bgtoolbar_button_active )
gpu.fill( 125, 3, 3, 2, ' ' )
gpu.set( alignCenterX(125, 3, "1"), 3, "▄" )
gpu.set( alignCenterX(125, 3, "1"), 4, "▀" )

gpu.setBackground( bgtoolbar_button_inactive )
gpu.fill( 125, 5, 3, 1, ' ' )
gpu.set( alignCenterX(125, 3, "1"), 5, "▼" )

gpu.setBackground( bgtoolbar_button_inactive )
gpu.fill( 140, 2, 3, 1, ' ' )
gpu.set( alignCenterX(140, 3, "1"), 2, "▲" )

gpu.setBackground( bgtoolbar_button_active )
gpu.fill( 140, 3, 3, 2, ' ' )
gpu.set( alignCenterX(140, 3, "1"), 3, "▄" )
gpu.set( alignCenterX(140, 3, "1"), 4, "▀" )

gpu.setBackground( bgtoolbar_button_inactive )
gpu.fill( 140, 5, 3, 1, ' ' )
gpu.set( alignCenterX(140, 3, "1"), 5, "▼" )

-- MAIN LOOP --
gpu.setBackground( bgworld )
gpu.setForeground( fgworld )

addObject( player.x, player.y, EXPLORED, player.layer )
redrawWorkspace(screenWidth/2, screenHeight/2+3, player.layer)

local control =
{
	["use"] = function()
		wifi.send(robot, 1, "robot.use")
		setStatus( PROCESSING )
	end,

	["place"] = function()
		wifi.send(robot, 1, "robot.place")
		setStatus( PROCESSING )
	end,

	[17] = function()
		wifi.send(robot, 1, "robot.forward")
		setStatus( PROCESSING )
	end, --w

	[31] = function()
		wifi.send(robot, 1, "robot.backward")
		setStatus( PROCESSING )
	end, --s

	[30] = function()
		wifi.send(robot, 1, "robot.turnLeft")
		setStatus( PROCESSING )
	end, --a

	[32] = function()
		wifi.send(robot, 1, "robot.turnRight")
		setStatus( PROCESSING )
	end, --d

	[42] = function()
		wifi.send(robot, 1, "robot.shutdown")
		running = false
	end, --shift

	[22] = function()
		wifi.send(robot, 1, "robot.swing")
		wifi.send( robot, 1, "robot.getInstumentData" )
		setStatus( PROCESSING )
	end, --u

	[16] = function()
		wifi.send(robot, 1, "robot.up")
		setStatus( PROCESSING )
	end, --q

	[18] = function()
		wifi.send(robot, 1, "robot.down")
		setStatus( PROCESSING )
	end, --e

	[44] = function()
		wifi.send(robot, 1, "robot.detect")
		setStatus( PROCESSING )
	end, --z
}
local meta = {}
function meta.__index(op, key)
	return function()
		running = false
	end
end
setmetatable( control, meta )

--Команды, которые я принимаю
local commands = 
{
	["server.forward"] = function( result, reason )
		addObjectAtLookPlayer( result and EXPLORED or detectStat[ reason ], player.layer )
		if ( result ) then movePlayerAtLook() end
		redrawWorkspace(screenWidth/2, screenHeight/2+3, player.layer)

		setStatus( IDLE )
	end,

	["server.backward"] = function( result, reason )
		addObjectAtLookPlayer( result and EXPLORED or detectStat[ reason ], player.layer, true )
		if ( result ) then movePlayerAtLook(true) end
		redrawWorkspace(screenWidth/2, screenHeight/2+3, player.layer)

		setStatus( IDLE )
	end,

	["server.swing"] = function( result, reason )
		control[44]()

		setStatus( IDLE )
	end,

	["server.turnLeft"] = function()
		player.dir = (player.dir-1) % (#playerDir+1)
		redrawWorkspace(screenWidth/2, screenHeight/2+3, player.layer)

		setStatus( IDLE )
	end,

	["server.turnRight"] = function()
		player.dir = (player.dir+1) % (#playerDir+1)
		redrawWorkspace(screenWidth/2, screenHeight/2+3, player.layer)

		setStatus( IDLE )
	end,

	["server.getInstumentData"] = function( data )
		local durability = "X"
		if ( type(data) == "number" ) then
			durability = math.modf( data*100 ) .. '%'
		elseif ( data == "no tool equipped" ) then
			durability = "NO TOOL!"
		elseif ( data == "tool cannot be damaged" ) then
			durability = "Invul. tool"
		end

		gpu.setBackground( bgtoolbar_button_inactive )
		gpu.setForeground( 0xffffff )

		gpu.fill( 145, 3, 15, 1, ' ' )
		gpu.set( 145, 3, "⚒║ " .. durability )

		gpu.setBackground( bgworld )
		gpu.setForeground( fgworld )

		setStatus( IDLE )
	end,

	["server.getEnergy"] = function( energy )
		gpu.setBackground( bgtoolbar_button_inactive )
		gpu.setForeground( 0xffffff )

		gpu.fill( 145, 2, 15, 1, ' ' )
		gpu.set( 145, 2, " ☇║ " .. energy )

		gpu.setBackground( bgworld )
		gpu.setForeground( fgworld )
	end,

	["server.up"] = function( result, reason )
		if ( not world[player.layer+1] ) then world[player.layer+1] = {} end

		if ( result ) then
			player.layer = player.layer + 1

			gpu.setBackground( bgworkspace )
			gpu.setForeground( fgworkspace )
			gpu.fill( 1, 7, screenWidth, screenHeight-7, '+' )
			gpu.setBackground( bgworld )
			gpu.setForeground( fgworld )
		end

		addObject( player.x, player.y, result and EXPLORED or detectStat[ reason ], result and player.layer or player.layer+1 )
		redrawWorkspace(screenWidth/2, screenHeight/2+3, player.layer)

		setStatus( IDLE )
	end,

	["server.down"] = function( result, reason )
		if ( not world[player.layer-1] ) then world[player.layer-1] = {} end

		if ( result ) then
			player.layer = player.layer - 1

			gpu.setBackground( bgworkspace )
			gpu.setForeground( fgworkspace )
			gpu.fill( 1, 7, screenWidth, screenHeight-7, '+' )
			gpu.setBackground( bgworld )
			gpu.setForeground( fgworld )
		end

		addObject( player.x, player.y, result and EXPLORED or detectStat[ reason ], result and player.layer or player.layer-1 )
		redrawWorkspace(screenWidth/2, screenHeight/2+3, player.layer)

		setStatus( IDLE )
	end,

	["server.detect"] = function( result, reason )
		addObjectAtLookPlayer( detectStat[ reason ], player.layer )
		redrawWorkspace(screenWidth/2, screenHeight/2+3, player.layer)

		setStatus( IDLE )
	end,

	["server.use"] = function( result, reason )
		--addObjectAtLookPlayer( detectStat[ reason ], player.layer )
		control[44]()

		setStatus( IDLE )
	end,

	["server.place"] = function( result, reason )
		--addObjectAtLookPlayer( detectStat[ reason ], player.layer )
		control[44]()

		setStatus( IDLE )
	end,
}
local meta = {}
function meta.__index(op, key)
	return function() end
end
setmetatable( commands, meta )

--Draw button active 
buttonRect = rect.CreateRectXYWH("ButtonMoveForward", 27, 2, 10, 4)
toolbarButtons.buttonForward = button.create(gpu, buttonRect, {"W▲", "ВПЕРЁД"}, control[17], buttonDesign)
toolbarButtons.buttonForward:redraw()

buttonRect = rect.CreateRectXYWH("ButtonMoveBackward", 37, 2, 10, 4)
toolbarButtons.buttonBackward = button.create(gpu, buttonRect, {"S▼", "НАЗАД"}, control[31], buttonDesign)
toolbarButtons.buttonBackward:redraw()

buttonRect = rect.CreateRectXYWH("ButtonMoveRight", 47, 2, 10, 4)
toolbarButtons.buttonRight = button.create(gpu, buttonRect, {"D►", "ВПРАВО"}, control[32], buttonDesign)
toolbarButtons.buttonRight:redraw()

buttonRect = rect.CreateRectXYWH("ButtonMoveLeft", 57, 2, 10, 4)
toolbarButtons.buttonLeft = button.create(gpu, buttonRect, {"A◄", "ВЛЕВО"}, control[30], buttonDesign)
toolbarButtons.buttonLeft:redraw()

buttonRect = rect.CreateRectXYWH("ButtonMoveDown", 67, 2, 10, 4)
toolbarButtons.buttonDown = button.create(gpu, buttonRect, {"E•", "ВНИЗ"}, control[18], buttonDesign)
toolbarButtons.buttonDown:redraw()

buttonRect = rect.CreateRectXYWH("ButtonMoveUp", 77, 2, 10, 4)
toolbarButtons.buttonUp = button.create(gpu, buttonRect, {"Q○", "ВВЕРХ"}, control[16], buttonDesign)
toolbarButtons.buttonUp:redraw()

buttonRect = rect.CreateRectXYWH("ButtonSwing", 87, 2, 10, 4)
toolbarButtons.buttonSwing = button.create(gpu, buttonRect, {"⚒", "УДАР"}, control[22], buttonDesign)
toolbarButtons.buttonSwing:redraw()

buttonRect = rect.CreateRectXYWH("ButtonUse", 101, 2, 10, 4)
toolbarButtons.buttonUse = button.create(gpu, buttonRect, {"⚙", "ИСП."}, control["use"], buttonDesign)
toolbarButtons.buttonUse:redraw()

buttonRect = rect.CreateRectXYWH("ButtonDetect", 115, 2, 10, 4)
toolbarButtons.buttonDetect = button.create(gpu, buttonRect, {"⍰" ,"ПРОВЕР."}, control[44], buttonDesign)
toolbarButtons.buttonDetect:redraw()

buttonRect = rect.CreateRectXYWH("ButtonPlace", 130, 2, 10, 4)
toolbarButtons.buttonPlace = button.create(gpu, buttonRect, {"▣" ,"РАЗМЕСТ."}, control["place"], buttonDesign)
toolbarButtons.buttonPlace:redraw()

setStatus( PROCESSING )
wifi.send( robot, 1, "robot.getInstumentData" )
wifi.send( robot, 1, "robot.getEnergy" )

local handlers = {}
local function callback(timer, button)
	if ( timer and button ) then
		table.insert( handlers, button )
	else
		local btn = table.remove( handlers )
		btn:handler()
	end
end

while ( running ) do
	local e = { event.pull() }

	if ( e[1] == "modem_message" ) then
		commands[ e[6] ]( e[7], e[8] )
	end

	if ( e[1] == "key_down" ) then
		control[ e[4] ]()
	end

	if ( e[1] == "touch" ) then
		for name, button in pairs(toolbarButtons) do
			button:handler(e, callback)
		end
	end
end
