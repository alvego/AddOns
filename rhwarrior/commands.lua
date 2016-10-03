-- Warrior Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
Teammate = "Nau"
local flyMounts = {
    "Непобедимый",
    "Пепел Ал'ара",
    "Голова Мимирона"
}
local groundMounts = {
    "Непобедимый",
    "Турбодолгоног",
    "Волшебный петух",
    "Большой кодо Хмельного фестиваля",
    "Анжинерский чоппер",
    "Повелитель воронов",
    "Черный киражский боевой танк",
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
        if HasBuff("Вихрь клинков", 0.01, player) then oexecute('CancelUnitBuff("player", "Вихрь клинков")') end
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
        local warbringer = HasTalent("Вестник войны") > 0
        if warbringer or stance == 2 then
          if DoSpell("Вмешательство", unit, true) then return end
        else
          if DoSpell("Оборонительная стойка") then return end
        end
    end,
    function(unit)
        if UnitMana(player) < 10 and not UseSpell("Кровавая ярость") then print("intervene - !rage") return true end
        if not IsInGroup() then  print("intervene - !group, player") return true end
        if not IsReadySpell("Вмешательство") then  print("intervene, !group") return true end
        if not UnitInRange(unit) then print("intervene - !group", unit) return true end
        if not InRange("Вмешательство", unit) then print("intervene, !range", unit) return true end
        return false
    end
)
---------------------------------------------------------------------------------------------------------------
SetCommand("run",
    function() return true end,
    function()
        if not InCombatLockdown() and PlayerInPlace() and IsOutdoors() then
          local mount = (IsShift() or IsBattleground() or not IsFlyableArea()) and getRandomMount(groundMounts) or getRandomMount(flyMounts)
          if IsAlt() then mount = "Тундровый мамонт путешественника" end
          if IsSwimming() then mount = "Морская черепаха" end
          DoCommand("mount", mount)
        else
          if IsInGroup() and IsReadySpell("Вмешательство") then
            local look = IsMouselooking()
            if not look and IsInteractUnit(Teammate) and UnitInRange(Teammate) and InRange("Вмешательство", Teammate) then
                DoCommand("intervene", Teammate)
            else
              UpdateObjects()
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
            end
            if _u then DoCommand("intervene", _u) end
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
        if HasBuff("Вихрь клинков", 0.01, player) then
          oexecute('CancelUnitBuff("player", "Вихрь клинков")')
          return true
        end
        Defence = true
        chat('Защищаемся')
        return GetShapeshiftForm() == 2
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
