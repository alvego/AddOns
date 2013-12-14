-- DK Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
local peaceBuff = {"Пища", "Питье"}
local stanceBuff = {"Власть крови", "Власть льда", "Власть нечестивости"}
local steathClass = {"ROGUE", "DRUID"}
local reflectBuff = {"Отражение заклинания", "Эффект тотема заземления", "Рунический покров"}
local UndeadFearClass = {"PALADIN", "PRIEST"}
local baseRP = 40
local advansedTime = 0
local weaponSwitchTime = 0
function Idle()
    local advansedMod = false
    if GetTime() - advansedTime > 1 then
        advansedTime = GetTime()
        advansedMod = true
    end

    if advansedMod and GetTime() - weaponSwitchTime > 5 then
        if IsAttack() or InCombatLockdown() then
            if EquipItem("Темная Скорбь") then 
                weaponSwitchTime = GetTime()
                return true 
            end
        else 
            if EquipItem("Большой меч разгневанного гладиатора") then 
                weaponSwitchTime = GetTime()
                return true 
            end
        end
    end

    if IsAttack() then 
        if HasBuff("Парашют") then RunMacroText("/cancelaura Парашют") return end
        if CanExitVehicle() then VehicleExit() return end
        if IsMounted() then Dismount() return end 

    else
        if IsMounted() or CanExitVehicle() or HasBuff(peaceBuff) or not InCombatLockdown() or IsPlayerCasting() then return end
        
        if advansedMod and not InCombatLockdown() then 
            if UnitExists("pet") and UnitMana("player") >= 40 and UnitHealth100("pet") < 99 and DoSpell("Лик смерти", "pet") then return end
            return 
        end
    end

    if CanInterrupt then
        for i=1,#TARGETS do
            TryInterrupt(TARGETS[i])
        end
    end
    
     -- гарга по контролу
    if IsCtr() and HasSpell("Призыв горгульи") and UnitMana("player") >= 60 and IsReadySpell("Призыв горгульи") then
        if advansedMod then
            RunMacroText("/cleartarget")
            RunMacroText("/targetlasttarget")
        end
        if DoSpell("Призыв горгульи") then return end
        if IsReadySpell("Призыв горгульи") then return end
    end

    -- призыв пета
    if not HasSpell("Цапнуть") and DoSpell("Воскрешение мертвых") then 
        return true 
    end

    if advansedMod then
        if IsPvP() and HasClass(TARGETS, UndeadFearClass) and not HasBuff("Антимагический панцирь") and HasBuff("Перерождение") and not HasBuff("Перерождение", 8) then RunMacroText("/cancelaura Перерождение") end    
        
        if not HasBuff(stanceBuff) and DoSpell("Власть нечестивости") then return end
        
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
    end    

    if TryHealing() then return end
    
    if TryProtect() then return end

    if HasSpell("Костяной щит") and not HasBuff("Костяной щит") and DoSpell("Костяной щит") then return end
    if IsAttack() and not IsValidTarget("target") and DoSpell("Зимний горн") then return end
    TryTarget()

    if not (IsValidTarget("target") and CanAttack("target") and (UnitAffectingCombat("target")  or IsAttack()))  then return end

    RunMacroText("/startattack")
    -- войти в бой
    if IsPvP() and UnitIsPlayer("target") and not InCombatLockdown() and not InMelee() and IsReadySpell("Темная власть") then DoSpell("Темная власть", "target") end
    if advansedMod then Pet() end

    -- Пытаемся мором продлить болезни
    if TryPestilence() then return end

    if IsMouse3() and TryTaunt("mouseover") then return end

    if advansedMod and not IsPvP() and HasBuff("Власть льда") and InGroup() and InCombat(3) and (IsReadySpell("Темная власть") or IsReadySpell("Хватка смерти")) then
        for i = 1, #TARGETS do
            local t = TARGETS[i]
            if UnitAffectingCombat(t) and TryTaunt(t) then return end
        end
    end

    local canMagic = CanMagicAttack("target")
    -- накладываем болезни
    if not HasMyDebuff("Кровавая чума", 3, "target") and DoSpell("Удар чумы") then return end
    if not HasMyDebuff("Озноб", 3, "target") and DoSpell((IsPvP() and not InMelee()) and "Ледяные оковы" or "Ледяное прикосновение") then return end
    if not Dotes() and not IsAttack() then return end
    if canMagic and DoSpell("Лик смерти", "target",  HasDebuff("Нечестивая порча", 2) and baseRP or 0) then return end
    if DoSpell("Рунический удар", "target", baseRP) then return end
    if DoSpell((CanAOE and (IsShiftKeyDown() or (not InMelee() and ActualDistance() and Dotes()))) and "Вскипание крови" or "Кровавый удар") then return end
    if Dotes() and DoSpell((not HasSpell("Удар Плети") or (not IsAttack() and UnitHealth100("player") < 85)) and "Удар смерти" or "Удар Плети") then return end 
    if not InMelee() and DoSpell(IsPvP() and "Ледяные оковы" or "Ледяное прикосновение") then return end
    if DoSpell("Зимний горн") then return end
    -- ресаем все.
    if NoRunes() and DoSpell("Усиление рунического оружия") then return end
    -- ресаем руну крови
    if NoRunes() and DoSpell("Кровоотвод") then return end

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
local totems = { "Тотем оков земли", "Тотем прилива маны", "Тотем заземления", "Тотем очищения", "Тотем источника маны VIII" }
function Pet()
    if not HasSpell("Цапнуть") then return end
    if UnitExists("mouseover") and tContains(totems, UnitName("mouseover"))  then
        RunMacroText("/petattack mouseover")
    end
    if not IsValidTarget("pet-target") or IsAttack() then
        RunMacroText("/petattack " .. ((IsValidTarget("focus") and IsAltKeyDown() == 1) and "[@focus]" or "[@target]"))
    end
    local mana = UnitMana("pet")
    if mana >= (IsAttack() and 40 or 70) then RunMacroText("/cast [@pet-target] Цапнуть") end
end

------------------------------------------------------------------------------------------------------------------
function TryHealing()
    local h = CalculateHP("player")
    if h < 40 and UnitMana("player") >= 40 and HasSpell("Цапнуть") and DoSpell("Смертельный союз") then return end
    if h < 80 and HasSpell("Захват рун") and DoSpell("Захват рун") then return end
    if HasBuff("Перерождение") and UnitHealth100("player") < 100 and DoSpell("Лик смерти", "player") then return end
    if InCombatLockdown() then
        if h < 30 and not IsArena() and UseHealPotion() then return true end
        if (not IsPvP() or not HasClass(TARGETS, UndeadFearClass) or HasBuff("Антимагический панцирь")) and HasSpell("Перерождение") and IsReadySpell("Перерождение") and h < 60 and UnitMana("player") >= 40 and DoSpell("Перерождение") then 
            return DoSpell("Лик смерти", "player") 
        end
    end
    if h < 45 and InMelee() and (HasMyDebuff("Озноб") or HasMyDebuff("Кровавая чума")) and DoSpell("Удар смерти") then return true end
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
local checkedTargets = TARGETS
function TryProtect()

    local defPhys = false;
    local defMagic = false;

    if InCombatLockdown() and (IsValidTarget("target") or IsValidTarget("focus")) then
        for i=1,#checkedTargets do
            local t = checkedTargets[i]
            if defPhys and defMagic then break end
            if IsValidTarget(t) then
                if HasBuff("Вихрь клинков", 4, t) and InRange("Ледяные оковы", t) then
                    echo("Вихрь клинков!", true)
                    defPhys = true
                    if HasSpell("Сжаться") then RunMacroText("/cast Сжаться") end
                end
                if IsOneUnit("player", t .. "-target") then
                    if HasBuff("Гнев карателя", 4, t) and InRange("Ледяные оковы", t) then
                        echo("Гнев карателя!", true)
                        defPhys = true
                        defMagic = true;
                    end
                    if HasDebuff(magicDebuff, 4, "player") or HasBuff(magicBuff, 4, t) then
                        echo("Магия!", true)
                        defMagic = true;
                    end
                    if HasDebuff(physDebuff, 4, "player") then
                        echo("Яды!", true)
                        defPhys = true;
                    end
                end

            end
        end

        if defPhys then 
            DoSpell("Незыблемость льда")
        end
        if defMagic then 
            if not HasBuff("Зона антимагии") and DoSpell("Антимагический панцирь") then return true end
            if HasSpell("Зона антимагии") and not IsReadySpell("Антимагический панцирь") and not HasBuff("Антимагический панцирь") and DoSpell("Зона антимагии") then 
                Notify("Зона антимагии!") 
                return true 
            end
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
    -- продлить болезни на цели
    if InMelee() and Dotes() and IsPestilenceTime() then 
        UseSpell("Мор") 
        return true
    end

    if not IsValidTarget("focus") then return false end
    -- кинуть болезни с цели на фокус
    if InMelee() and Dotes() and not Dotes(1, "focus") then 
        DoSpell("Мор") 
        return true
    end
    -- кинуть болезни с фокуса на цель
    if not Dotes() and InMelee("focus") and Dotes(2, "focus") then 
        DoSpell("Мор", "focus") 
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
