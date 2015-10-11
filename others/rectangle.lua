local rectangleAPI = {}

--Создание прямоугольника по координатам его верхней левой точки основываясь на ширине и высоте.
function rectangleAPI.CreateRectXYWH(name, x, y, width, height)
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

	return _rectangle
end

--Создание прямоугольника по координатам его верхней левой точки и нижней правой.
function rectangleAPI.CreateRectXYXY(name, sx, sy, ex, ey)
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

	return _rectangle
end

--Описание структуры прямоугольника - пустой прямоугольник.
function rectangleAPI.CreateVoidRect(name)
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

	return _rectangle
end

--Находится ли заданная точка внутри прямоугольника.
function rectangleAPI.PointInRectFree(x, y, sx, sy, ex, ey)
        if (x >= sx) and (x <= ex) and (y >= sy) and (y <= ey) then return true end    
        return false
end

--Находится ли заданная точка внутри прямоугольника. С использованием структуры "прямоугольник".
function rectangleAPI.PointInRect(x, y, rect)
        if (x >= rect.sx) and (x <= rect.ex) and (y >= rect.sy) and (y <= rect.ey) then return true end    
        return false
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
function rectangleAPI.IntersectRects(rect1, rect2)
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

return rectangleAPI
