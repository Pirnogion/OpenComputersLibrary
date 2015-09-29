--------ocif--------
--Автор: Pirnogion--
--------------------

--SWITCH
local MODE = nil
local PALETTE_PATH = "palette.cia"

--MODES
local MODES = {
	["MODE_24BIT"] = "24bit",
}

--CONSTANTS--
local FOREGROUND = 3
local BACKGROUND = 2
local ALPHA_CHANNEL = 1

local UTF8_CHAR = 0
local COMPRESSED_PIXEL = 1

local ELEMENT_COUNT = 2
local ELEMENT_COUNT_FULL_ARRAY = 4

local IMAGE_WIDTH  = 1
local IMAGE_HEIGHT = 2
local IMAGE_FRAMES = 3
local IMAGE        = 4

local BYTE_SIZE = 8
local NULL_CHAR = 0

local FILE_OPEN_ERROR = "Can't open file"
local LOAD_PALETTE_ERROR = "Can't load color index array. Table = nil or Table size less 256[0-255]"
local SIGNATURE_MATCH_ERROR = "Signatures not match"

--Загрузка палитры
local palette = nil
function LOAD_PALETTE( color_index_array )
	palette = color_index_array
end

local function reloadPalette()
	dofile( PALETTE_PATH )
	if ( not palette or #palette ~= 255 ) then
		error( LOAD_PALETTE_ERROR )
	end
end

--.ocif подпись
local ocif_signature1 = 0x896F6369
local ocif_signature2 = 0x00661A0A --7 bytes: 89 6F 63 69 66 1A 0A
local ocif_signature_expand = { string.char(0x89), string.char(0x6F), string.char(0x63), string.char(0x69), string.char(0x66), string.char(0x1A), string.char(0x0A) }

--Выделить бит-терминатор в первом байте utf8 символа: 1100 0010 --> 0010 0000
local function selectTerminateBit_l()
	local prevByte = nil
	local prevTerminateBit = nil

	return function( byte )
		local x, terminateBit = nil
		if ( prevByte == byte ) then
			return prevTerminateBit
		end

		x = bit32.band( bit32.bnot(byte), 0x000000FF )
		x = bit32.bor( x, bit32.rshift(x, 1) )
		x = bit32.bor( x, bit32.rshift(x, 2) )
		x = bit32.bor( x, bit32.rshift(x, 4) )
		x = bit32.bor( x, bit32.rshift(x, 8) )
		x = bit32.bor( x, bit32.rshift(x, 16) )

		terminateBit = x - bit32.rshift(x, 1)

		--save state
		prevByte = byte
		prevTerminateBit = terminateBit

		return terminateBit
	end
end
local selectTerminateBit = selectTerminateBit_l()

--Прочитать n <= 4 байтов из файла, возвращает прочитанные байты как число, если не удалось прочитать, то возвращает 0
local function readBytes(file, bytes)
  local readedByte = 0
  local readedNumber = 0
  for i = bytes, 1, -1 do
    readedByte = string.byte( file:read(1) or NULL_CHAR )
    readedNumber = readedNumber + bit32.lshift(readedByte, i*8-8)
  end

  return readedNumber
end

--Преобразует цвет в hex записи в rgb запись
local function HEXtoRGB(color)
  local rr = bit32.extract( color, 16, 8 )
  local gg = bit32.extract( color, 8,  8 )
  local bb = bit32.extract( color, 0,  8 )
 
  return rr, gg, bb
end

local function RGBtoHEX(rr, gg, bb)
  return bit32.lshift(rr, 16) + bit32.lshift(gg, 8) + bb
end

--Альфа-смешение
local function alphaBlend(background_screen_color, foreground_image_color, alpha_channel)
	if ( alpha_channel <= 0 ) then return foreground_image_color end

	local INVERTED_ALPHA_CHANNEL = 255-alpha_channel

	local background_screen_color_rr, background_screen_color_gg, background_screen_color_bb    = HEXtoRGB(background_screen_color)
	local foreground_image_color_rr, foreground_image_color_gg, foreground_image_color_bb = HEXtoRGB(foreground_image_color)

	local blended_rr = foreground_image_color_rr * INVERTED_ALPHA_CHANNEL / 255 + background_screen_color_rr * alpha_channel / 255
	local blended_gg = foreground_image_color_gg * INVERTED_ALPHA_CHANNEL / 255 + background_screen_color_gg * alpha_channel / 255
	local blended_bb = foreground_image_color_bb * INVERTED_ALPHA_CHANNEL / 255 + background_screen_color_bb * alpha_channel / 255

	return RGBtoHEX( blended_rr, blended_gg, blended_bb )
end

--Конвертация 24 битной палитры в 8 битную
local function HEX_color24to8_l()
	local prevHexcolor24 = nil
	local prevIndex = 0

	return function( hexcolor24 )
		if ( hexcolor24 == prevHexcolor24 ) then
			return prevIndex
		end
		prevHexcolor24 = hexcolor24

		local rr, gg, bb = HEXtoRGB( hexcolor24 )
		local reducedColor = math.modf(rr / 0x33) * 0x330000 + math.modf(gg / 0x24) * 0x2400 + math.modf(bb / 0x3F) * 0x3F

		for color_index, color in pairs(palette) do
			if ( hexcolor24 == color or reducedColor == color ) then
				prevIndex = color_index
				return color_index
			end
		end

		return 0
	end
end
local HEX_color24to8 = HEX_color24to8_l()

--Конвертация 8 битной палитры в 24 битную
local function HEX_color8to24( hexcolor8 )
	return palette[hexcolor8]
end

--Сжатие пикселя, исключая символ
local function compressPixel(foreground, background, alpha)
	return bit32.lshift( foreground, BYTE_SIZE*2 ) + bit32.lshift( background, BYTE_SIZE ) + alpha
end

--Восстановление пикселя
local function decompressPixel( compressed_pixel )
	return bit32.rshift( compressed_pixel, BYTE_SIZE*2 ), bit32.rshift( bit32.band( compressed_pixel, 0x00FF00 ), BYTE_SIZE ), bit32.band( compressed_pixel, 0x0000FF )
end

--Подготавливает цвета и символ для записи в файл
local function encodePixel(compressed_pixel, _, _, _, char)
	local decompressed_fg, decompressed_bg, alpha = decompressPixel( compressed_pixel )
	local ascii_char1, ascii_char2, ascii_char3, ascii_char4, ascii_char5, ascii_char6 = string.byte( char, 1, 6 )

	ascii_char1 = ascii_char1 or NULL_CHAR

	return { decompressed_fg, decompressed_bg, alpha, ascii_char1, ascii_char2, ascii_char3, ascii_char4, ascii_char5, ascii_char6 }
end

local function encodePixel_full_array(_, hexcolor_fg, hexcolor_bg, alpha, char)
	local converted_fg = HEX_color24to8( hexcolor_fg )
	local converted_bg = HEX_color24to8( hexcolor_bg )
	local ascii_char1, ascii_char2, ascii_char3, ascii_char4, ascii_char5, ascii_char6 = string.byte( char, 1, 6 )

	ascii_char1 = ascii_char1 or NULL_CHAR

	return { converted_fg, converted_bg, alpha, ascii_char1, ascii_char2, ascii_char3, ascii_char4, ascii_char5, ascii_char6 }
end

local function encodePixel_24bit_mode(_, hexcolor_fg, hexcolor_bg, alpha, char)
	local red_fg, green_fg, blue_fg = HEXtoRGB( hexcolor_fg )
	local red_bg, green_bg, blue_bg = HEXtoRGB( hexcolor_bg )
	local ascii_char1, ascii_char2, ascii_char3, ascii_char4, ascii_char5, ascii_char6 = string.byte( char, 1, 6 )
	ascii_char1 = ascii_char1 or NULL_CHAR

	return { red_fg, green_fg, blue_fg, red_bg, green_bg, blue_bg, alpha, ascii_char1, ascii_char2, ascii_char3, ascii_char4, ascii_char5, ascii_char6 }
end

--Выбор метода записи
local encodePixel =
{
	[MODES.MODE_24BIT] = encodePixel_24bit_mode,

	[true]  = encodePixel_full_array,
	[false]	= encodePixel
}

--Декодирование utf8 символа
local function decodeChar(file)
	local firstUTF8Byte = readBytes(file, 1)
	local charcodeArray = {firstUTF8Byte}
	local utf8Length = 1

	local terminateBit = selectTerminateBit(firstUTF8Byte)
	if ( terminateBit == 32 ) then
		utf8Length = 2
	elseif ( terminateBit == 16 ) then 
		utf8Length = 3
	elseif ( terminateBit == 8 ) then
		utf8Length = 4
	elseif ( terminateBit == 4 ) then
		utf8Length = 5
	elseif ( terminateBit == 2 ) then
		utf8Length = 6
	end

	for i = 1, utf8Length-1 do
		table.insert( charcodeArray, readBytes(file, 1) )
	end

	return string.char( table.unpack( charcodeArray ) )
end

local imageAPI = {}

--Установить режим работы
function imageAPI.setMode( mode )
	if ( mode == "8bit" ) then
		MODE = nil
	else
		MODE = mode
	end
end

--Установить путь до палитры
function imageAPI.setPalette( palette_path )
	PALETTE_PATH = palette_path or PALETTE_PATH
	reloadPalette()
end

--Получить текущий режим
function imageAPI.getMode()
	return MODE
end

--Запись в файл по массиву изображения
function imageAPI.write(path, picture, full_array)
	local elementCount = (full_array or MODE == MODES.MODE_24BIT) and ELEMENT_COUNT_FULL_ARRAY or ELEMENT_COUNT
	local encodedPixel = nil

	local file = assert( io.open(path, "w"), FILE_OPEN_ERROR )

	file:write( table.unpack(ocif_signature_expand) )
	file:write( string.char( picture[IMAGE_WIDTH]  ) )
	file:write( string.char( picture[IMAGE_HEIGHT] ) )
	file:write( string.char( picture[IMAGE_FRAMES] ) )
	
	for frame=0, picture[IMAGE_FRAMES]-1, 1 do
		for element = elementCount, picture[IMAGE_HEIGHT] * picture[IMAGE_WIDTH] * elementCount, elementCount do
			--Подготовка пикселя к записи
			encodedPixel = encodePixel[MODE or full_array or false]
			(
				picture[IMAGE+frame][element-COMPRESSED_PIXEL],
				picture[IMAGE+frame][element-FOREGROUND],
				picture[IMAGE+frame][element-BACKGROUND],
				picture[IMAGE+frame][element-ALPHA_CHANNEL],
				picture[IMAGE+frame][element-UTF8_CHAR]
			)

			--Запись
			for i = 1, #encodedPixel do
				file:write( string.char( encodedPixel[i] ) )
			end
		end
	end

	file:close()
end

--Чтение из файла, возвращет массив изображения
function imageAPI.read(path, full_array)
	local picture = {}
	local elementCount = (MODE == MODES.MODE_24BIT) and ELEMENT_COUNT_FULL_ARRAY or ELEMENT_COUNT
	local file = assert( io.open(path, "rb"), FILE_OPEN_ERROR )

	--Чтение подписи файла
	local signature1, signature2 = readBytes(file, 4), readBytes(file, 3)
	if ( signature1 ~= ocif_signature1 or signature2 ~= ocif_signature2 ) then
		file:close()
		error( SIGNATURE_MATCH_ERROR )
	end

	picture[IMAGE_WIDTH]  = readBytes(file, 1)
	picture[IMAGE_HEIGHT] = readBytes(file, 1)
	picture[IMAGE_FRAMES] = readBytes(file, 1)

	for frame=0, picture[IMAGE_FRAMES]-1, 1 do
		picture[IMAGE+frame] = {}

		for element = elementCount, picture[IMAGE_HEIGHT] * picture[IMAGE_WIDTH] * elementCount, elementCount do
			if ( MODE == MODES.MODE_24BIT or full_array ) then
				picture[IMAGE+frame][element-FOREGROUND] = readBytes(file, 3)
				picture[IMAGE+frame][element-BACKGROUND] = readBytes(file, 3)
				picture[IMAGE+frame][element-ALPHA_CHANNEL] = readBytes(file, 1)
			else
				picture[IMAGE+frame][element-COMPRESSED_PIXEL] = readBytes(file, 3)
			end

			picture[IMAGE+frame][element-UTF8_CHAR] = decodeChar( file )
		end
	end

	file:close()

	return picture
end

--Отрисовка изображения(Для примера. Медленная. Делайте СВОЮ отрисовку)
function imageAPI.draw(picture, frame, sx, sy, gpu)
	frame = frame - 1
	local x, y = 0, 0

	local screenBg = nil
	local fg8bit, bg8bit, alpha, fg24bit, bg24bit = nil

	local elementCount = (MODE == MODES.MODE_24BIT) and ELEMENT_COUNT_FULL_ARRAY or ELEMENT_COUNT
	for element = elementCount, picture[IMAGE_HEIGHT] * picture[IMAGE_WIDTH] * elementCount, elementCount do	
		x = (x % picture[IMAGE_WIDTH]) + 1
		y = (x == 1) and y+1 or y

		_, _, screenBg = gpu.get(sx+x-1, sy+y-1)

		if ( MODE == MODES.MODE_24BIT ) then
			fg24bit, bg24bit, alpha = picture[IMAGE+frame][element-FOREGROUND], picture[IMAGE+frame][element-BACKGROUND], picture[IMAGE+frame][element-ALPHA_CHANNEL]
		else
			fg8bit, bg8bit, alpha = decompressPixel( picture[IMAGE+frame][element-COMPRESSED_PIXEL] )
			fg24bit, bg24bit = HEX_color8to24( fg8bit ), HEX_color8to24( bg8bit )
		end

		gpu.setForeground( fg24bit )
		gpu.setBackground( alphaBlend( screenBg, bg24bit, alpha ) )

		gpu.set(sx+x-1, sy+y-1, picture[IMAGE+frame][element-UTF8_CHAR])
	end
end

return imageAPI
