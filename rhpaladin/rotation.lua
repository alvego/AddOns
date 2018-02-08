-- Paladin Rotation Helper by Alex Tim & Co
------------------------------------------------------------------------------------------------------------------
local peaceBuff = {"Пища", "Питье"}
local dispelTypes = {'Magic', 'Disease', 'Poison'}
local steathClass = {"ROGUE", "DRUID"}
local reflectBuff = {"Отражение заклинания", "Эффект тотема заземления"}
local physicDebuff = {"Смертельный удар"}

local redDispelList = {
    "Превращение",
    "Глубокая заморозка",
    "Огненный шок",
    "Покаяние",
    "Молот правосудия",
    "Замедление",
    "Эффект ледяной ловушки",
    "Эффект замораживающей стрелы",
    "Удушение",
    "Антимагия - немота",
    "Безмолвие",
    "Волшебный поток",
    "Вой ужаса",
    "Ментальный крик",
    "Успокаивающий поцелуй"
}

local function canDispel(u)
  return HasDebuff(dispelTypes, 1, u) and not HasDebuff("Нестабильное колдовство", 0.1, u)
end

function Idle()
  local target = "target"
  local player = "player"
  -- Дизамаунт
  if IsAttack() then
      if HasBuff("Парашют") then
        oexecute('CancelUnitBuff("player", "Парашют")')
      end
      if CanExitVehicle() then VehicleExit() end
      if IsMounted() then
        if HasBuff("Аура воина Света") then
           oexecute('CancelUnitBuff("player", "Аура воина Света")')
          if HasSpell("Частица Света") and DoSpell("Аура сосредоточенности") then return end
          if HasSpell("Удар воина Света") and DoSpell("Аура воздаяния")  then return end
        end
        Dismount()
      end
  end
  -- дайте поесть (побегать) спокойно
  --if not IsPvP() and IsMounted() and not HasBuff("Аура воина Света") and DoSpell("Аура воина Света") then return end

  if not IsAttack() and (IsMounted() or CanExitVehicle() or HasBuff(peaceBuff)) then return end

  -- Heal Rotation ------------------------------------------------------------------------------------------------------------------------------
  if HasSpell("Частица Света") then
      Heal()
      return
   end
   if HasSpell("Щит мстителя") then
      Tank()
      return
   end
   --DD_rotation--------------------------------------------------------------------------------------------------------------------------------------------
  if not HasSpell("Удар воина Света") then return end
  if IsPvP() then
      PvP()
    else
      PvE()
  end
end
------------------------------------------------------------------------------------------------------------------
function Heal()
    local target = "target"
    local player = "player"
    local focus = "focus"


    if IsPvP() and not HasBuff("Праведное неистовство") and IsSpellNotUsed("Праведное неистовство", 5) and DoSpell("Праведное неистовство") then return end
    if not HasBuff("Аура") and DoSpell("Аура сосредоточенности", player) then return end
    if not HasBuff("Печать") and DoSpell("Печать мудрости", player) then return end
    if not InCombatLockdown() and not IsArena() and not HasMyBuff("благословение королей") and not HasMyBuff("благословение могущества") then
        if not HasBuff("благословение королей") and DoSpell("Великое благословение королей", player) then return end
    end

    local hp = UnitHealth100(player)
    local mana = UnitMana100(player)
    if hp < 25 and DoSpell("Божественный щит", player) then return end
    if hp < 25 and not IsReadySpell("Божественный щит") and not HasMyBuff("Божественный щит", 0.1, player) and DoSpell("Божественная защита", player) then return end
    local thp = InInteractRange(teammate) and UnitHealth100(teammate) or nil
    if hp < 55 or (thp and thp < 55) then
      local bubble = HasMyBuff("Божественный щит", 0.1, player)
      if not bubble then
        -- Auto AntiControl --------------------------------------------------------
        local silence = false;
        local debuff, _, _, _, _, _duration, _expirationTime = HasDebuff(ControlList, 3, player)
        if not debuff then
          debuff, _, _, _, _, _duration, _expirationTime =  HasDebuff(SilenceList, 3, player)
          if debuff then silence = true end
        end

        if debuff and ((_duration - (_expirationTime - GetTime())) > 0.45) then
          if not silence or (hp < 35 or (thp and thp < 35)) then
            if IsSpellNotUsed("Божественный щит", 1) and DoSpell("Каждый за себя") then chat("Каждый за себя! " .. debuff)  return end
            if not IsReadySpell("Каждый за себя") and IsSpellNotUsed("Каждый за себя", 1) and DoSpell("Божественный щит") then chat("Божественный щит! " .. debuff) return end
          end
        end
        if not HasDebuff(SilenceList, 0.01, player) and GetSpellCooldownLeft("Вспышка Света") < 2 and DoSpell("Мастер аур") then chat("Мастер аур!") return end
      end
    end

    if IsSpellNotUsed("Длань жертвенности", 12) or IsSpellNotUsed("Священная жертва", 10) then
      if hp > 50 and thp and thp < 45 and DoSpell("Священная жертва", teammate) then return end
      if hp > 60 and thp and thp < 50 and DoSpell("Длань жертвенности", teammate) then return end
      if hp < 40 and DoSpell("Священная жертва", player) then return end
    end
    if thp and thp < 30 and HasDebuff(physicDebuff, 2, teammate) and DoSpell("Длань защиты", teammate) then chat("Длань защиты на"..teammate) return end

    if InCombatLockdown() then
      if hp < 50 and UseItem("Камень здоровья из Скверны") then return end
      if not (InDuel() or IsArena()) then
        if hp < 30 and UseItem("Рунический флакон с лечебным зельем") then return end
        if mana < 25 and UseItem("Рунический флакон с зельем маны") then return end
      end
    end
    if (IsPvP() or InCombatLockdown()) and hp < 40 and DoSpell("Длань спасения", player) then return end

    local u = player
    local du = nil
    if InInteractRange(teammate) and canDispel(teammate) then du = teammate end
    if not du and canDispel(u) then du = u end
    local hasShield = HasMyBuff("Священный щит",1, player) and true or false
    local hasLight = HasMyBuff("Частица Света",1, player) and true or false
    local h = UnitHealth100(u)
    local fatUnit = nil
    local fatHP = 0
    UpdateUnits()
    for i = 1, #UNITS do
      local _u = UNITS[i]
      if IsVisible(_u) then
      local _h = UnitHealth100(_u)
      local _h_mult = 1
      local _maxHP  = UnitHealthMax(_u)
      if _maxHP > fatHP then
        fatHP = _maxHP
        fatUnit = _u
      end
      if not hasShield and HasMyBuff("Священный щит",1,_u) then hasShield = true end
      if not hasLight and HasMyBuff("Частица Света",1,_u) then
        hasLight = true
         _h_mult = 1.1
      end
      if (_h * _h_mult) < h then
        u = _u
        h = _h * _h_mult
        if not du and canDispel(u) then du = u end
      end
    end
    end
    if not u then return end
    local l = UnitLostHP(u)

    if not IsArena() and InCombatLockdown() and IsInGroup() and IsSpellNotUsed("Частица Света", 10) and not hasLight then
      if InInteractRange(teammate) then
        if DoSpell("Частица Света",  teammate) then return end
      else
        if not IsOneUnit(player, fatUnit) and DoSpell("Частица Света",  fatUnit) then return end
      end
    end

    if mana > 50 then l = l * 1.5 end
    if HasBuff("Божественное одобрение") and DoSpell("Шок небес", u) then return end
    if (h < 35) and not IsReadyItem("Подвеска истинной крови") and GetSpellCooldownLeft("Шок небес") < 0.1 and DoSpell("Божественное одобрение") then return end
    if (h < 35) and UseEquippedItem("Подвеска истинной крови", u) then return end
    if InCombatMode() and h < 95 and UseEquippedItem("Украшенные перчатки разгневанного гладиатора") then return end
    if InCombatMode() and mana < 90 and UseEquippedItem("Осколок чистейшего льда") then return end

    if h > 45 and AdvMode then

      local ftar = nil --Вороная горгулья
      for i = 1, #TARGETS do
        local t = TARGETS[i]
        if IsValidTarget(t) then
           local ctype = UnitCreatureType(t)
           if (ctype =="Нежить" or ctype == "Демон") and CanMagicAttack(t) and InRange("Изгнание зла", t) then
              ftar = t
              if UnitName(t) == "Вороная горгулья" then  break end
           end
         end
       end
      if ftar and DoSpell("Изгнание зла", ftar) then  return true  end

      local mh, mt
      for i = 1, #TARGETS do
        local t = TARGETS[i]
        if CanMagicAttack(t) and UnitHealth100(t) < 19.99  and InRange("Молот гнева", t) then
          local _h = UnitHealth100(t)
          if not mh or mh > _t then
            mh = _h
            mt = t
          end
        end
      end
      if mt and DoSpell("Молот гнева", mt) then return end

    end

    if IsArena() and InInteractRange(shieldUnit) and IsSpellNotUsed("Священный щит", 5) and not HasMyBuff("Священный щит", 1, shieldUnit) and DoSpell("Священный щит", shieldUnit) then return end

    if not IsArena() and InCombatMode() and IsSpellNotUsed("Священный щит", 5) and not hasShield then
      if InInteractRange(teammate) then
        if DoSpell("Священный щит",  teammate) then return end
      else
        if h < 60 and not HasMyBuff("Священный щит", 1, u) and DoSpell("Священный щит", u) then return end
      end
    end

    if du and IsCtr()--[[(IsCtr() or (h > 45 and (IsSpellNotUsed("Очищение", 2) or HasDebuff(redDispelList, 1, du))))]] and DoSpell("Очищение", du) then return end
    if IsArena() and h < 95 and DoSpell("Шок небес", u) then return end
    if not IsArena() and (h < 98 or l > 3000) and DoSpell("Шок небес", u) then return end
    local infusion = HasBuff("Прилив Света")
    if (h < 50 or l > 2000) then
      local master = HasBuff("Мастер аур")
      local inPlace = PlayerInPlace()
      local canCastFlash = --[[not IsArena() or]] master
       if not inPlace and not infusion and canCastFlash then
         Notify((master and "Мастер! " or "Стой! ") .. UnitName(u) .. " hp: " .. h)
         if master and AdvMode then oexecute("MoveForwardStop()") end
       end
       if --[[(infusion or (canCastFlash and inPlace)) and]] DoSpell("Вспышка Света", u) then return end

    end

  if AdvMode and TimerMore('HolyDMG', 5) then
    if IsValidTarget(target) and UnitIsPlayer(target) and (tContains(steathClass, GetClass(target) and DistanceTo(player, target) > 25) or not UnitAffectingCombat(target) or HasBuff(reflectBuff, 1, target)) then
      if DoSpell("Правосудие света", target) then TimerStart('HolyDMG') return end
      if DoSpell("Длань возмездия", target) then TimerStart('HolyDMG') return end
    end

    if IsValidTarget(focus) and UnitIsPlayer(focus) and (tContains(steathClass, GetClass(focus) and DistanceTo(player, focus) > 25) or not UnitAffectingCombat(focus) or HasBuff(reflectBuff, 1, focus)) then
      if DoSpell("Правосудие света", focus) then TimerStart('HolyDMG') return end
      if DoSpell("Длань возмездия", focus) then TimerStart('HolyDMG') return end
    end

    if IsPvP() and not InCombatLockdown() then
    TryTarget()
    if not IsValidTarget(target) then return end
      if DoSpell("Правосудие света", target) then TimerStart('HolyDMG') return end
      if DoSpell("Длань возмездия", target) then TimerStart('HolyDMG') return end
    --if IsEquippedItemType("Щит") and DoSpell("Щит праведности", target) then return end
    end
  end
end
------------------------------------------------------------------------------------------------------------------
function Tank()
    local player = "player"
    local target = "target"
    local hp = UnitHealth100(player)
    local mana = UnitMana100(player)
    local aoe = false

    if IsShift() then
      aoe = true
    else
      if not InDuel() then
        local enemyCount = GetEnemyCountInRange(6)
        aoe = enemyCount >= 3
      end
    end

        -- heals
    if hp < 30 and DoSpell("Возложение рук", player) then return end

    if InCombatLockdown() then
      if hp < 50 and not (HasBuff("Затвердевшая кожа")) and UseEquippedItem("Проржавевший костяной ключ") then return true end
      if hp < 50 and UseItem("Камень здоровья из Скверны") then return end
      if hp < 30 and UseItem("Рунический флакон с лечебным зельем") then return end
      if mana < 25 and UseItem("Рунический флакон с зельем маны") then return end
    end

    if IsAlt() or InCombatLockdown() then
      -- Buffs
      if not HasBuff("Благословение") and DoSpell("Великое благословение неприкосновенности", player) then return end
      if not HasBuff("Праведное неистовство") and DoSpell("Праведное неистовство") then return end
      if HasSpell("Печать мщения") and not HasBuff("Печать мщения") and DoSpell("Печать мщения") then return end
      if HasSpell("Печать порчи") and not HasBuff("Печать порчи") and DoSpell("Печать порчи") then return end
      if not HasBuff("Священный щит") and DoSpell("Священный щит", player) then return end
      if not HasBuff("Святая клятва") and DoSpell("Святая клятва") then return end
      if not HasBuff("Щит небес", 0.8) and DoSpell("Щит небес") then return end
    end

  if TimerMore("AGGRO", 0.5) then
      TimerStart("AGGRO")
      UpdateUnits()

      if IsReadySpell("Длань возмездия") then
        for i = 1, #TARGETS do
          local uid = TARGETS[i]
          local name = UnitName(uid)
          if name and UnitAffectingCombat(uid) and not AggroIgnored[name] then
            for j = 1, #UNITS do
              local u = UNITS[j]
              local n = UnitName(u)
              if n and not IsOneUnit(u, player) and not AggroIgnored[n] and UnitThreat(u, uid) == 3 and DoSpell("Длань возмездия", uid) then
                chat("Длань возмездия на " .. name .. ", снимаем с " .. n )
                return
              end
            end -- for units
          end -- not ignored
        end --for units
      end --ready

      if IsReadySpell("Праведная защита") then
        local _u = nil
        local _c = 0
        local _n = ""
        for i = 1, #UNITS do
          local u = UNITS[i]
          local name = UnitName(u)

          if name and not AggroIgnored[name] and not IsOneUnit(u, player) and UnitThreat(u) == 3 then
            local c = 0;
            for j = 1, #TARGETS do
              if c >= 0 then
                local uid = TARGETS[j]
                local n = UnitName(uid)
                if n and UnitThreat(u, uid) == 3 then
                  if AggroIgnored[n] then
                    c = -1
                  else
                    c = c + 1
                  end
                end
              end --c >= 0
              if c > _c then
                print(name, c, _c)
                _u = u
                _n = name
                _c = c
              end
            end -- for units
          end -- not ignored
        end --for units
        if _u and DoSpell("Праведная защита", _u) then
          chat("Праведная защита на " .. _n .. ", на нем висело " .. _c .. " мобов")
          return
        end
      end --ready

    end --aggro


    TryTarget()
    if not CanAttack(target) then return end
    if (IsAttack() or UnitAffectingCombat(target)) then oexecute("StartAttack()") end
    if not IsValidTarget(target) then return end

    -- пытаемся сдиспелить с себя каку
    if IsCtr() and DoSpell("Очищение" , player) then return end

    FaceToTarget(target)
    if DoSpell("Щит мстителя", target) then return end
    if aoe then
        if mana > 50 and InMelee(target) and DoSpell("Освящение", target) then return end
        if (UnitCreatureType(target) == "Нежить") and mana > 60 and InMelee(target) and DoSpell("Гнев небес", target) then return end
    end
    if UnitHealth100(target) < 20 and DoSpell("Молот гнева", target) then return end
    if DoSpell("Молот праведника", target) then return end
    if DoSpell((mana > 55) and "Правосудие света" or "Правосудие мудрости", target) then return end
    if DoSpell("Щит праведности", target) then return end
end
------------------------------------------------------------------------------------------------------------------
function PvE()
  local target = "target"
  local player = "player"
  --if HasBuff("Праведное неистовство") then oexecute('CancelUnitBuff("player", "Праведное неистовство")') end
  if not HasBuff("Печать") and DoSpell("Печать мщения", player) then return  end
  local hp = UnitHealth100(player)
  local mana = UnitMana100(player)
  if hp < 30 and DoSpell("Возложение рук", player) then return end
  if hp < 25 and DoSpell("Божественный щит", player) then return end
  if InCombatLockdown() then
    if hp < 50 and UseItem("Камень здоровья из Скверны") then return end
    if hp < 30 and UseItem("Рунический флакон с лечебным зельем") then return end
    if mana < 25 and UseItem("Рунический флакон с зельем маны") then return end
  end
  if HasBuff("Искусство войны") then
     if hp < 30 and DoSpell("Вспышка Света", player) then return end
     --if IsInteractUnit(teammate) and UnitHealth100(teammate) < 30 and DoSpell("Вспышка Света", teammate) then return end
  end
  TryTarget()
  if not CanAttack(target) then return end
  if (IsAttack() or UnitAffectingCombat(target)) then oexecute("StartAttack()") end
  if not IsValidTarget(target) then return end
  if HasBuff("Проклятие хаоса") then oexecute('CancelUnitBuff("player", "Проклятие хаоса")') end
  if UnitHealth100(target) < 20 and DoSpell("Молот гнева", target) then return end

  FaceToTarget(target)
  if mana < 35 and DoSpell("Святая клятва") then return end

  --if not IsInGroup() and not IsOneUnit(player, target .. "-"..target) and DoSpell("Длань возмездия", target) then return end
  if (InMelee(target) or DistanceTo(player, target) < 8) and DoSpell("Божественная буря") then return end

  if DoSpell("Удар воина Света", target) then return end

  if CanMagicAttack(target) and DoSpell(IsAlt() and "Правосудие справедливости" or "Правосудие мудрости", target) then return end
  if HasBuff("Искусство войны") and CanMagicAttack(target) and DoSpell("Экзорцизм", target) then return end
  if UseEquippedItem("Перчатки ануб'арского охотника") then return end
  if (UnitCreatureType(target) == "Нежить") and mana > 30 and DistanceTo(player, target) < 8 and DoSpell("Гнев небес") then return end
  if IsEquippedItemType("Щит") and DoSpell("Щит праведности", target) then return end
  if mana > 30 and InMelee(target) and DoSpell("Освящение") then return end
  --if not HasBuff("Священный щит") and DoSpell("Священный щит", player) then return end
end

------------------------------------------------------------------------------------------------------------------
local last2H
function PvP()
  local target = "target"
  local player = "player"
  local isFinishHim = CanAttack(target) and UnitHealth100(target) < 35
  if not isFinishHim and not HasBuff("Аура") and DoSpell("Аура воздаяния")  then return end
  if not HasBuff("Печать") and DoSpell("Печать праведности", player) then return  end
  if IsCtr() and HasDebuff(dispelTypes, 1, player) and DoSpell("Очищение", player) then return end
  if not isFinishHim and not HasBuff("Праведное неистовство") and IsSpellNotUsed("Праведное неистовство", 5) and DoSpell("Праведное неистовство") then return end
  if not isFinishHim and not InCombatMode() then
    if not HasMyBuff("благословение королей")
        and not HasMyBuff("благословение могущества")
        and not HasBuff("благословение королей")
        and DoSpell("Великое благословение королей", player) then return end
    return
  end
  local hp = UnitHealth100(player)
  local mana = UnitMana100(player)
  local shield = IsEquippedItemType("Щит")
  if TimerMore('equipweapon', 0.5) then
    if hp < 40 and not shield then
      last2H = GetSlotItemName(16)
      -- одеваем одноручку и цит
      oexecute("UseEquipmentSet('upheal')")
      TimerStart('equipweapon')
      return
    end
    if hp > 80 and shield then
      -- одеваем двуручку
      EquipItem(last2H or 'Темная Скорбь', 16)
      TimerStart('equipweapon')
      return
    end
  end
  if not InDuel() then
    if not IsArena() and hp < 30 and DoSpell("Возложение рук", player) then return end
    if hp < 25 and DoSpell("Божественный щит", player) then return end
  end
  if not isFinishHim and mana > 30 and IsSpellNotUsed("Очищение", 5) and InInteractRange(teammate) and HasDebuff(redDispelList, 3, teammate)
    and not HasDebuff("Нестабильное колдовство", 0.1, teammate) and DoSpell("Очищение", teammate) then return end
  if InCombatLockdown() then
    if hp < 50 and UseItem("Камень здоровья из Скверны") then return end
    if not (InDuel() or IsArena()) then
      if hp < 30 and UseItem("Рунический флакон с лечебным зельем") then return end
      if mana < 25 and UseItem("Рунический флакон с зельем маны") then return end
    end
  end
  if HasBuff("Искусство войны") then
     if hp < (shield and 90 or 50) and DoSpell("Вспышка Света", player) then return end
     if IsInteractUnit(teammate) and UnitHealth100(teammate) < 50 and DoSpell("Вспышка Света", teammate) then return end
  end
  if AdvMode then
    for i = 1, #TARGETS do
      local t = TARGETS[i]
      if CanMagicAttack(t) and UnitHealth100(t) < 19.99 and DoSpell("Молот гнева", t) then return end
    end
  end
  TryTarget()
  if not CanAttack(target) then return end
  if (IsAttack() or UnitAffectingCombat(target)) then oexecute("StartAttack()") end
  FaceToTarget(target)
  if HasBuff("Проклятие хаоса") then oexecute('CancelUnitBuff("player", "Проклятие хаоса")') end
  if UnitHealth100(target) < 19.99 and DoSpell("Молот гнева", target) then return end
  if IsShift() and UseEquippedItem("Ремень триумфа разгневанного гладиатора", target) then return end
  if IsReadySpell("Длань возмездия") and UnitIsPlayer(target) and (
    (tContains(steathClass, GetClass(target)) and not InRange("Покаяние", target)) or HasBuff(reflectBuff, 1, target)
  ) and not HasDebuff("Длань возмездия", 1, target) and DoSpell("Длань возмездия", target) then return end
  if CanMagicAttack(target) and DoSpell((IsAlt() and "Правосудие справедливости" or "Правосудие мудрости"), target) then return end
  if not isFinishHim and not HasBuff("Священный щит") and IsSpellNotUsed("Священный щит", 4) and DoSpell("Священный щит", player) then return end
  if UseEquippedItem(GetSlotItemName(10), target) then return end
  if (UnitCreatureType(target) == "Нежить") and mana > 30 and DistanceTo(player, target) < 8 and DoSpell("Гнев небес") then return end
  if DistanceTo(player, target) < 8 and DoSpell("Божественная буря") then return end
  if DoSpell("Удар воина Света", target) then return end
  if mana < 30 and DoSpell("Святая клятва") then return end
  if shield then
    if DoSpell("Щит праведности", target) then return end
  else
    if HasBuff("Искусство войны") and CanMagicAttack(target) and DoSpell("Экзорцизм", target) then return end
  end
  if mana > 50 then
    if DistanceTo(player, target) < 8 and (UnitCreatureType(target) == "Нежить") and DoSpell("Гнев небес") then return end
    if HasBuff("Искусство войны") and hp < 95 and DoSpell("Вспышка Света", player) then return end
    --if not InDuel() and InMelee(target) and DoSpell("Освящение") then return end
  end
end
------------------------------------------------------------------------------------------------------------------
function TryTarget()
  if not IsValidTarget("target") then
      local _uid = nil
      local _face = false
      local _dist = 100
      local _combat = false
      local look = IsMouselooking()
      local attack = IsAttack()
      for i = 1, #TARGETS do
        local uid = TARGETS[i]
        repeat -- для имитации continue
          if not IsValidTarget(uid) then break end
          local combat = UnitAffectingCombat(uid)
          -- уже есть кто-то в бою
          if _combat and not combat then break end
          -- автоматически выбераем только цели в бою
          if not attack and not combat then break end
          -- не будет лута
          if (UnitIsTapped(uid)) and (not UnitIsTappedByPlayer(uid)) then break end
          if UnitIsPossessed(uid) then break end
          -- в pvp выбираем только игроков
          if pvp and not UnitIsPlayer(uid) then break end
          -- только актуальные цели
          local face = PlayerFacingTarget(uid, look and 15 or 90)
          -- если смотрим, то только впереди
          if look and not face then break end
          local dist = DistanceTo("player", uid)
          if _face and not face and dist > 8 then break end
          if dist > _dist then break end
          _uid = uid
          _combat = combat
          _face = face
          _dist = dist
        until true
      end
      if _uid then
        oexecute("TargetUnit('".. _uid .."')")
      end
  end
end
