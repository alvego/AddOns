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
    if (type(target) == 'table') then 
		for _,t in pairs(target) do 
			result = HasAura(aura, last, t, method, my)
			if result then break end
		end
		return result
    end
    
    if not UnitExists(target) then return false end
    if (type(aura) == 'table') then
		for _,a in pairs(aura) do 
			result = HasAura(a, last, target, method, my)
			if result then break end
		end
		return result
    end
    
    local i = 0
    local name, _, _, _, debuffType, _, Expires, unitCaster  = method(target, i)
    while (i <= 40) and not result do
        if ((name and sContains(name, aura)) or (debuffType and sContains(debuffType, aura)))
            and (Expires - GetTime() >= last or Expires == 0) 
            and (not my or unitCaster == "player") then
            result = true
        end
        i = i + 1
        if not result then
            name, _, _, _, debuffType, _, Expires, unitCaster  = method(target, i)
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
    local i = 1
    local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId  = UnitDebuff(target, i)
    local result = false
        while (i <= 40) and not result do
        if name and strlower(name):match(strlower(debuff)) and (unitCaster == "player")then 
            result = true
        end
        i = i + 1
        if not result then
            name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId  = UnitDebuff(target, i)
        end
    end
    if not result then return 0 end
    if expirationTime == 0 then return 10 end
    local left =  expirationTime - GetTime()
    if left < 0 then left = 0 end
    return left
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
    local i= 1
    while ( i <= nLines ) do
        local txt = enchantTooltip.left[i]
        
        if ( txt:GetTextColor() == 0 ) then
            local line = enchantTooltip.left[i]:GetText()  
            local paren = line:find("[(]")
            if ( paren ) then
                line = line:sub(1,paren-2)
                return line
            end
        end
        i = i + 1    
    end
end
