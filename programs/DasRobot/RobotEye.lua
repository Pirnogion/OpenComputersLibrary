-- ПОДКЛЮЧЕНИЕ СТАНДАРТНЫХ БИБЛИОТЕК --
local component = require "component"
local computer = require "computer"
local unicode = require "unicode"
local event = require "event"
local ser = require "serialization"

-- ПОДКЛЮЧЕНИЕ ВНЕШНИХ БИБЛИОТЕК --
--local ecs = require "ecs"
local rect = require "rectangle"
local button = require "button"
local slot =  require "slot"

-- ПОЛУЧЕНИЕ КОМПАНЕНТОВ --
local wifi = component.modem
local gpu = component.gpu

-- ОБЩАЯ ИНФОРМАЦИЯ --
local running = true

--Данные для подключения к роботу
local port  = 1
local robot = "cd95035b-fd10-4ac6-a836-722f80b72252"

--Данные об инвентаре робота
local robotInventory = nil

-- ЦВЕТОВАЯ СХЕМА --
local COLOR_SCHEME = 
{
	workspace = {
		bg = 0xD6D6D6,
		fg = 0xA6B0B6
	},

	world = {
		bg = 0x5E5E5E,
		fg = 0xA6B0B6,
	},

	toolbar = {
		bg = 0x5E5E5E,
		fg = 0xffffff,

		button = {
			active = {
				bg = 0xD6D6D6
			},

			inactive = {
				bg = 0x424242
			}
		}
	},

	inverntory = {
		bginventory = 0xff0000,
		fginventory = 0xffffff,
	},

	status = {
		idle       = 0x00A81F,
		processing = 0xBF2008
	}
}

-- ПОЛЕЗНЫЕ ФУНКЦИИ --
local function alignCenterX( sx, width, string )
	return width/2 - unicode.len(string)/2 + sx
end

local function ticker( text )
	return unicode.sub( text, 2, unicode.len(text) ) .. unicode.sub( text, 1, 1 )
end

-- ПРЕДИНИЦИАЛИЗАЦИЯ --

--Инициализация компанентов
if ( gpu and gpu.maxDepth() == 8 ) then
	gpu.setDepth(8)
else
	error("Graphic card not found! Or the GPU max depth less 8 bit.")
end

if ( wifi and wifi.isWireless() ) then
	wifi.open( port )
else
	error("Wireless modem not found! Or the modem not wireless.")
end

--Получение данных о размере экрана
local screenWidth, screenHeight = gpu.maxResolution()
local workspaceRect = rect.CreateRectXYWH("ScreenBound", 1, 7, screenWidth, screenHeight-6)
gpu.setResolution( screenWidth, screenHeight )

-- ОПЕРАЦИИ НАД СОСТОЯНИЯМИ ПРОГРАММЫ --
local IDLE       = 0
local PROCESSING = 1
local status = IDLE

local function setStatus( status )
	local bgprev = gpu.getBackground()
	local fgprev = gpu.getForeground()

	gpu.setForeground( 0xffffff )

	if ( status == IDLE ) then
		gpu.setBackground( COLOR_SCHEME.status.idle )
		gpu.fill( 145, 4, 15, 1, ' ' )
		gpu.set( 145, 4, "⏳║ ОЖИДАНИЕ" )
	elseif ( status == PROCESSING ) then
		gpu.setBackground( COLOR_SCHEME.status.processing )
		gpu.fill( 145, 4, 15, 1, ' ' )
		gpu.set( 145, 4, "⏳║ ВЫПОЛЕНИЕ" )
	end
	gpu.setBackground( bgprev )
	gpu.setForeground( fgprev )
end

-- ОПЕРАЦИИ ДЛЯ ОТРИСОВКИ КАРТЫ --

--Данные для скорллинга карты
local scrollX, scrollY = 0, 0
local scrollStep = 5

--Данные о возможных символах карты
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

--Данные о повороте робота относительно начального поворота
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

-- ??? --
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

--Информация о роботе и карте
local player = { x = 0, y = 0, dir = PLAYER_FW, layer = 0 }
local world =
{
	[0] = {},
}

--Добавить метку на карту
local function addObject( objx, objy, objglyph, layer )
	table.insert( world[layer], { x = objx, y = objy, glyph = objglyph } )
end

--Добавить метку на карту в направлении взгляда робота
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

--Перемещние робота в направлении его взгляда
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

--Перерисовка карты
local function redrawWorkspace(sx, sy, layer)
	gpu.setBackground( COLOR_SCHEME.workspace.bg )
	gpu.setForeground( COLOR_SCHEME.workspace.fg )
	gpu.fill( workspaceRect.sx, workspaceRect.sy, workspaceRect.width, workspaceRect.height, '+' )

	gpu.setBackground( COLOR_SCHEME.world.bg )
	gpu.setForeground( COLOR_SCHEME.world.fg )

	if ( not rect.PointInRect(sx+player.x+scrollX, sy+player.y+scrollY, workspaceRect) ) then
		if (sx+player.x+scrollX <= workspaceRect.sx) then
			scrollX = scrollX + scrollStep
		elseif (sx+player.x+scrollX >= workspaceRect.ex) then
			scrollX = scrollX - scrollStep
		elseif (sy+player.y+scrollY <= workspaceRect.sy) then
			scrollY = scrollY + scrollStep
		elseif (sy+player.y+scrollY >= workspaceRect.ey) then
			scrollY = scrollY - scrollStep
		end
	end

	for i, obj in ipairs(world[layer]) do
		if ( rect.PointInRect(sx+obj.x+scrollX, sy+obj.y+scrollY, workspaceRect) ) then
			gpu.set( sx+obj.x+scrollX, sy+obj.y+scrollY, worldGlyph[obj.glyph] )
		end
	end
	gpu.set( sx+player.x+scrollX, sy+player.y+scrollY, playerDir[player.dir] )
end

------------------------------------------------------------------------------------------------
--[[gpu.setBackground( bgtoolbar_button_inactive )
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
gpu.set( alignCenterX(140, 3, "1"), 5, "▼" )--]]
------------------------------------------------------------------------------------------------

--Запросы сервера отсылаемые роботу
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

	["getInventory"] = function()
		wifi.send(robot, 1, "robot.getInventory")
		setStatus( PROCESSING )
	end,

	["selectSlot"] = function(slot)
		wifi.send(robot, 1, "robot.selectSlot", slot)
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

--Если обнаружена попытка отправить несуществующий запрос роботу, то остановить программу сервера.
local meta = {}
function meta.__index(op, key)
	return function()
		running = false
	end
end
setmetatable( control, meta )

-- ИНВЕНТАРЬ --
local tickerTimer = nil
local updateInventoryButton = nil
local visibleInventoryList = false

--Создание кнопок инвентаря
updateInventoryButton = button.create(gpu, nil, {"ПРОВЕРИТЬ ИНВЕНТАРЬ"}, control["getInventory"], buttonDesign)
updateInventoryButton.rectangle = rect.CreateRectXYWH("UpdateInventory", screenWidth-71, screenHeight-6, 21, 3)

--Бегущая строка, прокручивает название предмета
local function tickerSlot()
	for i, value in ipairs(robotInventory) do
		if ( value ) then
			value.name = ticker( value.name )
			slot.slots[i]:redrawOutlineText(value.name)
		end
	end
end

--Обновить информацию об инвентаре
local function updateInventory()
	if ( #slot.slots < 1 ) then return nil end

	--Заполнить слоты информацией и отрисовать
	for i, value in ipairs(robotInventory) do
		if ( value ) then
			slot.slots[i].text = value.name
			slot.slots[i].stackSize = value.size
			slot.slots[i].maxStackSize = value.maxSize
			slot.slots[i].durability = value.maxDamage - value.damage
			slot.slots[i].maxDurability = value.maxDamage
		end

		if ( visibleInventoryList ) then
			slot.slots[i]:redraw()
			slot.slots[i]:redrawOutlineText()
		end
	end

	--Обвести рамкой текущий слот робота
	slot.slots[robotInventory.selectedSlot].status = 5
	slot.firstSelectedSlot = slot.slots[robotInventory.selectedSlot]
	slot.slots[robotInventory.selectedSlot]:redrawOutline()
end

--Отобразить или спрятать инвентарь робота
local function drawInventoryList()
	local _slot = nil

	--Отрисовка заднего фона для инвентрая
	gpu.setBackground( COLOR_SCHEME.workspace.fg )
	gpu.fill( 87, 7, 74, screenHeight-6, ' ' )

	--Отрисовка кнопки обновления инвентаря
	updateInventoryButton.status = 0
	updateInventoryButton:redraw()

	--Изменить размер карты
	rect.RecalculateWH(workspaceRect, 86, nil)

	--Создать слоты
	for y=0, 3, 1 do
		for x=0, 3, 1 do
			_slot = slot.create(gpu, 89+(18*y), 8+(9*x), 16, 8)
			_slot:redraw()
			_slot:redrawOutline()
		end
	end

	--Обновить инвентарь и установить коллбэк функцию для установки слота на роботе
	control["getInventory"]()
	slot.callback = control["selectSlot"]

	--Запустить прокрутку названий предметов и перерисовать карту
	tickerTimer = event.timer( 0.3, tickerSlot, math.huge )
	redrawWorkspace(workspaceRect.width/2, workspaceRect.height/2+3, player.layer)

	--Запустить обработку слотов
	slot.init()
end

--Скрыть инвентарь и остановить обработку слотов
local function hideInventory()
	slot.stop()
	event.cancel(tickerTimer)

	updateInventoryButton.status = 5

	rect.RecalculateWH(workspaceRect, screenWidth, nil)
	redrawWorkspace(workspaceRect.width/2, workspaceRect.height/2+3, player.layer)
end

--Отрисовать\скрыть инвентарь
local function switchInventoryListVisible()
	visibleInventoryList = not visibleInventoryList
	if ( visibleInventoryList ) then
		drawInventoryList()
	else
		hideInventory()
	end
end

--Ответы робота на запросы сервера
local commands = 
{
	["server.forward"] = function( result, reason )
		addObjectAtLookPlayer( result and EXPLORED or detectStat[ reason ], player.layer )
		if ( result ) then movePlayerAtLook() end
		redrawWorkspace(workspaceRect.width/2, workspaceRect.height/2+3, player.layer)

		setStatus( IDLE )
	end,

	["server.backward"] = function( result, reason )
		addObjectAtLookPlayer( result and EXPLORED or detectStat[ reason ], player.layer, true )
		if ( result ) then movePlayerAtLook(true) end
		redrawWorkspace(workspaceRect.width/2, workspaceRect.height/2+3, player.layer)

		setStatus( IDLE )
	end,

	["server.swing"] = function( result, reason )
		control[44]()

		setStatus( IDLE )
	end,

	["server.turnLeft"] = function()
		player.dir = (player.dir-1) % (#playerDir+1)
		redrawWorkspace(workspaceRect.width/2, workspaceRect.height/2+3, player.layer)

		setStatus( IDLE )
	end,

	["server.turnRight"] = function()
		player.dir = (player.dir+1) % (#playerDir+1)
		redrawWorkspace(workspaceRect.width/2, workspaceRect.height/2+3, player.layer)

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

		gpu.fill( 145, 3, 15, 1, ' ' )
		gpu.set( 145, 3, "⚒║ " .. durability )

		setStatus( IDLE )
	end,

	["server.getEnergy"] = function( energy )
		gpu.fill( 145, 2, 15, 1, ' ' )
		gpu.set( 145, 2, " ☇║ " .. energy )
	end,

	["server.up"] = function( result, reason )
		if ( not world[player.layer+1] ) then world[player.layer+1] = {} end

		if ( result ) then
			player.layer = player.layer + 1
		end

		addObject( player.x, player.y, result and EXPLORED or detectStat[ reason ], result and player.layer or player.layer+1 )
		redrawWorkspace(workspaceRect.width/2, workspaceRect.height/2+3, player.layer)

		setStatus( IDLE )
	end,

	["server.down"] = function( result, reason )
		if ( not world[player.layer-1] ) then world[player.layer-1] = {} end

		if ( result ) then
			player.layer = player.layer - 1
		end

		addObject( player.x, player.y, result and EXPLORED or detectStat[ reason ], result and player.layer or player.layer-1 )
		redrawWorkspace(workspaceRect.width/2, workspaceRect.height/2+3, player.layer)

		setStatus( IDLE )
	end,

	["server.detect"] = function( result, reason )
		addObjectAtLookPlayer( detectStat[ reason ], player.layer )
		redrawWorkspace(workspaceRect.width/2, workspaceRect.height/2+3, player.layer)

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

	["server.slotSelected"] = function()
		setStatus( IDLE )
	end,

	["server.getInventory"] = function( result, selectedSlot )
		robotInventory = ser.unserialize(result)
		robotInventory.selectedSlot = selectedSlot

		updateInventory()

		setStatus( IDLE )
	end,
}

--Если пришел неожиданный ответ от робота, то ничего не делать
local meta = {}
function meta.__index(op, key)
	return function() --[[НИЧЕГО НЕ ДЕЛАТЬ--]] end
end
setmetatable( commands, meta )

-- ОТРИСОВКА ТУЛБАРА --

--Отрисовка пустой карты
gpu.setBackground( COLOR_SCHEME.workspace.bg )
gpu.setForeground( COLOR_SCHEME.workspace.fg )
gpu.fill( 1, 1, screenWidth, screenHeight, ' ' )

--Отрисовка заднего фона тулбара
gpu.setBackground( COLOR_SCHEME.toolbar.bg )
gpu.setForeground( COLOR_SCHEME.toolbar.fg )
gpu.fill( 1, 1, screenWidth, 6, ' ' )

--Отрисовка вкладок
gpu.setBackground( COLOR_SCHEME.toolbar.button.inactive.bg )
gpu.fill( 2, 1, 12, 6, ' ' )
gpu.set( alignCenterX(2, 12, "АВТО"), 3, "АВТО" )
gpu.set( alignCenterX(2, 12, "УПРАВЛЕНИЕ"), 4, "УПРАВЛЕНИЕ" )

gpu.setBackground( COLOR_SCHEME.toolbar.button.active.bg )
gpu.fill( 15, 1, 12, 6, ' ' )
gpu.set( alignCenterX(15, 12, "РУЧНОЕ"), 3, "РУЧНОЕ" )
gpu.set( alignCenterX(15, 12, "УПРАВЛЕНИЕ"), 4, "УПРАВЛЕНИЕ" )

--Данные о виде кнопок
local buttonDesign = {
	blink_time = 0.2,

	[0] = {
		bg = COLOR_SCHEME.toolbar.button.inactive.bg,
		fg = 0xffffff,
		char = ' '
	},

	[5] = {
		bg = 0xffffff,
		fg = 0,
		char = ' '
	},

	[10] = {
		bg = COLOR_SCHEME.toolbar.button.active.bg,
		fg = 0xffffff,
		char = ' '
	}
}

--Данные о местоположении, надпиcям и действиям кнопок
local toolbarButtonsInfo =
{
	sx = 27,
	sy = 2,
	width = 10,
	height = 4,

	count = 11,

	[0] = {
		name = "buttonForward",
		text = {"W▲", "ВПЕРЁД"},
		callback = control[17]
	},

	[1] = {
		name = "buttonBackward",
		text = {"S▼", "НАЗАД"},
		callback = control[31]
	},

	[2] = {
		name = "buttonRight",
		text = {"D►", "ВПРАВО"},
		callback = control[32]
	},

	[3] = {
		name = "buttonLeft",
		text = {"A◄", "ВЛЕВО"},
		callback = control[30]
	},

	[4] = {
		name = "buttonDown",
		text = {"E•", "ВНИЗ"},
		callback = control[18]
	},

	[5] = {
		name = "buttonUp",
		text = {"Q○", "ВВЕРХ"},
		callback = control[16]
	},

	[6] = {
		name = "buttonSwing",
		text = {"⚒", "УДАР"},
		callback = control[22]
	},

	[7] = {
		name = "buttonUse",
		text = {"⚙", "ИСП."},
		callback = control["use"]
	},

	[8] = {
		name = "buttonDetect",
		text = {"⯑" ,"ПРОВЕР."},
		callback = control[44]
	},

	[9] = {
		name = "buttonPlace",
		text = {"⬛" ,"РАЗМЕСТ."},
		callback = control["place"]
	},

	[10] = {
		name = "buttonInventory",
		text = {"✉", "Инвентарь"},
		callback = switchInventoryListVisible
	}

}

--Отрисовка кнопок
for i=0, toolbarButtonsInfo.count-1, 1 do
	local _buttonInfo = toolbarButtonsInfo[i]
	local _rect = rect.CreateRectXYWH
	(
		toolbarButtonsInfo.name,
		toolbarButtonsInfo.sx+(toolbarButtonsInfo.width*i),
		toolbarButtonsInfo.sy,
		toolbarButtonsInfo.width, 
		toolbarButtonsInfo.height
	)

	button.create(gpu, _rect, _buttonInfo.text, _buttonInfo.callback, buttonDesign):redraw()
end

-- ИНИЦИАЛИЗАЦИЯ --

--Удаление ненужных данных
buttonDesign = nil
toolbarButtonsInfo = nil

--Получение начальной информации о роботе
setStatus( PROCESSING )
wifi.send( robot, 1, "robot.getInstumentData" )
wifi.send( robot, 1, "robot.getEnergy" )

--Первоначальная отрисовка карты
gpu.setBackground( COLOR_SCHEME.world.bg )
gpu.setForeground( COLOR_SCHEME.world.fg )

addObject( player.x, player.y, EXPLORED, player.layer )
redrawWorkspace(workspaceRect.width/2, workspaceRect.height/2+3, player.layer)

--Запуск обработки кнопок
button.start()

--Игорева хуита
--ecs.universalWindow("auto", "auto", 30, ecs.windowColors.background, true, {"EmptyLine"}, {"CenterText", 0x262626, "Сохранить как"}, {"EmptyLine"}, {"Input", 0x262626, 0x880000, "Путь"}, {"Selector", 0x262626, 0x880000, "PNG", "JPG", "PSD"}, {"EmptyLine"}, {"Button", {0xbbbbbb, 0xffffff, "OK!"}})

-- ГЛАВНЫЙ ЦИКЛ ПРОГРАММЫ --
while ( running ) do
	local e = { event.pull() }

	-- получение и обработка сообщений --
	if ( e[1] == "modem_message" ) then
		commands[ e[6] ]( e[7], e[8] )
	end

	-- обработка нажатий клавиш --
	if ( e[1] == "key_down" ) then
		control[ e[4] ]()
	end

	-- дебаг --
	gpu.set( 1, 1, computer.freeMemory() .. ' / ' .. computer.totalMemory() )
end

-- УДАЛЕНИЕ ВСЕГО НЕНУЖНОГО И ВЫХОД ИЗ ПРОГРАММЫ--
if ( tickerTimer ) then event.cancel(tickerTimer) end
button.stop()
slot.stop()
wifi.close()

--Выгрузка ненужных библиотек
package.loaded["slot"] = nil
package.loaded["button"] = nil
package.loaded["rectangle"] = nil
--package.loaded["ecs"] = nil
