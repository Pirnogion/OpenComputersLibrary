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

return rectangleAPI
