--[[
┌────────────────────── АВТОР ──────────────────────┐
├──────────────────── PIRNOGION ────────────────────┤
│                                                   │
│               Демопрограмма TextBox               │
│  Показывается как работать с библиотекой cursor.  │
│                                                   │
└───────────────────────────────────────────────────┘
--]]

-- Загрузка библиотек --
local component = require "component"
local cursor = require "cursor"
local event = require "event"
local term = require "term"
local unicode = require "unicode"
local keyboard = require "keyboard"

-- Загрузка компонентов --
local gpu = component.gpu
local keys = keyboard.keys

-- Очистка экрана --
local screenWidth, screenHeight = gpu.getResolution()
gpu.fill(1, 1, screenWidth, screenHeight, ' ')

-- Автоматический сброс цветов при завершении программы --
local exitListener = {}
setmetatable(exitListener, {__gc = function()
	gpu.setBackground( 0x000000 )
	gpu.setForeground( 0xffffff )

	package.loaded["cursor"] = nil
end})

-- Создание объекта --
local cursor1 = cursor.add(1, 5, 20, 4)

-- Установка позиции курсора на 1, 1 --
cursor1:set(1, 1)

-- Тест мультикурсора(случайно получившиеся фича, не юзать!) --
--local cursor2 = cursor.add(25, 4, 20, 4)
--cursor2:set(1, 3)
--cursor2.space.lines = cursor1.space.lines

-- Добавление в массив строк --
cursor1:addString("fox-bravo-pyat")
cursor1:addString("mnogo-mnogo-mnogo-mnogo-mnogo-mnogo-mnogo-mnogo-mnogo-mnogo-mnogo-mnogo-mnogo-mnogo-mnogo-mnogo")
cursor1:addString("Я ПАШУ ПОПРОСИЛ!")
cursor1:addString("DOFIGA1")
cursor1:addString("DOFIGA2")
cursor1:addString("DOFIGA3")
cursor1:addString("DOFIGA4")
cursor1:addString("DOFIGA5")
cursor1:addString("DOFIGA6")

-- Инициализация стандартного курсора --
term.setCursorBlink(true)
term.setCursor(cursor1.space.x-1 + cursor1.relative.x, cursor1.space.y-1 + cursor1.relative.y)

-- Отрисовка --
local function redraw(ucursor)
	gpu.fill(ucursor.space.x, ucursor.space.y, ucursor.space.width, ucursor.space.height, ' ')

	local startDrawLinePos = ucursor.delta.y+1
	local endDrawLinePos = ucursor.space.height+ucursor.delta.y
	for i = startDrawLinePos, endDrawLinePos, 1 do
		local croppedLine = unicode.sub(ucursor.space.lines[i] or "", ucursor.delta.x+1, ucursor.space.width+ucursor.delta.x)
		gpu.set(ucursor.space.x, ucursor.space.y-1+i-ucursor.delta.y, croppedLine )
	end
end

-- Дебаг
local function debug()
	gpu.set( 1, 1, tostring("ACur: " .. cursor1.absolute.x .. ":" .. cursor1.absolute.y) )
	gpu.set( 1, 2, tostring("RCur: " .. cursor1.relative.x .. ":" .. cursor1.relative.y) )
	gpu.set( 1, 3, tostring("DCur: " .. cursor1.delta.x .. ":" .. cursor1.delta.y) )
end

-- Цикл обработки событий --
local userInput = 
{
	[keys.right] = function()
		cursor1:move(1, 0)
	end,

	[keys.left] = function()
		cursor1:move(-1, 0)
	end,

	[keys.up] = function()
		cursor1:move(0, -1)
	end,

	[keys.down] = function()
		cursor1:move(0, 1)
	end,

	[keys.back] = function()
		if ( cursor1:onHomeLine() ) then
			cursor1:concatLine()
		else
			cursor1:removeChar()
		end
	end,

	[keys.enter] = function()
		cursor1:splitLine()
	end,

	[keys.home] = function()
		cursor1:moveHome()
		cursor1:calculate()
	end,

	[keys["end"]] = function()
		cursor1:moveEnd()
		cursor1:calculate()
	end,
}
-- Нажата любая другая клавиша
setmetatable( userInput, {__index = function() return function() end end} )

while (true) do
	redraw(cursor1)
	debug()

	-- Обработка пользовательского ввода --
	local e = { event.pull("key_down") }
	userInput[ e[4] ]()

	--Выход из программы по нажатию левого Ctrl
	if (e[4] == keys.lcontrol) then
		break
	--Написать символ, если он не служебный
	elseif not keyboard.isControl( e[3] ) then
		cursor1:insertChar( unicode.char(e[3]) )
	end

	--Установка стандартного курсора в нужную позицию
	term.setCursor(cursor1.space.x-1 + cursor1.relative.x, cursor1.space.y-1 + cursor1.relative.y)
end
