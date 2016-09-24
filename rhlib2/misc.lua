-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
--UIParentLoadAddOn("Blizzard_DebugTools");
--DevTools_Dump(n)

--[[
  /run UIParentLoadAddOn("Blizzard_DebugTools");
  /fstack true
  /etrace
]]

-- wow-circle error fix
local _format = format
format = function(str, ...)
  if not str then
    str = ""
    for i = 1, select('#', ...) do
        str = str .. '%s '
    end
  else
    str = gsub(str, "% ", "%s ")
  end
  return _format(str, ...)
end
------------------------------------------------------------------------------------------------------------------
local GetTime = GetTime
------------------------------------------------------------------------------------------------------------------

function echo(msg)
    UIErrorsFrame:Clear()
    UIErrorsFrame:AddMessage(msg, 0.0, 1.0, 0.0, 53, 2);
end
------------------------------------------------------------------------------------------------------------------
local lastMsg = {}
function chat(msg, r, g, b)
    r = r or 1.0
    b = b or 0.5
    g = g or 0.5
    local key  =  r * 100 + g * 10 + b
    if lastMsg[key] == msg and TimerLess('EchoMsg'..key, 2) then return end

    DEFAULT_CHAT_FRAME:AddMessage(msg, r, b, g);
    TimerStart('EchoMsg'..key)
    lastMsg[key] = msg
end
------------------------------------------------------------------------------------------------------------------
function tContainsKey(table, key)
    local result = false
    for name,value in pairs(table) do
        if key == name then
          result = true
          break
        end
    end
    return result
end
------------------------------------------------------------------------------------------------------------------
function sContains(str, sub)
    if (not str or not sub) then
      return false
    end
    return (strlower(str):find(strlower(sub), 1, true) ~= nil)
end

------------------------------------------------------------------------------------------------------------------
function IsMouse(n)
    return  IsMouseButtonDown(n) == 1
end

------------------------------------------------------------------------------------------------------------------
function IsCtr()
    return  (IsControlKeyDown() == 1 and not GetCurrentKeyBoardFocus())
end

------------------------------------------------------------------------------------------------------------------
function IsAlt()
    return  (IsAltKeyDown() == 1 and not GetCurrentKeyBoardFocus())
end

------------------------------------------------------------------------------------------------------------------
function IsShift()
    return  (IsShiftKeyDown() == 1 and not GetCurrentKeyBoardFocus())
end
------------------------------------------------------------------------------------------------------------------
local timers = {}
function TimerReset(name)
  timers[name] = 0
end
function TimerStarted(name)
  return (timers[name] or 0) > 0
end
function TimerStart(name, offset)
  timers[name] = GetTime() + (offset or 0)
end
function TimerElapsed(name)
  return  GetTime() - (timers[name] or 0)
end
function TimerLess(name, less)
  return TimerElapsed(name) < (less or 0)
end

function TimerMore(name, less)
  return TimerElapsed(name) > (less or 0)
end
