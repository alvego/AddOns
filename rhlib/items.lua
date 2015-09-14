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
local potions = { 
	"Камень здоровья из Скверны",
	"Великий камень здоровья",
	"Рунический флакон с лечебным зельем",
	"Бездонный флакон с лечебным зельем",
    "Гигантский флакон с лечебным зельем"
}
