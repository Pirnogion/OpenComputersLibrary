local filesystem = require "filesystem"
local component = require "component"
local unicode = require "unicode"
local event = require "event"
local shell = require "shell"

local cfg = require "simplecfg"

local function safeLoadComponent(type)
  return assert(component.isAvailable("debug") and component[type], "The component not found -> " .. type)
end

local function safeGetField(container, ...)
  local checkedField = assert(container, "The table is nil")
  
  for i, field in ipairs({...}) do
    checkedField = assert(checkedField[field], "The field is nil")
  end

  return checkedField
end

local function valuesToKeys(container)
  local reintContainer = {}
  
  for _, value in ipairs(container) do
    reintContainer[value] = true
  end

  return reintContainer
end

local function compileString(rawfunc)
  local chunk = assert(load(rawfunc))
  local status, compiled = pcall(chunk)

  return compiled
end

-- Checking an components --
local gpu = component.gpu
local dbg = safeLoadComponent("debug")
local chat = safeLoadComponent("chat_box")

local function getOnlinePlayers()
  return #dbg.getPlayers()
end

-- Variables --
local running = true

local voting = false
local currentVote = nil
local voteInitiaterPlayer = nil
local voteTimer = nil
local positiveVote = 0
local negativeVote = 0
local votePlayers = {}

-- Load data and define data --
local majorityCalculations = {
  simple = function() return positiveVote > negativeVote end,
  absolute = function() return positiveVote - negativeVote > getOnlinePlayers() end
}

local path = filesystem.concat(".", shell.getWorkingDirectory(), "")
local programData = cfg.read(filesystem.concat(path, "config.cfg"))

local calculateVotes = majorityCalculations[safeGetField(programData, "majorityType", 1)]
local positiveWords = valuesToKeys(safeGetField(programData, "positive"))
local negativeWords = valuesToKeys(safeGetField(programData, "negative"))

local topics = {}
for i = 1, #programData.topics do
  local topicFileName = safeGetField(programData, "topics", i)
  local data = cfg.read(filesystem.concat(path, topicFileName))

  local topicName = safeGetField(data, "topic", 1)
  local func = compileString(safeGetField(data, "execute", 1))

  topics['?'..topicName] = {
      voteName = topicName,
      voteAcceptText = safeGetField(data, "accept", 1),
      voteRejectText = safeGetField(data, "reject", 1),
      voteTime = tonumber(safeGetField(data, "delay", 1)),
      execute = function() func(package.loaded, package.loaded.component) end
    }
end

programData = nil

-- Sevice commands --
local listCmd = function()
  chat.say("Список тем голосования:")

  for _, v in pairs(topics) do
    chat.say(" - " .. v.voteName)
  end
end

local internalCommands = {
  ["?список тем"] = listCmd
}

-- Program --
local function reset()
  if (voteTimer) then event.cancel(voteTimer) end

  voting = false
  currentVote = nil
  voteInitiaterPlayer = nil
  positiveVote = 0
  negativeVote = 0
  votePlayers = {}

  --running = false--
end

local function checkResult()
  if (calculateVotes()) then
    currentVote.execute()

    chat.say(currentVote.voteAcceptText .. ".")
  else
    chat.say("Голосование отменено: " .. currentVote.voteRejectText .. ".")
  end

  reset()
end

local function startVoteTimer(time)  
  voteTimer = event.timer(time, checkResult)
end
 
local function stopVoteTimer()
  if (voteTimer) then event.cancel(voteTimer) end
end

print("[ProofedVote, ver. 1.1]")
chat.setName("Голосование")

while (running) do
  local e = {event.pull()}
 
  if (e[1] == "chat_message") then
    local msg = unicode.lower(e[4])

    if (not voting) then
      currentCmd = internalCommands[msg]
      currentVote = topics[msg]
      voteInitiaterPlayer = e[3]

      if (currentCmd) then
        currentCmd()
      elseif (currentVote) then
        -- Immediately accept a current vote topic as truth.
        if (getOnlinePlayers() <= 1) then
          positiveVote = positiveVote + 1
          votePlayers[voteInitiaterPlayer] = true
          checkResult()
        -- Otherwise is voting.
        else
          voting = true
          startVoteTimer(currentVote.voteTime)

          positiveVote = positiveVote + 1
          votePlayers[voteInitiaterPlayer] = true
     
          chat.say('Началось голосование: "' .. currentVote.voteName .. '". Инициатор: ' .. voteInitiaterPlayer .. ".")
        end
      end
    else
      if (positiveWords[msg] and not votePlayers[ e[3] ]) then
        positiveVote = positiveVote + 1
        votePlayers[ e[3] ] = true
        chat.say('Голосов "ЗА/ПРОТИВ": ' .. positiveVote .. "/" .. negativeVote .. ".")

        -- Immediately accept a current vote topic as truth.
        if (positiveVote >= getOnlinePlayers()) then
          checkResult()
        end
      elseif (negativeWords[msg] and not votePlayers[ e[3] ]) then
        negativeVote = negativeVote + 1
        votePlayers[ e[3] ] = true
        chat.say('Голосов "ЗА/ПРОТИВ": ' .. positiveVote .. "/" .. negativeVote .. ".")
      end
    end
  elseif (e[1] == "component_unavailable") then
    if (e[2] == "debug") then
      stopVoteTimer()
      error("Execution of the program was interrupted, because debug card is unavailable")
    elseif (e[2] == "chat_box") then
      stopVoteTimer()
      error("Execution of the program was interrupted, because chat box is unavailable")
    end
  end
end