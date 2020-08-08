local filesystem = require "filesystem"
local unicode = require "unicode"

-- PARSER AUTOMATO --
local skip, tiny, jump, long, save = 1, 2, 3, 4, 5
local triggers = {' ', ',', '"'}

local transition = {
--  skip  tiny  jump, long  save
	{skip, tiny, long, long, skip}, -- ' '
	{skip, save, long, long, skip}, -- ','
	{jump, tiny, skip, save, jump}, -- '"'
	{tiny, tiny, long, long, tiny}, -- '*'
}

local function getTriggerId(trigger)
	for id = 1, #triggers do
		if (triggers[id] == trigger) then
			return id
		end
	end
	
	return 4;
end

local function execute(state, trigger)
	return transition[getTriggerId(trigger)][state];
end

-- LIBRARY FUNCTIONS --
local function cfg_read(path)
	local content = {}

	if not (filesystem.exists(path)) then
		error("Incorrect path to cfg file.")
	end

	if (filesystem.isDirectory(path)) then
		error("Cfg file can't be a folder!")
	end

	for line in io.lines(filesystem.name(path)) do
		for key, values in line:gmatch("(%w+):%s-(.+)") do 
			local parsed = {}

			local state = skip
			local buffer = ""

			for i = 1, unicode.len(values) do
				local char = unicode.sub(values, i, i)

				state = execute(state, char)

				if (state == save) then
					table.insert(parsed, buffer)
					buffer = ""
				elseif (state ~= skip and state ~= jump) then
					buffer = buffer .. char
				end
			end

			if (#buffer ~= 0) then
				table.insert(parsed, buffer)
			end

			content[key] = parsed
		end
	end

	return content
end

local function cfg_print(content)
	for key, values in pairs(content) do
		io.write(key .. ": ")
		for i = 1, #values do
			io.write(values[i] .. "; ")
		end
		print("")
	end
end

return
{
	read = cfg_read,
	print = cfg_print,
}

-- debug --
-- local q = cfg_read("home/fish.dat")
-- cfg_print(q)