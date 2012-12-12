-- Paladin Rotation Helper by Timofeev Alexey
local ForbearanceTime = 0
function Tank()
    RunMacroText("/startattack")
    
    if DoSpell("Щит мстителя") then return end
    if IsAOE() then
        if UnitMana100() > 50 and InMelee() and DoSpell("Освящение") then return end
        if (UnitCreatureType("target") == "Нежить") and UnitMana100() > 60 and InMelee() and DoSpell("Гнев небес") then return end
    end
     
    if (IsAltKeyDown() == 1) and not (FindAura("Гнев карателя")) and DoSpell("Гнев карателя") then 
        ForbearanceTime = GetTime()
        return 
    end
    if UnitHealth100("target") < 20 and DoSpell("Молот гнева") then return end
     
    if DoSpell("Молот праведника") then return end
    if UnitMana100() > 55 and DoSpell("Правосудие света") then return end
    if UnitMana100() <= 55 and DoSpell("Правосудие мудрости") then return end
    if DoSpell("Щит праведности") then return end
    -- if UnitMana100() < 60 and DoSpell("Волшебный поток") then  return end
end


function Retribution()
    
    if DoSpell("Правосудие мудрости") then return end
    if UnitHealth100("target") < 20 and DoSpell("Молот гнева") then return end    
    if DoSpell("Удар воина Света") then return end
    if InMelee() and DoSpell("Божественная буря") then return end
    if UnitMana100() > 30 and InMelee() and DoSpell("Освящение") then return end
    if HasBuff("Искусство войны") and DoSpell("Экзорцизм") then return end   
    if (UnitCreatureType("target") == "Нежить") and UnitMana100() > 40 and InMelee() and DoSpell("Гнев небес") then return end    
    -- if UnitMana100() < 60 and DoSpell("Волшебный поток") then  return end
    if DoSpell("Святая клятва") then return end
    if InMelee() and DoSpell("Гнев карателя") then 
        ForbearanceTime = GetTime()
        return 
    end
    if InMelee() and UseEquippedItem("Отмщение отрекшихся") then return true end
    
end


local StartComatTime = 0
function Idle()
    if not InCombatLockdown() then
        StartComatTime = GetTime()
    end
    if (IsAttack() or InCombatLockdown()) then
        local harmTarget = GetHarmTarget()
        local units = GetPartyOrRaidMembers()
        if CanUseInterrupt() then
            local ret = false
            for _,target in pairs(harmTarget) do 
                if not ret and TryInterrupt(target) then ret = true end 
            end
            if ret then return end
        end 
        if IsMouseButtonDown(3) and TryTaunt("mouseover") then return end
        if GetAutoAGGRO() and InGroup() and ((GetTime() - StartComatTime > 1)) then
            local ret = false
            for _,unit in pairs(units) do 
                if not ret and (GetTime() - StartComatTime < 3) and IsInteractTarget(unit) 
                  and  UnitThreat(unit) == 2 and not IsOneUnit("player", unit) 
                  and DoSpell("Длань спасения",unit) then 
                    echo("Длань спасения " .. unit) 
                    ret = true 
                end
            end
            for _,target in pairs(harmTarget) do 
                if not ret and IsValidTarget(target) and UnitAffectingCombat(target) and TryTaunt(target) then ret = true end 
            end
            if ret then return end
        end
        -- Священная жертва
        if InCombatLockdown() and HasSpell("Щит мстителя") and InGroup() and CalculateHP("player") > 70 then
            local lowhpmembers = 0
            for _,target in pairs(units) do if CalculateHP(target) <= 50 then lowhpmembers = lowhpmembers + 1 end end
            if lowhpmembers > 2 and DoSpell("Священная жертва") then return end
        end
        
        if TryHealing() then return end
        if TryDispell("player") then return end
        if TryProtect() then return end
        if TryBuffs() then return end
        TryTarget()
        if not (IsValidTarget("target") and (UnitAffectingCombat("target") or IsAttack()))  then return end
        if HasSpell("Щит мстителя") then
            Tank() 
        else 
            Retribution()
        end
    end
end




function TryBuffs()

        if HasSpell("Удар воина Света") then
            if not HasBuff("Печать мщения") then
                if HasBuff("Печать повиновения") or HasBuff("Печать праведности") then else DoSpell("Печать мщения") end end
            if not FindAura("Благословение") and DoSpell("Великое благословение могущества") then return end
            if HasBuff("Праведное неистовство") and RunMacroText("/cancelaura Праведное неистовство") then return end
            else
                -- if not HasBuff("Стойкость") and not HasBuff("Молитва стойкости") and UseItem("Рунический свиток стойкости") then return true end
            if not FindAura("Благословение") and DoSpell("Великое благословение неприкосновенности") then return end
            if not HasBuff("Праведное неистовство") and DoSpell("Праведное неистовство") then return end
            if not HasBuff("Печать мщения") and DoSpell("Печать мщения") then return end
            if not HasBuff("Священный щит") and DoSpell("Священный щит") then return end
            if not HasBuff("Святая клятва") and DoSpell("Святая клятва") then return end
            if not HasBuff("Щит небес",0.8) and DoSpell("Щит небес") then return end
            return false
        end 
end

function TryHealing()
    local h = CalculateHP("player")
    if InCombatLockdown() then
        if h < 35 and UseHealPotion() then return true end
        if h < 30 and not HasDebuff("Воздержанность", 0.1, "player") and (GetTime() - ForbearanceTime > 30) and DoSpell("Возложение рук") then return true end
        if h < 50 and HasBuff("Искусство войны") then DoSpell("Вспышка Света") return end
        if UnitMana100() < 10 and UseItem("Рунический флакон с зельем маны") then return true end
    end
    return false
end


function TryTarget()

    if not IsValidTarget("target") then
        local found = false
        local members = GetPartyOrRaidMembers()
        for _,member in pairs(members) do 
            target = member .. "-target"
            if not found and IsValidTarget(target) and UnitCanAttack("player", target) and (CheckInteractDistance(target, 2) == 1)  then 
                found = true 
                RunMacroText("/startattack " .. target) 
            end
        end

        if not (CheckInteractDistance("target", 2) == 1) or not UnitCanAttack("player", "target") then
            RunMacroText("/cleartarget")
        end

    end

    if  not IsValidTarget("target") then
        if GetNextTarget() ~= nil then
            RunMacroText("/startattack "..GetNextTarget())
            if not (CheckInteractDistance("target", 2) == 1) or not NextIsTarget() or not UnitCanAttack("player", "target") then
                RunMacroText("/cleartarget")
            end
            ClearNextTarget()
        end
    end

    if not IsValidTarget("target") then
        RunMacroText("/targetenemy [nodead]")
        
        if not IsAttack() and not (CheckInteractDistance("target", 2) == 1) or not UnitCanAttack("player", "target") then
            RunMacroText("/cleartarget")
        end
    end

    if not IsValidTarget("target") or (IsAttack() and  not UnitCanAttack("player", "target")) then
        RunMacroText("/cleartarget")
    end
   
    if not IsValidTarget("focus") then
        local found = false
        local harmTarget = GetHarmTarget()
        for _,target in pairs(harmTarget) do 
            if not found and IsValidTarget(target) and UnitCanAttack("player", target) and InMelee(target) and not IsOneUnit("target", target) then 
                found = true 
                RunMacroText("/focus " .. target) 
            end
        end
    end

    if not IsValidTarget("focus") or IsOneUnit("target", "focus") or not InMelee("focus") then
        RunMacroText("/clearfocus")
    end
end


function TryProtect()
    if InCombatLockdown() then
        if (UnitHealth100() < 90 and not (HasBuff("Крепнущая броня"))) then
            if UseEquippedItem("Клятва Эйтригга") then return true end
        end
        
        if HasSpell("Щит мстителя") and UnitHealth100() < 80 and DoSpell("Святая клятва") then return end
        
        if (UnitHealth100() < 50 and not (HasBuff("Затвердевшая кожа"))) then
            if UseEquippedItem("Проржавевший костяной ключ") then return true end
        end
        --print(HasDebuff("Воздержанность", 0.1, "player"))
        if (UnitHealth100() < 20) and not HasDebuff("Воздержанность", 0.1, "player") and (GetTime() - ForbearanceTime > 30) and DoSpell("Божественная защита")  then return true end   
        end
    return false;
end

local InterruptTime = 0
function TryInterrupt(target)
    if (GetTime() - InterruptTime < 1) then return false end
    if target == nil then target = "target" end
    
    if not IsValidTarget(target) then return false end
    
    local spell, _, _, _, _, endTime, _, _, notinterrupt = UnitCastingInfo(target)
        
    if not spell then 
        spell, _, _, _, _, endTime, _, nointerrupt = UnitChannelInfo(target)
    end
    
    if not spell then return false end
   
    local time = endTime/1000 - GetTime()

    if time < 0.1 or time > 2 then 
        return false 
    end
    m = " -> " .. spell .. " ("..target..")"
    
    if not notinterrupt then 
        --[[if InMelee(target) and DoSpell("Волшебный поток", target) then 
            echo("Волшебный поток"..m)
            InterruptTime = GetTime()
            return true 
        end]]
        if DoSpell("Молот правосудия", target) then 
            echo("Молот правосудия"..m)
            InterruptTime = GetTime()
            return true 
        end
    end
    
    return false    
end

local TauntTime = 0
function TryTaunt(target)
    if not IsValidTarget(target) then return false end
    if UnitIsPlayer(target) then return false end
    if UnitThreat("player",target) == 3 then return false end

    if (GetTime() - TauntTime < 1.5) then return false end
    if DoSpell("Длань возмездия", target) then 
        TauntTime = GetTime()
        chat("Длань возмездия на " .. target)
        return true  
    end

    local tt = UnitName(target .. "-target") 
    if IsInteractTarget(tt) and DoSpell("Праведная защита", tt) then 
        TauntTime = GetTime()
        chat("Праведная защита на " .. tt)
        return true  
    end
    return false
end


--[[function IsValidTarget(target)
    if target == nil then target = "target" end
    local n = UnitName(target)
    if n == nil then return false end
    if IsIgnored(target) then return false end
    if UnitIsDeadOrGhost(target) then return false end
    if UnitIsEnemy("player",target) and UnitCanAttack("player", target) then return true end 
    if (UnitInParty(target) or UnitInRaid(target)) then return false end 
    return UnitCanAttack("player", target)
end]]
