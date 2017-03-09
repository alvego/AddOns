-- Rotation Helper Library by Alex Tim
------------------------------------------------------------------------------------------------------------------
function test()
  print("CanAttack", CanAttack("target"), CanAttackInfo)
  print("IsValidTarget", IsValidTarget("target"))
  print("UnitAffectingCombat", UnitAffectingCombat("target"))
  print("UnitCanAttack", UnitCanAttack("player","target"))
  print("InMelee", InMelee("target"))
  print("DistanceTo", DistanceTo("player", "target"))
  print("InCombatMode", InCombatMode())
  print("InCombatLockdown", InCombatLockdown())
end
------------------------------------------------------------------------------------------------------------------
-- l18n
BINDING_HEADER_RHLIB = "Rotation Helper Library"
BINDING_NAME_RHLIB_OFF = "Выкл ротацию"
BINDING_NAME_RHLIB_ON = "Вкл ротацию"
BINDING_NAME_RHLIB_DEBUG = "Вкл/Выкл режим отладки"
BINDING_NAME_RHLIB_LOG = "Вкл/Выкл окно логирования"
BINDING_NAME_RHLIB_RELOAD = "Перезагрузить интерфейс"
BINDING_NAME_RHLIB_FARM = "Режим фарминга"
-----------------------------------------------------------------------------------------------------------------
-- Условие для включения ротации
------------------------------------------------------------------------------------------------------------------
if Paused == nil then Paused = false end
-- Условие для включения ротации
local beginAttack = false
function IsAttack()
    if IsMouse(4) then
        if not beginAttack then
          beginAttack = true
          AdvMode = true
        end
        TimerStart('Attack')
    else
      beginAttack = false
    end
    return TimerLess('Attack', 0.05)
end

-- Включаем авторотацию
function AutoRotationOn()
    if Paused then
      echo("Авто ротация: ON")
      Paused = false
    end
end

-- Отключаем авторотацию, при повторном нажатии останавливаем каст (если есть)
function AutoRotationOff()
    if oexecute then
      if UnitIsCasting() and Paused then
          StopCast("Pause")
      end
      oexecute("StopAttack()")
      if Paused then
        oexecute("PetFollow()")
      end
    end
    if not Paused then
      echo("Авто ротация: OFF")
      Paused = true
    end

end

------------------------------------------------------------------------------------------------------------------
function FaceToTarget(target)
    if not target then target = "target" end
    if not FaceToUnit then return end
    if TimerLess("FaceToTarget", 1) then return end
    if IsMouselooking() then return end
    if not PlayerInPlace() then return end
    if not UnitExists(target) then return end
    if PlayerFacingTarget(target) then return end
    TimerStart("FaceToTarget")
    FaceToUnit(target)
end
------------------------------------------------------------------------------------------------------------------
if Debug == nil then Debug = false end

local debugFrame = CreateFrame('Frame')
debugFrame:ClearAllPoints()
debugFrame:SetHeight(15)
debugFrame:SetWidth(800)
debugFrame.text = debugFrame:CreateFontString(nil, 'BACKGROUND', 'GameFontNormalSmallLeft')
debugFrame.text:SetAllPoints()
debugFrame:SetPoint('TOPLEFT', 2, 0)
debugFrame:SetScale(0.8);
debugFrame:SetAlpha(1)
local updateDebugStatsTime = 0
local function updateDebugStats()
    if not Debug then
        if debugFrame:IsVisible() then debugFrame:Hide() end
        return
    end
    if TimerLess('DebugFrame', 2) then return end
    TimerStart('DebugFrame')
    UpdateAddOnMemoryUsage()
    local mem  = GetAddOnMemoryUsage("rhlib2")
    local fps = GetFramerate();
    local speed = GetUnitSpeed("player") / 7 * 100
    debugFrame.text:SetText(format('MEM: %.1fKB, LAG: %ims, FPS: %i, SPD: %d%%',  mem, LagTime * 1000, fps, speed))
    if not debugFrame:IsVisible() then debugFrame:Show() end
end

AttachUpdate(updateDebugStats)

function DebugToggle()
    Debug = not Debug
    if Debug then
        debugFrame:Show()
        SetCVar("scriptErrors", 1)
        --UIErrorsFrame:RegisterEvent("UI_ERROR_MESSAGE");
        SetCVar("Sound_EnableErrorSpeech", "1");
        echo("Режим отладки: ON")
    else
        debugFrame:Hide()
        SetCVar("scriptErrors", 0)
        --UIErrorsFrame:UnregisterEvent("UI_ERROR_MESSAGE");
        SetCVar("Sound_EnableErrorSpeech", "0");
        echo("Режим отладки: OFF")
    end
end
-------------------------------------------------------------------------------------------------------------------
 if Farm == nil then Farm = false end
 function FarmToggle()
     Farm = not Farm
     if Farm then
         echo("Режим фарма: ON",true)
         --chat("Автолут ON")
         --omacro("/console autoLootDefault 1")
     else
         echo("Режим фарма: OFF",true)
         --chat("Автолут OFF")
         --omacro("/console autoLootDefault 0")
     end
 end


 --[[function IsFarm()
     return Farm and not IsMouselooking() and PlayerInPlace()
 end]]
------------------------------------------------------------------------------------------------------------------
function IsFishingMode()
    return Farm and not IsMouselooking() and PlayerInPlace() and IsEquippedItemType("Удочка") and not InCombatMode() and not (IsMounted() or CanExitVehicle()) and GetFreeBagSlotCount() > 0
end
------------------------------------------------------------------------------------------------------------------
--[[local function updateCombatLogTimer(...)
  TimerStart("CombatLog")
end
local function resetCombatLog()
  if InCombatLockdown()
  and TimerStarted("CombatLog") and TimerMore("CombatLog", 6)
  and (not TimerStarted("CombatLogReset") or TimerMore("CombatLogReset", 30))  then
      CombatLogClearEntries()
      TimerStart("CombatLogReset")
      chat("Reset CombatLog!")
  end
end
AttachEvent('COMBAT_LOG_EVENT_UNFILTERED', updateCombatLogTimer)
AttachUpdate(resetCombatLog)]]
------------------------------------------------------------------------------------------------------------------
-- Вызывает функцию Idle если таковая имеется, с заданным рекомендованным интервалом UpdateInterval,
-- при включенной Авто-ротации

------------------------------------------------------------------------------------------------------------------
local bobber_guid = nil
local bobber_uid = nil
local isBobbing = false
local function updateSpellCreate(event, ...)
    if not IsFishingMode() then return true end
    local timestamp, type, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName, spellSchool, amount, info = ...
    if type:match("SPELL_CREATE") and sourceGUID == UnitGUID("player") and spellName == "Рыбная ловля" then
        bobber_uid = nil
        bobber_guid = destGUID
        isBobbing = false
        --print("Закинули удочку, bobber_guid = ", bobber_guid)
    end
end
AttachEvent('COMBAT_LOG_EVENT_UNFILTERED', updateSpellCreate)
------------------------------------------------------------------------------------------------------------------
local function death_update_handler()
  if not UnitIsDeadOrGhost("player") then return end
  if not (IsCtr() or IsBattleground()) then return end
  oexecute('AcceptResurrect()')
  if UnitIsDead("player") then
      oexecute("RepopMe()")
  end
  if UnitIsGhost("player") and GetCorpseRecoveryDelay() == 0 then
    oexecute("RetrieveCorpse()")
  end
end
AttachUpdate(death_update_handler)
------------------------------------------------------------------------------------------------------------------
TARGETS = {}
UNITS = {}
OBJECTS = {}
------------------------------------------------------------------------------------------------------------------
function GetEnemyCountInRange(range)
  local count = 0
  for i = 1, #TARGETS do
    local uid = TARGETS[i]
    local dist = DistanceTo("player", uid)
    if dist <= range then
      count = count + 1
    end
  end
  return count
end

function UpdateObjects(force)
  if not ObjectsCount then return end
  if not force and TimerLess("UpdateObjects", 0.5) then return end
  TimerStart("UpdateObjects")
  wipe(OBJECTS)
  local objCount = ObjectsCount()
  for i = 0, objCount - 1 do
    local uid = GUIDByIndex(i)
    if uid then
      tinsert(OBJECTS, uid)
    end
  end
end

function UpdateTargets(force)
  if not force and TimerLess("UpdateTargets", 0.5) then return end
  TimerStart("UpdateTargets")
  wipe(TARGETS)
  for i = 1, #OBJECTS do
    local uid = OBJECTS[i]
    if UnitCanAttack("player", uid) and DistanceTo("player", uid) <= 30 and IsValidTarget(uid) then
        tinsert(TARGETS, uid)
    end
  end
end

function UpdateUnits(force)
  if not ObjectsCount then return end
  if not force and TimerLess("UpdateUnits", 0.5) then return end
  TimerStart("UpdateUnits")
  wipe(UNITS)
  local groupUnits = GetGroupUnits()
  for i = 1, #groupUnits do
    local u = groupUnits[i]
    if InInteractRange(u) then
      tinsert(UNITS, u)
    end
  end
end


--local offsets = {}
--local ignored = {191, 171,168,169,170}

function UpdateIdle(elapsed)
    --[[if AdvMode  then
      if UnitExists('target') and UnitIsDead('target') then
        local ptr = UnitPtr('target')

        print('test', ReadByte(ptr, 168))--171
        for i = 1, 250 do
          if not tContains(ignored, i) then
          local data = ReadByte(ptr, i)

          if offsets[i] ~= data then
            if offsets[i] ~= nil then
                print(i, offsets[i], data, 'alarm!!!!!!!!!!!!!!!!!!!')
            end

            offsets[i] = data
              --break
          end
          end
        end
      end
    end]]

    if nil == oexecute then
        if not TimerStarted('UnlockTimer') then
          TimerStart('UnlockTimer')
        end
        if AdvMode and not Paused then
          UIErrorsFrame:Clear()
          UIErrorsFrame:AddMessage("Tребуется инъекция. " .. SecondsToTime(TimerElapsed('UnlockTimer')), 0.0, 1.0, 0.0, 53, 2);
        end
        return
    end

    --[[if StaticPopup1Button2:IsVisible() == 1 and StaticPopup1Button2:IsEnabled() == 1 and StaticPopup1Button2:GetText() == "Пропустить" then
       chat(StaticPopup1.text:GetText())
       StaticPopup1Button2:Click()
    end]]

    --local autoloog
    if LootFrame:IsVisible() then
      if (IsFishingMode() and IsFishingLoot()) or Farm and (not IsInGroup() or (GetLootMethod() == 'freeforall')) then
        for i=1, GetNumLootItems() do
          if not select(4, GetLootSlotInfo(i)) then LootSlot(i) end
        end
        if InCombatMode() then CloseLoot() return end
      end
      if IsAttack() then CloseLoot() end
      return
    end

    if InExecQueue() then return end
    if UpdateCommands() then return end
    if UnitIsDeadOrGhost("player") then return end
    if SpellIsTargeting() then
      if IsAttack() then
        oexecute('SpellStopTargeting()')
      else
          echo("Нужно выбрать цель")
          return
      end
    end

    if Paused then return end

    if AdvMode and InCombatMode() then
      UpdateObjects(true)
      UpdateTargets(true)
      UpdateUnits(true)
    end

    --[[if IsMouse(3) and UnitExists("mouseover") and not IsOneUnit("target", "mouseover") then
        oexecute("FocusUnit('mouseover')")
    end]]

    if IsArena() then
        if IsValidTarget("target") and (not UnitExists("focus") or IsOneUnit("target", "focus")) then
            if IsOneUnit("target","arena1") and UnitExists("arena2") then omacro("/focus arena2") end
            if IsOneUnit("target","arena2") and UnitExists("arena1") then omacro("/focus arena1") end
        end
    end

    if Idle then Idle() end


    if AdvMode and IsFishingMode() then

      if UnitIsCasting("player") == "Рыбная ловля" then

        if bobber_guid and not bobber_uid then
          --chat("Ищем, bobber_uid")
          UpdateObjects()
          for i = 1, #OBJECTS do
            local uid = OBJECTS[i]
            if uid and bobber_guid and UnitGUID(uid) == bobber_guid then
              bobber_uid = uid
              --print("bobber_uid = ", bobber_uid)
              break
            end
          end
        end

        if bobber_uid and UnitName(bobber_uid) then
          local ptr = UnitPtr(bobber_uid)
          if not isBobbing and ReadByte(ptr, 188) == 1 then
              --chat("Клюнуло")
              isBobbing = true
          end
          if isBobbing then
            --chat("Подсекаем")
            oexecute('InteractUnit("' ..bobber_uid .. '")')
            StopCast("Подсекли рыбку")
          end
        end
      else
        if UseSpell("Рыбная ловля") then return end
      end
    end

    if Farm and AdvMode and not InCombatMode() and TimerLess('CombatLock', 15) and not (IsMounted() or CanExitVehicle()) and GetFreeBagSlotCount() > 0 then --and (not IsInGroup() or (GetLootMethod() == 'freeforall'))
      UpdateObjects()
      for i = 1, #OBJECTS do
        local uid = OBJECTS[i]
        if uid and UnitIsDead(uid) and DistanceTo("player", uid) <= 5 and UnitIsTappedByPlayer(uid) then --not UnitIsPlayer(uid)
            --print('Лутаем: ' .. UnitName(uid))
            local ptr = UnitPtr(uid)
            if ReadByte(ptr, 168) ~= 0 then
              oexecute(format("InteractUnit('%s')", uid))
              break
            end
        end
      end
    end
end
------------------------------------------------------------------------------------------------------------------
-- Запоминаем вредоносные спелы которые нужно кастить (нужно для сбивания кастов, например тотемом заземления)
if HarmfulCastingSpell == nil then HarmfulCastingSpell = {} end
function IsHarmfulCast(spellName)
    return HarmfulCastingSpell[spellName]
end

local function UpdateHarmfulSpell(event, ...)
    local timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellID, spellName, spellSchool, agrs12, agrs13,agrs14 = select(1, ...)
    if event:match("SPELL_DAMAGE") and spellName and agrs12 > 0 then
        local name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange = GetSpellInfo(spellID)
        if castTime > 0 then HarmfulCastingSpell[name] = true end
    end
end
AttachEvent('COMBAT_LOG_EVENT_UNFILTERED', UpdateHarmfulSpell)
------------------------------------------------------------------------------------------------------------------
-- нас сапнул рога
function UpdateSapped(event, ...)
    local timestamp, type, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName, destFlag, err = select(1, ...)
	if spellName == "Ошеломление"
	and destGUID == UnitGUID("player")
	and (type == "SPELL_AURA_APPLIED" or type == "SPELL_AURA_REFRESH")
	then
		RunMacroText("/к Меня сапнули, помогите плиз!")
		Notify("Словил сап от роги: "..(sourceName or "(unknown)"))
	end
end
AttachEvent("COMBAT_LOG_EVENT_UNFILTERED", UpdateSapped)
------------------------------------------------------------------------------------------------------------------
--Arena Raid Icons
local unitCD = {}
local raidIconsByClass = {WARRIOR=8,DEATHKNIGHT=7,PALADIN=3,PRIEST=5,SHAMAN=6,DRUID=2,ROGUE=1,MAGE=8,WARLOCK=3,HUNTER=4}
local function UpdateArenaRaidIcons(event, ...)
    if IsArena() then
        local members = GetGroupUnits()
        for i=1, #members do
            local u = members[i]
            if UnitExists(u) and not GetRaidTargetIndex(u) and (not unitCD[u] or GetTime() - unitCD[u] > 5) then
                SetRaidTarget(u,raidIconsByClass[select(2,UnitClass(u))])
                unitCD[u] = GetTime()
            end
        end
	end
end
AttachEvent("GROUP_ROSTER_UPDATE", UpdateArenaRaidIcons)
AttachEvent("ARENA_OPPONENT_UPDATE", UpdateArenaRaidIcons)
AttachEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS", UpdateArenaRaidIcons)
------------------------------------------------------------------------------------------------------------------
-- Alert опасных спелов
local checkedTargets = {"target", "focus", "arena1", "arena2", "mouseover"}
function UpdateSpellAlert(event, ...)
    local timestamp, type, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName, destFlag, err = select(1, ...)
    --[[if sourceName == UnitName("player") or sourceName == UnitName("target") then
        print(type, sourceName, spellName, destName)
    end]]
    if InAlertList(spellName) then
        for i=1,#checkedTargets do
            local t = checkedTargets[i]
            if IsValidTarget(t) and UnitGUID(t) == sourceGUID then
                type = strreplace(type, "SPELL_AURA_", "")
                type = strreplace(type, "APPLIED", "+")
                type = strreplace(type, "REMOVED", "-")
                Notify("|cffff7d0a" .. spellName .. " ("..(UnitName(t) or "unknown")..")|r  - " .. type .. "!")
                PlaySound("RaidWarning", "master");
                break
            end
        end
    end
end
AttachEvent("COMBAT_LOG_EVENT_UNFILTERED", UpdateSpellAlert)
------------------------------------------------------------------------------------------------------------------
