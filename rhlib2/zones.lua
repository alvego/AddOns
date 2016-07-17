-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------

function CheckDistance(unit1,unit2)
  return DistanceTo(unit1, unit2)
end

------------------------------------------------------------------------------------------------------------------
function InDistance(unit1,unit2, distance)
  local d = DistanceTo(unit1, unit2)
  return not d or d < distance
end


------------------------------------------------------------------------------------------------------------------
local LastPosX, LastPosY = GetPlayerMapPosition("player")
local InPlace = true
local function UpdateInPlace()
	local posX, posY = GetPlayerMapPosition("player")
    InPlace = (LastPosX == posX and LastPosY == posY)
    LastPosX ,LastPosY = GetPlayerMapPosition("player")
    if not InPlace then InPlaceTime = GetTime() end
end
AttachUpdate(UpdateInPlace)
-- Игрок не двигается (можно кастить)
InPlaceTime = GetTime()
function PlayerInPlace()
    return InPlace and (GetTime() - InPlaceTime > 0.08) and (not IsFalling() or IsSwimming())
end
