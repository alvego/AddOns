-- Druid Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
local TryResUnit = nil
local TryResTime = 0
local ThreatEnd = 0
local ThreatList = {}


function Idle()
   
    if IsAttack() then
        if HasBuff("Походный облик") then RunMacroText("/cancelaura Походный облик") end
        if CanExitVehicle() then VehicleExit() end
        if IsMounted() then Dismount() return end 
    end
    -- дайте поесть спокойно
    if not IsAttack() and (HasBuff("Пища") or HasBuff("Питье") or IsMounted() or CanExitVehicle() or HasBuff("Призрачный волк")) then return end
    -- чтоб контроли не сбивать
    if not CanControl("target") then RunMacroText("/stopattack") end
    
    if InCombatLockdown() and HasSpell("Кровь земли") and ( UnitHealth100() < 60 or (CanUseInterrupt() and (UnitHealthMax("player") - UnitHealth("player") > 3800))) and DoSpell("Кровь земли") then return end 
    
    if IsMounted() or HasBuff("Облик стремительной птицы") or HasBuff("Походный облик") then return end
    
    if HasBuff("Облик кошки") and IsAltKeyDown() and not PlayerInPlace() and DoSpell("Порыв") then return end
    
    if IsControlKeyDown() and not PlayerInPlace() and not GetCurrentKeyBoardFocus() and not InCombatLockdown() and HasBuff("Облик кошки") and DoSpell("Крадущийся зверь") then return end
    
    if UnitPowerType("player") == 0 then 
        if UnitMana100() < 45 then DoSpell("Озарение", "player") end
        if InCombatLockdown() and UnitMana100() < 15 then UseItem("Рунический флакон с зельем маны") end
        if UnitMana100() < 90 and IsEquippedItem("Осколок чистейшего льда") and UseItem("Осколок чистейшего льда") then return end
    end
    
        
    if (not HasBuff("Облик кошки") or not GetBersState()) and InCombatLockdown() and not HasBuff("Облик лютого медведя") and (UnitPowerType("player") ~= 0 or UnitMana100() > 70) then 
        local members = {}
        for i=1,#UNITS do
            local u = UNITS[i]
            if IsInteractUnit(u) and UnitIsPlayer(u) and InRange("Озарение",u) and IsVisible(u) and UnitPowerType(u) == 0 then  
                table.insert(members, { Unit = u, Mana = UnitMana100(u)} )
            end
        end
        table.sort(members, function(x,y) return x.Mana < y.Mana end)
        if #members > 0 and members[1].Mana < 20 and DoSpell("Озарение", members[1].Unit) then return end
    end
    
    if CanUseInterrupt() and InCombatLockdown() and not HasBuff("Облик лютого медведя")  then 
        local ret = false
        for i=1,#UNITS do
            local u = UNITS[i]
            if not ret and IsValidTarget(u) and UnitIsPlayer(u) and not HasDebuff("Смерч", 1, u) and DoSpell("Смерч", u) then ret = true end 
        end
        if ret then return end
    end
    
  
    if IsMouseButtonDown(3) and UnitName("mouseover") and not CanRes("mouseover") then print("Не могу реснуть", UnitName("mouseover") ) end
    if IsMouseButtonDown(3) and CanRes("mouseover") then
        TryResUnit = UnitPartyName("mouseover")
        TryResTime = GetTime()
        Notify("Пробуем воскресить " ..UnitName(TryResUnit) .. "("..TryResUnit..")")
    end
    
    if TryResUnit and (not CanRes(TryResUnit) or (CanRes(TryResUnit) and (GetTime() - TryResTime) > 60) or not PlayerInPlace())  then
        if UnitName(TryResUnit) and not CanHeal(TryResUnit) then Notify("Не удалось воскресить " .. UnitName(TryResUnit)) end
        TryResUnit = nil
        TryResTime = 0
    end

    if TryResUnit and CanRes(TryResUnit) and not HasBuff("Облик лютого медведя") and (not HasBuff("Облик кошки") or HasBuff("Быстрота хищника")) and TryRes(TryResUnit) then return end
    
    --[[if not InCombatLockdown() and #ThreatList > 0 then wipe(ThreatList) end
    if not IsTank() and InCombatLockdown() and InGroup() and (UnitThreat("player") == 3) and GetTime() - ThreatEnd > 30 then 
        local ret = false
        for _,t in pairs(TARGETS) do 
            local g = UnitGUID(t)
            if not ret and IsValidTarget(t) and UnitAffectingCombat(t) and IsOneUnit(t.."-target", "player") and  UnitHealth(t) > 14000 then 
                if not ThreatList[g]  then ThreatList[g] = GetTime() end
                if ThreatList[g] and (GetTime() - ThreatList[g]) > 5 then 
                    RunMacroText("/к СНИМИТЕ ЕГО С МЕНЯ!!!!")
                    RunMacroText("/helpme")
                    ThreatEnd = GetTime()
                    ret = true 
                end
            else
                if ThreatList[g]  then ThreatList[g] = nil end
            end 
        end
    end]]

    if IsHeal() then
        HealRotation()
        return
    end
    
   
    if IsAttack() and HasBuff("Облик лютого медведя") then
        if DoSpell("Исступление") then return end
        if IsValidTarget("target") and DoSpell("Звериная атака - медведь", "target")  then return true end
    end

    if (IsAttack() or InCombatLockdown()) then
        if CanUseInterrupt() then
            local ret = false
            for key,value in pairs(TARGETS) do if not ret and TryInterrupt(value) then ret = true end end
            if ret then return end
        end 
        if IsMouseButtonDown(3) and IsTank() and TryTaunt("mouseover") then return end
        if CanUseInterrupt() and IsTank() and InGroup() and InCombat(3) then
            local ret = false
            for _,target in pairs(TARGETS) do if not ret and IsValidTarget(target) and UnitAffectingCombat(target) and TryTaunt(target) then ret = true end end
            if ret then return end
        end
        if InCombatLockdown() and UnitHealth100() < 31 and UseHealPotion() then return end
        if TryProtect() then return end
        if TryBuffs() then return end
        TryTarget(CanAutoAOE())

        if IsTank() then
            TankRotation() 
        else
            DDRotation() 
        end
    end
end

------------------------------------------------------------------------------------------------------------------
function TankRotation()
    if (IsAttack() or InCombatLockdown()) and GetShapeshiftForm() ~= 1 then
        UseMount("Облик лютого медведя(Смена облика)")
        return
    end
    if not (IsValidTarget("target") and (UnitAffectingCombat("target") or IsAttack()))  then return end
    RunMacroText("/startattack")
    if UnitMana("palyer") < 20 then DoSpell("Исступление") end
    if HasBuff("Исступление") and (UnitThreat("player") == 3) then RunMacroText("/cancelaura Исступление") end
    
    if IsControlKeyDown() and DoSpell("Оглушить") then return end
    
    if InMelee() and DoSpell("Берсерк") then return end
    
    DoSpell("Трепка")
    
    if IsAOE() then
        if not HasDebuff("Увечье (медведь)",3) and HasBuff("Берсерк",3) and DoSpell("Увечье (медведь)") then return end
        if DoSpell("Размах (медведь)") then return end
    end
    
    if not HasDebuff("Устрашающий рев",3) and DoSpell("Устрашающий рев") then return end
    if not HasDebuff("Волшебный огонь (зверь)",3) and DoSpell("Волшебный огонь (зверь)") then return end
    if (not HasDebuff("Увечье (медведь)") or HasBuff("Берсерк",3)) and DoSpell("Увечье (медведь)") then return end
    if (not HasDebuff("Растерзать", 7) or GetDebuffStack("Растерзать") < 5) and DoSpell("Растерзать") then return end
    if UnitMana("player") > 60 and DoSpell("Увечье (медведь)") then return end
    if DoSpell("Волшебный огонь (зверь)") then return end
    if UnitMana("player") > 60 and DoSpell("Размах (медведь)") then return end
    
   
end 

------------------------------------------------------------------------------------------------------------------
function CanHeal(t)
    
    if InInteractRange(t) 
        and InRange("Омоложение", t)
        and IsVisible(t)
    then return true end 
    
    return false
end


------------------------------------------------------------------------------------------------------------------
local manaEnd = 0
local hpEnd = 0
local buffTime = 0
function HealRotation()
        if IsControlKeyDown() then 
            if IsValidTarget("target") and not HasDebuff("Смерч", 1, "target") then DoSpell("Смерч", "target") end
            return
        end
        
        if IsAttack() or InCombatLockdown() then
            if HasSpell("Буйный рост") then
                if GetShapeshiftForm() ~= 5 and UseMount("Древо Жизни") then return end
            else
                if GetShapeshiftForm() ~= 0 then RunMacroText("/cancelform") end
            end
        end

        if IsAttack() then 
            if not IsInteractUnit("target") then TryTarget(false) end
        else
            if InCombatLockdown() and UnitName("target") and not IsInteractUnit("target") and not IsOneUnit("tareget-target", "player") and UnitThreat("player") == 3 then
                RunMacroText("/cleattarget")
            end
        end
        
        if not (GetShapeshiftForm() == 0 or GetShapeshiftForm() == 5) then return end
       
        local spell = UnitCastingInfo("player")
        local lastHealCastTarget = GetLastHealCastTarget()
        if  InCombatLockdown() and IsHealCast(spell) and lastHealCastTarget and (UnitHealth100(lastHealCastTarget) > 99) then
            RunMacroText("/stopcasting")
            print("Для игрока", lastHealCastTarget, spell, "уже не нужно." )
        end
        local myHP = CalculateHP("player")
        local lowhpmembers = 0
        local lowhpmembers2 = 0
        local notbuffmembers = 0
        local members = {}
        if PlayerInPlace() and not InCombatLockdown() then
            if myHP < 70 then 
                local u = "player"
                if not HasMyBuff("Восстановление", 3, u) and DoSpell("Восстановление", u) then return end
                if HasMyBuff("Восстановление", 2, u) and DoSpell("Покровительство Природы", u) then return end
                return
            end
            local res = false
            for i=1,#UNITS do
               if not res and TryRes(UNITS[i]) then res = true end
            end
            if res then return end
            
            for i=1,#UNITS do
               if CanRes(UNITS[i]) then needRes = true end
            end
            if res then return end
        end
        
               
        for i=1,#UNITS do
            local u = UNITS[i]
           
            if CanHeal(u) then  
                h =  CalculateHP(u)
                if not InCombatLockdown() and IsAttack() and IsOneUnit(u, "mouseover") then 
                    h = h - 56 
                end
                
                if IsOneUnit(u, "player") then 
                    h = h - 1 
                end
                
                if (u:match("pet")) then
                    if UnitAffectingCombat("player") then 
                        h = h * 1.5
                    end
                else
                    if UnitGroupRolesAssigned(u) == "TANK" then h = h - 5 end
                    if UnitThreat(u) == 3 then h = h - 10 end
                    if HasBuff("Частица Света", 1, u) then h = h + 3 end
                    if not (HasBuff("Знак дикой природы", 5, u) or HasBuff("Дар дикой природы",5, u)) then h = h - 5 end
                    if  myHP < 50 and not IsOneUnit("player", u) and not (UnitThreat(u) == 3) then
                        h = h + 40
                    end
                end
                table.insert(members, { Unit = u, HP = h } )
            end
        end
        table.sort(members, function(x,y) return x.HP < y.HP end)
        
        local rUnit, rCount = nil, 0
        for i=1,#members do 
            local u, c = members[i].Unit, 0
            for j=1,#members do
                local d = CheckDistance(u, members[j].Unit)
                if members[j].HP < 95 and d and d < 15 then c = c + 1 end 
            end
            if rUnit == nil or rCount < c then 
                rUnit = u
                rCount = c
            end
            if members[i].HP < 65 then lowhpmembers = lowhpmembers + 1 end 
            if members[i].HP < 95 then lowhpmembers2 = lowhpmembers2 + 1 end
            if not (HasBuff("Знак дикой природы", 5, u) or HasBuff("Дар дикой природы",5, u)) then notbuffmembers = notbuffmembers + 1 end
        end 
        
                 
        if InCombatLockdown() and UnitPowerType("player") == 0 and UnitMana100() < 10 and GetTime() - manaEnd > 120 then 
            RunMacroText("/с Недостаточно маны...")
            RunMacroText("/oom")
            manaEnd = GetTime()
        end
        
        if InCombatLockdown() and myHP < 30 and (UnitThreat("player") == 3) and GetTime() - hpEnd > 120 then 
            RunMacroText("/с Ааааааа! Хила убиваааают!")
            RunMacroText("/helpme")
            hpEnd = GetTime()
        end        
        
       
        local u, h = members[1].Unit, members[1].HP
        
        if not GetBersState() and h > 70 then h = h + 10 end
        
        if UnitPowerType("player") == 0 and UnitMana100() < 70 and not InCombatLockdown() and not(UnitAffectingCombat(u)) then return end
        
        if not IsAttack() and CanHeal("focus") and h > 45  and CalculateHP("focus") < 100 then
            u = "focus"
            h = 46
        end
       
        if (HasBuff("Природная стремительность")) then
            if not HasMyBuff("Восстановление", 3, u) and DoSpell("Восстановление", u) then return end
            if HasMyBuff("Восстановление", 2, u) and DoSpell("Покровительство Природы", u) then return end
            return 
        end
        
        if HasBuff("Ясность мысли") then 
            if not InGCD() and HasBuff("Ясность мысли") and DoSpell("Жизнецвет", u) then 
                RunMacroText("/cancelaura Ясность мысли")
                return 
            end
            return 
        end
        
        if CanUseInterrupt() then
            local ret = false
            for i=1,#members do if not ret and TryDispel(members[i].Unit) then ret = true end end
            if ret then return end
        end 
       
        if h > 70 and CanUseInterrupt() then
            local ret = false
            for key,value in pairs(TARGETS) do if not ret and TryInterrupt(value) then ret= true end end
            if ret then return end
        end 

        if h > 70 and CanUseInterrupt() then
            local ret = false
            for i=1,#members do 
                if not ret and (UnitThreatAlert(members[i].Unit) == 3) and not HasBuff("Шипы",1,members[i].Unit) and DoSpell("Шипы",members[i].Unit) then ret= true end
            end
            if ret then return end
        end 
        
        if (GetTime() - buffTime > 600) and  notbuffmembers > 2 and DoSpell("Дар дикой природы") then buffTime = GetTime() return end

        
        local buffTime = 1
        if not InCombatLockdown() then buffTime = 15 * 60 end
        if (UnitIsPlayer(u) or u:match("pet")) and not (HasBuff("Знак дикой природы", buffTime, u) or HasBuff("Дар дикой природы",buffTime, u)) and DoSpell("Знак дикой природы", u) then return end 

        if (HasSpell("Буйный рост")) then
            if rCount > 1 and DoSpell("Буйный рост",rUnit) then return end
            if rCount == 0 and lowhpmembers2 > 1 and DoSpell("Буйный рост",u) then return end
        end
       
        
        if InCombatLockdown() and PlayerInPlace() and (lowhpmembers > 3 and (100 / #members * lowhpmembers > 35)) and (DoSpell("Дубовая кожа") or HasBuff("Дубовая кожа"))and DoSpell("Спокойствие") then return end
        if (h < 96 or (h < 100 and UnitThreatAlert(u) == 3)) and not HasMyBuff("Омоложение", 1, u) and DoSpell("Омоложение", u) then return end
        
        if InCombatLockdown() then
            if myHP < 41 and UseHealPotion() then return end
                        
            if (h < 35 or ( h < 55 and UnitThreatAlert(u) == 3)) and HasSpell("Природная стремительность") and DoSpell("Природная стремительность") then  return end

            if (h < 45 or ( h < 65 and UnitThreatAlert(u) == 3)) and (HasMyBuff("Омоложение", 1, u) or HasMyBuff("Восстановление", 1, u)) and HasSpell("Быстрое восстановление") and DoSpell("Быстрое восстановление", u) then return end
                
            if myHP < 60 then DoSpell("Дубовая кожа") end
        end
        
        if InCombatLockdown() and IsAOE() or (UnitThreatAlert("player") == 3 and CanUseInterrupt()) then
            if not HasBuff("Хватка природы") and DoSpell("Хватка природы")  then return end
            
            if InCombatLockdown() and PlayerInPlace() and not IsReadySpell("Хватка природы") and not HasBuff("Хватка природы")  then
                local ret = false
                for _,t in pairs(TARGETS) do 
                
                    if  not ret and IsValidTarget(t) and UnitAffectingCombat(t) and IsOneUnit(t.."-target","player") and not HasDebuff("Смерч",1,t) then
                        
                        if (UnitCastingInfo(t) or UnitChannelInfo(t)) and (not HasDebuff("Смерч",1, t)) and DoSpell("Смерч",t) then 
                            print("Смерч на", UnitName(t), "("..t..")")
                            ret= true
                         end
                    
                    
                        if not ret and (not HasDebuff("Гнев деревьев",1, t)) and not InMelee(t) and DoSpell("Гнев деревьев",t) then 
                            print("Гнев деревьев на", UnitName(t), "("..t..")")
                            ret= true
                        end
                    

                    end 
                end
                if ret then return end
            end
            
        end
        
        
        if GetBersState() then
            if ((UnitThreatAlert(u) == 3) or IsOneUnit("focus", u)) and h < 100 then
                if not (h < 60 and HasMyBuff("Жизнецвет", 0.01, u)) and (not HasMyBuff("Жизнецвет", 2, u) or GetBuffStack("Жизнецвет", u) < 3) and DoSpell("Жизнецвет", u) then return end
              else
                if UnitMana100("player") > 50 and h < 80 and h > 50 and (not HasMyBuff("Жизнецвет", 2, u) or GetBuffStack("Жизнецвет", u) < 3) and DoSpell("Жизнецвет", u) then return end
            end
        end

        if PlayerInPlace() and (IsAttack() or InCombatLockdown()) then
            if (h < 60 or ( h < 80 and UnitThreatAlert(u) == 3)) and HasMyBuff("Благоволение природы") and not HasMyBuff("Восстановление", 3, u) and DoSpell("Восстановление", u) then return end
            if (h < 55 or (h < 75 and UnitThreatAlert(u) == 3)) and (HasMyBuff("Омоложение", 2, u) or HasMyBuff("Восстановление", 2, u) or HasMyBuff("Жизнецвет", 2, u) or HasMyBuff("Буйный рост", 2, u)) and DoSpell("Покровительство Природы", u) then return end
        end
        
     end

------------------------------------------------------------------------------------------------------------------
-- local tRotation = false
function DDRotation()
    local myHP = CalculateHP("player")
--[[    if myHP < 30 then tRotation = true end
    if myHP > 60 then tRotation = false end
    if tRotation then 
        TankRotation()
    end]]
    
--[[    local oUnit = "Reasonable"
    if InCombatLockdown() and CanHeal(oUnit) and UnitMana100(oUnit) < 40 and InRange("Озарение") and IsReadySpell("Озарение") then RunMacroText("/cast [target="..oUnit.."] Озарение") end
 ]]   
    if HasBuff("Быстрота хищника") and CanUseInterrupt() then
        if UnitHealthMax("player") - UnitHealth("player") > 5000 then DoSpell("Целительное прикосновение", "player") return end
        local members = {}
        for i=1,#UNITS do
            local u = UNITS[i]
            if CanHeal(u) then  
                h =  CalculateHP(u)
                if UnitIsPlayer(u) then
                    if UnitGroupRolesAssigned(u) == "TANK" then h = h - 5 end
                    if UnitThreat(u) == 3 then h = h - 10 end
                    if HasBuff("Частица Света", 1, u) then h = h + 3 end
                end
                table.insert(members, { Unit = u, HP = h } )
            end
        end
        table.sort(members, function(x,y) return x.HP < y.HP end)
        if members[1].HP < 40 then DoSpell("Целительное прикосновение", members[1].Unit) return end
    end
    
    if HasBuff("Быстрота хищника") then
        if IsControlKeyDown() and HasDebuff("Смерч",1,"target") then DoSpell("Смерч") return end
        if myHP < 60 then DoSpell("Целительное прикосновение", "player") return end
    end
    
    if CanUseInterrupt() and TryDispel("player") then return end
    
    if not IsAOE() and HasDebuff("Смерч") then
        RunMacroText("/stopattack")
        if IsControlKeyDown() and not HasBuff("Омоложение", 2, "player") and DoSpell("Омоложение", "player") then return end
        if IsControlKeyDown() and (not HasBuff("Жизнецвет", 2, "player") or GetBuffStack("Жизнецвет", "player") < 3) and DoSpell("Жизнецвет", "player") then return end
        return
    end
    
    if HasBuff("Облик лютого медведя") and IsValidTarget("target")  then
        if UnitMana("target") < 50 and DoSpell("Исступление") then return end
    
        if HasSpell("Звериная атака - медведь")and InRange("Звериная атака - медведь", "target")  and (UnitMana("target") >= 5 or IsReadySpell("Исступление")) then 
            DoSpell("Звериная атака - медведь")
            return
        end
    
        -- if DoSpell("Оглушить") then return end
        -- if not HasDebuff("Устрашающий рев",3) and DoSpell("Устрашающий рев") then return end
    end
    if HasBuff("Облик кошки") then
        if not HasBuff("Крадущийся зверь") and HasSpell("Звериная атака - медведь") and IsAttack() and IsValidTarget("target") and InRange("Звериная атака - медведь", "target") and GetSpellCooldownLeft("Звериная атака - кошка") > 2 and GetSpellCooldownLeft("Звериная атака - медведь") == 0 then
            UseMount("Облик лютого медведя(Смена облика)")
            return
        end
    
        if IsAttack() and InRange("Волшебный огонь (зверь)", "target") and IsValidTarget("target") and not InCombatLockdown() and HasBuff("Облик кошки") and IsReadySpell("Крадущийся зверь") then 
            DoSpell("Крадущийся зверь")
            return 
        end
        
    
        if not (IsValidTarget("target") and (UnitAffectingCombat("target") or IsAttack()))  then return end
        
        if IsAttack() and HasSpell("Звериная атака - кошка") and (IsStealthed() or not IsReadySpell("Крадущийся зверь")) and DoSpell("Звериная атака - кошка") then return end
        
        if IsStealthed() then 
            
            if not IsBehind() then
                if DoSpell("Наскок") then return end
            else
                if DoSpell("Накинуться") then return end
            end
            return 
        end
       
        
        
        if InCombatLockdown() and IsAttack() and IsValidTarget("target") and InRange("Звериная атака - кошка", "target") and DoSpell("Звериная атака - кошка") then return end
                
        RunMacroText("/startattack")
        
        if InGroup() then
            if TryEach(TARGETS, function(t) 
                if tContains({"worldboss", "rareelite", "elite"}, UnitClassification(t)) then 
                local isTanking, state, scaledPercent, rawPercent, threatValue = UnitDetailedThreatSituation("player", t)
                    if not isTanking and state == 1 and DoSpell("Попятиться", t) then
                         print("Попятиться!!")
                        return true
                    end
                end
            end) then return end
        end

--~      Ротация для кошки 
        if IsAOE() then
            if UnitMana("player") < 35 and UnitMana("player") > 25 and not HasBuff("Берсерк") and DoSpell("Тигриное неистовство") then return end
            DoSpell("Размах (кошка)")
            return
        end
        
        
        if UnitMana("player") < 30 and DoSpell("Тигриное неистовство") then return end
        
        if HasDebuff("Глубокая рана") and HasDebuff("Волшебный огонь (зверь)", 5) and HasDebuff("Разорвать",7) and InMelee() then
            if UnitMana("player") > 25 and UnitMana("player") < 85 and HasSpell("Берсерк") and DoSpell("Берсерк") then return end
        end
        
        if HasBuff("Ясность мысли") then
            if not IsBehind() then
                if HasSpell("Увечье (кошка)") then
                    if DoSpell("Увечье (кошка)") then return end
                else
                    if DoSpell("Цапнуть") then return end
                end
            else
                if DoSpell("Полоснуть")  then return end
            end
        end
        
        
        if not HasDebuff("Волшебный огонь (зверь)", 2) and DoSpell("Волшебный огонь (зверь)") then return end
        
        if HasSpell("Увечье (кошка)") and not (HasDebuff("Увечье (медведь)") or HasDebuff("Увечье (кошка)") or HasDebuff("Травма"))then
                DoSpell("Увечье (кошка)") 
            return
        end
        if not HasDebuff("Глубокая рана") then 
            DoSpell("Глубокая рана") 
            return 
        end
        
        local CP = GetComboPoints("player", "target")

        if (CP > 3) and not HasBuff("Дикий рев", 3) and DoSpell("Дикий рев") then return end
        if (CP > 0) and not HasBuff("Дикий рев") then 
            DoSpell("Дикий рев")
            return 
        end
        if (CP == 5) then
            if UnitMana("player") < 40 and HasSpell("Берсерк") and HasBuff("Дикий рев", 5) and HasDebuff("Разорвать", 5) and DoSpell("Свирепый укус") then return end
            if not HasDebuff("Разорвать", 0.8) and DoSpell("Разорвать") then return end
            if UnitMana("player") < 40 and HasBuff("Дикий рев", 6) and HasDebuff("Разорвать", 6) and DoSpell("Свирепый укус") then return end
            if InGCD() or UnitMana("player") < 40 then return end
        end
      
      
        if not IsBehind() then
            if HasSpell("Увечье (кошка)") then
                if DoSpell("Увечье (кошка)") then return end
            else
                if DoSpell("Цапнуть") then return end
            end
        else
            if DoSpell("Полоснуть")  then return end
        end
        
        if not HasDebuff("Волшебный огонь (зверь)", 7) and DoSpell("Волшебный огонь (зверь)") then return end
        
    else
        if (HasBuff("Знак дикой природы") or HasBuff("Дар дикой природы")) and HasBuff("Шипы") and UseMount("Облик кошки") then return end
    end
        
end

------------------------------------------------------------------------------------------------------------------
local InterruptTime = 0
function TryInterrupt(target)
    if (GetTime() - InterruptTime < 1) then return false end
    if target == nil then target = "target" end
    
    if not IsValidTarget(target) then return false end
    if IsPlayerCasting() then return false end

    local spell, _, _, _, _, endTime, _, _, notinterrupt = UnitCastingInfo(target)
        
    if not spell then 
        spell, _, _, _, _, endTime, _, nointerrupt = UnitChannelInfo(target)
    end
    
    if not spell then return false end

    if UnitIsPlayer(target) then
        local buff = { 118,116,61305,28271,28272,61780,61721,2637,33786,5185,8936,50464,19750,2061,9484,605,8129,331,8004,51505,403,51514,5782,1120,48181,30108 }
        local ret = true
        for i,v in ipairs(buff) do 
            if ret and spell == GetSpellInfo(v) then 
                ret = false
            end 
        end
        if ret then return false end
    end
    
    local time = endTime/1000 - GetTime() - GetLagTime()

    if time < 1 then return false end
    
    if not HasBuff("Облик лютого медведя") and not HasBuff("Облик кошки") and PlayerInPlace() and InMelee(target) and DoSpell("Громовая поступь") then
        echo("Interrupt " .. spell .. " ("..target.." => Громовая поступь)")
        InterruptTime = GetTime()
        return true 
    end

    if HasBuff("Облик лютого медведя") and DoSpell("Оглушить", target) then
        echo("Interrupt " .. spell .. " ("..target.." => Оглушить)")
        InterruptTime = GetTime()
        return true 
    end
    
    if IsOneUnit("target", target) and HasBuff("Облик лютого медведя") and HasSpell("Звериная атака - медведь") and DoSpell("Звериная атака - медведь", target) then
        echo("Interrupt " .. spell .. " ("..target.." => Звериная атака - медведь)")
        InterruptTime = GetTime()
        return true 
    end
    
    if IsOneUnit("target", target) and HasBuff("Облик кошки") and HasSpell("Звериная атака - кошка") and DoSpell("Звериная атака - кошка", target) then
        echo("Interrupt " .. spell .. " ("..target.." => Звериная атака - кошка)")
        InterruptTime = GetTime()
        return true 
    end    
    
    if HasBuff("Облик кошки") and GetComboPoints("player", target) > 0 and DoSpell("Калечение", target) then
        echo("Interrupt " .. spell .. " ("..target.." => Калечение)")
        InterruptTime = GetTime()
        return true 
    end 
    
--[[    if HasBuff("Быстрота хищника") and DoSpell("Смерч", target) then
        echo("Interrupt " .. spell .. " ("..target.." => Смерч)")
        InterruptTime = GetTime()
        return true 
    end]]
    
    return false    
end

------------------------------------------------------------------------------------------------------------------
function ActualDistance(target)
    if target == nil then target = "target" end
    return (CheckInteractDistance(target, 3) == 1) and not InRange("Звериная атака - медведь", target)
--~     return (InMelee(target, 3) == 1)
end


------------------------------------------------------------------------------------------------------------------
local focusTime = 0
function TryTarget(useFocus)
    if useFocus == nil then useFocus = true end
    if not IsValidTarget("target") then
        local found = false
        local members = GetGroupUnits()
        for _,member in pairs(members) do 
            target = member .. "-target"
            if not found and IsValidTarget(target) and UnitCanAttack("player", target) and ActualDistance(target)  then 
                found = true 
                RunMacroText("/startattack " .. target) 
            end
        end

        if not ActualDistance("target") or not UnitCanAttack("player", "target") then
            RunMacroText("/cleartarget")
        end

    end

    if  not IsValidTarget("target") then
        if GetNextTarget() ~= nil then
            RunMacroText("/startattack "..GetNextTarget())
            if not ActualDistance("target") or not NextIsTarget() or not UnitCanAttack("player", "target") then
                RunMacroText("/cleartarget")
            end
            ClearNextTarget()
        end
    end

    if not IsValidTarget("target") then
        RunMacroText("/targetenemy [nodead]")
        
        if not IsAttack() and not ActualDistance("target") or not UnitCanAttack("player", "target") then
            RunMacroText("/cleartarget")
        end
    end

    if not IsValidTarget("target") or (IsAttack() and  not UnitCanAttack("player", "target")) then
        RunMacroText("/cleartarget")
    end
   
    if not useFocus then return end
   
    if not IsValidTarget("focus") then
        local found = false
        for _,target in pairs(TARGETS) do 
            if not found and IsValidTarget(target) and UnitCanAttack("player", target) and ActualDistance(target) and not IsOneUnit("target", target) then 
                found = true 
                RunMacroText("/focus " .. target) 
            end
        end
    end

    if IsValidTarget("target") and not IsValidTarget("focus") and GetNextTarget() ~= nil and (GetTime()-focusTime > 2) then
        RunMacroText("/focus")
        RunMacroText("/cleartarget")
        RunMacroText("/startattack "..GetNextTarget())
        RunMacroText("/stopattack")
        RunMacroText("/target focus")
        RunMacroText("/targetlasttarget")
        RunMacroText("/focus")
        RunMacroText("/targetlasttarget")
        focusTime = GetTime()
    end
    
    if not IsValidTarget("focus") or IsOneUnit("target", "focus") or not ActualDistance("focus") then
        RunMacroText("/clearfocus")
    end
end

------------------------------------------------------------------------------------------------------------------
function TryProtect()
    local h = CalculateHP("player")
    if InCombatLockdown() then
        if InMelee() and IsEquippedItem("Знак превосходства") and UseItem("Знак превосходства") then return true end
        
        if ((UnitThreatAlert("player") == 3) and (GetBersState() and h < 80 and not (HasBuff("Дубовая кожа") or HasBuff("Повышенная стойкость") or HasBuff("Инстинкты выживания")))) or (h < 50) then
            if DoSpell("Дубовая кожа") then return true end
            if IsEquippedItem("Гниющий палец Ика") and UseItem("Гниющий палец Ика") then return true end
            if HasSpell("Инстинкты выживания") and DoSpell("Инстинкты выживания") then return true end
        end
        
        if (h < 50 and UnitMana("player") > 60 and GetShapeshiftForm() == 1) then
            if HasSpell("Неистовое восстановление") and DoSpell("Неистовое восстановление") then return true end
        end
    end
    
    return false;
end

------------------------------------------------------------------------------------------------------------------
local TauntTime = 0
function TryTaunt(target)
    if GetShapeshiftForm() ~= 1 then return false end
    if not IsValidTarget(target) then return false end
    if UnitIsPlayer(target) then return false end
    local p = UnitName("player")
    local tt = UnitName(target .. "-target") 
    if (p == tt) then return false end
    if (GetTime() - TauntTime < 2) then return false end
    if IsAOE() and DoSpell("Вызывающий рев") then 
        TauntTime = GetTime()
        chat("Вызывающий рев для " .. target)
        return true  
    end
    if  DoSpell("Рык", target) then 
        TauntTime = GetTime()
            chat("Рык на " .. target)
        return true  
    end
    return false
end

------------------------------------------------------------------------------------------------------------------
function TryBuffs()
    if HasBuff("Крадущийся зверь") or InCombatLockdown() or (IsFalling() or IsSwimming()) or not IsAttack() then return false end
    local t = 15 * 60
    local HasDryBuff = (HasBuff("Знак дикой природы", t) or HasBuff("Дар дикой природы", t))
    local HasThornsBuff = HasBuff("Шипы", t / 2)
    
    if HasDryBuff and HasThornsBuff then return false end
    if GetShapeshiftForm() ~= 0 then RunMacroText("/cancelform") return true end
    if not HasDryBuff and DoSpell("Знак дикой природы", "player") then return true end
    if not HasThornsBuff and DoSpell("Шипы", "player") then return true end

    return false
end

