local button = require "button"
local rect = require "rectangle"

local component = require "component"
local event = require "event"
local ser = require "serialization"
local unicode = require "unicode"

local gpu = component.gpu

-- Автоматический сброс цветов при завершении программы --
local exitListener = {}
setmetatable(exitListener, {__gc = function()
	gpu.setBackground( 0x000000 )
	gpu.setForeground( 0xffffff )

	button.stop()

	package.loaded["button"] = nil
	package.loaded["rectangle"] = nil
end})

-- КОНСТАНТЫ --
local bgColor = 0xffffff
local fgColor = 0x000000

local questionsFilepath = "questions.txt"

local screenWidth, screenHeight = gpu.getResolution()

-- РАЗНОЕ --
function swap(array, index1, index2)
  array[index1], array[index2] = array[index2], array[index1]
end

function shake(array)
  local counter = #array

  while counter > 1 do
    local index = math.random(counter)

    swap(array, index, counter)		
    counter = counter - 1
  end
end

-- КНОПКИ --

--Данные о внешнем виде кнопок
local buttonDesign = {
	blink_time = 0.2,

	-- Вид кнопки в обычном состоянии --
	[0] = {
		bg = 0xCCCCCC,
		fg = 0xffffff,
		char = ' '
	},

	-- Вид кнопки в состоянии "недоступна" --
	[5] = {
		bg = 0xffffff,
		fg = 0x000000,
		char = ' '
	},

	-- Подсветка кнопки --
	[10] = {
		bg = 0xBF2008,
		fg = 0xffffff,
		char = ' '
	}
}

local buttonDesign_correct = {
	blink_time = 0.2,

	-- Вид кнопки в обычном состоянии --
	[0] = {
		bg = 0xCCCCCC,
		fg = 0xffffff,
		char = ' '
	},

	-- Вид кнопки в состоянии "недоступна" --
	[5] = {
		bg = 0xffffff,
		fg = 0x000000,
		char = ' '
	},

	-- Подсветка кнопки --
	[10] = {
		bg = 0x00911B,
		fg = 0xffffff,
		char = ' '
	}
}

-- Информация о кнопках --
local buttons = {}

local buttonWidth, buttonHeight = 20, 3
local buttonMarginX, buttonMarginY = 1, 1
local buttonClusterX, buttonClusterY = nil
local buttonClusterWidth = nil

-- РАБОТА С МАССИВОМ ВОПРОСОВ --

-- Информация о кол-ве вопросов и текущем вопросе --
local questions = nil
local randomizedQuestionIds = {}
local countQuestions = nil
local currentQuestion = 1

-- Получение массива вопросов из файла --
local function readQuestions( filename )
	local data = nil

	local file = assert( io.open(filename, "r"), "File not found!" )

	data = file:read("*a")
	questions = ser.unserialize( data )
	countQuestions = #questions

	file:close()

	-- Перемешать массив с вопросами--
	shake(questions)
end

local function initButtons()
	local _countAnswers = #questions[currentQuestion].answers

	buttonClusterWidth = buttonWidth * _countAnswers + buttonMarginX * (_countAnswers-1)
	buttonClusterX, buttonClusterY = math.floor(screenWidth/2) - math.floor(buttonClusterWidth/2), math.floor(screenHeight/2) - math.floor(buttonHeight/2) + buttonHeight

	for i, btn in ipairs(buttons) do
		btn:redraw()
	end

	for i = 1, _countAnswers, 1 do
		buttons[i] = button.create(gpu, nil, nil, nil, buttonDesign)
		buttons[i].rectangle = rect.CreateRectXYWH("", buttonClusterX + (i-1) * (buttonWidth+buttonMarginX), buttonClusterY, buttonWidth, buttonHeight)
	end
end

-- ОСНОВНАЯ ЛОГИКА --
local function update()
	local function incorrectAnswer()
		--print("incorrect")
	end

	local function correctAnswer()
		if ( currentQuestion < countQuestions) then
			currentQuestion = currentQuestion + 1

			-- Анимция исчезания --
			for i=0, 20, 1 do
				gpu.copy(buttonClusterX-1-i, buttonClusterY, buttonClusterWidth+5, buttonHeight, -i, 0)
				os.sleep(0.05)
			end

			-- Анимация появления --
			local _countAnswers = #questions[currentQuestion].answers
			local _moveStep = 10
			local _normalizedWidth = (buttonClusterWidth+buttonClusterX)-((buttonClusterWidth+buttonClusterX)%_moveStep)

			for j=0, _normalizedWidth, _moveStep do
				gpu.setBackground(0xffffff)
				gpu.fill(1, buttonClusterY, screenWidth, buttonHeight, ' ')
				for i = 1, _countAnswers, 1 do
					buttons[i].rectangle = rect.CreateRectXYWH("", buttonClusterX + (i-1) * (buttonWidth+buttonMarginX)+_normalizedWidth-j, buttonClusterY, buttonWidth, buttonHeight)
					buttons[i]:redraw()
				end
				os.sleep(0.05)
			end
		else
			currentQuestion = 1
			
			-- Перемешать массив с вопросами--
			shake(questions)
		end

		update()
	end

	local question = questions[currentQuestion]

	for i, btn in ipairs(buttons) do
		btn.text[1] = question.answers[i]
		btn.action = incorrectAnswer
		btn.design = buttonDesign

		btn:redraw()
	end

	local _correctAnswerButton = buttons[question.correctAnswer]
	if ( _correctAnswerButton ) then
		_correctAnswerButton.action = correctAnswer
		_correctAnswerButton.design = buttonDesign_correct
	end

	gpu.setBackground(bgColor)
	gpu.setForeground(fgColor)
	gpu.fill(1, screenHeight/2, screenWidth, 1, ' ')
	gpu.set( math.floor(screenWidth/2) - math.floor(unicode.len(question.question)/2), math.floor(screenHeight/2), question.question )

	-- прогресс бар --
	local progressBar = (buttonClusterWidth*(currentQuestion-1))/countQuestions

	gpu.setForeground(0xCCCCCC)
	gpu.fill( math.floor(screenWidth/2) - math.floor(buttonClusterWidth/2), math.floor(screenHeight/2)+10, buttonClusterWidth, 1, '▂' )

	gpu.setForeground(0xBF2008)
	gpu.fill( math.floor(screenWidth/2) - math.floor(buttonClusterWidth/2), math.floor(screenHeight/2)+10, progressBar, 1, '▂' )
end

-- ИНИЦИАЛИЗАЦИЯ --
gpu.setBackground(bgColor)
gpu.setForeground(fgColor)
gpu.fill(1, 1, screenWidth, screenHeight, ' ')

readQuestions( "questions.txt" )
initButtons()
update()
button.start()

-- Цикл-заглушка, чтобы прога сразу не завершалась --
while (true) do
	os.sleep(100)
end
