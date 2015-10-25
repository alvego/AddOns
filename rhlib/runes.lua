-- Rotation Helper Library by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
function Runes(slot)
    if slot == 2 then slot = 5 end
    local c = 0
    if IsRuneReady(slot) then c = c + 1 end
    if IsRuneReady(slot + 1) then c = c + 1 end
    return c;
end

------------------------------------------------------------------------------------------------------------------
function NoRunes(t)
    if (t == nil) then t = 1.6 end
    for i=1,6 do
        if GetRuneCooldownLeft(i) < t then return false end    
    end
    return true
end

------------------------------------------------------------------------------------------------------------------
function IsRuneReady(id, time)
    if nil == time then time = 0 end
    local left = GetRuneCooldownLeft(id)
    if left - time > LagTime then return false end
    return true
end

------------------------------------------------------------------------------------------------------------------
function GetRuneCooldownLeft(id)
    local start, duration = GetRuneCooldown(id);
    if not start then return 0 end
    if start == 0 then return 0 end
    local left = start + duration - GetTime()
    if left < 0 then left = 0 end
    return left
end

