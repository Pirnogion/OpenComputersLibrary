-- ПОДКЛЮЧЕНИЕ СТАНДАРТНЫХ БИБЛИОТЕК --
local component = require "component"
local computer = require "computer"
local unicode = require "unicode"
local event = require "event"
local ser = require "serialization"

-- ПОДКЛЮЧЕНИЕ ВНЕШНИХ БИБЛИОТЕК --
local ecs = require "ecs"

-- ПОЛУЧЕНИЕ КОМПАНЕНТОВ --
local wifi = component.modem
local gpu = component.gpu

-- ЦВЕТОВАЯ СХЕМА --
local COLOR_SCHEME = 
{
	workspace = {
		bg = 0xFFFFFF,
		fg = 0x000000
	},

	header = {
		bg = 0xEAEAEA,
		fg = 0x000000
	},

	robot_list = {
		selected = 0xFF863B,

		bg1 = 0xD6D6D6,
		bg2 = 0x424242,
		fg = 0x424242
	},

	button = {
		active = {
			bg = 0xD6D6D6
		},

		inactive = {
			bg = 0x424242
		}
	},

	bevel = {
		topfg = 0xC5C5C5,
		bottomfg = 0xA5A5A5
	},

	status = {
		connect_ok = 0x00911B,
		connect_er = 0xBF2008
	}
}

-- ??? --
local running = true
local port = 1

local prevSelectedItem = nil
local aviableRobots = {}

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
--local workspaceRect = rect.CreateRectXYWH("ScreenBound", 1, 7, screenWidth, screenHeight-6)
gpu.setResolution( screenWidth, screenHeight )

-- ФУНКЦИИ --
function pointInRectFree(x, y, sx, sy, ex, ey)
        if (x >= sx) and (x <= ex) and (y >= sy) and (y <= ey) then return true end    
        return false
end

local connectAnimationTimer = nil
local function connectAnimation()
	print(1)
end

local infoPanelStartY = 12
local infoPanelHeight = 8
local maxPanels = 4
local offset = 0
local shift = infoPanelHeight+1
local function drawRobotInfo()
	gpu.setBackground( COLOR_SCHEME.robot_list.bg1 )
	gpu.fill( screenWidth/2-5, 8, 11, 3, ' ' )
	gpu.set( screenWidth/2, 9, '▲' )

	gpu.fill( screenWidth/2-5, screenHeight-2, 11, 3, ' ' )
	gpu.set( screenWidth/2, screenHeight-1, '▼' )
	for i=0, math.min(maxPanels-1, #aviableRobots-1-offset), 1 do

		--Нарисовать ленту
		gpu.setBackground( COLOR_SCHEME.robot_list.bg1 )
		gpu.fill(1, infoPanelStartY+shift*i, screenWidth, infoPanelHeight, ' ' )

		--Нарисовать "объем" ленты
		gpu.setForeground( COLOR_SCHEME.bevel.topfg )
		gpu.fill(1, infoPanelStartY+shift*i, screenWidth, 1, '▀' )
		gpu.setForeground( COLOR_SCHEME.bevel.bottomfg )
		gpu.fill(1, infoPanelStartY+7+shift*i, screenWidth, 1, '▄' )

		--Вывод информации о роботе
		gpu.setForeground( COLOR_SCHEME.robot_list.fg )
		gpu.set(17, infoPanelStartY+1+shift*i, 'Название робота:      ' .. aviableRobots[i+1+offset].name)
		gpu.set(17, infoPanelStartY+2+shift*i, 'Адрес робота:         ' .. aviableRobots[i+1+offset].address)
		gpu.set(17, infoPanelStartY+3+shift*i, 'Контроллер инвентаря: ' .. tostring(aviableRobots[i+1+offset].inventory_controller))
		gpu.set(17, infoPanelStartY+4+shift*i, 'Разрешение от робота: ' .. tostring(aviableRobots[i+1+offset].access))		

		--Вывод информации о возможности подключения
		if ( aviableRobots[i+1+offset].inventory_controller and aviableRobots[i+1+offset].access ) then
			gpu.set(17, infoPanelStartY+6+shift*i, 'ПОДКЛЮЧЕНИЕ ВОЗМОЖНО!')
			gpu.setBackground( COLOR_SCHEME.status.connect_ok )
			gpu.setForeground( COLOR_SCHEME.workspace.bg )
			gpu.fill(3, infoPanelStartY+1+shift*i, 12, 6, ' ')
			gpu.set(8, infoPanelStartY+3+shift*i, "▶⯁")
			gpu.set(5, infoPanelStartY+4+shift*i, "ПОДКЛЮЧ.")

			gpu.setForeground( COLOR_SCHEME.workspace.fg )
		else
			gpu.set(17, infoPanelStartY+6+shift*i, 'ПОДКЛЮЧЕНИЕ НЕВОЗМОЖНО!')
			gpu.setBackground( COLOR_SCHEME.status.connect_er)
			gpu.setForeground( COLOR_SCHEME.workspace.bg )
			gpu.fill(3, infoPanelStartY+1+shift*i, 12, 6, ' ')
			gpu.set(8, infoPanelStartY+3+shift*i, "❌")
			gpu.set(4, infoPanelStartY+4+shift*i, "НЕВОЗМОЖНО")

			gpu.setForeground( COLOR_SCHEME.workspace.fg )
		end
	end
end

local robotFinderTimer = nil
local robotFinderMaxTime = 4 --secs
local robotFinderTime = 0 --secs
local function robotFinder()
	if ( robotFinderTime == 0 ) then wifi.broadcast( port, "robot.access" ) end
	robotFinderTime = robotFinderTime + 1

	local line = (100*robotFinderTime)/robotFinderMaxTime

	gpu.setBackground(0x00911B)
	gpu.fill(screenWidth/2-50, screenHeight/2+10, line, 1, ' ' )
	if ( robotFinderTime >= robotFinderMaxTime and #aviableRobots == 0 ) then
		local result = ecs.universalWindow("auto", "auto", 50, ecs.windowColors.background, true, {"EmptyLine"}, {"CenterText", 0x262626, "РОБОТОВ НЕ НАЙДЕНО"}, {"CenterText", 0x262626, "ПОВТОРИТЬ ПОПЫТКУ?"}, {"EmptyLine"}, {"Button", {0xbbbbbb, 0xffffff, "ДА"}}, {"Button", {0xbbbbbb, 0xffffff, "НЕТ"}})
		if ( result and result[1] == "ДА" ) then
			robotFinderTime = 0
			robotFinderTimer = event.timer(1, robotFinder, robotFinderMaxTime)

			gpu.setBackground(0xC5C5C5)
			gpu.setForeground(0x424242)
			gpu.fill(screenWidth/2-50, screenHeight/2+10, 100, 1, ' ' )
		else
			running = false
		end
	elseif ( robotFinderTime >= robotFinderMaxTime and #aviableRobots > 0 ) then
		gpu.setBackground( COLOR_SCHEME.workspace.bg )
		gpu.fill( 1, 8, screenWidth, screenHeight, ' ' )
		drawRobotInfo()
	end
end

-- ИНИЦИАЛИЗАЦИЯ --
gpu.setBackground( COLOR_SCHEME.workspace.bg )
gpu.fill( 1, 1, screenWidth, screenHeight, ' ' )

gpu.setBackground( COLOR_SCHEME.header.bg )
gpu.setForeground( 0x424242 )
gpu.fill( 1, 1, screenWidth, 7, ' ' )
gpu.set(3, 3, 'ПЕРВОНАЧАЛЬНАЯ КОНФИГУРАЦИЯ')
gpu.set(6, 4, 'установка соединения и настройка')
gpu.setForeground( 0xA5A5A5 )
gpu.fill(1, 7, screenWidth, 1, '▄' )

--▄ ▀ █
gpu.setBackground( COLOR_SCHEME.robot_list.bg1 )
gpu.fill(screenWidth/2-10, screenHeight/2-5, 20, 10, ' ' )
gpu.set(screenWidth/2-10, screenHeight/2-5+0, '                    ')
gpu.set(screenWidth/2-10, screenHeight/2-5+1, '                    ')
gpu.set(screenWidth/2-10, screenHeight/2-5+2, '          ▄▀▀▀▄     ')
gpu.set(screenWidth/2-10, screenHeight/2-5+3, '         █     █    ')
gpu.set(screenWidth/2-10, screenHeight/2-5+4, '         ▀▄   ▄▀    ')
gpu.set(screenWidth/2-10, screenHeight/2-5+5, '       ▄██ ▀▀▀      ')
gpu.set(screenWidth/2-10, screenHeight/2-5+6, '     ▄██▀           ')
gpu.set(screenWidth/2-10, screenHeight/2-5+7, '     ▀▀             ')
gpu.set(screenWidth/2-10, screenHeight/2-5+8, '                    ')
gpu.set(screenWidth/2-10, screenHeight/2-5+9, '                    ')

gpu.setBackground(0xC5C5C5)
gpu.setForeground(0x424242)
gpu.fill(screenWidth/2-50, screenHeight/2+10, 100, 1, ' ' )

gpu.setBackground(0xFFFFFF)
gpu.set(screenWidth/2-6, screenHeight/2+9, 'ПОИСК РОБОТОВ' )

robotFinderTimer = event.timer(1, robotFinder, robotFinderMaxTime)

--ecs.universalWindow("auto", "auto", 20, ecs.windowColors.background, true, {"EmptyLine"}, {"CenterText", 0x262626, "Введите порт"}, {"EmptyLine"}, {"Input", 0x262626, 0x880000, "25565"}, {"Button", {0xbbbbbb, 0xffffff, "НАЧАТЬ ПОИСК РОБОТОВ"}})
--ecs.universalWindow("auto", "auto", 30, ecs.windowColors.background, true, {"EmptyLine"}, {"CenterText", 0x262626, "Сохранить как"}, {"EmptyLine"}, {"Input", 0x262626, 0x880000, "Путь"}, {"Selector", 0x262626, 0x880000, "PNG", "JPG", "PSD"}, {"EmptyLine"}, {"Button", {0xbbbbbb, 0xffffff, "OK!"}})

-- ГЛАВНЫЙ ЦИКЛ ПРОГРАММЫ --
while ( running ) do
	local e = { event.pull() }

	-- получение и обработка сообщений --
	if ( e[1] == "modem_message" ) then
		if ( e[6] == "server.access.allow" ) then
			local robotInfo =
			{ 
				name = e[8],
				access = true,
				address = e[3],
				inventory_controller = e[7]
			}

			for i=1, #aviableRobots, 1 do
				if ( aviableRobots[i].address == e[3] ) then
					goto EXIT
				end
			end

			table.insert( aviableRobots, robotInfo )

			::EXIT::
		end
	end

	-- обработка нажатий клавиш --
	if ( e[1] == "key_down" ) then
		if ( e[4] == 200 ) then
			offset = (offset - 1) % #aviableRobots
			gpu.setBackground( COLOR_SCHEME.workspace.bg )
			gpu.fill( 1, 8, screenWidth, screenHeight, ' ' )
			drawRobotInfo()
		elseif ( e[4] == 208 ) then
			offset = (offset + 1) % #aviableRobots
			gpu.setBackground( COLOR_SCHEME.workspace.bg )
			gpu.fill( 1, 8, screenWidth, screenHeight, ' ' )
			drawRobotInfo()
		else
			break
		end
	end

	if ( e[1] == "touch" and e[5] == 0 ) then
		for i=0, math.min(maxPanels-1, #aviableRobots-1-offset), 1 do
			if ( aviableRobots[i+1].access and aviableRobots[i+1].inventory_controller and pointInRectFree(e[3], e[4], 3, infoPanelStartY+1+shift*i, 14, infoPanelStartY+6+shift*i) ) then
				local f = io.open("c.cfg", "wb")
				f:write("return\n{\n	address = \"" .. aviableRobots[i+1].address .. "\",\n}")
				f:close()

				wifi.send( aviableRobots[i+1].address, port, "robot.receive.address", aviableRobots[i+1].address )

				ecs.universalWindow("auto", "auto", 50, ecs.windowColors.background, true, {"EmptyLine"}, {"CenterText", 0x262626, "КОНФИГУРАЦИЯ УСПЕШНО ПРОЙДЕНА!"}, {"EmptyLine"}, {"Button", {0xbbbbbb, 0xffffff, "OK"}})

				running = false
				break
			end
		end

		if ( pointInRectFree(e[3], e[4], screenWidth/2-5, 8, screenWidth/2+6, 11) ) then
			offset = (offset - 1) % #aviableRobots
			gpu.setBackground( COLOR_SCHEME.workspace.bg )
			gpu.fill( 1, 8, screenWidth, screenHeight, ' ' )
			drawRobotInfo()
		elseif ( pointInRectFree(e[3], e[4], screenWidth/2-5, screenHeight-2, screenWidth/2+6, screenHeight+1) ) then
			offset = (offset + 1) % #aviableRobots
			gpu.setBackground( COLOR_SCHEME.workspace.bg )
			gpu.fill( 1, 8, screenWidth, screenHeight, ' ' )
			drawRobotInfo()
		end
	end

	-- дебаг --
	gpu.set( 1, 1, computer.freeMemory() .. ' / ' .. computer.totalMemory() )
end

-- УДАЛЕНИЕ ВСЕГО НЕНУЖНОГО И ВЫХОД ИЗ ПРОГРАММЫ--
if ( robotFinderTimer ) then event.cancel(robotFinderTimer) end
wifi.close()

--Выгрузка ненужных библиотек
package.loaded["ecs"] = nil

-- ??? --
gpu.setBackground(0)
gpu.setForeground(0xFFFFFF)
gpu.fill(1, 1, screenWidth, screenHeight, ' ')
