local comp = require "computer"
local gpu = require "component".gpu
local ocif = require "ocif"

local X_SHIFT = 2
function fillChess(gpu, color1, color2, startX, startY, screenX, screenY)
  local shift = 0
  --Fill using color1
  gpu.setBackground(color1)
  gpu.fill(startX, startY, screenX, screenY, ' ')

  --Fill using color2
  gpu.setBackground(color2)
  for y=startY, screenY+startY-1, 1 do
    for x=startX, screenX+startX-2, 4 do
      gpu.fill(x+shift, y, 2, 1, ' ')
    end
    shift = shift ~= X_SHIFT and X_SHIFT or 0
  end
end

local width, height = gpu.getResolution()
--gpu.setBackground( 0x114B96 )
--gpu.fill(1, 1, width, height, ' ')
fillChess(gpu, 0xffffff, 0xe1e1e1, 1, 1, width, height)

--Константы(можно скопипастить)--
local IMAGE_WIDTH  = 1
local IMAGE_HEIGHT = 2
local IMAGE_FRAMES = 3
local IMAGE        = 4

--Сырое изображение, т.е. массив(первый формат, удобен для редактирования из редактора)
local ocif_image_raw = {
	[IMAGE_WIDTH] = 8, --Ширина изображения
	[IMAGE_HEIGHT] = 4, --Высота изображения
	[IMAGE_FRAMES] = 2,
	[IMAGE] = { 
		0xffffff, 0x000000, 0, '┌',
		0xffffff, 0x114B96, 120, '─', 
		0xffffff, 0x114B96, 120, '─',
		0xffffff, 0x114B96, 120, '─',
		0xffffff, 0x114B96, 120, '─',
		0xffffff, 0x114B96, 120, '─',
		0xffffff, 0x114B96, 120, '─', 
		0xffffff, 0x000000, 0, '┐',

		0xffffff, 0x114B96, 120, '╞',
		0xffffff, 0x114B96, 120, '─', 
		0xffffff, 0x114B96, 120, 'O',
		0xffffff, 0x114B96, 120, 'C',
		0xffffff, 0x114B96, 120, 'I',
		0xffffff, 0x114B96, 120, 'F', 
		0xffffff, 0x114B96, 120, '─',
		0xffffff, 0x114B96, 120, '╡',
	
		0xffffff, 0x114B96, 120, '╞',
		0xffffff, 0x114B96, 120, '─', 
		0xffffff, 0x114B96, 120, 'L',
		0xffffff, 0x114B96, 120, 'I',
		0xffffff, 0x114B96, 120, 'B',
		0xffffff, 0x114B96, 120, 'R', 
		0xffffff, 0x114B96, 120, '─',
		0xffffff, 0x114B96, 120, '╡',

		0xffffff, 0x114B96, 120, '└',
		0xffffff, 0x114B96, 120, '─', 
		0xffffff, 0x114B96, 120, '─',
		0xffffff, 0x114B96, 120, '─',
		0xffffff, 0x114B96, 120, '─',
		0xffffff, 0x114B96, 120, '─', 
		0xffffff, 0x114B96, 120, '─',
		0xffffff, 0x114B96, 120, '┘'
	},
	[IMAGE+1] = { 
		0xffffff, 0x000000, 0, '┌',
		0xffffff, 0x114B96, 0, '─', 
		0xffffff, 0x114B96, 0, '─',
		0xffffff, 0x114B96, 0, '─',
		0xffffff, 0x114B96, 0, '─',
		0xffffff, 0x114B96, 0, '─',
		0xffffff, 0x114B96, 0, '─', 
		0xffffff, 0x000000, 0, '┐',

		0xffffff, 0x114B96, 0, '╞',
		0xffffff, 0x114B96, 0, '─', 
		0xffffff, 0x114B96, 0, 'O',
		0xffffff, 0x114B96, 0, 'C',
		0xffffff, 0x114B96, 0, 'I',
		0xffffff, 0x114B96, 0, 'F', 
		0xffffff, 0x114B96, 0, '─',
		0xffffff, 0x114B96, 0, '╡',
	
		0xffffff, 0x114B96, 0, '╞',
		0xffffff, 0x114B96, 0, '─', 
		0xffffff, 0x114B96, 0, 'L',
		0xffffff, 0x114B96, 0, 'I',
		0xffffff, 0x114B96, 0, 'B',
		0xffffff, 0x114B96, 0, 'R', 
		0xffffff, 0x114B96, 0, '─',
		0xffffff, 0x114B96, 0, '╡',

		0xffffff, 0x114B96, 0, '└',
		0xffffff, 0x114B96, 0, '─', 
		0xffffff, 0x114B96, 0, '─',
		0xffffff, 0x114B96, 0, '─',
		0xffffff, 0x114B96, 0, '─',
		0xffffff, 0x114B96, 0, '─', 
		0xffffff, 0x114B96, 0, '─',
		0xffffff, 0x114B96, 0, '┘'
	}
}

--Загрузка палитры. Обязательно для 8bit формата!
--ocif.setPalette("palette.cia")
--ocif.setMode( "8bit" )

--Режим записи 24bit(больше размер файла, точная цветопередача) или 8bit
--ocif.setMode( "24bit" )

--Запись в файл сырого изображения в "удобном" формате, т.е во вторичном(последний аргумент)
ocif.write("ocif_test.ocif", ocif_image_raw, true)
--Чтение изображения(получили массив изображения в "неудобном" формате, т.е основном)
local ocif_image = ocif.read("ocif_test.ocif")
--Вывод изображения
ocif.draw( ocif_image, 1, 1, 1, gpu )
ocif.draw( ocif_image, 2, 9, 1, gpu )

--Запись в файл сырого изображения в "неудобном" формате(который был ранее уже прочитан из файла)
ocif.write("ocif_test.ocif", ocif_image)
--Чтение изображения
ocif_image = ocif.read("ocif_test.ocif")
--Вывод изображения
ocif.draw( ocif_image, 1, 18, 1, gpu )
ocif.draw( ocif_image, 2, 26, 1, gpu )

--Чтение в виде "удобного" массива
--ocif_image = ocif.read("ocif_test.ocif", true)

--Для дебага--
gpu.setBackground(0)
gpu.setForeground(0xFFFFFF)
