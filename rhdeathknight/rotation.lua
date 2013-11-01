﻿-- DK Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
local peaceBuff = {"Пища", "Питье"}
local stanceBuff = {"Власть крови", "Власть льда", "Власть нечестивости"}
local steathClass = {"ROGUE", "DRUID"}
local reflectBuff = {"Отражение заклинания", "Эффект тотема заземления", "Рунический покров"}
local UndeadFearClass = {"PALADIN", "PRIEST"}
local burstBuff = { 
    "Гнев карателя", 
    "Стылая кровь",
    "Гнев карателя"
}


local advansedTime = 0

function Idle()
    local advansedMod = IsAttack()
    if GetTime() - advansedTime > 1 then
        advansedTime = GetTime()
        advansedMod = true
    end
    if IsAttack() then 
        if HasBuff("Парашют") then RunMacroText("/cancelaura Парашют") return end
        if CanExitVehicle() then VehicleExit() return end
        if IsMounted() then Dismount() return end 

    else
        if IsMounted() or CanExitVehicle() or HasBuff(peaceBuff) or (not InCombatLockdown() and IsPlayerCasting()) then return end
        
        if advansedMod and not InCombatLockdown() then 
            if UnitExists("pet") and UnitMana("player") >= 40 and UnitHealth100("pet") < 99 and DoSpell("Лик смерти", "pet") then return end
            return 
        end
    end
    
    --if IsAttack() and not IsArena() and IsAOE() and IsValidTarget("mouseover") and UseItem("Саронитовая бомба") then return end
    -- гарга по контролу
    

    if CanInterrupt then
        for i=1,#TARGETS do
            TryInterrupt(TARGETS[i])
        end
    end
    
    if TryHealing() then return end
    
    if TryProtect() then return end

    if IsCtr() and UnitMana("player") >= 60 and DoSpell("Призыв горгульи") then return end

    if advansedMod then
         -- призыв пета
        if not HasSpell("Цапнуть") and not InGCD() and DoSpell("Воскрешение мертвых") then return true end

        

        --[[if not IsArena() and InParty() and IsReadySpell("Воскрешение союзника") then
            local units = GetGroupUnits()
            for i=1,#units do
                local u = units[i]
                if UnitExists(u) and UnitIsPlayer(u) 
                    and not UnitIsAFK(u) and not UnitIsFeignDeath(u) 
                    and not UnitIsEnemy("player",u) and UnitIsDead(u) 
                    and not UnitIsGhost(u) and UnitIsConnected(u) 
                    and IsVisible(u) and InRange("Воскрешение союзника", u) then 
                    UseSpell("Воскрешение союзника", u) 
                    break 
                end
            end
        end]]

        if IsPvP() and HasClass(TARGETS, UndeadFearClass) and not HasBuff("Антимагический панцирь") and HasBuff("Перерождение") and not HasBuff("Перерождение", 8) then RunMacroText("/cancelaura Перерождение") end    
        
        if HasRunes(100) and (not HasBuff(stanceBuff) or (IsPvP() and IsAttack() and not HasBuff("Власть крови") )) and DoSpell("Власть крови") then return end
        -- if IsAttack() or (IsCtr() and UnitHealth100("player") > 60) then
        --      if EquipItem("Темная Скорбь") then return true end
        --      if (IsPvP() or not InCombatLockdown()) and HasRunes(100) and not HasBuff("Власть крови") and DoSpell("Власть крови") then return end
        --  end

        if IsPvP() and IsReadySpell("Темная власть") then
            for i = 1, #ITARGETS do
                local t = ITARGETS[i]
                if UnitIsPlayer(t) and ((tContains(steathClass, GetClass(t)) and not InRange("Ледяные оковы", t)) or HasBuff(reflectBuff, 1, t)) and not HasDebuff("Темная власть", 1, t) and DoSpell("Темная власть", t) then return end
            end
        end
        
        if InParty() and HasSpell("Прыжок") and IsPvP() and IsReadySpell("Прыжок") then
            for i = 1, #IUNITS do
                local u = IUNITS[i]
                if UnitIsPlayer(u) and HasDebuff("Дезориентирующий выстрел", 1, u) then
                    RunMacroText("/cast [@" ..u.."] Прыжок")
                    break
                end
            end
        end

    
        
        if TryBuffs() then return end
    end    
    
    TryTarget()

    if not (IsValidTarget("target") and (UnitAffectingCombat("target") and CanAttack("target") or IsAttack()))  then return end
    
    RunMacroText("/startattack")
    if advansedMod then Pet() end
    -- ресаем все.
    if NoRunes() and DoSpell("Усиление рунического оружия") then return end
    -- ресаем руну крови
    if not HasRunes(100, true) and  (min(GetRuneCooldownLeft(1), GetRuneCooldownLeft(2)) > 4) and DoSpell("Кровоотвод") then return end
    -- Пытаемся мором продлить болезни
    if TryPestilence() then return end
    
    if HasSpell("Костяной щит") and HasRunes(001) and not HasBuff("Костяной щит") and DoSpell("Костяной щит") then return end
    if IsMouse3() and TryTaunt("mouseover") then return end
    if advansedMod and not IsPvP() and HasBuff("Власть льда") and InGroup() and InCombat(3) and (IsReadySpell("Темная власть") or IsReadySpell("Хватка смерти")) then
        for i = 1, #TARGETS do
            local t = TARGETS[i]
            if UnitAffectingCombat(t) and TryTaunt(t) then return end
        end
    end
    if advansedMod and IsPvP() and HasRunes(100) and IsReadySpell("Удушение") then
        for i = 1, #ITARGETS do
            local t = ITARGETS[i]
            if HasBuff(burstBuff, 4, t) and DoSpell("Удушение", t) then return end
        end
    end
   
    

    -- if IsPvP() and InMelee() and not HasDebuff("Осквернение") then
    --     if Dotes() and HasRunes(011) and DoSpell(UnitHealth100("player") < 85 and "Удар смерти" or "Удар Плети") then return end
    --     if HasRunes(001) and DoSpell("Удар чумы") then return end
    -- end

    local canMagic = CanMagicAttack("target")
     if canMagic and UseSlot(10) then return end
    local hasFocus = IsValidTarget("focus")
    local canMagicFocus = hasFocus and CanMagicAttack("focus")
    if canMagic and IsPvP() and not InMelee() and not HasDebuff("Ледяные оковы",6,"target") and HasRunes(010) and UseSpell("Ледяные оковы", "target") then return end

    -- накладываем болезни
    if not HasMyDebuff("Кровавая чума", 1, "target") and HasRunes(001) and DoSpell("Удар чумы") then return end
    if not HasMyDebuff("Озноб", 1, "target") and HasRunes(010) and DoSpell(IsPvP() and "Ледяные оковы" or "Ледяное прикосновение") then return end

    -- Если нет болезней и не аое, дальше не идем
    if not (Dotes() or (hasFocus  and  Dotes(1,"focus"))) and IsShiftKeyDown() ~= 1 and not IsAttack() then return end
    
    if not IsCtr() and (IsAttack() or UnitMana("player") >= 60) and (DoSpell("Рунический удар") or (hasFocus and DoSpell("Рунический удар", "focus"))) then return end

    if not IsCtr() and (IsAttack() or UnitMana("player") >= 80) and ((canMagic and DoSpell("Лик смерти")) or (canMagicFocus and DoSpell("Лик смерти", "focus"))) then return end

    if IsAOE() and HasRunes(100) and DoSpell("Вскипание крови") then return end
    if HasRunes(011, IsAOE()) then
        local spellName = UnitHealth100("player") < 85 and "Удар смерти" or "Удар Плети"
        if Dotes() and DoSpell(spellName) then return end 
        if hasFocus and Dotes(1, "focus") and DoSpell(spellName, "focus") then return end 
    end

    if HasRunes(100, true) and (DoSpell("Кровавый удар") or (hasFocus and DoSpell("Кровавый удар", "focus"))) then return end

    if not InMelee() and HasRunes(010) and DoSpell("Ледяное прикосновение") then return end
    if UnitMana("player") >= 100 and ((canMagic and DoSpell("Лик смерти")) or (canMagicFocus and DoSpell("Лик смерти", "focus")))  then return end
    if DoSpell("Зимний горн") then return end
    if hasFocus then
        if not HasMyDebuff("Кровавая чума", 1, "focus") and HasRunes(001) and DoSpell("Удар чумы", "focus") then return end
        if not HasMyDebuff("Озноб", 1, "focus") and HasRunes(010) and DoSpell(IsPvP() and "Ледяные оковы" or "Ледяное прикосновение", "focus") then return end
    end
end

------------------------------------------------------------------------------------------------------------------
local TauntTime = 0
function TryTaunt(target)
    if not CanAttack(target) then return false end
    if UnitThreat("player",target) == 3 then return false end
    if (GetTime() - TauntTime < 1.5) then return false end
    local tt = UnitName(target .. "-target")
    if not IsMouse3() and (UnitIsPlayer(target) or not UnitExists(tt) or IsOneUnit("player", tt)) then return false end
    if DoSpell("Темная власть", target) then 
        TauntTime = GetTime()
            chat("Темная власть на " .. target)
        return true  
    end
    if DoSpell("Хватка смерти", target) then 
        TauntTime = GetTime()
            chat("Хватка смерти на " .. target)
        return true  
    end
    return false
end

------------------------------------------------------------------------------------------------------------------
local totems = { "Тотем оков земли", "Тотем прилива маны", "Тотем заземления" }
function Pet()
    if not HasSpell("Цапнуть") then return end

    if UnitExists("mouseover") and tContains(totems, UnitName("mouseover"))  then
        RunMacroText("/petattack mouseover")
    end
    if not IsValidTarget("pet-target") or IsAttack() then
        RunMacroText("/petattack " .. ((IsValidTarget("focus") and IsAltKeyDown() == 1) and "[@focus]" or "[@target]"))
    end
    --RunMacroText("/petattack")   -- подумать над фокусом
    if IsReadySpell("Сжаться") and UnitHealth100("pet") < 50 then
        for i = 1, #TARGETS do
            local t = TARGETS[i]
            if t and UnitAffectingCombat(t) and IsOneUnit(t .. "target", "pet") then 
                RunMacroText("/cast Сжаться")
                break
            end
        end
    end
    local mana = UnitMana("pet")
    if mana > 70 then RunMacroText("/cast [@pet-target] Цапнуть") end
end


------------------------------------------------------------------------------------------------------------------
function TryBuffs()
    -- Если моб даже не элитка, то смысл бафаться?
    --if CanAttack("target") and UnitHealth("target") < 19000 then return false end
    if HasSpell("Костяной щит") and not InCombatLockdown() and not HasBuff("Костяной щит") and HasRunes(001) and DoSpell("Костяной щит") then return true end
    if not HasBuff("Зимний горн") and DoSpell("Зимний горн") then return true end
    return false
end

------------------------------------------------------------------------------------------------------------------
function TryHealing()
    local h = CalculateHP("player")
    if h < 40 and UnitMana("player") >= 40 and HasSpell("Цапнуть") and UseSpell("Смертельный союз") then return end
    if HasBuff("Перерождение") and UnitHealth100("player") < 100 and DoSpell("Лик смерти", "player") then return end
    if InCombatLockdown() then
        if h < 30 and not IsArena() and UseHealPotion() then return true end
        --if HasSpell("Кровь земли") and h < 40 and DoSpell("Кровь земли") then return true end
        --if h < 50 and HasRunes(100) and HasSpell("Захват рун") and DoSpell("Захват рун") then return true end
        if (not IsPvP() or not HasClass(TARGETS, UndeadFearClass) or HasBuff("Антимагический панцирь")) and HasSpell("Перерождение") and IsReadySpell("Перерождение") and h < 60 and UnitMana("player") >= 40 and DoSpell("Перерождение") then 
            return DoSpell("Лик смерти", "player") 
        end
    end
    if h < ((IsAOE() and Dotes()) and 90 or 65) and HasRunes(011) and InMelee() and (HasMyDebuff("Озноб") or HasMyDebuff("Кровавая чума")) and DoSpell("Удар смерти") then return true end
    if h < ((IsAOE() and Dotes(1, "focus")) and 90 or 65) and HasRunes(011) and InMelee("focus") and (HasMyDebuff("Озноб", 1, "focus") or HasMyDebuff("Кровавая чума", 1, "focus")) and DoSpell("Удар смерти", "focus") then return true end
    
    --if UnitExists("pet")  and UnitMana("player") >= 110 and UnitHealth100("pet") < 40 and DoSpell("Лик смерти", "pet") then return end
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
                RunMacroText("/startattack [@" .. target .. "]") 
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
            or (not IsArena() and not ActualDistance("target"))  -- далековато
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
        
        if not IsValidTarget("focus") or IsOneUnit("target", "focus") or (not IsArena() and not ActualDistance("focus")) then
            if UnitExists("focus") then RunMacroText("/clearfocus") end
        end
    end

    if IsArena() then
        if IsValidTarget("target") and (not UnitExists("focus") or IsOneUnit("target", "focus")) then
            if IsOneUnit("target","arena1") then RunMacroText("/focus arena2") end
            if IsOneUnit("target","arena2") then RunMacroText("/focus arena1") end
        end
    end
end

------------------------------------------------------------------------------------------------------------------

local physDebuff = {
    "Poison"
}
local magicBuff = {
    "Стылая кровь",
    "Героизм",
    "Жажда крови"

}
local magicDebuff = {
    "Призыв горгульи"
}
local checkedTargets = TARGETS --{"target", "focus", "arena1", "arena2", "mouseover"}
function TryProtect()

    local defPhys = false;
    local defMagic = false;

    if InCombatLockdown() then
        if (UnitHealth100() < (IsPvP() and 30 or 50)) then
            echo("Все плохо!", true)
            defPhys = true
            defMagic = true;
        else
            for i=1,#checkedTargets do
                local t = checkedTargets[i]
                if defPhys and defMagic then break end
                if IsValidTarget(t) then
                    if HasBuff("Вихрь клинков", 5, t) and InRange("Ледяные оковы", t) then
                        echo("Вихрь клинков!", true)
                        defPhys = true
                        if HasSpell("Сжаться") then RunMacroText("/cast Сжаться") end
                    end
                    if IsOneUnit("player", t .. "-target") then
                        if HasBuff("Гнев карателя", 5, t) and InRange("Ледяные оковы", t) then
                            echo("Гнев карателя!", true)
                            defPhys = true
                            defMagic = true;
                        end
                        if HasDebuff(magicDebuff, 5, "player") or HasBuff(magicBuff, 5, t) then
                            echo("Магия!", true)
                            defMagic = true;
                        end
                        if HasDebuff(physDebuff, 5, "player") then
                            echo("Яды!", true)
                            defPhys = true;
                        end
                    end

                end
            end
        end
    end
    if defPhys then 
        DoSpell("Незыблемость льда")
        if IsPvP() and Runes(2) > 0 and not HasBuff("Влсть льда") and DoSpell("Власть льда") then 
            Notify("Влсть льда!") 
            return true 
        end
    end
    if defMagic then 
        if not HasBuff("Зона антимагии") and DoSpell("Антимагический панцирь") then return true end
        if HasSpell("Зона антимагии") and not HasBuff("Антимагический панцирь") and Runes(3) > 0 and DoSpell("Зона антимагии") then 
            Notify("Зона антимагии!") 
            return true 
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
    

    if not IsValidTarget("target") then return false end

    if InMelee() and Dotes() and IsPestilenceTime() then 
        DoSpell("Мор") 
        return true
    end


    if not HasRunes(100) then return false end

    if InMelee() and IsAlt() and (HasMyDebuff("Озноб") or HasMyDebuff("Кровавая чума")) then 
        DoSpell("Мор") 
        return true
    end

    if not IsValidTarget("focus") then return false end
  
    if InMelee("focus") and Dotes(0.2, "focus") and not Dotes(2) then 
        DoSpell("Мор", "focus")  
        return true
    end

    if HasRunes(100) and InMelee() and (CheckInteractDistance("focus", 2) == 1) 
        and not Dotes(2, "focus") and Dotes() then 
         DoSpell("Мор")
        return true 
    end

    return false
end

------------------------------------------------------------------------------------------------------------------
function GetDotesTime(target)
    return min(GetMyDebuffTime("Озноб", target),GetMyDebuffTime("Кровавая чума", target))
end

------------------------------------------------------------------------------------------------------------------
function IsPestilenceTime(target)
    if target == nil then
        target = "target"
    end
    local dotes = GetDotesTime(target)
    local r ,_r = 0, 0
    for i = 1, 6 do
        local c,t = GetRuneCooldownLeft(i), GetRuneType(i)
        if (t == 1 or t == 4) then 
            if c < 0.05 then _r = _r + 1 end
            if c == 0 then c =  10 end
            if (dotes - c) > 3 then r = r + 1 end
        end
    end
    if (dotes > 0.01 and r < 1 and _r > 0 and dotes < 6) then 
         --chat("Мор -> "..target.." Dotes("..floor(dotes)..")") 
        return true
    end
    return false
end

------------------------------------------------------------------------------------------------------------------
function LockBloodRunes()
    if not InMelee() then return false end
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
function HasRunes(runes, strong, time)
    local r = floor(runes / 100)
    local g = floor((runes - r * 100) / 10)
    local b = floor(runes - r * 100 - g * 10)
    local a = 0
    
    local m = false
    if r < 1 then m = true end
   
    for i = 1, 6 do
        if IsRuneReady(i, time) then
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

------------------------------------------------------------------------------------------------------------------
