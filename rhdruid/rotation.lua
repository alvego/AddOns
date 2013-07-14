-- Druid Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
local peaceBuff = {"Пища", "Питье", "Походный облик", "Облик стремительной птицы", "Водный облик"}
function Idle()
    if IsAttack() then
        if CanExitVehicle() then VehicleExit() end
        if IsMounted() then Dismount() return end 
    end
    -- дайте поесть (побегать) спокойно 
    if not IsAttack() and (IsMounted() or CanExitVehicle() or HasBuff(peaceBuff)) then return end
    -- чтоб контроли не сбивать
    if not CanControl("target") then RunMacroText("/stopattack") end
    if IsHeal() then
        HealRotation()
        return
    end
end

------------------------------------------------------------------------------------------------------------------


local members = {}
local protBuffsList = {"Ледяная глыба", "Божественный щит", "Превращение", "Щит земли", "Частица Света"}
local dangerousType = {"worldboss", "rareelite", "elite"}
local function compareMembers(hp1, hp2) return hp1 < hp2 end
function HealRotation()
	Notify(UnitGetIncomingHeals("player"))
	if IsAttack() then
        if HasSpell("Буйный рост") then
            if GetShapeshiftForm() ~= 5 and UseMount("Древо Жизни") then return end
        else
            if GetShapeshiftForm() ~= 0 then RunMacroText("/cancelform") end
        end
    end
    if not (IsAttack() or InCombatLockdown()) then return end
    wipe(members)
    for _,u in pairs(UNITS) do
		if CanHeal(u) then 
			 h =  CalculateHP(u)
			if IsFriend(u) then 
				if UnitAffectingCombat(u) and h > 99 then h = h - 1 end
				h = h  - ((100 - h) * 1.15) 
			end
			if UnitIsPet(u) then
				if UnitAffectingCombat("player") then 
					h = h * 1.5
				end
			else
				local status = 0
				for _,t in pairs(TARGETS) do
					if tContains(dangerousType, UnitClassification(t)) then 
						local isTanking, state, scaledPercent, rawPercent, threatValue = UnitDetailedThreatSituation("player", t)
						if state ~= nil and state > status then status = state end
					end
				end
				h = h - 2 * status
				if HasBuff(protBuffsList, 1, u) then h = h + 5 end
			end
			members[u] = h
		end
    end
	table.sort(members, compareMembers)    
	for u,h in pairs(members) do
		
		
		if (HasBuff("Природная стремительность")) then
            if not HasMyBuff("Восстановление", 3, u) and DoSpell("Восстановление", u) then return end
            if HasMyBuff("Восстановление", 2, u) and DoSpell("Покровительство Природы", u) then return end
            return 
        end
        --[[
        if HasBuff("Ясность мысли") then 
			for u,h in pairs(members) do
				if GetBuffStack("Жизнецвет", u) < 3 then 
					DoSpell("Жизнецвет", u)
					return 
				end
			end
        end
        
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
        
        if GetBersState() then
            if ((UnitThreatAlert(u) == 3) or IsOneUnit("focus", u)) and h < 100 then
                if not (h < 60 and HasMyBuff("Жизнецвет", 0.01, u)) and (not HasMyBuff("Жизнецвет", 2, u) or GetBuffStack("Жизнецвет", u) < 3) and DoSpell("Жизнецвет", u) then return end
              else
                if UnitMana100("player") > 50 and h < 80 and h > 50 and (not HasMyBuff("Жизнецвет", 2, u) or GetBuffStack("Жизнецвет", u) < 3) and DoSpell("Жизнецвет", u) then return end
            end
        end

        if PlayerInPlace() and (IsAttack() or InCombatLockdown()) then
            if (h < 60 or ( h < 80 and UnitThreatAlert(u) == 3)) 
				and HasMyBuff("Благоволение природы") 
				and not HasMyBuff("Восстановление", 3, u) 
				and DoSpell("Восстановление", u) then return end
            if (h < 55 or (h < 75 and UnitThreatAlert(u) == 3)) 
				and (HasMyBuff("Омоложение", 2, u) or HasMyBuff("Восстановление", 2, u) or HasMyBuff("Жизнецвет", 2, u) or HasMyBuff("Буйный рост", 2, u)) 
				and DoSpell("Покровительство Природы", u) then return end
        end
        ]]
		break
    end
    
    
    
    
    --GetMySpellHeal("Покровительство Природы"),
    
    --DoSpell("Покровительство Природы")
end


