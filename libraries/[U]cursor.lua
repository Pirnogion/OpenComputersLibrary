local function range(bottom, top, value, step)
	if ( value + step > top ) then
		return top
	elseif ( value + step < bottom ) then
		return bottom
	end

	return value + step
end

local function isPositive(value)
	return value == math.abs(value)
end

local function isPositive_zero(value)
	return ( value == 0 and 0 ) or value == math.abs(value)
end

local cursor = {}

function cursor.init()
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
	cursor.space.lengthX = 1
	cursor.space.lengthY = 1

	--[[
		wall = {
			len_string,
			len_string,
			...
			len_string
		}
	]]--
	cursor.space.wall = {}
	cursor.space.freeSpace = true

	cursor.allowMoveX = true
	cursor.allowMoveY = true
end

function cursor.addStringLen(number, position)
	if ( number < 0 ) then
		number = 0
	end

	table.insert( cursor.space.wall, position, number )

	if ( cursor.absolute.x > cursor.space.wall[cursor.absolute.y] ) then
		cursor.moveEnd()
		cursor.calculate()
	end
end

function cursor.removeStringLen(position)
	if ( #cursor.space.wall > 1 ) then
		table.remove( cursor.space.wall, position )

		cursor.absolute.prev.y = cursor.absolute.y
		if ( cursor.onBottom() ) then
			cursor.absolute.y = #cursor.space.wall
		end
		if ( cursor.absolute.x > cursor.space.wall[cursor.absolute.y] ) then
			cursor.moveEnd()
		end
	else
		cursor.space.wall[cursor.absolute.y] = 0
		cursor.moveHome()
	end

	cursor.calculate()
end

function cursor.modifyStringLen_onCursor(number, realtive)
	if ( realtive ) then
		cursor.space.wall[cursor.absolute.y] = cursor.space.wall[cursor.absolute.y] + number
	else
		cursor.space.wall[cursor.absolute.y] = number
	end

	if ( cursor.space.wall[cursor.absolute.y] < 0 ) then
		cursor.space.wall[cursor.absolute.y] = 0
	end

	if ( cursor.absolute.x > cursor.space.wall[cursor.absolute.y] ) then
		cursor.moveEnd()
		cursor.calculate()
	end
end

function cursor.modifyStringLen(number, position, realtive)
	if ( not position ) then
		return nil
	end

	if ( realtive ) then
		cursor.space.wall[position] = cursor.space.wall[position] + number
	else
		cursor.space.wall[position] = number
	end

	if ( cursor.space.wall[cursor.absolute.y] < 0 ) then
		cursor.space.wall[cursor.absolute.y] = 0
	end

	if ( cursor.absolute.x > cursor.space.wall[cursor.absolute.y] ) then
		cursor.moveEnd()
		cursor.calculate()
	end
end

function cursor.onEndLine()
	return cursor.absolute.x == cursor.space.wall[cursor.absolute.y] + 1
end

function cursor.onHomeLine()
	return cursor.absolute.x == 1
end

function cursor.onBottom()
	return cursor.absolute.y >= #cursor.space.wall
end

function cursor.onTop()
	return cursor.absolute.y == 1
end

function cursor.checkLine(step)
	local lineExist = cursor.space.wall[cursor.absolute.y+step] ~= nil
	local lineLessCurrent = nil
	if ( lineExist ) then
		lineLessCurrent = cursor.space.wall[cursor.absolute.y+step] < cursor.space.wall[cursor.absolute.y]
		lineLessCurrent = lineLessCurrent and cursor.absolute.x > cursor.space.wall[cursor.absolute.y+step]
	end

	return lineExist, lineLessCurrent
end

function cursor.calculate()
	cursor.relative.prev.x = cursor.relative.x
	cursor.relative.prev.y = cursor.relative.y
	cursor.relative.x = math.max( math.min(cursor.absolute.x, cursor.space.lengthX), 1 )
	cursor.relative.y = math.max( math.min(cursor.absolute.y, cursor.space.lengthY), 1 )

	cursor.delta.prev.x = cursor.delta.x
	cursor.delta.prev.y = cursor.delta.x
	cursor.delta.x = cursor.absolute.x - cursor.relative.x
	cursor.delta.y = cursor.absolute.y - cursor.relative.y
end

function cursor.set(absolute_x, absolute_y)
	cursor.absolute.prev.x = cursor.absolute.x
	cursor.absolute.prev.y = cursor.absolute.y

	cursor.absolute.x = absolute_x
	cursor.absolute.y = absolute_y

	cursor.calculate()
end

function cursor.move(step_x, step_y)
	local stepY_positive = isPositive_zero(step_y)
	if ( stepY_positive ~= 0 ) then
		local action = ( stepY_positive and cursor.moveEndNextLine ) or cursor.moveEndPrevLine

		local exist, less = cursor.checkLine(step_y)
		if ( exist and less ) then
			action(step_y)
		elseif ( exist ) then
			cursor.absolute.prev.y = cursor.absolute.y
			cursor.absolute.y = cursor.absolute.y + step_y
		end
	end

	local stepX_positive = isPositive_zero(step_x)
	if ( stepX_positive == true and cursor.onEndLine() and not cursor.onBottom() ) then
		cursor.absolute.prev.y = cursor.absolute.y
		cursor.absolute.y = cursor.absolute.y + 1
		cursor.moveHome()
	elseif ( stepX_positive == false and cursor.onHomeLine() and not cursor.onTop() ) then
		cursor.absolute.prev.y = cursor.absolute.y
		cursor.absolute.y = cursor.absolute.y - 1
		cursor.moveEnd()
	elseif ( stepX_positive ~= 0 ) then
		cursor.absolute.prev.x = cursor.absolute.x
		cursor.absolute.x = range(1, cursor.space.wall[cursor.absolute.y] + 1, cursor.absolute.x, step_x)
	end

	cursor.calculate()
end

function cursor.moveHome()
	if ( cursor.space.wall[cursor.absolute.y] ) then
		cursor.absolute.prev.x = cursor.absolute.x
		cursor.absolute.x = 1
	end
end

function cursor.moveEnd()
	if ( cursor.space.wall[cursor.absolute.y] ) then
		cursor.absolute.prev.x = cursor.absolute.x
		cursor.absolute.x = cursor.space.wall[cursor.absolute.y] + 1
	end
end

function cursor.moveEndNextLine(step)
	if ( cursor.space.wall[cursor.absolute.y+step] ) then
		cursor.absolute.prev.y = cursor.absolute.y
		cursor.absolute.y = cursor.absolute.y + step

		cursor.absolute.prev.x = cursor.absolute.x
		cursor.absolute.x = cursor.space.wall[cursor.absolute.y] + 1
	end
end

function cursor.moveEndPrevLine(step)
	if ( cursor.space.wall[cursor.absolute.y+step] ) then
		cursor.absolute.prev.y = cursor.absolute.y
		cursor.absolute.y = cursor.absolute.y + step

		cursor.absolute.prev.x = cursor.absolute.x
		cursor.absolute.x = cursor.space.wall[cursor.absolute.y] + 1
	end
end

return cursor
