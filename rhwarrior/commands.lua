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
        if not InCombatLockdown() and PlayerInPlace() and IsOutdoors() then
          local mount = (IsShift() or IsBattleground() or not IsFlyableArea()) and getRandomMount(groundMounts) or getRandomMount(flyMounts)
          if IsAlt() then mount = "Тундровый мамонт путешественника" end
          if IsSwimming() then mount = "Морская черепаха" end
          DoCommand("mount", mount)
        else
          chat("Вмешательство")
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

---------------------------------------------------------------------------------------------------------------
local bobberGUID = nil
local function updateSpellCreate(event, ...)
    local timestamp, type, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName, spellSchool, amount, info = ...
    if type:match("SPELL_CREATE") and sourceGUID == UnitGUID("player") and spellName == "Рыбная ловля" then
        bobberGUID = destGUID
    end
end
AttachEvent('COMBAT_LOG_EVENT_UNFILTERED', updateSpellCreate)

SetCommand("tryFishLoot",
    function()
      if LootFrame:IsVisible() and IsFishingLoot() then
          for i=1, GetNumLootItems() do
            LootSlot(i)
          end
          CloseLoot()
       end
    end,
    function()
        if not TimerStarted("fishLoot") then
          TimerStart("fishLoot")
          return false
        end
        if TimerMore("fishLoot", 1) then
          TimerReset("fishLoot")
          return true
        end
        return false
    end
)

SetCommand("fish",
    function()
      if LootFrame:IsVisible() and IsFishingLoot() then return false end
      if not IsEquippedItemType("Удочка") then
        if TimerMore('equipweapon', 0.5) then
          oexecute("EquipItemByName('Мастерски сделанная калуакская удочка')")
          TimerStart('equipweapon')
        end
        return
      end
      if not UnitIsCasting("player") == "Рыбная ловля" and UseSpell("Рыбная ловля") then return true end
    end,
    function()

      if InCombatMode() then return true end
      if UnitIsCasting("player") == "Рыбная ловля" then
        local objCount = ObjectsCount()
        for i = 0, objCount - 1 do
          local uid = GUIDByIndex(i)
          if uid and bobberGUID then
            if UnitGUID(uid) == bobberGUID then
              oexecute('InteractUnit("' ..uid .. '")')
              DoCommand('tryFishLoot')
              return true
            end
          end
        end
      else
          if not IsEquippedItemType("Удочка") then
            oexecute("EquipItemByName('Мастерски сделанная калуакская удочка')")
          end
          UseSpell("Рыбная ловля")
      end
      return true
    end
)

---------------------------------------------------------------------------------------------------------------
