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
SetCommand("stun",
    function(target)
      local stance = GetShapeshiftForm()
      if stance ~= 1 then
        UseShapeshiftForm(1)
        return true
      end
      return DoSpell("Исступление")
    end,
    function(target)
        if not target then target = "target" end
        local stance = GetShapeshiftForm()
        if HasBuff("Исступление") then
          chat("stun Оглушить!")
          DoCommand("spell", "Оглушить", target)
          return true
        end
        if stance ~= 1 then
          if not IsReadySpell("Исступление") then
            chat("stun !Исступление")
            return true
          end
        end
        if not IsReadySpell("Оглушить") then
          chat("stun !IsReady")
          return true
        end
        if not CanAttack(target) then
            chat("stun !CanAttack")
          return true
        end
        if not InRange("Оглушить", target) then
          chat("stun !InRange")
          return true
        end

        return false
    end
)
---------------------------------------------------------------------------------------------------------------
local stance1, stance2
SetCommand("unRoot",
    function()
      --if not AdvMode then return true end
      local stance = GetShapeshiftForm()
      if (stance1 and stance ~= stance1) then
        return UseShapeshiftForm(stance1)
      else
        stance1 = nil
      end
      if (stance2 and stance ~= stance2) then
        return UseShapeshiftForm(stance2)
      else
        stance2 = nil
      end
      return false
    end,
    function()
        if IsMounted() or CanExitVehicle() or IsFlying() or UnitIsCasting("player") then return true end
        return stance1 == nil and stance2 == nil
    end,
    function()
        local stance = GetShapeshiftForm()
        stance1 = stance == 0 and ((HasTalent("Древо Жизни") or HasTalent("Облик лунного совуха")) and 5 or 1) or 0
        stance2 = stance
        return stance1
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

      if not combat and swimming and outdoors and stance ~= 2 then
        DoCommand("form", 2)
        return true
      end

      form = (ground or combat) and 4 or 6
      if not (mounted or swimming) and not inPlace and outdoors and stance ~= form then
        DoCommand("form", form)
        return true
      end

      if not (mounted or combat or swimming or falling) and inPlace and outdoors then
        UseShapeshiftForm(0)
        local mount = (IsShift() or IsBattleground() or not isFlyable) and getRandomMount(groundMounts) or getRandomMount(flyMounts)
        if IsAlt() then mount = "Тундровый мамонт путешественника" end
        DoCommand("mount", mount)
        return true
      end

      return true
    end
)
---------------------------------------------------------------------------------------------------------------
SetCommand("form",
    function(stance)
        if UseShapeshiftForm(stance) then
            print("form ".. stance .."!")
            return true
        end
    end,
    function(stance)
        if UnitIsCasting('player') then
            chat("Кастуем " .. spell)
            return true
        end
        return stance == GetShapeshiftForm()
    end
)
---------------------------------------------------------------------------------------------------------------
