-- Druid Rotation Helper by Alex Tim
------------------------------------------------------------------------------------------------------------------
local flyMounts = {
    "Обагренный ледяной покоритель",
}
local groundMounts = {
    "Волшебный петух",
    "Стремительный призрачный тигр"
}

local function getRandomMount(mountList)
    return mountList[random(#mountList)]
end

_mount = false
SetCommand("mount",
    function(mount)
        if InGCD() then return true end
        if UseMount(mount) then _mount = true return true end
    end,
    function()
        if _mount then
          _mount = false
          return true
        end
        if IsMounted() or CanExitVehicle() or not IsOutdoors()  or UnitIsCasting("player") then return true end
        if not PlayerInPlace() or InCombatLockdown() then return true end
        return false
    end
)
---------------------------------------------------------------------------------------------------------------
SetCommand("run",
    function() return true end,
    function()
      local player = "player"
      local mounted = IsMounted() or CanExitVehicle()
      local inPlace = PlayerInPlace()
      local combat = InCombatLockdown()
      local outdoors = IsOutdoors()
      local swimming = IsSwimming()
      local falling = IsFalling()
      local isFlyable = IsFlyableArea()
      local stance = GetShapeshiftForm()
      local ground = IsShift() or IsBattleground() or not isFlyable

      if falling and stance ~= (not ground and outdoors and 3 or 6) then
        DoCommand("spell",  not ground and outdoors and "Облик стремительной птицы" or "Облик кошки", player)
        return true
      end

      if swimming and outdoors and stance ~= 2 then
        DoCommand("spell", "Водный облик", player)
        return true
      end

      if not (mounted or combat or swimming or falling) and not inPlace and outdoors and stance ~= (ground and 4 or 6) then
        DoCommand("spell", ground and "Походный облик" or "Облик стремительной птицы" , player)
        return true
      end

      if not (mounted or combat or swimming or falling) and inPlace and outdoors then
        if stance ~= 0 then omacro("/cancelform") end
        local mount = (IsShift() or IsBattleground() or not isFlyable) and getRandomMount(groundMounts) or getRandomMount(flyMounts)
        if IsAlt() then mount = "Тундровый мамонт путешественника" end
        DoCommand("mount", mount)
        return true
      end

      return true
    end
)
---------------------------------------------------------------------------------------------------------------
