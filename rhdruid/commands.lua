-- Druid Rotation Helper by Alex Tim
------------------------------------------------------------------------------------------------------------------
local flyMounts = {
    "Обагренный ледяной покоритель",
}
local groundMounts = {
    "Волшебный петух",
    "Стремительный призрачный тигр",
    "Боевой скакун Грозовой Вершины",
    "Черный боевой баран",
    "Черный боевой медведь",
    "Черный боевой элекк",
    "Большой медведь Blizzard",
    "Огромный серый кодо",
    "Большой черный боевой мамонт",
    "Стремительный зеленый механодолгоног",
    "Стремительный желтый механодолгоног",
    "Стремительный белый рысак",
    "Стремительный игреневый конь"
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
SetCommand("cyclone",
    function(target)
      return DoSpell("Природная стремительность")
    end,
    function(target)
        if not target then target = "target" end
        local stance = GetShapeshiftForm()
        if HasBuff("Природная стремительность") then
          chat("Смерч!")
          DoCommand("spell", "Смерч", target)
          return true
        end
        return false
    end,
    function(target)
        if not target then target = "target" end
        if not IsReadySpell("Природная стремительность") then
          chat("stun !Природная стремительность")
          return true
        end
        if not CanMagicAttack(target) then
          chat("stun !CanMagicAttack: " .. CanMagicAttackInfo)
          return true
        end
        if not InRange("Смерч", target) then
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
        if IsMounted() or CanExitVehicle() or IsFlying() or UnitIsCasting("player") or HasBuff("Неистовое восстановление") or HasBuff("Исступление") then return true end
        return stance1 == nil and stance2 == nil
    end,
    function()
        local stance = GetShapeshiftForm()
        stance1 = stance == 0 and ((HasTalent("Древо Жизни") or HasTalent("Облик лунного совуха")) and 5 or 1) or 0
        stance2 = stance
    end
)
---------------------------------------------------------------------------------------------------------------
SetCommand("followMount",
    nil,
    function()
      local player = "player"
      local stance = GetShapeshiftForm()
      local mounted = IsMounted() or CanExitVehicle() or (stance == 6)
      if mounted then return true end
      local combat = InCombatLockdown()
      local outdoors = IsOutdoors()
      local swimming = IsSwimming()
      local falling = IsFalling()
      local isFlyable = IsFlyableArea()
      if mounted or combat or swimming or falling or not outdoors then return true end
      local ground = IsShift() or IsBattleground() or not isFlyable
      if ground then
        UseShapeshiftForm(0)
        local inPlace = PlayerInPlace()
        FollowPause()
        if not inPlace then
          return false
        end
        if not UnitIsCasting("player") then
          UseMount(getRandomMount(groundMounts))
          return false
        end
      else
        DoCommand("form", 6)
      end
      return true
    end
)
---------------------------------------------------------------------------------------------------------------
SetCommand("followDismount",
    nil,
    nil,
    function()
      local stance = GetShapeshiftForm()
      if CanExitVehicle() then VehicleExit() return false end
      if IsMounted() then Dismount() return false end
      if stance == 4 or stance == 6 then UseShapeshiftForm(0) return false end -- stance == 2 or
      return true
    end
)
---------------------------------------------------------------------------------------------------------------
SetCommand("run",
    nil,
    function()
      local player = "player"
      local mounted = IsMounted() or CanExitVehicle()
      local inPlace = PlayerInPlace()
      local combat = InCombatLockdown()
      local outdoors = IsOutdoors()
      local swimming = IsSwimming()
      local falling = IsFalling()
      local isFlyable = IsFlyableArea()
      local ground = IsShift() or IsBattleground() or not isFlyable

      if not IsStealthed() and not combat and swimming and outdoors and not HasBuff("Водный облик") then
        DoCommand("spell", "Водный облик", player)
        return true
      end

      if HasBuff("Облик кошки") and not inPlace and IsReadySpell("Порыв") then
        DoCommand('spell', "Порыв", player)
        return true
      end
      if IsStealthed() then return true end

      if not mounted and not inPlace and ((ground and outdoors) or combat or not outdoors) and (IsReadySpell("Порыв") or HasBuff("Порыв")) then
        DoCommand("spell", "Водный облик", player)
        return false
      end

      form = (ground or combat) and "Походный облик" or "Облик стремительной птицы"
      if not (mounted or swimming) and not inPlace and outdoors and not HasBuff(form) and (form ~= 4 or not HasBuff("Порыв")) then
        DoCommand("spell", form, player)
        return true
      end

      if not (mounted or combat or swimming or falling) and inPlace and outdoors then
        UseShapeshiftForm(0)
        local mount = ground and getRandomMount(groundMounts) or getRandomMount(flyMounts)
        if IsAlt() then mount = "Тундровый мамонт путешественника" end
        DoCommand("mount", mount)
        return true
      end

      return true
    end
)
---------------------------------------------------------------------------------------------------------------
SetCommand("bye",
    function(target)

      local stance = GetShapeshiftForm()
      if stance ~= 3 then
        UseShapeshiftForm(3)
        return true
      end
      if InCombatLockdown() then
         return PlayerInPlace() and DoSpell('Слиться с тенью')
      end
      return DoSpell('Крадущийся зверь')
    end,
    function()
        return HasBuff('Крадущийся зверь')
    end,
    function()
        if not IsReadySpell('Крадущийся зверь') then
            chat("bye !Крадущийся зверь")
          return false
        end
        if InCombatLockdown() then
          if not IsReadySpell('Слиться с тенью') then
            chat("bye cbt !Слиться с тенью")
            return false
          end
          if not PlayerInPlace() then
            chat("bye cbt !inPlace")
            return false
          end
        end
    end
)
---------------------------------------------------------------------------------------------------------------
SetCommand("form",
    function(stance)
        if UseShapeshiftForm(stance) then
            --print("form ".. stance .."!")
            return true
        end
    end,
    function(stance)
        if UnitIsCasting('player') then
            chat("Кастуем " .. stance)
            return true
        end
        return stance == GetShapeshiftForm()
    end
)
  ---------------------------------------------------------------------------------------------------------------
