local gpu = require "component".gpu
local ocif = require "ocif"

--Константы(можно скопипастить)--
local IMAGE_WIDTH  = 1
local IMAGE_HEIGHT = 2
local IMAGE        = 3

--Сырое изображение, т.е. массив(первый формат, удобен для редактирования из редактора)
local ocif_image_raw = {
	[IMAGE_WIDTH] = 8, --Ширина изображения
	[IMAGE_HEIGHT] = 5, --Высота изображения
	[IMAGE] = { 
		0x000000, 0x003f49, 0, '1',
		0x000000, 0x338592, 0, '0', 
		0x000000, 0x338592, 0, 'З',
		0x000000, 0x003f49, 0, '0',
		0x000000, 0x003f49, 0, '1',
		0x000000, 0x004980, 200, ' ',
		0x000000, 0x004980, 200, ' ', 
		0x000000, 0x004980, 200, ' ',

		0x000000, 0x004980, 0, ' ',
		0xFF0000, 0xFFFFFF, 0, '1', 
		0x000000, 0xFFFFFF, 0, '0',
		0x000000, 0xFFFFFF, 0, '1',
		0x000000, 0xFFFFFF, 0, '0',
		0x000000, 0xFFFFFF, 0, '1', 
		0x000000, 0x004980, 0, ' ',
		0x000000, 0x004980, 0, ' ',
	
		0x000000, 0x004980, 0, ' ',
		0x000000, 0x004980, 0, ' ', 
		0x000000, 0xFFFFFF, 0, '1',
		0x000000, 0xFFFFFF, 0, '0',
		0x000000, 0xFFFFFF, 0, '1',
		0x000000, 0xFFFFFF, 0, '0', 
		0x000000, 0xFFFFFF, 0, '1',
		0x000000, 0x004980, 0, ' ',

		0x000000, 0xFFFFFF, 0, 'P',
		0x000000, 0xFFFFFF, 0, 'A', 
		0x000000, 0xFFFFFF, 0, 'S',
		0x000000, 0xFFFFFF, 0, '░',
		0x000000, 0xFFFFFF, 0, 'Ж',
		0x000000, 0xFFFFFF, 0, 'B', 
		0x000000, 0xFFFFFF, 0, 'I',
		0x000000, 0xFFFFFF, 0, 'N',

		0x000000, 0x48CC37, 255, ' ',
		0x000000, 0x48CC37, 255, ' ',
		0x000000, 0x48CC37, 255, ' ',
		0x000000, 0x48CC37, 200, ' ',
		0x000000, 0x48CC37, 200, ' ',
		0x000000, 0x48CC37, 200, ' ',
		0x000000, 0x48CC37, 200, ' ',
		0x000000, 0x48CC37, 200, ' ',
	}
}

--Режим записи 24bit(больше размер файла, точная цветопередача) или 8bit
ocif.setMode( "8bit" )

--Путь до палитры(по умолчанию palette.cia)
--ocif.setPalette( "palette.cia" )

--Запись в файл сырого изображения в "удобном" формате, т.е во вторичном(последний аргумент)
ocif.write("ocif_test.ocif", ocif_image_raw, true)
--Чтение изображения(получили массив изображения в "неудобном" формате, т.е основном)
local ocif_image = ocif.read("ocif_test.ocif")
--Вывод изображения
ocif.draw( ocif_image, 2, 1, gpu )

--Запись в файл сырого изображения в "неудобном" формате(который был ранее уже прочитан из файла)
ocif.write("ocif_test.ocif", ocif_image)
--Чтение изображения
local ocif_image = ocif.read("ocif_test.ocif")
--Вывод изображения
ocif.draw( ocif_image, 11, 1, gpu )

--Для дебага--
gpu.setBackground(0)
gpu.setForeground(0xFFFFFF)
