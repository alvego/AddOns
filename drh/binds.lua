-- Druid Rotation Helper by Timofeev Alexey
-- Binding
BINDING_HEADER_DRH = "Druid Rotation Helper"
BINDING_NAME_DRH_MOUNT = "Вкл/Выкл маунта"
BINDING_NAME_DRH_INTERRUPT = "Вкл/Выкл сбивание кастов"
BINDING_NAME_DRH_BERSMOD = "Режим берсерка"
BINDING_NAME_DRH_AUTOAOE = "Авто AOE"
print("Druid Rotation Helper loaded")

local LastUpdate = 0
local UpdateInterval = 0.090
local resList = {}
local Role = 0

if CanInterrupt == nil then CanInterrupt = true end
if BersState == nil then BersState = true end
if AutoAOE == nil then AutoAOE = true end
if DispelWhitelist == nil then DispelWhitelist = {} end
if DispelBlacklist == nil then DispelBlacklist = {} end
if AutoAOE == nil then AutoAOE = true end

------------------------------------------------------------------------------------------------------------------
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

------------------------------------------------------------------------------------------------------------------


function UnitPartyName(unit)
    if not unit or not UnitExists(unit) then return nil end
    local guid = UnitGUID(unit)
    for i=1,#UNITS do 
        if UNITS[i] ~= "mouseover" and UnitGUID(UNITS[i]) == guid then return UNITS[i] end
    end
    return unit
end

------------------------------------------------------------------------------------------------------------------
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
------------------------------------------------------------------------------------------------------------------
-- TODO перенести в команды
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

------------------------------------------------------------------------------------------------------------------
function BersModToggle()
    BersState = not BersState
    if BersState then
        echo("Берс Мод: ON",true)
    else
        echo("Берс Мод: OFF",true)
    end 
end

------------------------------------------------------------------------------------------------------------------
function AutoAOEToggle()
    AutoAOE = not AutoAOE
    if AutoAOE then
        echo("Авто АОЕ: ON",true)
    else
        echo("Авто АОЕ: OFF",true)
    end 
end

------------------------------------------------------------------------------------------------------------------
function CanAutoAOE()
    return AutoAOE
end 

------------------------------------------------------------------------------------------------------------------
function GetBersState()
    return BersState
end 

------------------------------------------------------------------------------------------------------------------
function IsAOE()
   return (IsShiftKeyDown() == 1) or (CanAutoAOE() and IsValidTarget("target") and IsValidTarget("focus") and not IsOneUnit("target", "focus") and UnitAffectingCombat("focus") and UnitAffectingCombat("target"))
end

------------------------------------------------------------------------------------------------------------------
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

--TODO: Посмотреть как реализовано у шамана
function ResetRes()
    local spell = UnitCastingInfo("player")
    if (not InCombatLockdown() and spell == "Возрождение") or (CanHeal(resUnit) and (spell == "Возрождение" or spell == "Оживление"))  then RunMacroText("/stopcasting") end
end    



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

------------------------------------------------------------------------------------------------------------------
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

------------------------------------------------------------------------------------------------------------------
local function UpdateRole(event, ...)
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
AttachEvent("ACTIVE_TALENT_GROUP_CHANGED", UpdateRole)
AttachEvent("PLAYER_ENTERING_WORLD", UpdateRole)
------------------------------------------------------------------------------------------------------------------
--TODO review this
local function healCastsUpdate(event, ...)
    local unit, spell = select(1,...)
    if spell and unit == "player" then
        if event == "UNIT_SPELLCAST_SENT" then
            local _,_,_,target = select(1,...)
            if target and UnitExists(target) then
                lastTarget = target
                if IsHealCast(spell) then
                    lastHealCastTarget = target
                end
            end
        end
        if  event == "UNIT_SPELLCAST_SUCCEEDED" then
            if spell == resSpell then
                RunMacroText("/w " .. resUnit .. " Реснул тебя, вставай давай!")
                if InCombatLockdown() then RunMacroText("/w " .. resUnit .. " Но смотри аккуратно, чтоб сразу не умереть!") end
                resList[resUnit] = GetTime()
                Notify("Успешно применил "..resSpell .. " на " .. resUnit)
            end
        end
        if event == "UNIT_SPELLCAST_SUCCEEDED" or event == "UNIT_SPELLCAST_FAILED" then
            if IsHealCast(spell) then
                lastHealCastTarget = nil
            end
            if spell == resSpell then
                resSpell = nil
                resUnit = nil
            end
        end
    end
end    
AttachEvent("UNIT_SPELLCAST_SENT", healCastsUpdate)
AttachEvent("UNIT_SPELLCAST_SUCCEEDED", healCastsUpdate)
AttachEvent("UNIT_SPELLCAST_FAILED", healCastsUpdate)
------------------------------------------------------------------------------------------------------------------
--TODO review this
local function UpdateDispel(event, ...)
    local timestamp, type, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName, destFlag, err, dispel = select(1, ...)

        if sourceGUID == UnitGUID("player") and ( type == "SPELL_DISPEL") and spellId and spellName and dispel then
            DispelWhitelist[dispel] = true
        end
    
        if sourceGUID == UnitGUID("player") and (type:match("^SPELL_CAST") and spellId and spellName) 
            and err and dispel and err == "Нечего рассеивать." then
            print(dispel, "не снимается")
            DispelBlacklist[dispel] = GetTime()
        end
end    
AttachEvent("COMBAT_LOG_EVENT_UNFILTERED", UpdateDispel)
------------------------------------------------------------------------------------------------------------------
-- TODO review this
-- Ясность мысли залипла
local function UpdateAura(event, ...)
    local timestamp, type, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName, destFlag, err, dispel = select(1, ...)
    if sourceGUID == UnitGUID("player") and (type:match("^SPELL_CAST") and spellId and spellName)  then
        if err then
            if HasBuff("Ясность мысли") and err:match("Недостаточно") then 
                print("Ясность мысли залипла!")
                RunMacroText("/cancelaura Ясность мысли")
            end
            if Debug  then
                print("["..spellName .. "]: ".. err)
            end
        end
    end
end    
AttachEvent("COMBAT_LOG_EVENT_UNFILTERED", UpdateAura)

------------------------------------------------------------------------------------------------------------------
function DoSpell(spell, target, mana)

    if not spell then return false end
    if CalculateHP("player") < 60 and UnitMana("player") < 70 and GetShapeshiftForm() == 1 and IsReadySpell("Неистовое восстановление") and spell ~= "Неистовое восстановление" then
        local name, _, _, _, _, powerType  = GetSpellInfo(spell)
        if not name or powerType == 1 then return false end
    end
    
    return UseSpell(spell, target, mana)
end
