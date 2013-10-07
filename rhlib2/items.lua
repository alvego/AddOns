-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
function IsReadySlot(slot)
    if not HasAction(slot) then return false end 
    local itemID = GetInventoryItemID("player",slot)
    if not itemID or (IsItemInRange(itemID, "target") == 0) then return false end
    if not IsReadyItem(itemID) then return false end
    return true
end

------------------------------------------------------------------------------------------------------------------
function UseSlot(slot)
    if IsPlayerCasting() then return false end
    if not IsReadySlot(slot) then return false end
    RunMacroText("/use " .. slot) 
    if SpellIsTargeting() then
        --SpellTargetUnit("target")
        CameraOrSelectOrMoveStart() CameraOrSelectOrMoveStop() 
        --TurnOrActionStart()  TurnOrActionStop()
    end
    return not IsReadySlot(slot)
end

------------------------------------------------------------------------------------------------------------------
function GetItemCooldownLeft(name)
    local start, duration, enabled = GetItemCooldown(name);
    if enabled ~= 1 then return 1 end
    if not start then return 0 end
    if start == 0 then return 0 end
    local left = start + duration - GetTime()
    return left
end

------------------------------------------------------------------------------------------------------------------
function ItemExists(item)
    return GetItemInfo(item) and true or false
end
function ItemInRange(item, unit)
    if ItemExists(item) then
        return (IsItemInRange(item, unit) == 1)
    end
    return false
end
------------------------------------------------------------------------------------------------------------------
function IsReadyItem(name)
   local usable = IsUsableItem(name) 
   if not usable then return true end
   local left = GetItemCooldownLeft(name)
   if left > LagTime then return false end
   return true
end

------------------------------------------------------------------------------------------------------------------
function EquipItem(itemName)
    if IsEquippedItem(itemName) then return false end
    if Debug then
        print(itemName)
    end
    RunMacroText("/equip  " .. itemName) 
    return  IsEquippedItem(itemName)
end
------------------------------------------------------------------------------------------------------------------
function UseItem(itemName, count)
    if SpellIsTargeting() then CameraOrSelectOrMoveStart() CameraOrSelectOrMoveStop() end  
    if IsPlayerCasting() then return false end
    if not IsEquippedItem(itemName) and not IsUsableItem(itemName) then return false end
    if not IsReadyItem(itemName) then return false end
    if Debug then
        print(itemName)
    end
    if not count then count = 1 end
    for i = 1, count do
        RunMacroText("/use " .. itemName)
        if SpellIsTargeting() then
            --SpellTargetUnit("target")
            CameraOrSelectOrMoveStart() CameraOrSelectOrMoveStop() 
            --TurnOrActionStart()  TurnOrActionStop()
            break 
        end
    end
    return not IsReadyItem(itemName)
end

------------------------------------------------------------------------------------------------------------------
function UseEquippedItem(item)
    if ItemExists(item) and IsReadyItem(item) then
        local itemSpell = GetItemSpell(item)
        if itemSpell and IsSpellInUse(itemSpell) then return false end
    end 
    if IsEquippedItem(item) and UseItem(item) then return true end
    return false
end

------------------------------------------------------------------------------------------------------------------
local potions = { 
	"Камень здоровья из Скверны",
	"Великий камень здоровья",
	"Рунический флакон с лечебным зельем",
	"Бездонный флакон с лечебным зельем",
    "Гигантский флакон с лечебным зельем"
}
function UseHealPotion()
    for i = 1, #potions do 
		if UseItem(potions[i], 5) then return true end
	end
    return false
end