-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
-- Универсальный внутренний метод, для работы с бафами и дебафами
-- bool HasAura('auraName' or {'aura1', ...}, minExpiresTime(s), 'target' or {'target', 'focus', ...}, UnitDebuff or UnitBuff or UnitAura, bool AuraCaster = player)
local function HasAura(aura, last, target, method, my)
    if aura == nil then return false end
    if method == nil then method = UnitAura end
    if target == nil then target = "player" end
    if last == nil then last = 0.1 end
    local result = false
    if type(target) == 'table' and #target > 0 then 
        for i = 1, #target do 
			result = HasAura(aura, last, target[i], method, my)
			if result then break end
		end
		return result
    end
    
    if not UnitExists(target) then return false end
    if (type(aura) == 'table' and #aura > 0) then
		for i = 1, #aura do 
			result = HasAura(aura[i], last, target, method, my)
			if result then break end
		end
		return result
    end
    for i = 1, 40 do
        local name, _, _, _, debuffType, _, Expires, unitCaster  = method(target, i)
        if not name then break end
        if (sContains(name, aura) or (debuffType and sContains(debuffType, aura)))
            and (Expires - GetTime() >= last or Expires == 0) 
            and (not my or unitCaster == "player") then
            result = name
            break
        end 
    end 
    return result
end

------------------------------------------------------------------------------------------------------------------
function HasDebuff(aura, last, target, my)
    if target == nil then target = "target" end
    return HasAura(aura, last, target, UnitDebuff, my)
end

------------------------------------------------------------------------------------------------------------------
function HasBuff(aura, last, target, my)
    if target == nil then target = "player" end
    return HasAura(aura, last, target, UnitBuff, my)
end

------------------------------------------------------------------------------------------------------------------
function HasMyBuff(aura, last, target)
    return HasBuff(aura, last, target, true)
end

------------------------------------------------------------------------------------------------------------------
function HasMyDebuff(aura, last, target)
    return HasDebuff(aura, last, target, true)
end

------------------------------------------------------------------------------------------------------------------
function GetBuffStack(aura, target)
    if aura == nil then return false end
    if target == nil then target = "player" end
    local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId  = UnitBuff(target, aura) 
    if not name or unitCaster ~= "player" or not count then return 0 end;
    return count
end

------------------------------------------------------------------------------------------------------------------
function GetDebuffTime(aura, target)
    if aura == nil then return false end
    if target == nil then target = "player" end
    local name, _, _, count, _, _, Expires  = UnitDebuff(target, aura) 
    if not name then return 0 end
    if expirationTime == 0 then return 10 end
    local left =  expirationTime - GetTime()
    if left < 0 then left = 0 end
    return left
end

------------------------------------------------------------------------------------------------------------------
function GetDebuffStack(aura, target)
    if aura == nil then return false end
    if target == nil then target = "target" end
    local name, _, _, count, _, _, Expires  = UnitDebuff(target, aura) 
    if not name or not count then return 0 end;
    return count
end

------------------------------------------------------------------------------------------------------------------
function GetMyDebuffTime(debuff, target)
    if debuff == nil then return false end
    if target == nil then target = "target" end
    local result = 0
    for i = 1, 40 do
        local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId  = UnitDebuff(target, i)
        if not name then break end
        if name and sContains(name, debuff) and (unitCaster == "player")then 
            if expirationTime == 0 then 
                -- постоянный
                result = 10 
                break
            end
            result =  expirationTime - GetTime()
            if result < 0 then result = 0 end
            break
        end
    end
    return result
end

------------------------------------------------------------------------------------------------------------------
-- using: HasTemporaryEnchant(16 or 17)
local enchantTooltip
function GetTemporaryEnchant(slot)
    if enchantTooltip == nil then
        enchantTooltip = CreateFrame("GameTooltip", "EnchantTooltip")
        enchantTooltip:SetOwner(UIParent, "ANCHOR_NONE")
        enchantTooltip.left = {}
        enchantTooltip.right = {}
        -- Most of the tooltip lines share the same text widget,
        -- But we need to query the third one for cooldown info
        for i = 1, 30 do
            enchantTooltip.left[i] = enchantTooltip:CreateFontString()
            enchantTooltip.left[i]:SetFontObject(GameFontNormal)
            if i < 5 then
                enchantTooltip.right[i] = enchantTooltip:CreateFontString()
                enchantTooltip.right[i]:SetFontObject(GameFontNormal)
                enchantTooltip:AddFontStrings(enchantTooltip.left[i], enchantTooltip.right[i])
            else
                enchantTooltip:AddFontStrings(enchantTooltip.left[i], enchantTooltip.right[4])
            end
        end 
        enchantTooltip:ClearLines()
    end
    enchantTooltip:SetInventoryItem("player", slot)
    local n,h = enchantTooltip:GetItem()

    local nLines = enchantTooltip:NumLines()

    for i = 1, nLines do
        local txt = enchantTooltip.left[i]
        if ( txt:GetTextColor() == 0 ) then
            local line = txt:GetText()  
            local paren = line:find("[(]")
            if ( paren ) then
                line = line:sub(1,paren-2)
                return line
            end
        end
    end
end
