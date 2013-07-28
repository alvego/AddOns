﻿-- DK Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
local peaceBuff = {"Пища", "Питье"}
local stanceBuff = {"Власть крови", "Власть льда", "Власть нечестивости"}
local steathClass = {"ROGUE", "DRUID"}
function Idle()

    if IsAttack() then 
        if CanExitVehicle() then VehicleExit() return end
        if IsMounted() then Dismount() return end 
    else
        if not InCombatLockdown() or IsMounted() or CanExitVehicle() or HasBuff(peaceBuff) then return end
    end

    if CanInterrupt then
        for i=1,#TARGETS do
            TryInterrupt(TARGETS[i])
        end
    end
        
    if HasRunes(001) and not HasBuff(stanceBuff) and DoSpell("Власть нечестивости") then return end

    if IsPvP() and IsReadySpell("Темная власть") then
        for i = 1, #TARGETS do
            local t = TARGETS[i]
            if UnitIsPlayer(t) and tContains(steathClass, GetClass(t)) and not InRange("Ледяные оковы", t) and not HasDebuff("Темная власть", 1, t) and DoSpell("Темная власть", t) then return end
        end
    end
        
    
    if TryHealing() then return end
    if TryProtect() then return end
    if TryBuffs() then return end
    TryTarget()
    -- призыв пета
    if not HasSpell("Цапнуть") and DoSpell("Воскрешение мертвых") then return end
    if UnitExists("pet") and UnitHealth100("pet") < 70 and DoSpell("Лик смерти", "pet") then return end
    if not (IsValidTarget("target") and (UnitAffectingCombat("target") and CanAttack("target") or IsAttack()))  then return end
    -- чтоб контроли не сбивать
    if not CanControl("target") then 
        RunMacroText("/stopattack") 
        RunMacroText("/petfollow")
    else
        RunMacroText("/startattack")
        RunMacroText("/petattack")    
    end
    
    
    -- ресаем все.
    if NoRunes() and DoSpell("Усиление рунического оружия") then return end
    -- ресаем руну крови
    if not HasRunes(100) and  min(GetRuneCooldownLeft(1), GetRuneCooldownLeft(2)) > 4 and DoSpell("Кровоотвод") then return end
    -- Пытаемся мором продлить болезни
    if TryPestilence() then return end
    local canMagic = CanMagicAttack("target")
    if canMagic then
        if not HasMyDebuff("Кровавая чума", 1, "target") and HasRunes(001) and DoSpell("Удар чумы") then end
        if not HasMyDebuff("Озноб", 1, "target") and HasRunes(010) and DoSpell("Ледяное прикосновение") then return end
    else
        DoSpell("Рунический удар")
    end

    if not CanMagicAttack("target") then DoSpell("Рунический удар") end
    -- if DoSpell("Призыв горгульи") then return end
    -- if not Dotes() and not(IsAOE() or IsAttack()) then return end
    if Dotes() and InMelee() and UseEquipedItem("Карманные часы Феззика") then return end
    
    if IsAltKeyDown() == 1 and HasRunes(100) and DoSpell("Мор") then return end
    if HasRunes(100, true) and DoSpell("Кровавый удар") then return end
    -- print(3)
    if UnitMana("player") > 100 and DoSpell("Лик смерти") then return end
    -- print(4)
    if IsAOE() then
        if HasRunes(100) and DoSpell("Вскипание крови") then return end
    end
    -- print(5)
    if not IsAOE() and Dotes() then
        if IsPvP() and UnitHealth100("player") < 85 then
            if HasRunes(011) and DoSpell("Удар смерти") then return end 
        else
            if HasMyDebuff("Озноб") and HasMyDebuff("Кровавая чума") and HasRunes(011) and DoSpell("Удар Плети") then return end 
        end
    end
    if canMagic and DoSpell("Лик смерти") then return end
    if DoSpell("Зимний горн") then return end
    if HasSpell("Костяной щит") and HasRunes(001) and not HasBuff("Костяной щит") and DoSpell("Костяной щит") then return end
end

------------------------------------------------------------------------------------------------------------------
function TryBuffs()
    -- Если моб даже не элитка, то смысл бафаться?
    if CanAttack("target") and UnitHealth("target") < 19000 then return false end
    if HasSpell("Костяной щит") and not InCombatLockdown() and not HasBuff("Костяной щит") and HasRunes(001) and DoSpell("Костяной щит") then return end
    if not HasBuff("Зимний горн") and DoSpell("Зимний горн") then return true end
    return false
end

------------------------------------------------------------------------------------------------------------------
function TryHealing()
    local h = CalculateHP("player")
    if InCombatLockdown() then
        if h < 20 and not IsArena() and UseHealPotion() then return true end
        if h < 40 and DoSpell("Кровь земли") then return true end
        if h < 50 and HasRunes(100) and HasSpell("Захват рун") and DoSpell("Захват рун") then return true end
    end
    if h < 50 and (InMelee() and (HasMyDebuff("Озноб") or HasMyDebuff("Кровавая чума")) and HasRunes(011) and DoSpell("Удар смерти")) then return true end
    return false
end
------------------------------------------------------------------------------------------------------------------
function ActualDistance(target)
    if target == nil then target = "target" end
    return (CheckInteractDistance(target, 3) == 1)
end
------------------------------------------------------------------------------------------------------------------
function TryTarget(useFocus)
    -- помощь в группе
    if not IsValidTarget("target") and InGroup() then
        -- если что-то не то есть в цели
        if UnitExists("target") then RunMacroText("/cleartarget") end
        for i = 1, #TARGET do
            local t = TARGET[i]
            if t and (UnitAffectingCombat(t) or IsPvP()) and ActualDistance(t) and (not IsPvP() or UnitIsPlayer(t))  then 
                RunMacroText("/startattack " .. target) 
                break
            end
        end
    end
    -- пытаемся выбрать ну хоть что нибудь
    if not IsValidTarget("target") then
        -- если что-то не то есть в цели
        if UnitExists("target") then RunMacroText("/cleartarget") end

        if IsPvP() then
            RunMacroText("/targetenemyplayer [nodead]")
        else
            RunMacroText("/targetenemy [nodead]")
        end
        if not IsAttack()  -- если в авторежиме
            and (
            not IsValidTarget("target")  -- вообще не цель
            or not ActualDistance("target")  -- далековато
            or (not IsPvP() and not UnitAffectingCombat("target")) -- моб не в бою
            or (IsPvP() and not UnitIsPlayer("target")) -- не игрок в пвп
            )  then 
            if UnitExists("target") then RunMacroText("/cleartarget") end
        end
    end

    if useFocus ~= false then 
        if not IsValidTarget("focus") then
            if UnitExists("focus") then RunMacroText("/clearfocus") end
            for i = 1, #TARGETS do
                local t = TARGETS[i]
                if UnitAffectingCombat(t) and ActualDistance(t) and not IsOneUnit("target", t) then 
                    RunMacroText("/focus " .. t) 
                    break
                end
            end
        end
        
        if not IsValidTarget("focus") or IsOneUnit("target", "focus") or not ActualDistance("focus") then
            if UnitExists("focus") then RunMacroText("/clearfocus") end
        end
    end

    if not IsArena() then
        if IsValidTarget("target") and (not UnitExists("focus") or IsOneUnit("target", "focus")) then
            if IsOneUnit("target","arena1") then RunMacroText("/focus arena2") end
            if IsOneUnit("target","arena2") then RunMacroText("/focus arena1") end
        end
    end
end


------------------------------------------------------------------------------------------------------------------
function TryProtect()
    if not IsPvP() and InCombatLockdown() then
        if (UnitHealth100() < 50) then
            if DoSpell("Антимагический панцирь") then return true end
            if DoSpell("Незыблемость льда") then return true end
        end
    end
    return false;
end

------------------------------------------------------------------------------------------------------------------
function Dotes(t, target)
    if target == nil then target = "target" end
    if t == nil then t = 0.2 end
    return GetDotesTime(target) > t
end

------------------------------------------------------------------------------------------------------------------
function TryPestilence()
    if not CanAOE then return false end
    if Dotes() and IsPestilenceTime() and InMelee() then DoSpell("Мор") return true end
    if Dotes() and HasRunes(100) and IsShiftKeyDown() and DoSpell("Мор") then return true end

    if HasRunes(100) and IsValidTarget("focus") 
        and (CheckInteractDistance("focus", 2) == 1) 
        and not Dotes(1, "focus") and Dotes(1) and DoSpell("Мор") then return true end
    if HasRunes(100) and IsValidTarget("focus") 
        and IsValidTarget("target") and (CheckInteractDistance("target", 2) == 1) 
        and not Dotes(1) and Dotes(1, "focus") and InMelee("focus") then DoSpell("Мор", "focus") return true end
    return false
end

------------------------------------------------------------------------------------------------------------------
function GetDotesTime(target)
    return min(GetMyDebuffTime("Озноб", target),GetMyDebuffTime("Кровавая чума", target))
end

------------------------------------------------------------------------------------------------------------------
function IsPestilenceTime()
    local dotes = GetDotesTime("target")
    local r ,_r = 0, 0
    for i = 1, 6 do
        local c,t = GetRuneCooldownLeft(i), GetRuneType(i)
        if (t == 1 or t == 4) then 
            if c < 0.05 then _r = _r + 1 end
            if c == 0 then c =  10 end
            if (dotes - c) > 3 then r = r + 1 end
        end
    end
    if (dotes > 0.01 and r < 1 and _r > 0 and dotes < 5) then 
--~         chat("Мор ("..floor(dotes)..")") 
        return true
    end
    return false
end

------------------------------------------------------------------------------------------------------------------
function LockBloodRunes()
    if not InRange("Мор", "target") then return false end
    local dotes = GetDotesTime("target")
    local r = 0
    for i = 1, 6 do
        local c,t = GetRuneCooldownLeft(i), GetRuneType(i)
        if (t == 1 or t == 4) then 
            if c == 0 then c =  9 end
            if (dotes - c) > 4 then r = r + 1 end
        end
    end
    if (dotes < 10.1 and dotes > 0.01 and r < 1) then 
        return true
    end
    return false
end

------------------------------------------------------------------------------------------------------------------
function HasRunes(runes, strong)
    local r = floor(runes / 100)
    local g = floor((runes - r * 100) / 10)
    local b = floor(runes - r * 100 - g * 10)
    local a = 0
    
    local m = false
    if r < 1 then m = true end
   
    for i = 1, 6 do
        if IsRuneReady(i) then
            local t = select(1,GetRuneType(i))
            if t == 1 then r = r - 1 end
            if t == 2 then g = g - 1 end
            if t == 3 then b = b - 1 end
            if t == 4 then a = a + 1 end
        end
    end
    
    if CanAOE and LockBloodRunes() then
        if m then
            if a > 0 then a = a - 1 end
        else
            r = r + 1
        end
    end
    
    
    if r < 0 then r = 0 end
    if g < 0 then g = 0 end
    if b < 0 then b = 0 end
    if strong then a = 0 end
    if r + g + b - a <= 0 then return true end
    return false;
end