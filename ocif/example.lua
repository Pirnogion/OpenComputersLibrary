local gpu = require "component".gpu
local ocif = require "ocif"

--Константы(можно скопипастить)--
local IMAGE_WIDTH  = 1
local IMAGE_HEIGHT = 2
local IMAGE        = 3

--Сырое изображение, т.е. массив
local ocif_image_raw = {
	[IMAGE_WIDTH] = 8, --Ширина изображения
	[IMAGE_HEIGHT] = 5, --Высота изображения
	[IMAGE] = { 
		0x000000, 0xFFFFFF, 200, '1',
		0x000000, 0xFFFFFF, 200, '0', 
		0x000000, 0xFFFFFF, 200, '1',
		0x000000, 0xFFFFFF, 200, '0',
		0x000000, 0xFFFFFF, 200, '1',
		0x000000, 0x004980, 200, ' ',
		0x000000, 0x004980, 200, ' ', 
		0x000000, 0x004980, 200, ' ',

		0x000000, 0x004980, 0, ' ',
		0x000000, 0xFFFFFF, 0, '1', 
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
		0x000000, 0xFFFFFF, 0, 'З',
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

--Запись в файл сырого изображения
ocif.write("ocif_test.ocif", ocif_image_raw)

--Чтение изображения
local ocif_image = ocif.read("ocif_test.ocif")

--Вывод изображения
ocif.draw( ocif_image, 16, 13, gpu )

--Для дебага--
gpu.setBackground(0)
gpu.setForeground(0xFFFFFF)
