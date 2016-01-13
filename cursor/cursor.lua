--[[
┌────────────────────── АВТОР ──────────────────────┐
├──────────────────── PIRNOGION ────────────────────┤
│                                                   │
│                 Библиотека Cursor                 │
│                        ---                        │
│                                                   │
└───────────────────────────────────────────────────┘
--]]

--[[
Описание функций библиотеки cursor:
	1. Служебное:
		1.1. range(_, bottom:number, top:number, value:number, step:number):number
		1.2. isPositive(_, value:number):boolean
		1.3. isPositive_zero(_, value:number):number or boolean

	2. Функции библиотеки:
		2.1. cursor.add([x:number, y:number, width:number, height:number]):table
			создает и инциализирует объект cursor, который содержит информацию о местоположении курсора,
			размере и положении поля ввода и массив с обрабатываемыми строками.
			Возвращает готовый объект.

		2.2. addString(value:string, [position:number]):nil
			добавляет строку value в массив строк в позицию position(если не указано, то вставляет строку в конец).
			Кроме того функция вызывает перерасчет позиции курсора.

		2.3. removeString([position:number]):nil
			удаляет из массива строку строку в позиции position(если не указано, то удаляется последняя строка).
			Вызывает перерасчет позиции курсора.

		2.4. replaceString(value:string, [position:number]):nil
			заменяет строку в позиции position(если не указано, то заменяет последнюю строку) на строку value. 
			Вызывает перерасчет позиции курсора.

		2.5. insertChar(value:string):nil
			вставляет строку value в разрыв строки на которой находится курсор.
			Вызывает перерасчет позиции курсора.

		2.6. replaceChar(value:string):nil
			заменяет символ в позиции курсора на строку value.
			Вызывает перерасчет позиции курсора.

		2.7. removeChar():nil
			удаляет символ в позиции курсора.
			Вызывает перерасчет позиции курсора.

		2.8. splitLine():nil
			разрывает строку в позиции курсора и переносит вторую разорванную часть на новую строку.
			Вызывает перерасчет позиции курсора.

		2.9. concatLine():nil
			соединяет текущую строку с предыдущей.
			Вызывает перерасчет позиции курсора.

		2.10. cursor:onEndLine():boolean
			проверяет, находится ли курсор в конце строки. Если да, то возвращается true, а false в противном случае.

		2.11. cursor:onHomeLine():boolean
			проверяет, находится ли курсор в начале строки. Если да, то возвращается true, а false в противном случае.

		2.12. cursor:onBottom():boolean
			проверяет, находится ли курсор на последней строке. Если да, то возвращается true, а false в противном случае.

		2.13. cursor:onTop():boolean
			проверяет, находится ли курсор на первой строке. Если да, то возвращается true, а false в противном случае.

		2.14. cursor:checkLine(step:number):boolean, boolean
			проверяет, сможет ли курсор переместиться на step шагов.
			Возвращет true, если возможно, а false в противном случае.
			Второе возвращаемое значение говорит о том, меньше ли текущая строка проверяемой строки.

		2.14. set(absolute_x:number, absolute_y:number):nil
			устанавливает курсор в абсолютную позицию x, y.
			Вызывает перерасчет позиции курсора.

		2.15. move(step_x:number, step_y:number):nil
			перемещает курсор на x, y шагов, если это возможно.
			Вызывает перерасчет позиции курсора.

		2.16. cursor:moveHome():nil
			перемещает курсор на начало текущей строки.

		2.17. cursor:moveEnd():nil
			перемещает курсор в конец текущей строки.

		2.18. cursor:moveHomeNextLine(step:number):nil
			перемещает курсор на начало следующей строки, если это возможно.

		2.19. cursor:moveEndNextLine(step:number):nil
			перемещает курсор в конец следующей строки, если это возможно.

		2.20. cursor:moveEndPrevLine(step:number):nil
			перемещает курсор в конец предыдущей строки, если это возможно.
--]]

local unicode = require "unicode"

-- РАЗНОЕ --
local function range(_, bottom, top, value, step)
	if ( value + step > top ) then
		return top
	elseif ( value + step < bottom ) then
		return bottom
	end

	return value + step
end

local function isPositive(_, value)
	return value == math.abs(value)
end

local function isPositive_zero(_, value)
	return ( value == 0 and 0 ) or value == math.abs(value)
end

-- ОСНОВНАЯ ЛОГИКА --
local cursor = {}

-- СОЗДАНИЕ НОВОГО КУРСОРА --
function cursor.add(x, y, width, height)
	cursor = {}

	cursor.absolute = {}
	cursor.absolute.x = 1
	cursor.absolute.y = 1
	cursor.absolute.prev = {}
	cursor.absolute.prev.x = 1
	cursor.absolute.prev.y = 1

	cursor.relative = {}
	cursor.relative.x = 1
	cursor.relative.y = 1
	cursor.relative.prev = {}
	cursor.relative.prev.x = 1
	cursor.relative.prev.y = 1

	cursor.delta = {}
	cursor.delta.x = 0
	cursor.delta.y = 0
	cursor.delta.prev = {}
	cursor.delta.prev.x = 0
	cursor.delta.prev.y = 0

	cursor.space = {}
	cursor.space.x = x or 1
	cursor.space.y = y or 1
	cursor.space.width = width or 10
	cursor.space.height = height or 10

	--[[
		lines = {
			len_string,
			len_string,
			...
			len_string
		}
	]]--
	cursor.space.lines = {}

	function cursor:addString(value, position)
		if ( position ) then
			table.insert( self.space.lines, position, value )
		else
			table.insert( self.space.lines, value )
		end

		if ( self.absolute.x > unicode.len(self.space.lines[self.absolute.y]) ) then
			self:moveEnd()
			self:calculate()
		end
	end

	function cursor:removeString(position)
		if ( unicode.len(self.space.lines) > 1 ) then
			table.remove( self.space.lines, position )

			self.absolute.prev.y = self.absolute.y
			if ( self:onBottom() ) then
				self.absolute.y = unicode.len(self.space.lines)
			end
			if ( self.absolute.x > unicode.len(self.space.lines[self.absolute.y]) ) then
				self:moveEnd()
			end
		else
			self.space.lines[self.absolute.y] = ""
			self:moveHome()
		end

		self:calculate()
	end

	function cursor:replaceString(value, position)
		self.space.lines[position or self.absolute.y] = tostring(value)

		if ( self.absolute.x > unicode.len(self.space.lines[self.absolute.y]) ) then
			self:moveEnd()
			self:calculate()
		end
	end

	function cursor:insertChar(value)
		local line = self.space.lines[self.absolute.y]
		self.space.lines[self.absolute.y] = unicode.sub( line, 1, self.absolute.x-1 ) .. value .. unicode.sub( line, self.absolute.x, -1 )

		self:move(1, 0)
	end

	function cursor:replaceChar(value)
		local line = self.space.lines[self.absolute.y]
		self.space.lines[self.absolute.y] = unicode.sub(line, 1, self.absolute.x-1) .. value .. unicode.sub(line, self.absolute.x+1, -1)

		self:move(1, 0)
	end

	function cursor:removeChar()
		if ( not self:onHomeLine() ) then
			local line = self.space.lines[self.absolute.y]
			self.space.lines[self.absolute.y] = unicode.sub(line, 1, self.absolute.x-2) .. unicode.sub(line, self.absolute.x, -1)

			self:move(-1, 0)
		end
	end

	function cursor:splitLine()
		local line = self.space.lines[self.absolute.y]
		self.space.lines[self.absolute.y] = unicode.sub(line, 1, self.absolute.x-1)
		table.insert(self.space.lines, self.absolute.y+1, unicode.sub(line, self.absolute.x, -1))

		self:moveHomeNextLine(1)
		self:calculate()
	end

	function cursor:concatLine()
		if ( not self:onTop() ) then
			self:moveEndPrevLine(-1)
			self.space.lines[self.absolute.y] = self.space.lines[self.absolute.y] .. self.space.lines[self.absolute.y+1]

			table.remove(self.space.lines, self.absolute.y+1)

			self:calculate()
		end
	end

	function cursor:onEndLine()
		return self.absolute.x == unicode.len(self.space.lines[self.absolute.y]) + 1
	end

	function cursor:onHomeLine()
		return self.absolute.x == 1
	end

	function cursor:onBottom()
		return self.absolute.y >= #self.space.lines
	end

	function cursor:onTop()
		return self.absolute.y == 1
	end

	function cursor:checkLine(step)
		local lineExist = self.space.lines[self.absolute.y+step] ~= nil
		local lineLessCurrent = nil
		if ( lineExist ) then
			lineLessCurrent = unicode.len(self.space.lines[self.absolute.y+step]) < unicode.len(self.space.lines[self.absolute.y])
			lineLessCurrent = lineLessCurrent and self.absolute.x > unicode.len(self.space.lines[self.absolute.y+step])
		end

		return lineExist, lineLessCurrent
	end

	function cursor:calculate()
		self.relative.prev.x = self.relative.x
		self.relative.prev.y = self.relative.y
		self.relative.x = math.max( math.min(self.relative.x, self.space.width), 1 )
		self.relative.y = math.max( math.min(self.relative.y, self.space.height), 1 )

		self.delta.prev.x = self.delta.x
		self.delta.prev.y = self.delta.x
		self.delta.x = self.absolute.x - self.relative.x
		self.delta.y = self.absolute.y - self.relative.y
	end

	function cursor:set(absolute_x, absolute_y)
		self.absolute.prev.x = self.absolute.x
		self.absolute.prev.y = self.absolute.y

		self.absolute.x = absolute_x
		self.absolute.y = absolute_y

		self.relative.prev.x = self.relative.x
		self.relative.prev.y = self.relative.y

		self.relative.x = absolute_x
		self.relative.y = absolute_y

		self:calculate()
	end

	function cursor:move(step_x, step_y)
		local stepY_positive = isPositive_zero(nil, step_y)
		
		if ( stepY_positive ~= 0 ) then
			local action = ( stepY_positive ) and self.moveEndNextLine or self.moveEndPrevLine

			local exist, less = self:checkLine(step_y)
			if ( exist and less ) then
				action(self, step_y)
			elseif ( exist ) then
				self.absolute.prev.y = self.absolute.y
				self.absolute.y = self.absolute.y + step_y

				self.relative.prev.y = self.relative.y
				self.relative.y = self.relative.y + step_y
			end
		end

		local stepX_positive = isPositive_zero(nil, step_x)
		if ( stepX_positive == true and self:onEndLine() and not self:onBottom() ) then
			self.absolute.prev.y = self.absolute.y
			self.absolute.y = self.absolute.y + 1

			self.relative.prev.y = self.relative.y
			self.relative.y = self.relative.y + 1

			self:moveHome()
		elseif ( stepX_positive == false and self:onHomeLine() and not self:onTop() ) then
			self.absolute.prev.y = self.absolute.y
			self.absolute.y = self.absolute.y - 1

			self.relative.prev.y = self.relative.y
			self.relative.y = self.relative.y - 1

			self:moveEnd()
		elseif ( stepX_positive ~= 0 ) then
			self.absolute.prev.x = self.absolute.x
			self.absolute.x = range(_, 1, unicode.len(self.space.lines[self.absolute.y]) + 1, self.absolute.x, step_x)

			self.relative.prev.x = self.relative.x
			self.relative.x = self.relative.x + step_x
		end

		self:calculate()
	end

	function cursor:moveHome()
		if ( self.space.lines[self.absolute.y] ) then
			self.absolute.prev.x = self.absolute.x
			self.absolute.x = 1

			self.relative.prev.x = self.relative.x
			self.relative.x = 1
		end
	end

	function cursor:moveEnd()
		if ( self.space.lines[self.absolute.y] ) then
			self.absolute.prev.x = self.absolute.x
			self.absolute.x = unicode.len(self.space.lines[self.absolute.y]) + 1

			self.relative.prev.x = self.relative.x
			self.relative.x = self.absolute.x
		end
	end

	function cursor:moveHomeNextLine(step)
		if ( self.space.lines[self.absolute.y+step] ) then
			self.absolute.prev.y = self.absolute.y
			self.absolute.y = self.absolute.y + step

			self.absolute.prev.x = self.absolute.x
			self.absolute.x = 1

			self.relative.prev.y = self.relative.y
			self.relative.y = self.absolute.y

			self.relative.prev.x = self.relative.x
			self.relative.x = 1
		end
	end

	function cursor:moveEndNextLine(step)
		if ( self.space.lines[self.absolute.y+step] ) then
			self.absolute.prev.y = self.absolute.y
			self.absolute.y = self.absolute.y + step

			self.absolute.prev.x = self.absolute.x
			self.absolute.x = unicode.len(self.space.lines[self.absolute.y]) + 1

			self.relative.prev.y = self.relative.y
			self.relative.y = self.absolute.y

			self.relative.prev.x = self.relative.x
			self.relative.x = self.absolute.x
		end
	end

	function cursor:moveEndPrevLine(step)
		if ( self.space.lines[self.absolute.y+step] ) then
			self.absolute.prev.y = self.absolute.y
			self.absolute.y = self.absolute.y + step

			self.absolute.prev.x = self.absolute.x
			self.absolute.x = unicode.len(self.space.lines[self.absolute.y]) + 1

			self.relative.prev.y = self.relative.y
			self.relative.y = self.absolute.y

			self.relative.prev.x = self.relative.x
			self.relative.x = self.absolute.x
		end
	end

	return cursor
end

return cursor
