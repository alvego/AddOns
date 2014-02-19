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
	if IsDD() then
        Sova()
        return
    end
end

------------------------------------------------------------------------------------------------------------------

local tranquilityAlertTimer = 0;
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

    local members = GetHealingMembers(UNITS)
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
		for i = 1, #members do
			local u = members[i]
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
		local lowhpmembers, membersCount = 0, #members     
		local heal = GetMySpellHeal("Спокойствие")  
		for i = 1, #members do
			if UnitLostHP(members[i]) >= heal then lowhpmembers = lowhpmembers + 1 end
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

		for i = 1, #members do 
			local u = members[i]
			local c = 0
			for j = 1, #members do 
				local u2 = members[j]
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

------------------------------------------------------------------------------------------------------------------
local t = 0
local s = 0
local l = 0
function Sova()
    if t ~= 7 and Debug then print(t) end
    t = 0
    if not HasBuff("Облик лунного совуха") and DoSpell("Облик лунного совуха") then return end
    t = 1
    if UnitMana100("player") < 50 and DoSpell("Озарение", "player") then return end
    t = 2
    if UnitHealth("target") > 200000 and not HasDebuff("Волшебный огонь") and DoSpell("Волшебный огонь") then return end
    t = 3
    --if not HasDebuff("Земля и луна") and DoSpell("Гнев") then end
    if not HasMyDebuff("Рой насекомых", 1,"target") and DoSpell("Рой насекомых") then return end
    t = 4
    if not HasMyDebuff("Лунный огонь", 1,"target") and DoSpell("Лунный огонь") then return end
    t = 5

    if not HasBuff("Солнечное") and (HasBuff("Лунное") or GetTime() - l < 4.6) and DoSpell("Звездный огонь") then l = GetTime() return end
    t = 6
    if not (HasBuff("Лунное")or GetTime() - l < 4.6) and DoSpell("Гнев") then return end
    t = 7
	if HasBuff("Солнечное") and DoSpell("Гнев") then return end
end
