-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
-- Универсальный внутренний метод, для работы с бафами и дебафами
-- bool HasAura('auraName' or {'aura1', ...}, minExpiresTime(s), 'target' or {'target', 'focus', ...}, UnitDebuff or UnitBuff or UnitAura, bool AuraCaster = player)
local function HasAura(aura, last, target, method, my)
    if aura == nil then return false end
    if method == nil then method = UnitAura end
    if target == nil then target = "player" end
    if last == nil then last = 0.1 end
    if (type(target) == 'table') then 
        return TryEach(target, function(t) return HasAura(aura, last, t, method, my) end)
    end
    if (type(aura) == 'table') then
        return TryEach(aura, function(a) return HasAura(a, last, target, method, my) end)
    end
    if not UnitExists(target) then return false end
    local i = 0
    local name, _, _, _, debuffType, _, Expires, unitCaster  = method(target, i)
    local result = false
    while (i <= 40) and not result do
        if name and (strlower(name):match(strlower(aura)) or (debuffType and strlower(debuffType):match(strlower(aura)) )) 
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
-- Устарело
function FindAura(aura, target)
    return HasAura(aura, 1, target)
end

------------------------------------------------------------------------------------------------------------------
-- Enchants helper
local function GetUtilityTooltips()
    if ( not RH_Tooltip1 ) then
        for idxTip = 1,2 do
            local ttname = "RH_Tooltip"..idxTip
            local tt = CreateFrame("GameTooltip", ttname)
            tt:SetOwner(UIParent, "ANCHOR_NONE")
            tt.left = {}
            tt.right = {}
            -- Most of the tooltip lines share the same text widget,
            -- But we need to query the third one for cooldown info
            for i = 1, 30 do
                tt.left[i] = tt:CreateFontString()
                tt.left[i]:SetFontObject(GameFontNormal)
                if i < 5 then
                    tt.right[i] = tt:CreateFontString()
                    tt.right[i]:SetFontObject(GameFontNormal)
                    tt:AddFontStrings(tt.left[i], tt.right[i])
                else
                    tt:AddFontStrings(tt.left[i], tt.right[4])
                end
            end 
         end
    end
    local tt1,tt2 = RH_Tooltip1, RH_Tooltip2
    
    tt1:ClearLines()
    tt2:ClearLines()
    return tt1,tt2
end

------------------------------------------------------------------------------------------------------------------
--~ using: TempEnchantName = DetermineTempEnchantFromTooltip(16 or 17)
function DetermineTempEnchantFromTooltip(i_invID)
    local tt1,tt2 = GetUtilityTooltips()
    
    tt1:SetInventoryItem("player", i_invID)
    local n,h = tt1:GetItem()

    tt2:SetHyperlink(h)
    
    -- Look for green lines present in tt1 that are missing from tt2
    local nLines1, nLines2 = tt1:NumLines(), tt2:NumLines()
    local i1, i2 = 1,1
    while ( i1 <= nLines1 ) do
        local txt1 = tt1.left[i1]
        if ( txt1:GetTextColor() ~= 0 ) then
            i1 = i1 + 1
        elseif ( i2 <= nLines2 ) then
            local txt2 = tt2.left[i2]
            if ( txt2:GetTextColor() ~= 0 ) then
                i2 = i2 + 1
            elseif (txt1:GetText() == txt2:GetText()) then
                i1 = i1 + 1
                i2 = i2 + 1
            else
                break
            end
        else
            break
        end
    end
    if ( i1 <= nLines1 ) then
        local line = tt1.left[i1]:GetText()
        local paren = line:find("[(]")
        if ( paren ) then
            line = line:sub(1,paren-2)
        end
        return line
    end    
end
