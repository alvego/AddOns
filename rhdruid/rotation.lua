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

local tranquilityAlertTimer = 0;
local members = {}
local membersHP = {}
local protBuffsList = {"Ледяная глыба", "Божественный щит", "Превращение", "Щит земли", "Частица Света"}
local dangerousType = {"worldboss", "rareelite", "elite"}
local hotBuffList = {"Омоложение", "Восстановление", "Жизнецвет", "Буйный рост"}
local function compareMembers(u1, u2) 
	return membersHP[u1] < membersHP[u2]
end
function HealRotation()
	if IsAttack() then
        if HasSpell("Буйный рост") then
            if GetShapeshiftForm() ~= 5 and UseMount("Древо Жизни") then return end
        else
            if GetShapeshiftForm() ~= 0 then RunMacroText("/cancelform") end
        end
    end

    wipe(members)
    wipe(membersHP)
    for _,u in pairs(UNITS) do
		if CanHeal(u) then 
			 local h =  CalculateHP(u)
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
			tinsert(members, u)
			membersHP[u] = h
		end
    end
	table.sort(members, compareMembers)  
	local myHP, myLost = CalculateHP("player"), UnitLostHP("player")
	local u = members[1]
	local l = UnitLostHP(u)
	
    if InCombatLockdown() then
        if myHP < 41 and UseHealPotion() then return end
        
        if HasSpell("Кровь земли") and myLost > 3800 and DoSpell("Кровь земли") then return end 

		if HasSpell("Быстрое восстановление") and IsReadySpell("Быстрое восстановление") and (HasMyBuff("Омоложение", 0.5, u) or HasMyBuff("Восстановление", 0.5, u)) then  
			if l >= GetMySpellHeal("Восстановление") and HasSpell("Быстрое восстановление") and DoSpell("Быстрое восстановление") then return end
        end

        if HasSpell("Природная стремительность") and IsReadySpell("Природная стремительность") then  
			if l >= GetMySpellHeal("Покровительство Природы") and HasSpell("Природная стремительность") and DoSpell("Природная стремительность") then return end
        end     
               
                    
            
        if myHP < 60 then DoSpell("Дубовая кожа") end
    end
    
    if HasBuff("Ясность мысли") then 
		if HasBuff("Природная стремительность") then
			if l >= GetMySpellHeal("Целительное прикосновение") then DoSpell("Целительное прикосновение", u) end
			return
		end
		for _,u in pairs(members) do
			if GetBuffStack("Жизнецвет", u) < 3 then 
				DoSpell("Жизнецвет", u)
				return 
			end
		end
    end
    
    if HasBuff("Природная стремительность") then
		if HasMyBuff(hotBuffList, 1.2, u) and DoSpell("Покровительство Природы", u) then return end
        if not HasMyBuff("Восстановление", 3, u) and DoSpell("Восстановление", u) then return end
        return 
    end
    
    if IsReadySpell("Спокойствие") and InCombatLockdown() then
		local lowhpmembers, membersCount = 0, 0     
		local heal = GetMySpellHeal("Спокойствие")  
		for _, u in pairs(members) do 
			membersCount = membersCount + 1
			if UnitLostHP(u) >= heal then lowhpmembers = lowhpmembers + 1 end
		end
		if (lowhpmembers > 3 and (100 / membersCount * lowhpmembers > 35)) and (IsReadySpell("Дубовая кожа") or HasBuff("Дубовая кожа")) then
			if tranquilityAlertTimer == 0 then
				Notify("Стой на месте! Ща жахнем 'Спокойствие!'")
				tranquilityAlertTimer = GetTime()
			end
			if (GetTime() - tranquilityAlertTimer > 1) and PlayerInPlace() and (DoSpell("Дубовая кожа") or HasBuff("Дубовая кожа")) and DoSpell("Спокойствие") then 
				tranquilityAlertTimer = 0
				return 
			end
		end
    end
    
    if PlayerInPlace() and (IsAttack() or InCombatLockdown()) then
		if HasMyBuff("Благоволение природы") and not HasMyBuff("Восстановление", 0.01, u) and l >= GetMySpellHeal("Восстановление") and DoSpell("Восстановление", u) then return end
		if HasMyBuff(hotBuffList, 1.2, u) and l >= GetMySpellHeal("Покровительство Природы") and DoSpell("Покровительство Природы", u) then return end
		if not HasMyBuff("Восстановление", 0.01, u)	and l >= GetMySpellHeal("Восстановление") and DoSpell("Восстановление", u) then return end
    end
    
    if (HasSpell("Буйный рост") and IsReadySpell("Буйный рост")) then
		local dUnit, dCount = nil, 0
		local heal = GetMyHotSpellHeal("Буйный рост")
		for _,u in pairs(members) do 
			local c = 0
			for _,u2 in pairs(members) do 
				local d = CheckDistance(u, u2)
				if UnitLostHP(u2) >= heal and d and d < 15 then c = c + 1 end
			end
			if dUnit == nil or dCount < c then 
				dUnit = u
				dCount = c
			end
		end
        if dCount > 1 then
			if DoSpell("Буйный рост",dUnit) then return end
		else
			if l >= heal and DoSpell("Буйный рост",u) then return end
		end
    end
    
    if IsReadySpell("Омоложение") and not HasMyBuff("Омоложение", 1, u) then
		if l >= GetMyHotSpellHeal("Буйный рост") and DoSpell("Омоложение", u) then return end
    end
    
	if IsReadySpell("Жизнецвет") then
		if (l >= GetMyHotSpellHeal("Жизнецвет") or (UnitThreatAlert(u) == 3 and GetBuffStack("Жизнецвет", u) < 2)) and GetBuffStack("Жизнецвет", u) < 3 and DoSpell("Жизнецвет", u) then return end
	end
	
    


end


