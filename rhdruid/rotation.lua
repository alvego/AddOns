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
local function compareMembers(hp1, hp2) return hp1 < hp2 end
function HealRotation()
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
		members[u] = CalculateHP(u)
    end
	table.sort(members, compareMembers)    
	for u,h in pairs(members) do
		print(u, h)
		break
    end
    
    
    
    
    --GetMySpellHeal("Покровительство Природы"),
    --Notify(CalculateHP("player"))
    --DoSpell("Покровительство Природы")
end


