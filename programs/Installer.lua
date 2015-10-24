local event = require "event"
local unicode = require "unicode"
local net = require "internet"
local fs = require "filesystem"
local computer = require "computer"
local gpu = require "component".gpu

-- INITIALIZATION --
local screenWidth, screenHeight = gpu.maxResolution()
gpu.setResolution( screenWidth, screenHeight )

local github = "https://raw.githubusercontent.com/Pirnogion/OpenComputers_library/master/programs"

-- UTILS --
local function DrawText_Center( y, string )
	gpu.set( screenWidth/2 - unicode.len(string)/2, y, string )
end

--Находится ли заданная точка внутри прямоугольника.
local function PointInRectFree(x, y, sx, sy, ex, ey)
        if (x >= sx) and (x <= ex) and (y >= sy) and (y <= ey) then return true end    
        return false
end

local function restrictString(string, max_len, n, restrictLeft)
	if ( unicode.len(string) > max_len ) then
		if ( not restrictLeft ) then
			return unicode.sub(string, 1, max_len - unicode.len(n)*2 ) .. n
		else
			return n .. unicode.sub(string, unicode.len(string)-max_len+unicode.len(n)*2, unicode.len(string) )
		end
	end
	return string
end

--Загрузка списка файлов, которые требуют загрузки.
local function loadFilelist(url)
	local filelist = nil

	local request_result, request = pcall( net.request, url )
	if ( request_result ) then
		local response_result, response = pcall(
			function(request)
				local filedata = ""
				for chunk in request do
					filedata = filedata .. chunk
				end

				return filedata
			end,
			request
		)

		if ( response_result ) then
			return load(response)()
		else
			error("Bad response: " .. response)
		end
	else
		error("Download filelist failed: " .. request)
	end
end

--Загрузка и сохранение на диск файлов.
local function loadAndSaveFiles(filelist)
	local allFilepath = nil
	local info = nil

	for i, file in ipairs(filelist) do
		allFilepath = github .. file.folder .. "/" .. file.filename

		--инфо
		local info = "Загружено файлов: " .. i .. " из " .. #filelist
		gpu.fill( 1, 1, screenWidth, 2, ' ' )
		gpu.setBackground(0)
		gpu.fill( 2, 5, (screenWidth-2)*(i/#filelist), screenHeight-5, ' ' )
		gpu.setBackground(0xffffff)
		gpu.set( screenWidth/2-unicode.len(info)/2, 2, info )
		DrawText_Center(3, restrictString(allFilepath, screenWidth, '...', true))

		local request_result, request = pcall( net.request, allFilepath )

		if ( request_result ) then
			if ( not fs.exists( file.folder ) ) then os.execute("mkdir " .. file.folder) end
			local f = assert( io.open( file.folder .. "/" .. file.filename, "wb" ), "Can't write to the '" .. allFilepath .. "' file!" )
			local write_result, write_err = pcall(
				function()
					for chunk in request do
						f:write( chunk )
					end
				end
			)
			f:close()
			if ( write_err ) then error("Bad response: " .. write_err) end
		else
			error("Can't load file! " .. request)
		end
	end
end

-- PREPARE --
gpu.setBackground( 0xffffff )
gpu.setForeground( 0 )
gpu.fill(1, 1, screenWidth, screenHeight, ' ')

-- DRAW GRAPHICS --

-- DOWNLOAD FILELIST --
filelist = loadFilelist(github .. "FileList")

-- DOWNLOAD FILES --
loadAndSaveFiles(filelist)

gpu.fill(1, 1, screenWidth, screenHeight, ' ')
gpu.fill(1, 3, screenWidth, 1, '─')
gpu.fill(1, screenHeight-2, screenWidth, 1, '─')
DrawText_Center(3, " MiniShell успешно установлена! ")
DrawText_Center(screenHeight/2-4, " Нажмите любую клавишу для завершения ")

gpu.set(screenWidth/2-5, screenHeight/2+0-2, '         ██')
gpu.set(screenWidth/2-5, screenHeight/2+1-2, '        ██ ')
gpu.set(screenWidth/2-5, screenHeight/2+2-2, '       ██  ')
gpu.set(screenWidth/2-5, screenHeight/2+3-2, '██    ██   ')
gpu.set(screenWidth/2-5, screenHeight/2+4-2, ' ██  ██    ')
gpu.set(screenWidth/2-5, screenHeight/2+5-2, '  ████     ')
gpu.set(screenWidth/2-5, screenHeight/2+6-2, '   ██      ')

event.pull()

-- RESET GRAPHICS OPTIONS --
gpu.setBackground( 0 )
gpu.setForeground( 0xffffff )
