-- Автор: Pirnogion --

local rectangleAPI = {}

--Метаиаблица. Требуется для отслеживания доступа к структурам и облегчения работы с ним.
local unique_key = {}
local metatable = {
	__index = function(table, key)
		return table[unique_key][key]
	end,

	__newindex = function(table, key, value)
		--Перерасчет струтуры
		if ( table[unique_key][key] ~= value ) then
			table[unique_key][key] = value

			--Практика китайского кода
			if ( key == "sx" ) then
				table[unique_key]["width"] = math.abs(table[unique_key]["ex"]-value)
				table[unique_key]["area"] = table[unique_key]["width"] * table[unique_key]["height"]
			elseif ( key == "sy" ) then
				table[unique_key]["width"] = math.abs(table[unique_key]["width"]-value)
				table[unique_key]["area"] = table[unique_key]["width"] * table[unique_key]["height"]
			elseif ( key == "ex" ) then
				table[unique_key]["width"] = math.abs(value-table[unique_key]["sx"])
				table[unique_key]["area"] = table[unique_key]["width"] * table[unique_key]["height"]
			elseif ( key == "ey" ) then
				table[unique_key]["width"] = math.abs(value-table[unique_key]["sy"])
				table[unique_key]["area"] = table[unique_key]["width"] * table[unique_key]["height"]
			elseif ( key == "width" ) then
				table[unique_key]["ex"] = table[unique_key]["sx"]+value
				table[unique_key]["area"] = value * table[unique_key]["height"]
			elseif ( key == "height" ) then
				table[unique_key]["ey"] = table[unique_key]["sy"]+value
				table[unique_key]["area"] = table[unique_key]["width"] * value
			elseif ( key == "name" ) then
				table[unique_key][key] = value
			end
		end
	end,

	__pairs = function(table)
		return function(table, key)
			return next(table[unique_key], key)
		end, table
	end,

	__metatable = "This metatable is protected!"
}

local function track(source_table)
	local proxy_table = {}
	proxy_table[unique_key] = source_table
	setmetatable(proxy_table, metatable)

	return proxy_table
end

--Создание прямоугольника по координатам его верхней левой точки основываясь на ширине и высоте.
function rectangleAPI.createRectXYWH(name, x, y, width, height)
	local _rectangle = {
		["name"] = name,
		["sx"] = x,
		["sy"] = y,
		["ex"] = x+width,
		["ey"] = y+height,
		["width"] = width,
		["height"] = height,
		["area"] = width * height
	}

	return track( _rectangle )
end

--Создание прямоугольника по координатам его верхней левой точки и нижней правой.
function rectangleAPI.createRectXYXY(name, sx, sy, ex, ey)
	local _w, _h = math.abs(ex-sx), math.abs(ey-sy)

	local _rectangle = {
		["name"] = name,
		["sx"] = sx,
		["sy"] = sy,
		["ex"] = ex,
		["ey"] = ey,
		["width"] = _w,
		["height"] = _h,
		["area"] = _w * _h
	}

	return track( _rectangle )
end

--Описание структуры прямоугольника - пустой прямоугольник.
function rectangleAPI.createVoidRect(name)
	local _rectangle = {
		["name"] = name,
		["sx"] = 0,
		["sy"] = 0,
		["ex"] = 0,
		["ey"] = 0,
		["width"] = 0,
		["height"] = 0,
		["area"] = 0
	}

	return track( _rectangle )
end

--Копирование прямоугольника.
function rectangleAPI.copyRect(rect)
	local _rectangle = {
		["name"] = rect.name,
		["sx"] = rect.sx,
		["sy"] = rect.sy,
		["ex"] = rect.ex,
		["ey"] = rect.ey,
		["width"] = rect.width,
		["height"] = rect.height,
		["area"] = rect.area
	}

	return track( _rectangle )
end

--Перемещение структуры от левой верхней точки.
function rectangleAPI.moveNXY(rect, nsx, nsy)
	rect.ex = rect.ex + ( nsx - rect.sx )
	rect.ey = rect.ey + ( nsy - rect.sy )

	rect.sx = nsx
	rect.sy = nsy
end

--Изменение левой верхней точки и переасчет структуры.
function rectangleAPI.recalculateNSXY(rect, nsx, nsy)
	rect.sx, rect.sy = nsx, nsy
	rect.width, rect.height = math.abs(ex-sx), math.abs(ey-sy)
	rect.area = rect.width * rect.height
end

--Изменение левой верхней точки и переасчет структуры.
function rectangleAPI.recalculateNEXY(rect, nex, ney)
	rect.ex, rect.ey = nex, ney
	rect.width, rect.height = math.abs(ex-sx), math.abs(ey-sy)
	rect.area = rect.width * rect.height
end

--Изменение высоты и ширины и переасчет структуры.
function rectangleAPI.recalculateWH(rect, nwidth, nheight)
	if ( nwidth ) then
		rect.width = nwidth
		rect.ex = rect.sx+nwidth
	end

	if ( nheight ) then
		rect.height = nheight
		rect.ey = rect.sy+nheight
	end

	rect.area = rect.height * rect.width
end

--Находится ли заданная точка внутри прямоугольника.
function rectangleAPI.pointInRectRaw(x, y, sx, sy, ex, ey)
        if (x >= sx) and (x <= ex) and (y >= sy) and (y <= ey) then return true end    
        return false
end

--Находится ли заданная точка внутри прямоугольника. С использованием структуры "прямоугольник".
function rectangleAPI.pointInRect(x, y, rect)
        if (x >= rect.sx) and (x <= rect.ex) and (y >= rect.sy) and (y <= rect.ey) then return true end    
        return false
end

--Находится ли данный прямоугольник полностью внутри другого прямоугольника.
function rectangleAPI.rectInRect(rect1, rect2)
	return (rect1.sx >= rect2.sx) and (rect1.sy >= rect2.sy) and (rect1.ex+1 <= rect2.ex) and (rect1.ey+1 <= rect2.ey)
end

--Проверка двух прямоугольников на пересечение. Возвращает true - если пересеклись, false - в противном случае.
function rectangleAPI.bIntersectRects(rect1, rect2)
    --Мерзкое и отвратительное условие - придумать новое!
	local intersectCondition =
		rectangleAPI.PointInRect(rect2.sx, rect2.sy, rect1) or rectangleAPI.PointInRect(rect2.ex, rect2.ey, rect1) or
		rectangleAPI.PointInRect(rect1.sx, rect1.sy, rect2) or rectangleAPI.PointInRect(rect1.ex, rect1.ey, rect2) or
		rectangleAPI.PointInRect(rect2.sx+rect2.width, rect2.sy, rect1) or rectangleAPI.PointInRect(rect2.ex-rect2.width, rect2.ey, rect1) or
		rectangleAPI.PointInRect(rect1.sx+rect1.width, rect1.sy, rect2) or rectangleAPI.PointInRect(rect1.ex-rect1.width, rect1.ey, rect2)

	return intersectCondition
end

--Проверка двух прямоугольников на пересечение. Возвращает прямоугольник образованный пересечением двух заданных.
function rectangleAPI.intersectRects(rect1, rect2)
	local _rect3 = rectangleAPI.CreateVoidRect(rect1.name .. ":" .. rect2.name)

	if ( rectangleAPI.bIntersectRects(rect1, rect2) ) then
		_rect3.sy = math.max(rect1.sy, rect2.sy)
        _rect3.sx = math.max(rect1.sx, rect2.sx)
        _rect3.ey = math.min(rect1.ey, rect2.ey)
        _rect3.ex = math.min(rect1.ex, rect2.ex)

        _rect3.width = math.abs(_rect3.ex - _rect3.sx)
        _rect3.height = math.abs(_rect3.ey - _rect3.sy)
        _rect3.area = _rect3.width * _rect3.height
    end

	return _rect3
end

--Вычисляет наиболее благоприятную сторону для вытеснения одного прямоугольника из другого(запланировано).
function rectangleAPI.calculatePushDirection( rect1, rect2 )
	return nil
end

return rectangleAPI
