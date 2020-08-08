local gpu = require "component".gpu
local term = require "term"
local rect = require "rectangle"

--Первая пара прямоугольников--
local rect1 = rect.CreateRectXYWH("r1", 5, 5, 20, 10)
local rect2 = rect.CreateRectXYXY("r2", 10, 8, 30, 18)
local rect3 = rect.IntersectRects(rect1, rect2)

--Вторая пара прямоугольников--
local rect1_2 = rect.CreateRectXYWH("r1_2", 55, 5, 20, 10)
local rect2_2 = rect.CreateRectXYXY("r2_2", 80, 5, 100, 15)
local rect3_2 = rect.IntersectRects(rect1, rect2)

--Пустой прямоугольник--
local void1 = rect.CreateVoidRect("v3")

--Очистка экрана
local screenWidth, screenHeight = gpu.getResolution()

gpu.setBackground(0)
gpu.fill(1, 1, screenWidth, screenHeight, ' ')
term.setCursor(1, 1)

--Отрисовка первой пары--
--Отрисовка первого прямоугольника
gpu.setBackground( 0x00ff00 )
gpu.fill( rect1.sx, rect1.sy, rect1.width, rect1.height, ' ' )
--Отрисовка второго прямоугольника
gpu.setBackground( 0x0000ff )
gpu.fill( rect2.sx, rect2.sy, rect2.width, rect2.height, ' ' )
--Отрисовка пересечения
gpu.setBackground( 0xff0000 )
gpu.fill( rect3.sx, rect3.sy, rect3.width, rect3.height, ' ' )

local intersect1 = rect.bIntersectRects(rect1, rect2)

--Отрисовка второй пары--
--Отрисовка первого прямоугольника
gpu.setBackground( 0x00ff00 )
gpu.fill( rect1_2.sx, rect1_2.sy, rect1_2.width, rect1_2.height, ' ' )
--Отрисовка второго прямоугольника
gpu.setBackground( 0x0000ff )
gpu.fill( rect2_2.sx, rect2_2.sy, rect2_2.width, rect2_2.height, ' ' )
--Отрисовка пересечения
gpu.setBackground( 0xff0000 )
gpu.fill( rect3_2.sx, rect3_2.sy, rect3_2.width, rect3_2.height, ' ' )

local intersect2 = rect.bIntersectRects(rect1_2, rect2_2)

gpu.setBackground(0)
print("Пересечения: ")
print("Первая пара: ", intersect1, "Вторая пара: ", intersect2)
os.sleep(3)

--Очистка экрана
local screenWidth, screenHeight = gpu.getResolution()

gpu.setBackground(0)
gpu.fill(1, 1, screenWidth, screenHeight, ' ')
term.setCursor(1, 1)

--Первая пара прямоугольник-точка--
local isRect_1 = rect.PointInRectFree(5, 5, 3, 3, 10, 8)

gpu.setBackground( 0x00ff00 )
gpu.fill(3, 3, 7, 5, ' ')

gpu.setBackground( 0xff0000 )
gpu.set(5, 5, '*')

local isRect_2 = rect.PointInRectFree(5, 5, 14, 3, 22, 8)

gpu.setBackground( 0x00ff00 )
gpu.fill(14, 3, 36, 5, ' ')

gpu.setBackground( 0xff00ff )
gpu.set(55, 4, '*')

--Вторая пара прямоугольник-точка--
local rectPoint_3 = rect.CreateRectXYWH("rp1", 6, 10, 20, 10)
local isRect_3 = rect.PointInRect(15, 12, rectPoint_3)

gpu.setBackground( 0x00ff00 )
gpu.fill(rectPoint_3.sx, rectPoint_3.sy, rectPoint_3.width, rectPoint_3.height, ' ')

gpu.setBackground( 0xff0000 )
gpu.set(15, 12, '*')

local rectPoint_4 = rect.CreateRectXYWH("rp2", 36, 10, 20, 10)
local isRect_4 = rect.PointInRect(100, 20, rectPoint_4)

gpu.setBackground( 0x00ff00 )
gpu.fill(rectPoint_4.sx, rectPoint_4.sy, rectPoint_4.width, rectPoint_4.height, ' ')

gpu.setBackground( 0xff00ff )
gpu.set(100, 20, '*')

gpu.setBackground(0)
print("Пересечения: ")
print("Первая пара: ", isRect_1, isRect_2, "Вторая пара: ", isRect_3, isRect_4)

os.sleep(3)

gpu.setBackground(0)
