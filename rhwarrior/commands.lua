-- Warrior Rotation Helper by Alex Tim & Co
------------------------------------------------------------------------------------------------------------------
Teammate = "Nau"
local flyMounts = {
    "Непобедимый",
    "Пепел Ал'ара",
    "Голова Мимирона",
    "Прогулочная ракета X-53",
    --"Черный летающий киражский боевой танк",
    "Большая ракета любви",
}
local groundMounts = {
    "Большая ракета любви",
    "Белый шерстистый носорог",
    "Непобедимый",
    "Турбодолгоног",
    "Волшебный петух",
    "Белый боевой талбук",
    "Большой боевой медведь",
    "Боевой скакун Грозовой Вершины",
    "Большой лиловый элекк",
    "Большой черный боевой мамонт",
    "Большой медведь Blizzard",
    "Большой кодо Хмельного фестиваля",
    "Белый боевой конь крестоносца",
    "Анжинерский чоппер",
    "Повелитель воронов",
    "Штормградский скакун",
    "Скакун Всадника без головы",
    "Черный боевой баран",
    "Черный киражский боевой танк",
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
---------------------------------------------------------------------------------------------------------------
SetCommand("intervene",
    function(unit)
        if GetShapeshiftForm() == 2 or (HasTalent("Вестник войны") > 0) then
          if DoSpell("Вмешательство", unit, true) then return end
        else
          if DoSpell("Оборонительная стойка") then return end
        end
    end,
    function(unit)
        if UnitMana("player") < 10 and not IsReadySpell("Кровавая ярость") then
          print("intervene - !rage")
          return true
        end
        if not IsInGroup() then
          print("intervene - !group, player")
          return true
        end
        if not IsReadySpell("Вмешательство") then
          print("intervene, !ready")
          return true
        end
        if not UnitInRange(unit) then
          print("intervene - !group", unit)
          return true
        end
        if not InRange("Вмешательство", unit) then
          print("intervene, !range", unit)
          return true
        end
        return false
    end
)
---------------------------------------------------------------------------------------------------------------
SetCommand("run",
    function() return true end,
    function()
        if HasBuff("Вихрь клинков", 0.01, player) then oexecute('CancelUnitBuff("player", "Вихрь клинков")') return true end
        if not InCombatLockdown() and PlayerInPlace() and IsOutdoors() then
          local mount = (IsShift() or IsBattleground() or not IsFlyableArea()) and ( GetFreeBagSlotCount() < 3 and "Тундровый мамонт путешественника" or getRandomMount(groundMounts)) or getRandomMount(flyMounts)
          if IsAlt() then mount = "Тундровый мамонт путешественника" end
          --if IsSwimming() then mount = "Морская черепаха" end
          DoCommand("mount", mount)
        else
          chat("Вмешательство")
          if IsArena() then
            DoCommand("intervene", Teammate)
            return true
          end
          if IsInGroup() and IsReadySpell("Вмешательство") then
            local look = IsMouselooking()
            if (IsArena() or not look) and IsInteractUnit(Teammate) and InRange("Вмешательство", Teammate) then
                DoCommand("intervene", Teammate)
            else
              UpdateUnits()
              local _u = nil
              local _dist = 0
              local _face = false
              for i = 1, #UNITS do
                local u = UNITS[i]
                repeat -- для имитации continue
                  if not InRange("Вмешательство", u) then break end
                  local face = PlayerFacingTarget(u, 15)
                  if look and not face then break end
                  if _face and not face then break end
                  local dist = DistanceTo("player", u)
                  if dist < _dist then break end
                  _u = u
                  _dist = dist
                  _face = face
                until true
              end
              if _u then DoCommand("intervene", _u) end
            end
          end
        end
        return true
    end
)
---------------------------------------------------------------------------------------------------------------
SetCommand("defence",
    function()
      return DoSpell("Оборонительная стойка")
    end,
    function()
        if HasBuff("Вихрь клинков", 0.01, "player") then
          oexecute('CancelUnitBuff("player", "Вихрь клинков")')
          return true
        end
        Defence = true
        chat('Защищаемся')
        return GetShapeshiftForm() == 2
    end
)
---------------------------------------------------------------------------------------------------------------
SetCommand("dispel",
    function()
      if not IsEquippedItemType("Щит") then
        Equip1HShield()
        return true
      end
      return DoSpell("Мощный удар щитом", "target", true)
    end,
    function()
        if not IsValidTarget("target") then return true end
        if not InRange("Мощный удар щитом", "target") then return true end
        if HasBuff("Вихрь клинков", 0.01, "player") then return true end
        if IsReadySpell("Мощный удар щитом") then return false end
        chat("Мощный удар щитом")
        return not IsSpellNotUsed('Мощный удар щитом', 1)
    end
)
---------------------------------------------------------------------------------------------------------------
SetCommand("shatter",
    function()
      local stance = GetShapeshiftForm()
      if stance ~= 1 and  DoSpell("Боевая стойка") then
        return true
      end
      return DoSpell("Сокрушительный бросок", "target", true)
    end,
    function()
        if not IsValidTarget("target") then return true end
        if not InRange("Сокрушительный бросок", "target") then return true end
        if IsReadySpell("Сокрушительный бросок") then return false end
        local stance = GetShapeshiftForm()
        if stance ~= 1 then return false end
        chat('Сокрушительный бросок')
        if UnitMana100('player') >= 25 and HasBuff("Вихрь клинков", 0.01, "player") then
          oexecute('CancelUnitBuff("player", "Вихрь клинков")')
        end
        return not IsSpellNotUsed('Сокрушительный бросок', 1)
    end
)
---------------------------------------------------------------------------------------------------------------
SetCommand("retaliation",
    function()
      local stance = GetShapeshiftForm()
      if stance ~= 1 and  DoSpell("Боевая стойка") then
        return true
      end
      return UseSpell("Возмездие")
    end,
    function()
        if IsReadySpell("Возмездие") then return false end
        local stance = GetShapeshiftForm()
        if stance ~= 1 then return false end
        chat('Возмездие')
        return not IsSpellNotUsed('Возмездие', 1)
    end
)
---------------------------------------------------------------------------------------------------------------
SetCommand("disarm",
    function()
      local stance = GetShapeshiftForm()
      if stance ~= 2 and  DoSpell("Оборонительная стойка") then
        return true
      end
      return DoSpell("Разоружение", "target", true)
    end,
    function()
        if IsReadySpell("Разоружение") then return false end
        local stance = GetShapeshiftForm()
        if stance ~= 2 then return false end
        chat('Разоружение')
        return not IsSpellNotUsed('Разоружение', 1)
    end
)
---------------------------------------------------------------------------------------------------------------
SetCommand("spell",
    function(spell, target)
        if DoSpell(spell, target, true) then
            chat(spell.."!",1)
            return true
        end
    end,
    function(spell, target)
        if not HasSpell(spell) then
            chat(spell .. " - нет спела!")
            return true
        end
        if target and not InRange(spell, target) then
            chat(spell .. " - неверная дистанция!")
            return true
        end
        if not IsSpellNotUsed(spell, 1)  then
            chat(spell .. " - успешно сработало!")
            return true
        end
        if not IsReadySpell(spell) then
            chat(spell .. " - не готово!")
            return true
        end

        local cast = UnitCastingInfo("player")
        if spell == cast then
            chat("Кастуем " .. spell)
            return true
        end
        return false
    end
)
---------------------------------------------------------------------------------------------------------------
