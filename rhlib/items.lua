-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
function IsReadySlot(slot)
    local itemID = GetInventoryItemID("player",slot)
    if not itemID or (IsItemInRange(itemID, "target") == 0) then return false end
    if not IsReadyItem(itemID) then return false end
    return true
end

------------------------------------------------------------------------------------------------------------------
function UseSlot(slot)
    if SpellIsTargeting() then CameraOrSelectOrMoveStart() CameraOrSelectOrMoveStop() end  
    if IsPlayerCasting() then return false end
    if not IsReadySlot(slot) then return false end
    RunMacroText("/use " .. slot) 
    return true
end

------------------------------------------------------------------------------------------------------------------
function GetItemCooldownLeft(name)
    local start, duration = GetItemCooldown(name);
    if not start then return 0 end
    if not duration or duration < 1.45 then duration = 1.45  end
    local left = start + duration - GetTime()
    if left < 0.01 then 
        return 0
    end
    return left
end

------------------------------------------------------------------------------------------------------------------
function IsReadyItem(name)
   local usable = IsUsableItem(name) 
   if not usable then return true end
   local left = GetItemCooldownLeft(name)
   return (left < 0.01)
end

------------------------------------------------------------------------------------------------------------------
function UseItem(itemName)
    if SpellIsTargeting() then CameraOrSelectOrMoveStart() CameraOrSelectOrMoveStop() end  
    if IsPlayerCasting() then return false end
    if not IsEquippedItem(itemName) and not IsUsableItem(itemName) then return false end
    local start = GetTime()
    local try = 0
    while IsReadyItem(itemName) and GetTime() - start < 1 and try < 3 do
        RunMacroText("/use " .. itemName)
        try = try + 1
    end
    return true
end

------------------------------------------------------------------------------------------------------------------
function UseEquippedItem(item)
    if IsEquippedItem(item) and UseItem(item) then return true end
    return false
end

------------------------------------------------------------------------------------------------------------------
function UseHealPotion()
    local potions = { 
    "Камень здоровья из Скверны",
    "Великий камень здоровья",
    "Рунический флакон с лечебным зельем",
    "Бездонный флакон с лечебным зельем",
    }
    return TryEach(potions, UseItem)
end