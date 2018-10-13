-- Druid Rotation Helper by Alex Tim
-----------------------------------------------------------------------------------------------------------------
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
        if IsMounted() or CanExitVehicle() or not IsOutdoors() or UnitIsCasting("player") then return true end
        if not PlayerInPlace() or InCombatLockdown() then return true end
        return false
    end
)
---------------------------------------------------------------------------------------------------------------
SetCommand("run",
    nil,
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
      local cat = HasBuff("Облик кошки")
      local bird = HasBuff("Облик стремительной птицы")
      local travel = HasBuff("Походный облик")
      local fish = HasBuff("Водный облик")
      local stealth = IsStealthed()

      if inPlace and outdoors and not (mounted or combat or swimming or falling)  then
        local mount = ground and getRandomMount(groundMounts) or getRandomMount(flyMounts)
        if IsAlt() then mount = "Тундровый мамонт путешественника" end
        UseShapeshiftForm(0)
        DoCommand("mount", mount)
        return true
      end

      if outdoors and not (combat or bird or ground) then
        chat("Падение -> птица")
        DoCommand("spell", "Облик стремительной птицы")
        return true
      end

      if falling and not (combat or cat) then
        chat("Падение -> кошка")
        DoCommand("spell", "Облик кошки")
        return true
      end

      if swimming and outdoors and not (combat or fish) then
        chat("Вода -> рыба")
        DoCommand("spell", "Водный облик")
        return true
      end

      if cat and not inPlace and IsReadySpell("Порыв") then
        DoCommand('spell', "Порыв", player)
        return true
      end


      if not (mounted or inPlace or cat or travel) and ((ground and outdoors) or combat or not outdoors) then
        DoCommand("spell", "Облик кошки", player)
        return true
      end

      if cat and (ground and outdoors) and not (IsReadySpell("Порыв") or HasBuff("Порыв")) then
        DoCommand("spell", "Походный облик", player)
        return true
      end

      return true
    end
)
-----------------------------------------------------------------------------------------------------------------
SetCommand("defence",
    function()
      return DoSpell("Облик лютого медведя")
    end,
    function()
        Defence = true
        if IsAttack() and not AutoTaunt then
          chat('Зажата атака, остаемся в коте')
          return true
        end
        chat('Защищаемся')
        return HasBuff("Облик лютого медведя")
    end
)
-----------------------------------------------------------------------------------------------------------------
SetCommand("bearHeal",
    function()
      if not HasBuff("Инстинкты выживания") then
        if DoSpell("Инстинкты выживания") then return true end
        return false
      end
      local mana = UnitMana("player")
      if mana < 90 and not HasBuff("Исступление") and DoSpell("Исступление") then return true end
      if not HasBuff("Неистовое восстановление") then
        if DoSpell("Неистовое восстановление") then return true end
        return false
      end
    end,
    function()
        chat('Хилимся')
        return HasBuff("Неистовое восстановление")
    end,
    function()
      if not HasBuff("Облик лютого медведя") then
        chat('Не в мишке')
        return true
      end
      local mana = UnitMana("player")
      if mana < 60 and not IsReadySpell("Исступление") and not HasBuff("Исступление", 5) then
        chat('Раги всего ' .. mana .. ' и Исступление не готово')
        return true
      end
      if not IsReadySpell("Инстинкты выживания") and not HasBuff("Инстинкты выживания", 10) then
        chat('Инстинкты выживания не готово')
        return true
      end
      if not IsReadySpell("Неистовое восстановление") then
        chat('Неистовое восстановление не готово')
        return true
      end
      return false
    end
)

-----------------------------------------------------------------------------------------------------------------
SetCommand("bye",
    function(target)
      if InCombatLockdown() then
        if not  PlayerInPlace() then
          chat("bye combat !inPlace")
          return false
        end
        return DoSpell('Слиться с тенью')
       end
      if not HasBuff("Облик кошки") then
        return DoSpell("Облик кошки")
      end
      return DoSpell('Крадущийся зверь')
    end,
    function()
        return HasBuff('Крадущийся зверь')
    end,
    function()
        if not IsReadySpell('Крадущийся зверь') then
            chat("bye !Крадущийся зверь")
          return true
        end
        if InCombatLockdown() then
          if not IsReadySpell('Слиться с тенью') then
            chat("bye combat !Слиться с тенью")
            return true
          end
          if not PlayerInPlace() then
            chat("bye combat !inPlace")
            return true
          end
        end
        if UnitIsCasting("player") then
            StopCast("bye")
        end
        oexecute("StopAttack()")
    end
)
-----------------------------------------------------------------------------------------------------------------
