-- Death Knight Helper 2 by Alex Tim & Co
------------------------------------------------------------------------------------------------------------------
Teammate = "Nau"
local flyMounts = {
    "Большая ракета любви",
    "Непобедимый"
}
local groundMounts = {
    "Большая ракета любви",
    "Анжинерский чоппер",
    "Черный киражский боевой танк",
    "Непобедимый",
    "Конь смерти Акеруса",
    "Стремительный призрачный тигр"
}
local lastMount = nil
local function getRandomMount(mountList)
  if #mountList ==  1 then return mountList[1] end
  if #mountList > 1 then
    for i = 1, 10 do
      local m = mountList[random(#mountList)]
      if m ~= lastMount then
        lastMount = m
        return m
      end
    end
    return mountList[random(#mountList)]
  end
  return ""
end

_mount = false
SetCommand("mount",
    function(mount)
        if HasBuff("Целеустремленность железного дворфа", 0.01, player) then oexecute('CancelUnitBuff("player", "Целеустремленность железного дворфа")') end
        if HasBuff("Сила таунка", 0.01, player) then oexecute('CancelUnitBuff("player", "Сила таунка")') end
        if HasBuff("Мощь таунка", 0.01, player) then oexecute('CancelUnitBuff("player", "Мощь таунка")') end
        if HasBuff("Скорость врайкулов", 0.01, player) then oexecute('CancelUnitBuff("player", "Скорость врайкулов")') end
        if HasBuff("Ловкость врайкула", 0.01, player) then oexecute('CancelUnitBuff("player", "Ловкость врайкула")') end
        if InGCD() then return true end
        if UseMount(mount) then _mount = true return true end
    end,
    function()
        if _mount == true then
          _mount = false
          return true
        end
        _mount = false
        if IsMounted() or CanExitVehicle() or not IsOutdoors()  or UnitIsCasting("player") then return true end
        if not PlayerInPlace() or InCombatLockdown() then return true end
        return false
    end
)
-----------------------
SetCommand("run",
    nil,
    function()
        if not InCombatLockdown() and PlayerInPlace() and IsOutdoors() then
          local mount = (IsShift() or IsBattleground() or not IsFlyableArea()) and ( GetFreeBagSlotCount() < 3 and "Тундровый мамонт путешественника" or getRandomMount(groundMounts)) or getRandomMount(flyMounts)
          if IsAlt() then mount = "Тундровый мамонт путешественника" end
          DoCommand("mount", mount)
        end
        return true
    end
)
------------------------------------------------------------------------------------------------------------------
SetCommand("defence",
    nil,
    function()
        Defence = true
        chat('Защищаемся')
        return true
    end
)
