local computer = require "computer"
local component = require "component"
local event = require "event"
local robot = require "robot"

local inventory = component.inventory_controller
local wifi = component.modem

local running = true
local server = "71ac5e68-69ab-46ab-9ebe-f399f6f488dc"
wifi.open(1)

--Команды, которые я принимаю
local commands = 
{
	["robot.forward"] = function()
		local result, reason = robot.forward()
		wifi.send(server, 1, "server.forward", result, reason)
	end,

	["robot.backward"] = function()
		local result, reason = robot.back()
		wifi.send(server, 1, "server.backward", result, reason)
	end,

	["robot.turnLeft"] = function()
		robot.turnLeft()
		wifi.send(server, 1, "server.turnLeft")
	end,

	["robot.turnRight"] = function()
		robot.turnRight()
		wifi.send(server, 1, "server.turnRight")
	end,

	["robot.swing"] = function()
		local result, reason = robot.swing()
		wifi.send(server, 1, "server.swing", result, reason)
	end,

	["robot.up"] = function()
		local result, reason = robot.up()
		wifi.send(server, 1, "server.up", result, reason)
	end,

	["robot.down"] = function()
		local result, reason = robot.down()
		wifi.send(server, 1, "server.down", result, reason)
	end,

	["robot.use"] = function()
		local result, reason = robot.use()
		wifi.send(server, 1, "server.use", result, reason)
	end,

	["robot.detect"] = function()
		local result, reason = robot.detect()

		wifi.send(server, 1, "server.detect", result, reason)
	end,

	["robot.place"] = function()
		local result, reason = robot.place()

		wifi.send(server, 1, "server.place", result, reason)
	end,

	["robot.getInstumentData"] = function()
		local durability, errorReason = robot.durability()

		--local item = inventory.getStackInInternalSlot( 1 )
		wifi.send(server, 1, "server.getInstumentData", durability or -errorReason)
	end,

	["robot.getEnergy"] = function()
		local energy = computer.energy()

		wifi.send(server, 1, "server.getEnergy", energy)
	end,

	["robot.shutdown"] = function()
		running = false
	end,
}
local meta = {}
function meta.__index(op, key)
	return function() end
end
setmetatable( commands, meta )

while (running) do
	local e = { event.pull() }

	if ( e[1] == "modem_message" ) then
		commands[ e[6] ]( e[7] )
	end
end


