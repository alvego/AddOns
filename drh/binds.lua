-- Druid Rotation Helper by Timofeev Alexey
-- Binding
BINDING_HEADER_DRH = "Druid Rotation Helper"
BINDING_NAME_DRH_OFF = "Выкл ротацию"
BINDING_NAME_DRH_DEBUG = "Вкл/Выкл режим отладки"
BINDING_NAME_DRH_MOUNT = "Вкл/Выкл маунта"
BINDING_NAME_DRH_INTERRUPT = "Вкл/Выкл сбивание кастов"
BINDING_NAME_DRH_BERSMOD = "Режим берсерка"
BINDING_NAME_DRH_AUTOAOE = "Авто AOE"
-- addon main frame
local frame=CreateFrame("Frame",nil,UIParent)
-- attach events
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
frame:RegisterEvent("UNIT_SPELLCAST_FAILED")
frame:RegisterEvent("UNIT_SPELLCAST_SENT")
frame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
print("Druid Rotation Helper loaded")
-- protected lock test
RunMacroText("/cleartarget")

local LastUpdate = 0
local UpdateInterval = 0.090
local LastPosX, LastPosY = GetPlayerMapPosition("player")
local InPlace = true
local InCast = {}
local resList = {}
local NextTarget = nil
local NextGUID = nil
local NotBehindTarget = 0
local Role = 0

if Paused == nil then Paused = false end
if Debug == nil then Debug = false end
if CanInterrupt == nil then CanInterrupt = true end
if BersState == nil then BersState = true end
if AutoAOE == nil then AutoAOE = true end
if DispelWhitelist == nil then DispelWhitelist = {} end
if DispelBlacklist == nil then DispelBlacklist = {} end
if AutoAOE == nil then AutoAOE = true end

function NextRole()
    Role = Role + 1 
    if Role > 2 then Role = 0 end
end

function IsTank()
    return (Role == 0)
end

function IsDD()
    return (Role == 1)
end

function IsHeal()
    return not (IsDD() or IsTank())
end

function RoleName()
    if IsTank() then return "Танк" end
    if IsDD() then return "ДД" end
    return "Хил"
end

function RoleTank()
    Role = 0
    Notify(RoleName())
end

function RoleDD()
    Role = 1
    Notify(RoleName())
end

function RoleHeal()
    Role = 2
    Notify(RoleName())
end

function PlayerInPlace()
    return InPlace and (not IsFalling() or IsSwimming())
end

function IsNotBehindTarget()
    return GetTime() - NotBehindTarget < 1
end


--~ Цель вне поля зрения.
local notVisible = {}
local sayNotVisible = 0
function IsVisible(target)
    if not target or target == "player"  then return true end
    if not UnitIsVisible(target) then return false end
    local t = notVisible[target]
    if t and GetTime() - t < 1 then
        local u = UnitName(target)
        if u and UnitIsPlayer(u) and (GetTime() - sayNotVisible) > 15 and CalculateHP(u) < 50 then
            print("Не могу подхилить ".. u ..". Вне поля зрения.")
--~             RunMacroText("/с Не могу подхилить ".. u ..". Вне поля зрения.")
            sayNotVisible = GetTime()
        end
        return false
    end
    return true;
end


function UnitPartyName(unit)
    if not unit or not UnitExists(unit) then return nil end
    local guid = UnitGUID(unit)
    for i=1,#UNITS do 
        if UNITS[i] ~= "mouseover" and UnitGUID(UNITS[i]) == guid then return UNITS[i] end
    end
    return unit
end


function CanUseInterrupt()
    return CanInterrupt
end

function UseInterrupt()
    CanInterrupt = not CanInterrupt
    if CanInterrupt then
        echo("Interrupt: ON",true)
    else
        echo("Interrupt: OFF",true)
    end 
end

function GetNextTarget()
    return NextTarget
end

function ClearNextTarget()
    NextTarget = nil
    NextGUID = nil
end


function NextIsTarget(target)
    if not target then target = "target" end
    return (UnitGUID("target") == NextGUID)
end

function Mount()
    
    if HasBuff("Облик кошки") and HasBuff("Крадущийся зверь") then
        RunMacroText("/cancelaura Крадущийся зверь")
        return
    end
    
    
    if CanExitVehicle() then
        VehicleExit()
        return
    end
    
    if IsMounted() then
        Dismount()
        return
    end 
    
    if GetShapeshiftForm() ~= 0 and not (IsFalling() or IsSwimming()) then
        RunMacroText("/cancelform")
        return
    end
    
    if InGCD() then return end
    
    
    if IsAltKeyDown() then
        UseMount("Тундровый мамонт путешественника")
        return
    end
    
    
    if IsSwimming() then
        UseMount("Водный облик")
        return
    end
    
    if InCombatLockdown() or IsAttack() or IsIndoors() or (IsFalling() and not IsFlyableArea() and not HasBuff("Облик кошки")) then 
        UseMount("Облик кошки")
        return 
    end

    if IsFlyableArea() and not IsControlKeyDown() then
--~         if not PlayerInPlace() then
            UseMount("Облик стремительной птицы")
            return
--~         end
--~         if IsOutdoors() then
--~             UseMount("Бронзовый дракон")
--~         return
--~         end
    end
        

    
    if not PlayerInPlace() then
        if IsControlKeyDown() then
            UseMount("Облик кошки")
            return
        end
        UseMount("Походный облик")
        return
    end
    
    if IsOutdoors() then
--~     UseMount("Бронированный бурый медведь")
        UseMount("Огромный белый кодо")
        return
    end
end    
    
function AutoRotationOff()
    Paused = true
    RunMacroText("/stopattack")
    wipe(InCast)
    wipe(resList)
    echo("Авто ротация: OFF",true)
end

function BersModToggle()
    BersState = not BersState
    if BersState then
        echo("Берс Мод: ON",true)
    else
        echo("Берс Мод: OFF",true)
    end 
end


function AutoAOEToggle()
    AutoAOE = not AutoAOE
    if AutoAOE then
        echo("Авто АОЕ: ON",true)
    else
        echo("Авто АОЕ: OFF",true)
    end 
end

function CanAutoAOE()
    return AutoAOE
end 

function GetBersState()
    return BersState
end 


function DebugToggle()
    Debug = not Debug
    if Debug then
         SetCVar("scriptErrors", 1)
        echo("Режим отладки: ON",true)
    else
         SetCVar("scriptErrors", 0)
        echo("Режим отладки: OFF",true)
    end 
end

function IsDebug()
    return Debug
end    

function IsAttack()
    return (IsMouseButtonDown(4) == 1)
end

function IsAOE()
   return (IsShiftKeyDown() == 1) or (CanAutoAOE() and IsValidTarget("target") and IsValidTarget("focus") and not IsOneUnit("target", "focus") and UnitAffectingCombat("focus") and UnitAffectingCombat("target"))
end


local resSpell = nil
local resUnit = nil
function CanRes(t)
    if not (UnitExists(t)
        and UnitIsPlayer(t)
        and not UnitIsAFK(t)
        and not UnitIsFeignDeath(t)
        and not UnitIsEnemy("player",t)
        and UnitIsDead(t)
        and not UnitIsGhost(t)
        and UnitIsConnected(t)
        and IsVisible(t)
        and InRange("Оживление", t)
        and (not resList[UnitName(t)] or (GetTime() - resList[UnitName(t)]) > 60)
    ) then return false end
    return true
end

function TryRes(t)
    local spell = "Оживление"
    if InCombatLockdown() then
        spell = "Возрождение"
    end
    if not CanRes(t) then return false end
    
    if InCombatLockdown() and not HasBuff("Быстрота хищника") and HasSpell("Природная стремительность") and IsReadySpell("Природная стремительность") then
        DoSpell("Природная стремительность")
        return true
    end
    
    if DoSpell(spell, t) then
        resUnit = UnitName(t)
        resSpell = spell
        Notify(spell .. " " .. resUnit .. "(" ..t ..")")
        return true
    end
    return false
end

function onUpdate(frame, elapsed)
    local posX, posY = GetPlayerMapPosition("player")
    if posX == 0 and posY == 0 then
        SetMapToCurrentZone() 
    end
    
    InPlace = (LastPosX == posX and LastPosY == posY)
    
    LastPosX = posX
    LastPosY = posY
    
    if (IsAttack() and Paused) then
        echo("Авто ротация: ON",true)
        Paused = false
    end
    
    local spell = UnitCastingInfo("player")
    if (not InCombatLockdown() and spell == "Возрождение") or (CanHeal(resUnit) and (spell == "Возрождение" or spell == "Оживление"))  then RunMacroText("/stopcasting") end
    
    LastUpdate = LastUpdate + elapsed
    if LastUpdate < UpdateInterval then return end
    LastUpdate = 0
  
    
    -- if UnitIsDeadOrGhost("player") or UnitIsCharmed("player") or not UnitPlayerControlled("player") then return end
    if UnitIsDeadOrGhost("player") then return end

    if Paused then 
        return 
    end
    
    Idle()
    
end
frame:SetScript("OnUpdate", onUpdate)


function IsHealCast(spell)
    if not spell then return false end
    local healCasts = {"Целительное прикосновение", "Восстановление", "Покровительство природы" }
    local result = false
    for name,value in pairs(healCasts) do 
        if value == spell then result = true end
    end
    return result
end

local lastHealCastTarget = nil
function GetLastHealCastTarget()
    return lastHealCastTarget
end

local lastTarget = nil


local dispel = nil
local dispelTime = GetTime()
function TryDispel(unit)
    if GetTime() - dispelTime < 1.5 then return false end
    local ret = false
    for i = 1, 40 do
        if not ret then
            local name, _, _, _, debuffType, duration, expirationTime   = UnitDebuff(unit, i,true) 
            if name and (expirationTime - GetTime() >= 3 or expirationTime == 0) and (debuffType == "Poison" or debuffType == "Curse") and (not DispelBlacklist[name] or GetTime() - DispelBlacklist[name] > 30) then
                local spell = "Снятие проклятия"
                if debuffType == "Poison" then 
                    if HasBuff("Устранение яда", 0.1, unit) then return false end
                    spell = "Выведение яда"  
                    if DispelWhitelist[name] then spell = "Устранение яда" end
                end
                if DoSpell(spell, unit) then 
                    print(spell .. " ", unit, name)
                    dispel = name
                    dispelTime = GetTime()
                    ret = true 
                end
            end
        end
    end
    return ret
end



function onEvent(self, event, ...)
    if event == "ACTIVE_TALENT_GROUP_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
--[[        print(event)]]
        if HasSpell("Буйный рост") or HasBuff("Древо Жизни") then 
            RoleHeal() 
        else
            if HasBuff("Облик лютого медведя") then 
                RoleTank() 
            else
                RoleDD()
            end
        end
    end

    if event:match("^UNIT_SPELLCAST") then
        local unit, spell = select(1,...)
--~         print(event,  unit, spell )
        if spell and unit == "player" then
            if event == "UNIT_SPELLCAST_SENT" then
                local _,_,_,target = select(1,...)
                if target and UnitExists(target) then
                    lastTarget = target
                    if IsHealCast(spell) then
                        lastHealCastTarget = target
                    end
                end
                InCast[spell] = true
            end
            if  event == "UNIT_SPELLCAST_SUCCEEDED" then
--[[                 if Debug then 
                     chat(spell)
                 end]]
                if spell == resSpell then
                    RunMacroText("/w " .. resUnit .. " Реснул тебя, вставай давай!")
                    if InCombatLockdown() then RunMacroText("/w " .. resUnit .. " Но смотри аккуратно, чтоб сразу не умереть!") end
                    resList[resUnit] = GetTime()
                    Notify("Успешно применил "..resSpell .. " на " .. resUnit)
                end
            end
            if event == "UNIT_SPELLCAST_SUCCEEDED" or event == "UNIT_SPELLCAST_FAILED" then
                InCast[spell] = false
                if IsHealCast(spell) then
                    lastHealCastTarget = nil
                end
                if spell == resSpell then
                    resSpell = nil
                    resUnit = nil
                end
            end
        end
        return
    end
    
    local timestamp, type, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName, destFlag, err, dispel = select(1, ...)
    if not(destName ~= GetUnitName("player")) and sourceName ~= nil and not UnitIsFriend("player",sourceName) then 
        if not Paused then 
            NextTarget = sourceName 
            NextGUID = sourceGUID
        end
    end

    if (event=="COMBAT_LOG_EVENT_UNFILTERED") then
        
        if sourceGUID == UnitGUID("player") and ( type == "SPELL_DISPEL") and spellId and spellName and dispel then
            DispelWhitelist[dispel] = true
--~             print(spellName,"рассеяло" dispel)
        end
    
        if sourceGUID == UnitGUID("player") and (type:match("^SPELL_CAST") and spellId and spellName)  then
       
            if err then
            
                if dispel and err == "Нечего рассеивать." then
                    print(dispel, "не снимается")
                    DispelBlacklist[dispel] = GetTime()
                end
            
                if err == "Цель вне поля зрения." then
                    local partyName = UnitPartyName(lastTarget)
                    if partyName then
                        notVisible[partyName] = GetTime()
                    end
                end
                if err == "Вы должны находиться позади цели." then NotBehindTarget = GetTime() end
                if HasBuff("Ясность мысли") and err:match("Недостаточно") then 
--~                     print("Ясность мысли залипла!")
                    RunMacroText("/cancelaura Ясность мысли")
                end
                if Debug  then
                    print("["..spellName .. "]: ".. err)
                end
            end
        end
    end
end
frame:SetScript("OnEvent", onEvent)

function UnitThreatAlert(u)
    local threat = UnitThreatSituation(u)
    if threat == nil then threat = 0 end
    if IsOneUnit("player", u) and (CalculateHP(u) < 50 or (UnitIsPlayer("target") and UnitIsEnemy("player","target") and IsOneUnit("player", "target-target"))) then threat = 3 end
    if IsOneUnit("focus", u) and IsAttack() then threat = 3 end
    return threat
end

function DoSpell(spell, target, mana)
    if not spell then return false end
    if (InCast[spell]) then return false end
    local cast = false
    for key,value in pairs(InCast) do 
        if key ~= "Трепка" and value then cast = true end
    end
    if cast then return false end
--~     print(spell, InCast[spell])
    if CalculateHP("player") < 60 and UnitMana("player") < 70 and GetShapeshiftForm() == 1 and IsReadySpell("Неистовое восстановление") and spell ~= "Неистовое восстановление" then
        local name, _, _, _, _, powerType  = GetSpellInfo(spell)
        if not name or powerType == 1 then return false end
    end
    
    return UseSpell(spell, target, mana)
end
