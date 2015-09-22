--------ocif--------
--Автор: Pirnogion--
--------------------

--CONSTANTS--
local IMAGE_FG = 3
local IMAGE_BG = 2
local IMAGE_AL = 1

local IMAGE_CH = 0
local IMAGE_COMPRESS = 1

local ELEMENT_COUNT = 2
local ELEMENT_COUNT_HF = 4

local IMAGE_WIDTH  = 1
local IMAGE_HEIGHT = 2
local IMAGE        = 3

local BYTE      = 8
local NULL_CHAR = 0

local FILE_OPEN_ERROR = "Can't open file"

--.ocif подпись
--.ocif signature
local ocif_signature1 = 0x896F6369
local ocif_signature2 = 0x00661A0A --7 bytes: 89 6F 63 69 66 1A 0A
local ocif_signature_expand = { string.char(0x89), string.char(0x6F), string.char(0x63), string.char(0x69), string.char(0x66), string.char(0x1A), string.char(0x0A) }

local imageAPI = {}

--Выделить бит-терминатор в первом байте utf8 символа: 1100 0010 --> 0010 0000
--Select terminate bit in the first byte utf8 char: 1100 0010 --> 0010 0000
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

--Прочитать n байтов из файла, возвращает прочитанные байты как число, если не удалось прочитать, то возвращает 0
--Read n byte from file and returns readed bytes as number. If read failed, then returns 0
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
--Convert HEX color to RGB color
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
--Alpha blending
local function alpha_blend(back_color, front_color, alpha_channel)
	local INVERTED_ALPHA_CHANNEL = 255-alpha_channel

	local back_color_rr, back_color_gg, back_color_bb    = HEXtoRGB(back_color)
	local front_color_rr, front_color_gg, front_color_bb = HEXtoRGB(front_color)

	local blended_rr = front_color_rr * INVERTED_ALPHA_CHANNEL / 255 + back_color_rr * alpha_channel / 255
	local blended_gg = front_color_gg * INVERTED_ALPHA_CHANNEL / 255 + back_color_gg * alpha_channel / 255
	local blended_bb = front_color_bb * INVERTED_ALPHA_CHANNEL / 255 + back_color_bb * alpha_channel / 255

	return RGBtoHEX( blended_rr, blended_gg, blended_bb )
end

--Конвертация 24 битной палитры в 8 битную
--Convert 24bit palette to 8bit
local function HEX_color24to8( hexcolor24 )
	local rr, gg, bb = HEXtoRGB( hexcolor24 )

	return bit32.lshift( bit32.rshift(rr, 5), 5 ) + bit32.lshift( bit32.rshift(gg, 5), 2 ) + bit32.rshift(bb, 6)
end

--Конвертация 8 битной палитры в 24 битную
--Convert 8bit palette to 24bit
local function HEX_color8to24( hexcolor8 )
	local rr = bit32.lshift( bit32.rshift( hexcolor8, 5 ), 5 )
	local gg = bit32.lshift( bit32.rshift( bit32.band( hexcolor8, 28 ), 2 ), 5 )
	local bb = bit32.lshift( bit32.band( hexcolor8, 3 ), 6 )

	return RGBtoHEX( rr, gg, bb )
end

local function compressPixel(foreground, background, alpha)
	return bit32.lshift( foreground, BYTE*2 ) + bit32.lshift( background, BYTE ) + alpha
end

local function decompressPixel( compressed_pixel )
	return bit32.rshift( compressed_pixel, BYTE*2 ), bit32.rshift( bit32.band( compressed_pixel, 0x00FF00 ), BYTE ), bit32.band( compressed_pixel, 0x0000FF )
end

--Подготавливает цвета и символ для записи в файл
--Preparation colors and char from write to file
local function encodePixel(compressed_pixel, char)
	--split hex-colors
	local new_fg, new_bg, alpha = decompressPixel( compressed_pixel )
	local ascii_char1, ascii_char2, ascii_char3, ascii_char4, ascii_char5, ascii_char6 = string.byte( char, 1, 6 )

	ascii_char1 = ascii_char1 or NULL_CHAR

	return new_fg, new_bg, alpha, ascii_char1, ascii_char2, ascii_char3, ascii_char4, ascii_char5, ascii_char6
end

local function encodePixel_hf(hexcolor_fg, hexcolor_bg, alpha, char)
	--split hex-colors
	local new_fg = HEX_color24to8( hexcolor_fg )
	local new_bg = HEX_color24to8( hexcolor_bg )
	local ascii_char1, ascii_char2, ascii_char3, ascii_char4, ascii_char5, ascii_char6 = string.byte( char, 1, 6 )

	ascii_char1 = ascii_char1 or NULL_CHAR

	return new_fg, new_bg, alpha, ascii_char1, ascii_char2, ascii_char3, ascii_char4, ascii_char5, ascii_char6
end

--Декодирование utf8 символа
--Decode utf8 char
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
--Write image array to file
function imageAPI.write(path, image, human_form)
	local elementCount = human_form and ELEMENT_COUNT_HF or ELEMENT_COUNT
	local encodedPixel = nil
	local file = assert( io.open(path, "w"), FILE_OPEN_ERROR )

	file:write( table.unpack(ocif_signature_expand) )
	file:write( string.char( image[IMAGE_WIDTH]  ) )
	file:write( string.char( image[IMAGE_HEIGHT] ) )
	
	for element = elementCount, image[IMAGE_HEIGHT] * image[IMAGE_WIDTH] * elementCount, elementCount do
		if ( human_form ) then
			encodedPixel =
			{
				encodePixel_hf
				(
					image[IMAGE][element-IMAGE_FG],
					image[IMAGE][element-IMAGE_BG],
					image[IMAGE][element-IMAGE_AL],
					image[IMAGE][element-IMAGE_CH]
				)
			}
		else
			encodedPixel =
			{
				encodePixel
				(
					image[IMAGE][element-IMAGE_COMPRESS],
					image[IMAGE][element-IMAGE_CH]
				)
			}
		end
		for i = 1, #encodedPixel do
			file:write( string.char( encodedPixel[i] ) )
		end
	end

	file:close()
end

--Чтение из файла, возвращет массив изображения
--Read from file, return image array
function imageAPI.read(path)
	local image = {}
	local file = assert( io.open(path, "rb"), FILE_OPEN_ERROR )

	local signature1, signature2 = readBytes(file, 4), readBytes(file, 3)
	if ( signature1 ~= ocif_signature1 or signature2 ~= ocif_signature2 ) then
		file:close()
		return nil
	end

	image[IMAGE_WIDTH]  = readBytes(file, 1)
	image[IMAGE_HEIGHT] = readBytes(file, 1)

	image[IMAGE] = {}

	for element = ELEMENT_COUNT, image[IMAGE_HEIGHT] * image[IMAGE_WIDTH] * ELEMENT_COUNT, ELEMENT_COUNT do
		image[IMAGE][element-IMAGE_COMPRESS] = readBytes(file, 3)
		image[IMAGE][element-IMAGE_CH]       = decodeChar( file )
	end

	file:close()

	return image
end

--Отрисовка изображения
--Draw image
function imageAPI.draw(image, sx, sy, gpu)
	local x, y = 0, 0
	local prevBG, prevFG = nil, nil
	local currentBG, currentFG = nil, nil
	for element = ELEMENT_COUNT, image[IMAGE_HEIGHT] * image[IMAGE_WIDTH] * ELEMENT_COUNT, ELEMENT_COUNT do	
		x = (x % image[IMAGE_WIDTH]) + 1
		y = (x == 1) and y+1 or y

		local _, _, back_color = gpu.get(sx+x-1, sy+y-1)
		local fg8, bg8, al = decompressPixel( image[IMAGE][element-IMAGE_COMPRESS] )
		local fg24, bg24 = HEX_color8to24( fg8 ), HEX_color8to24( bg8 )

		currentFG = fg24
		currentBG = alpha_blend( back_color, bg24, al )

		if ( currentFG ~= prevFG ) then
			prevFG = currentFG
			gpu.setForeground(currentFG)
		end
		if ( currentBG ~= prevBG ) then
			prevBG = currentBG
			gpu.setBackground(currentBG)
		end

		gpu.set(sx+x-1, sy+y-1, image[IMAGE][element-IMAGE_CH])
	end
end

return imageAPI
