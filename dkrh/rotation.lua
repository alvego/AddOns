-- DK Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
function Idle()
    if IsAttack() then 
        if CanExitVehicle() then VehicleExit() return end
        if IsMounted() then Dismount() return end 
    end
    if not IsAttack() and (HasBuff("Пища") or HasBuff("Питье") or IsMounted()) then return end
    
    if IsNeedTaunt() and TryTaunt("mouseover") then return end
    
    if (IsAttack() or InCombatLockdown()) then
        if TryEach(TARGETS, TryInterrupt) then return end
        
        if HasRunes(100) and not (HasBuff("Власть крови") or HasBuff("Власть льда") or HasBuff("Власть нечестивости")) 
            and DoSpell("Власть крови") then return end
        
        if HasClass(TARGETS, {"PALADIN", "PRIEST"}) and HasBuff("Перерождение") then RunMacroText("/cancelaura Перерождение") end
        if TryEach(TARGETS, function(t) 
            return UnitIsPlayer(t) and tContains({"ROGUE", "DRUID"}, GetClass(t)) and not InRange("Ледяные оковы", t) and not HasDebuff("Темная власть", 1, t) and DoSpell("Темная власть", t) 
        end) then return end
        if TryEach(TARGETS, function(t) 
            return UnitIsPlayer(t) and not InRange("Ледяные оковы", t) and not HasDebuff("Темная власть", 1, t) and DoSpell("Темная власть", t) 
        end) then return end
        
        if DeathGripState and HasBuff("Власть льда") and InGroup() and InCombat(3) 
            and TryEach(TARGETS, function(target) return IsValidTarget(target) and UnitAffectingCombat(target) and TryTaunt(target) end) then return end
            
        if not HasSpell("Удар Плети") and TryPestilence() then return end
        if TryHealing() then return end
        if TryProtect() then return end
        if TryBuffs() then return end
        TryTarget()

        -- if HasSpell("Удар в сердце") then Blood() 
            if HasSpell("Удар Плети") then Anh() else
                Frost() 
            -- end
        end
    end
end

------------------------------------------------------------------------------------------------------------------
function Anh()
        if not (IsValidTarget("target") and (UnitAffectingCombat("target") and CanAttack("target") or IsAttack()))  then return end
        RunMacroText("/startattack")
        RunMacroText("/petattack")
        
        if not HasSpell("Цапнуть") and DoSpell("Воскрешение мертвых") then return end
        
        if NoRunes() then DoSpell("Усиление рунического оружия") end
        -- if not HasRunes(100, false) and  min(GetRuneCooldownLeft(1), GetRuneCooldownLeft(2)) > 4 then DoSpell("Кровоотвод") end
        if not HasMyDebuff("Кровавая чума", 1, "target") and HasRunes(001) and DoSpell("Удар чумы") then end
        -- print(1)
        if not HasMyDebuff("Озноб", 1, "target") and HasRunes(010) and DoSpell("Ледяное прикосновение") then end
        -- print(2)
        -- DoSpell("Рунический удар")
        -- if DoSpell("Призыв горгульи") then return end
        -- if not Dotes() and not(IsAOE() or IsAttack()) then return end
        if Dotes() and InMelee() then
            DoSpell("Кровавое неистовство")
        end 
        if IsAltKeyDown() == 1 and HasRunes(100) and DoSpell("Мор") then return end
        if HasRunes(100) and not HasBuff("Отчаяние") and DoSpell("Кровавый удар") then return end
        -- print(3)
        if UnitMana("player") > 85 and DoSpell("Лик смерти") then return end
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
        -- print(6)
        if DoSpell("Лик смерти") then return end
        -- print(7)
        if HasRunes(100) and DoSpell("Кровавый удар") then return end
        -- print(8)
        if DoSpell("Зимний горн") then return end
        
        if HasRunes(001) and not HasBuff("Костяной щит") and DoSpell("Костяной щит") then return end
        
end

------------------------------------------------------------------------------------------------------------------
function Frost()
        if not (IsValidTarget("target") and (UnitAffectingCombat("target") and CanAttack("target") or IsAttack()))  then return end
        RunMacroText("/startattack")
        RunMacroText("/petattack")
        
        -- if CanAOE and HasBuff("Морозная дымка") and DoSpell("Воющий ветер") then return end
        
        if NoRunes() then DoSpell("Усиление рунического оружия") end
        if not HasRunes(100, false) and  min(GetRuneCooldownLeft(1), GetRuneCooldownLeft(2)) > 4 then DoSpell("Кровоотвод") end

        if not HasMyDebuff("Озноб", 1, "target") and HasRunes(010) and DoSpell("Ледяное прикосновение") then return end
        if not HasMyDebuff("Кровавая чума", 1, "target") and HasRunes(001) and DoSpell("Удар чумы") then return end
        
        DoSpell("Рунический удар")
        if DoSpell("Ледяной удар") then return end
        if (not InMelee() and DoSpell("Лик смерти")) then return end
        
        if not Dotes() and not(IsAOE() or IsAttack()) then return end
        
        if Dotes() and InMelee() then
            DoSpell("Кровавое неистовство")
            if not InGCD() and HasRunes(011) and DoSpell("Несокрушимая броня") then 
                if DoSpell("Удар чумы") then end
            end
        end 

        if IsAOE() then
            if HasRunes(011) and DoSpell("Воющий ветер") then return end
            if HasRunes(100) and DoSpell("Вскипание крови") then return end
        end

        if not IsAOE() and Dotes() then
            if IsPvP() and UnitHealth100("player") < 85 then
                if HasRunes(011) and DoSpell("Удар смерти") then return end 
            else
                if HasRunes(011) and DoSpell("Уничтожение") then return end 
            end
            if HasRunes(100) and DoSpell("Кровавый удар") then return end
        end
        if HasBuff("Морозная дымка") and DoSpell("Воющий ветер") then return end
        if NoRunes() and UnitMana("player") < 90 and DoSpell("Зимний горн") then return end
        
end

------------------------------------------------------------------------------------------------------------------
function Blood()
        if not (IsValidTarget("target") and (UnitAffectingCombat("target") and CanAttack("target") or IsAttack()))  then return end
        RunMacroText("/startattack")
        RunMacroText("/petattack")
        
       
        if NoRunes() then DoSpell("Усиление рунического оружия") end
        if not HasRunes(100, false) and  min(GetRuneCooldownLeft(1), GetRuneCooldownLeft(2)) > 4 then DoSpell("Кровоотвод") end
        
        if Dotes() and InMelee() then
            DoSpell("Кровавое неистовство")
        end 
      
        if IsAOE() then
            if HasRunes(100) and DoSpell("Вскипание крови") then return end
        end
        
        if not HasMyDebuff("Озноб") and HasRunes(010) and DoSpell("Ледяное прикосновение") then return end
        if not HasMyDebuff("Кровавая чума") and HasRunes(001) and DoSpell("Удар чумы") then return end
        
        DoSpell("Рунический удар")
        if (not InMelee(target) or UnitMana("player") > 65 ) and DoSpell("Лик смерти", target) then return end

        
        if not IsAOE() and Dotes(target) then
            if HasRunes(011) and DoSpell("Удар смерти", target) then return end 
            if HasRunes(100) and DoSpell("Удар в сердце", target) then return end
        end

        if NoRunes() and UnitMana("player") < 90 and DoSpell("Зимний горн") then return end
        
end

------------------------------------------------------------------------------------------------------------------
function TryBuffs()
    if CanAttack("target") and UnitHealth("target") < 19000 then return false end
    if HasSpell("Удар Плети") and not InCombatLockdown() and not HasBuff("Костяной щит") and HasRunes(001) and DoSpell("Костяной щит") then return end
    if not HasBuff("Зимний горн") and DoSpell("Зимний горн") then return true end
    if not (HasBuff("Настой") or HasBuff("Эликсир")) then 
        if (BersState and IsUsableItem("Настой бесконечной ярости")) then
            if UseItem("Настой бесконечной ярости") then return true end
        else
            if UseItem("Настой севера") then return true end
        end
    end
    if BersState then
        if not (HasBuff("Сила") or HasBuff("Выносливость")) then
            if not HasBuff("Власть льда") then
                if UseItem("Свиток силы VIII", "player") then return true end
                if UseItem("Свиток силы VII", "player") then return true end
            else
                if UseItem("Свиток выносливости VIII", "player") then return true end
                if UseItem("Свиток выносливости VII", "player") then return true end
            end
        end
        if not HasBuff("Стойкость") and not HasBuff("Молитва стойкости") and UseItem("Рунический свиток стойкости") then return true end
    end
    return false
end

------------------------------------------------------------------------------------------------------------------
function TryHealing()
    local h = CalculateHP("player")
    if InCombatLockdown() then
        if TryDeathPact() then return true end
        if h < 20 and UseHealPotion() then return true end
        if h < 40 and DoSpell("Кровь земли") then return true end
        if h < 50 and HasRunes(100) and HasSpell("Захват рун") and DoSpell("Захват рун") then return true end
    end
    if h < 50 and (InMelee() and (HasMyDebuff("Озноб") or HasMyDebuff("Кровавая чума")) and HasRunes(011) and DoSpell("Удар смерти")) then return true end
    return false
end

------------------------------------------------------------------------------------------------------------------
function TryTarget()

    if not IsValidTarget("target") then
        TryEach(GetGroupUnits(), function(member)
            target = member .. "-target"
            if IsValidTarget(target) and UnitCanAttack("player", target) and (CheckInteractDistance(target, 2) == 1)  then 
                RunMacroText("/startattack " .. target) 
                return true
            end
            return false
        end)

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
        TryEach(TARGETS, function(target) 
            if IsValidTarget(target) and UnitCanAttack("player", target) and (CheckInteractDistance(target, 2) == 1) and not IsOneUnit("target", target) then 
                RunMacroText("/focus " .. target) 
                return true
            end
            return false
        end)
    end

    if not IsValidTarget("focus") or IsOneUnit("target", "focus") or not (CheckInteractDistance("focus", 2) == 1) then
        RunMacroText("/clearfocus")
    end
end

------------------------------------------------------------------------------------------------------------------
function TryProtect()
    if InCombatLockdown() then
        if (UnitThreat("player") == 3) and (UnitHealth100() < 70 
            and not (HasBuff("Незыблемость льда") or HasBuff("Повышенная стойкость") or HasBuff("Тактика защиты") or HasBuff("Кровь вампира"))) then
            if DoSpell("Незыблемость льда") then return true end
            if UseEquippedItem("Гниющий палец Ика") then return true end
            if UseEquippedItem("Символ неукротимости") then return true end
            if HasSpell("Кровь вампира") and DoSpell("Кровь вампира") then return true end
        end

        if (UnitHealth100() < 50) then
            if DoSpell("Антимагический панцирь") then return true end
            if DoSpell("Незыблемость льда") then return true end
        end
    end
    
    return false;
end

------------------------------------------------------------------------------------------------------------------
local TauntTime = 0
function TryTaunt(target)
    if not CanAttack(target) then return false end
    if UnitThreat("player",target) == 3 then return false end
    if (GetTime() - TauntTime < 1.5) then return false end
    local tt = UnitName(target .. "-target")
    if not IsNeedTaunt() and (UnitIsPlayer(target) or not UnitExists(tt) or IsOneUnit("player", tt)) then return false end
    if DoSpell("Темная власть", target) then 
        TauntTime = GetTime()
            --chat("Темная власть на " .. target)
        return true  
    end
    if DoSpell("Хватка смерти", target) then 
        TauntTime = GetTime()
            --chat("Хватка смерти на " .. target)
        return true  
    end
    return false
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
    if HasRunes(100) and IsValidTarget("focus") and (CheckInteractDistance("focus", 2) == 1) and not Dotes(1, "focus") and Dotes(1) and DoSpell("Мор") then return true end
    if HasRunes(100) and IsValidTarget("focus") and IsValidTarget("target") and (CheckInteractDistance("target", 2) == 1) and not Dotes(1) and Dotes(1, "focus") and InMelee("focus") then DoSpell("Мор", "focus") return true end
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
function HasRunes(runes)
    local r = floor(runes / 100)
    local g = floor((runes - r * 100) / 10)
    local b = floor(runes - r * 100 - g * 10)
    local a = 0
    
    local m = false
    if r < 1 then m = true end
   
    for i = 1, 6 do
        if IsRuneReady(i) then
            local c,t = GetRuneCount(i), GetRuneType(i)
            if t == 1 then r = r - c end
            if t == 2 then g = g - c end
            if t == 3 then b = b - c end
            if t == 4 then a = a + c end
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
    if r + g + b - a <= 0 then return true end
    return false;
end