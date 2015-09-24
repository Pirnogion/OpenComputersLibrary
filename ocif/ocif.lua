--------ocif--------
--Автор: Pirnogion--
--------------------

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
local IMAGE        = 3

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
dofile("palette.cia")
if ( not palette or #palette ~= 255 ) then
	error( LOAD_PALETTE_ERROR )
end

--.ocif подпись
local ocif_signature1 = 0x896F6369
local ocif_signature2 = 0x00661A0A --7 bytes: 89 6F 63 69 66 1A 0A
local ocif_signature_expand = { string.char(0x89), string.char(0x6F), string.char(0x63), string.char(0x69), string.char(0x66), string.char(0x1A), string.char(0x0A) }

local imageAPI = {}

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
function HEXtoRGB(color)
  local rr = bit32.rshift( color, 16 )
  local gg = bit32.rshift( bit32.band(color, 0x00ff00), 8 )
  local bb = bit32.band(color, 0x0000ff)
 
  return rr, gg, bb
end

function RGBtoHEX(rr, gg, bb)
  return bit32.lshift(rr, 16) + bit32.lshift(gg, 8) + bb
end

--Альфа-смешение
local function alphaBlend(background_screen_color, foreground_image_color, alpha_channel)
	if ( alpha_channel < 0 ) then return foreground_image_color end

	local INVERTED_ALPHA_CHANNEL = 255-alpha_channel

	local background_screen_color_rr, background_screen_color_gg, background_screen_color_bb    = HEXtoRGB(background_screen_color)
	local foreground_image_color_rr, foreground_image_color_gg, foreground_image_color_bb = HEXtoRGB(foreground_image_color)

	local blended_rr = foreground_image_color_rr * INVERTED_ALPHA_CHANNEL / 255 + background_screen_color_rr * alpha_channel / 255
	local blended_gg = foreground_image_color_gg * INVERTED_ALPHA_CHANNEL / 255 + background_screen_color_gg * alpha_channel / 255
	local blended_bb = foreground_image_color_bb * INVERTED_ALPHA_CHANNEL / 255 + background_screen_color_bb * alpha_channel / 255

	return RGBtoHEX( blended_rr, blended_gg, blended_bb )
end

--Конвертация 24 битной палитры в 8 битную
local function HEX_color24to8( hexcolor24 )
	local rr, gg, bb = HEXtoRGB( hexcolor24 )
	local reduced = math.modf(rr / 0x33) * 0x330000 + math.modf(gg / 0x24) * 0x2400 + math.modf(bb / 0x3F) * 0x3F

	for i, color in pairs(palette) do
		if ( hexcolor24 == color ) then
			return i
		elseif ( reduced == color ) then
			return i
		end
	end

	return 0
end

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
local function encodePixel(compressed_pixel, char)
	local decompressed_fg, decompressed_bg, alpha = decompressPixel( compressed_pixel )
	local ascii_char1, ascii_char2, ascii_char3, ascii_char4, ascii_char5, ascii_char6 = string.byte( char, 1, 6 )

	ascii_char1 = ascii_char1 or NULL_CHAR

	return decompressed_fg, decompressed_bg, alpha, ascii_char1, ascii_char2, ascii_char3, ascii_char4, ascii_char5, ascii_char6
end

local function encodePixel_full_array(hexcolor_fg, hexcolor_bg, alpha, char)
	local decompressed_fg = HEX_color24to8( hexcolor_fg )
	local decompressed_bg = HEX_color24to8( hexcolor_bg )
	local ascii_char1, ascii_char2, ascii_char3, ascii_char4, ascii_char5, ascii_char6 = string.byte( char, 1, 6 )

	ascii_char1 = ascii_char1 or NULL_CHAR

	return decompressed_fg, decompressed_bg, alpha, ascii_char1, ascii_char2, ascii_char3, ascii_char4, ascii_char5, ascii_char6
end

--Декодирование utf8 символа
local function decodeChar(file)
	local first_byte = readBytes(file, 1)
	local charcode_array = {first_byte}
	local len = 1

	local middle = selectTerminateBit(first_byte)
	if ( middle == 32 ) then
		len = 2
	elseif ( middle == 16 ) then 
		len = 3
	elseif ( middle == 8 ) then
		len = 4
	elseif ( middle == 4 ) then
		len = 5
	elseif ( middle == 2 ) then
		len = 6
	end

	for i = 1, len-1 do
		table.insert( charcode_array, readBytes(file, 1) )
	end

	return string.char( table.unpack( charcode_array ) )
end

--Запись в файл по массиву изображения
function imageAPI.write(path, image, full_array)
	local elementCount = full_array and ELEMENT_COUNT_FULL_ARRAY or ELEMENT_COUNT
	local encodedPixel = nil
	local file = assert( io.open(path, "w"), FILE_OPEN_ERROR )

	file:write( table.unpack(ocif_signature_expand) )
	file:write( string.char( image[IMAGE_WIDTH]  ) )
	file:write( string.char( image[IMAGE_HEIGHT] ) )
	
	for element = elementCount, image[IMAGE_HEIGHT] * image[IMAGE_WIDTH] * elementCount, elementCount do
		if ( full_array ) then
		--Погдотовка к записи по полному массиву(full_array)
			encodedPixel =
			{
				encodePixel_full_array
				(
					image[IMAGE][element-FOREGROUND],
					image[IMAGE][element-BACKGROUND],
					image[IMAGE][element-ALPHA_CHANNEL],
					image[IMAGE][element-UTF8_CHAR]
				)
			}
		else
		--Погдотовка к записи по сжатому массиву
			encodedPixel =
			{
				encodePixel
				(
					image[IMAGE][element-COMPRESSED_PIXEL],
					image[IMAGE][element-UTF8_CHAR]
				)
			}
		end

		--Запись
		for i = 1, #encodedPixel do
			file:write( string.char( encodedPixel[i] ) )
		end
	end

	file:close()
end

--Чтение из файла, возвращет массив изображения
function imageAPI.read(path)
	local image = {}
	local file = assert( io.open(path, "rb"), FILE_OPEN_ERROR )

	--Чтение подписи файла
	local signature1, signature2 = readBytes(file, 4), readBytes(file, 3)
	if ( signature1 ~= ocif_signature1 or signature2 ~= ocif_signature2 ) then
		file:close()
		error( SIGNATURE_MATCH_ERROR )
	end

	image[IMAGE_WIDTH]  = readBytes(file, 1)
	image[IMAGE_HEIGHT] = readBytes(file, 1)

	image[IMAGE] = {}

	for element = ELEMENT_COUNT, image[IMAGE_HEIGHT] * image[IMAGE_WIDTH] * ELEMENT_COUNT, ELEMENT_COUNT do
		image[IMAGE][element-COMPRESSED_PIXEL] = readBytes(file, 3)
		image[IMAGE][element-UTF8_CHAR]       = decodeChar( file )
	end

	file:close()

	return image
end

--Отрисовка изображения(для примера. Медленная. Делайте СВОЮ отрисовку)
function imageAPI.draw(image, sx, sy, gpu)
	local x, y = 0, 0
	local prevBG, prevFG = nil, nil
	local currentBG, currentFG = nil, nil
	for element = ELEMENT_COUNT, image[IMAGE_HEIGHT] * image[IMAGE_WIDTH] * ELEMENT_COUNT, ELEMENT_COUNT do	
		x = (x % image[IMAGE_WIDTH]) + 1
		y = (x == 1) and y+1 or y

		local _, _, back_color = gpu.get(sx+x-1, sy+y-1)
		local fg8, bg8, al = decompressPixel( image[IMAGE][element-COMPRESSED_PIXEL] )
		local fg24, bg24 = HEX_color8to24( fg8 ), HEX_color8to24( bg8 )

		currentFG = fg24
		currentBG = alphaBlend( back_color, bg24, al )

		if ( currentFG ~= prevFG ) then
			prevFG = currentFG
			gpu.setForeground(currentFG)
		end
		if ( currentBG ~= prevBG ) then
			prevBG = currentBG
			gpu.setBackground(currentBG)
		end

		gpu.set(sx+x-1, sy+y-1, image[IMAGE][element-UTF8_CHAR])
	end
end

return imageAPI
