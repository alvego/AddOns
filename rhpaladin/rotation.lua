-- Paladin Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
local peaceBuff = {"Пища", "Питье"}
local dispelTypes = {'Magic', 'Disease', 'Poison'}
local steathClass = {"ROGUE", "DRUID"}
local reflectBuff = {"Отражение заклинания", "Эффект тотема заземления"}

local redDispelList = {
    "Превращение",
    "Глубокая заморозка",
    "Огненный шок",
    "Покаяние",
    "Молот правосудия",
    "Замедление",
    "Эффект ледяной ловушки",
    "Эффект замораживающей стрелы",
    --"Удушение",
    --"Антимагия - немота",
    --"Безмолвие",
    --"Волшебный поток",
    "Вой ужаса",
    "Ментальный крик",
    "Успокаивающий поцелуй"
}

teammate = "Qo"
function Idle()

  local target = "target"
  local player = "player"
  -- Дизамаунт
  if IsAttack() then
      if HasBuff("Парашют") then
        oexecute('CancelUnitBuff("player", "Парашют")')
      end
      if CanExitVehicle() then VehicleExit() end
      if IsMounted() and not IsPvP() then
        if HasBuff("Аура воина Света") then
           oexecute('CancelUnitBuff("player", "Аура воина Света")')
          if HasSpell("Частица Света") and DoSpell("Аура сосредоточенности") then return end
          if HasSpell("Удар воина Света") and DoSpell("Аура воздаяния")  then return end
        end
        Dismount()
      end
  end
  -- дайте поесть (побегать) спокойно
  if not IsPvP() and IsMounted() and not HasBuff("Аура воина Света") and DoSpell("Аура воина Света") then return end

  if not IsAttack() and (IsMounted() or CanExitVehicle() or HasBuff(peaceBuff)) then return end

  -- Heal Rotation ------------------------------------------------------------------------------------------------------------------------------
  if HasSpell("Частица Света") then

    if not InCombatLockdown() and IsPvP() and not HasBuff("Праведное неистовство") and DoSpell("Праведное неистовство") then return end

      if (IsAttack() or InCombatLockdown()) and not HasBuff("Аура сосредоточенности") and DoSpell("Аура сосредоточенности", player) then return end
      --if IsPvP() and not HasBuff("Печать") and DoSpell("Печать праведности") then return true end
      if not HasBuff("Печать") and DoSpell("Печать мудрости", player) then return end
      --if not HasBuff("Печать") and DoSpell("Печать мудрости","player") then return end
      if not InCombatLockdown() and not HasMyBuff("благословение королей") and not HasMyBuff("благословение могущества") then
          if not HasBuff("благословение королей") and DoSpell("Великое благословение королей", player) then return end
      end

      local hp = UnitHealth100(player)
      local mana = UnitMana100(player)

      if InCombatLockdown() then
        if hp < 50 and UseItem("Камень здоровья из Скверны") then return end
        if not (InDuel() or IsArena()) then
          if hp < 30 and UseItem("Рунический флакон с лечебным зельем") then return end
          if mana < 25 and UseItem("Рунический флакон с зельем маны") then return end
        end
        if IsPvP() and hp < 40 and DoSpell("Длань спасения", player) then return end
      end

      local u = "player"
      local hasShield = HasMyBuff("Священный щит",1, player) and true or false
      local hasLight = HasMyBuff("Частица Света",1, player) and true or false
      local h = UnitHealth100(u)
      local fatUnit = nil
      local fatHP = 0
      for i = 1, #UNITS do
        local _u = UNITS[i]

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
        end
      end

      if not u then return end



      local l = UnitLostHP(u)
      if InCombatLockdown() and IsInGroup() and IsSpellNotUsed("Частица Света", 10) and not hasLight then
        if not UnitCanAttack("player", teammate) and IsInteractUnit(teammate) then
          if DoSpell("Частица Света",  teammate) then return end
        else
          if not IsOneUnit(player, fatUnit) and DoSpell("Частица Света",  fatUnit) then return end
        end
      end

      --[[if IsShift() then
        h = 20
        l = 25000
      end]]

      if mana > 50 then l = l * 1.5 end
      if HasBuff("Божественное одобрение") and DoSpell("Шок небес", u) then return end
      if (h < 35) and not IsReadyItem("Подвеска истинной крови") and GetSpellCooldownLeft("Шок небес") < 0.1 and DoSpell("Божественное одобрение") then return end
      if (h < 35) and UseEquippedItem("Подвеска истинной крови", u) then return end
      if InCombatMode() and h < 95 and UseEquippedItem("Украшенные перчатки разгневанного гладиатора") then return end
      if InCombatMode() and mana < 90 and UseEquippedItem("Осколок чистейшего льда") then return end
      if InCombatMode() and IsSpellNotUsed("Священный щит", 5) and (not hasShield or (h < 50 and not HasMyBuff("Священный щит", 1, u))) and DoSpell("Священный щит", u) then return end

      if (h < 98 or l > 3000) and DoSpell("Шок небес", u) then return end
      if (HasBuff("Прилив Света") or PlayerInPlace()) and (h < 50 or l > 2000) and DoSpell("Вспышка Света", u) then return end
      if IsSpellNotUsed("Очищение", 2) and HasDebuff(dispelTypes, 1, u) and not HasDebuff("Нестабильное колдовство", 0.1, u) and DoSpell("Очищение", u) then return end

      if InCombatMode() then
        TryTarget()
        if not IsValidTarget(target) then return end
        if DoSpell("Правосудие света", target) then return end
        if IsEquippedItemType("Щит") and DoSpell("Щит праведности", target) then return end
      end
      return
   end
   --DD_rotation--------------------------------------------------------------------------------------------------------------------------------------------
  if not HasSpell("Удар воина Света") then return end

  if IsPvP() and not HasBuff("Аура воздаяния") and DoSpell("Аура воздаяния")  then return end
  if not InCombatLockdown() and IsPvP() and not HasBuff("Праведное неистовство") and DoSpell("Праведное неистовство") then return end
  if not HasBuff("Печать") and DoSpell("Печать праведности", player) then return true end
  if not InCombatLockdown() and not HasMyBuff("благословение королей") and not HasMyBuff("благословение могущества") then
      if not HasBuff("благословение королей") and DoSpell("Великое благословение королей", player) then return end
  end

  if IsCtr() and HasDebuff(dispelTypes, 1, player) and DoSpell("Очищение", player) then return end
  if InCombatMode() then

    local hp = UnitHealth100(player)
    local mana = UnitMana100(player)

    if not InDuel() and not IsArena() and hp < 30 and DoSpell("Возложение рук", player) then return end
    if not InDuel() and hp < 25 and DoSpell("Божественный щит", player) then return end

    if UnitHealth100(target) < 20 and DoSpell("Молот гнева", target) then return end

    if mana > 30 and IsSpellNotUsed("Очищение", 4) then
      --if HasDebuff(redDispelList, 1, player) and not HasDebuff("Нестабильное колдовство", 0.1, player) and DoSpell("Очищение", player) then return end
      if not UnitCanAttack("player", teammate) and IsInteractUnit(teammate) and HasDebuff(redDispelList, 1, teammate) and not HasDebuff("Нестабильное колдовство", 0.1, teammate) and DoSpell("Очищение", teammate) then return end
    end

    if InCombatLockdown() then
      if hp < 50 and UseItem("Камень здоровья из Скверны") then return end
      if not (InDuel() or IsArena()) then
        if hp < 30 and UseItem("Рунический флакон с лечебным зельем") then return end
        if mana < 25 and UseItem("Рунический флакон с зельем маны") then return end
      end
    end

    if HasBuff("Искусство войны") --[[and (IsEquippedItemType("Щит") or ((not IsValidTarget(target) or GetSpellCooldownLeft("Экзорцизм") > 0.5)))]] then
       if hp < 80 and DoSpell("Вспышка Света", player) then return end
       if IsInteractUnit(teammate) and UnitHealth100(teammate) < 50 and DoSpell("Вспышка Света", teammate) then return end
    end


    TryTarget()

    if not CanAttack(target) then return end

    if (IsAttack() or UnitAffectingCombat(target)) then
        if IsValidTarget(target) and not IsCurrentSpell("Автоматическая атака") then oexecute("StartAttack()") end
    else
      if IsCurrentSpell("Автоматическая атака") then  oexecute("StopAttack()") end
    end

    if IsShift() and UseEquippedItem("Ремень триумфа разгневанного гладиатора", target) then return end

    if IsReadySpell("Длань возмездия") and UnitIsPlayer(target) and (
      (tContains(steathClass, GetClass(target)) and not InRange("Покаяние", target)) or HasBuff(reflectBuff, 1, target)
    ) and not HasDebuff("Длань возмездия", 1, target) and DoSpell("Длань возмездия", target) then return end

    if CanMagicAttack(target) and DoSpell((IsAlt() and "Правосудие справедливости" or "Правосудие мудрости"), target) then return end
    if not IsPvP() and DistanceTo(player, target) < 8 and DoSpell("Божественная буря") then return end
    if not IsPvP() and DoSpell("Удар воина Света") then return end

    if IsPvP() and not HasBuff("Священный щит") and DoSpell("Священный щит", player) then return end

    if not IsValidTarget(target) then return end
    FaceToTarget(target)
    if HasBuff("Проклятие хаоса") then
       oexecute('CancelUnitBuff("player", "Проклятие хаоса")')
    end
    if not IsInGroup() and not IsOneUnit(player, target .. "-"..target) and DoSpell("Длань возмездия", target) then return end
    if UseItem("Чешуйчатые рукавицы разгневанного гладиатора") then return end
    if not IsEquippedItemType("Щит") and HasBuff("Искусство войны") and CanMagicAttack(target) and DoSpell("Экзорцизм", target) then return end
    if (UnitCreatureType(target) == "Нежить") and mana > 30 and DistanceTo(player, target) < 8 and DoSpell("Гнев небес") then return end
    if IsPvP() and  DistanceTo(player, target) < 8 and DoSpell("Божественная буря") then return end
    if DoSpell("Удар воина Света", target) then return end
            --if true then return end
    if IsEquippedItemType("Щит") and DoSpell("Щит праведности", target) then return end
    if mana > 50 then
      if DistanceTo(player, target) < 8 and (UnitCreatureType(target) == "Нежить") and DoSpell("Гнев небес") then return end
      if not InDuel() and InMelee(target) and DoSpell("Освящение") then return end
    end
    --if not HasBuff("Священный щит") and DoSpell("Священный щит", player) then return end
    if mana < 30 and DoSpell("Святая клятва") then return end

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
