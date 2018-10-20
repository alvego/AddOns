-- Rotation Helper Library by Alex Tim
------------------------------------------------------------------------------------------------------------------
local GetTime = GetTime
------------------------------------------------------------------------------------------------------------------
function Runes(slot, time)
    local c = 0
    if slot == 1 then
       if IsRuneReady(1, time) then c = c + 1 end
       if IsRuneReady(2, time) then c = c + 1 end
    elseif slot == 2 then
        if IsRuneReady(5, time) then c = c + 1 end
        if IsRuneReady(6, time) then c = c + 1 end
    elseif slot == 3 then
        if IsRuneReady(3, time) then c = c + 1 end
        if IsRuneReady(4, time) then c = c + 1 end
    end
    return c;
end

------------------------------------------------------------------------------------------------------------------
function NoRunes(t)
    if (t == nil) then t = GCDDuration end
    if GetRuneCooldownLeft(1) < t then return false end
    if GetRuneCooldownLeft(2) < t then return false end
    if GetRuneCooldownLeft(3) < t then return false end
    if GetRuneCooldownLeft(4) < t then return false end
    if GetRuneCooldownLeft(5) < t then return false end
    if GetRuneCooldownLeft(6) < t then return false end
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
RuneDuration = 8
function GetRuneCooldownLeft(id)
    local start, duration = GetRuneCooldown(id);
    if not start then return 0 end
    if start == 0 then return 0 end
    if duration then RuneDuration = duration end
    local left = start + duration - GetTime()
    if left < 0 then left = 0 end
    return left
end
