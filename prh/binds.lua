-- Paladin Rotation Helper by Timofeev Alexey & Co
-- Binding
BINDING_HEADER_PRH = "Paladin Rotation Helper"
BINDING_NAME_PRH_OFF = "Выкл ротацию"
BINDING_NAME_PRH_DEBUG = "Вкл/Выкл режим отладки"
BINDING_NAME_PRH_MOUNT = "Вкл/Выкл маунта"
BINDING_NAME_PRH_AOE = "Вкл/Выкл AOE в ротации"
BINDING_NAME_PRH_INTERRUPT = "Вкл/Выкл сбивание кастов"
BINDING_NAME_PRH_AUTOAGGRO = "Авто АГГРО"
BINDING_NAME_PRH_BERSMOD = "Режим берсерка"
BINDING_NAME_PRH_STOP = "Тормознуть цель"
BINDING_NAME_PRH_STAN = "Снять стан"


--~ if GetClass() ~= 'DEATHKNIGHT' then return end
-- addon main frame
local frame=CreateFrame("Frame",nil,UIParent)
print("Paladin Rotation Helper loaded")
-- protected lock test
RunMacroText("/cleartarget")
-- attach events
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:RegisterEvent("UNIT_SPELLCAST_START")
frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
frame:RegisterEvent("UNIT_SPELLCAST_FAILED")
frame:RegisterEvent("UNIT_SPELLCAST_SENT")

local LastUpdate = 0
local UpdateInterval = 0.001
local Paused = false
local Debug = false
local StopTarget = false
local DispellStun = false
local AutoAGGRO = true
local BersState = false
local CanInterrupt = true
local NextTarget = nil
local NextGUID = nil
local InCast = {}



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

function NextIsTarget(target)
    if not target then target = "target" end
    return (UnitGUID("target") == NextGUID)
end

function ClearNextTarget()
    NextTarget = nil
    NextGUID = nil
end

function GetNextTarget()
    return NextTarget
end

function Mount()

    if CanExitVehicle() then
        VehicleExit()
    end
    
    if not IsMounted() and InCombatLockdown() then return end
    
    if IsMounted() then
            Dismount()
    else 
        if IsEquippedItemType("Удочка") then
             UseSpell("Рыбная ловля")
            return
        end
        
        if IsAltKeyDown() then
            UseMount("Тундровый мамонт путешественника")
            return
        end

        if IsFlyableArea() and not IsShiftKeyDown() then
            UseMount("Великолепный ковер-самолет")
        else
            UseMount("Призыв скакуна")
        end

    end
    
end    
    
function TryStopTarget()
    StopTarget = true;
end

function TryDispellStun()
    DispellStun = true;
end

function AutoAGGROToggle()
    AutoAGGRO = not AutoAGGRO
    if AutoAGGRO then
        echo("АвтоАГГРО: ON",true)
    else
        echo("АвтоАГГРО: OFF",true)
    end 
end

function GetAutoAGGRO()
    return AutoAGGRO
end 

function BersModToggle()
    BersState = not BersState
    if BersState then
        echo("Берс Мод: ON",true)
    else
        echo("Берс Мод: OFF",true)
    end 
end

function GetBersState()
    return BersState
end  

function AutoRotationOff()
    Paused = true
    wipe(InCast)
    echo("Авто ротация: OFF",true)
    RunMacroText("/stopattack")
end

function DebugToggle()
    Debug = not Debug
    if Debug then
        echo("Режим отладки: ON",true)
    else
        echo("Режим отладки: OFF",true)
    end 
end

function IsDebug()
    return Debug
end    

function IsAttack()
    return (IsControlKeyDown() == 1)
end

function IsAOE()
   if IsShiftKeyDown() == 1 then return true end
   return (IsValidTarget("target") and IsValidTarget("focus") and not IsOneUnit("target", "focus") and InMelee())
end

function onUpdate(frame, elapsed)
    if (IsAttack() and Paused) then
        echo("Авто ротация: ON",true)
        Paused = false
    end
    
    LastUpdate = LastUpdate + elapsed
    if LastUpdate < UpdateInterval then return end
    LastUpdate = 0

    if Paused then 
        return 
    end
    
    if UnitIsDeadOrGhost("player") or UnitIsCharmed("player") or not UnitPlayerControlled("player") then return end

   
    if not InGCD() and DispellStun then
        DispellStun = false    
        if IsEquippedItem("Медальон Орды") and UseItem("Медальон Орды") then return end
    end

    if not InGCD() and StopTarget then 
        StopTarget = false;
        if not HasDebuff("Сеть из ледяной ткани") then
            if UseItem("Сеть из ледяной ткани") then return end
        end
    end
    
    Idle()   
  
end
frame:SetScript("OnUpdate", onUpdate)


local dispellBlacklist = {}
local dispell = nil
local dispelTime = GetTime()
function TryDispell(unit)
    if not UnitIsFriend("player", unit) then return false end
    if not InRange("Очищение", unit) then return false end
    if GetTime() - dispelTime < 1.5 then return false end
    local ret = false
    for i = 1, 40 do
        if not ret then
            local name, _, _, _, debuffType, duration, expirationTime   = UnitDebuff(unit, i,true) 
            if HasSpell("Щит мстителя") and name and (expirationTime - GetTime() >= 3 or expirationTime == 0) and (debuffType == "Poison" or debuffType == "Disease" or debuffType == "Magic") and (not dispellBlacklist[name] or GetTime() - dispellBlacklist[name] > 30) then
                if DoSpell("Очищение", unit) then 
                    print("Очищение ", unit, name)
                    dispell = name
                    dispelTime = GetTime()
                    ret = true 
                end
            end
        end
    end
    return ret
end

function onEvent(self, event, ...)
--~ print(1,event)
    if event:match("^UNIT_SPELLCAST") then
        local unit, spell = select(1,...)
--~         print(event,  unit, spell )
        if unit == "player" then
            
        
            if spell and event == "UNIT_SPELLCAST_SENT" then
                InCast[spell] = true
            end
            if spell and event == "UNIT_SPELLCAST_SUCCEEDED" then
--~                 if Debug then 
--~                     chat(spell)
--~                 end
            end
            if event == "UNIT_SPELLCAST_SUCCEEDED" or event == "UNIT_SPELLCAST_FAILED" then
                InCast[spell] = false
            end
        end
        return
    end
    
    local timestamp, type, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName, destFlag, err = select(1, ...)
    if not(destName ~= GetUnitName("player")) and sourceName ~= nil and not UnitCanCooperate("player",sourceName) then 
        if not Paused then 
            NextTarget = sourceName
            NextGUID = sourceGUID
        end
    end
    
    if (event=="COMBAT_LOG_EVENT_UNFILTERED") then
        if sourceGUID == UnitGUID("player") and (type:match("^SPELL_CAST") and spellId and spellName)  then

            if  err then
                
                if dispell and err == "Нечего рассеивать." then
                    print(dispell, "не снимается")
                    dispellBlacklist[dispell] = GetTime()
                end
                
                if Debug then
                    print("["..spellName .. "]: ".. err)
                end
            end
            
        end
    end
end
frame:SetScript("OnEvent", onEvent)




function DoSpell(spellName, target, runes)
    if (InCast[spellName]) then return false end
     for _,value in pairs(InCast) do 
        if value then cast = true end
    end
    return UseSpell(spellName, target)
end
