-- Paladin Rotation Helper by Alex Tim & Co
------------------------------------------------------------------------------------------------------------------
teammate = "Qo"

SetCommand("fear",
    function() --Apply true if done
        local target = nil --Вороная горгулья
        UpdateObjects()
        for i = 1, #TARGETS do
          local t = TARGETS[i]
          if IsValidTarget(t) then
             local ctype = UnitCreatureType(t)
             if ctype =="Нежить" or ctype == "Демон" then
                target = t
                if UnitName(t) == "Вороная горгулья" then  break end
             end
           end
         end
        if target and DoSpell("Изгнание зла", target) then
            return true
        end
    end,
    function() --check true if done or not can
        if not IsReadySpell("Изгнание зла") then return true end
        return false
    end
)
------------------------------------------------------------------------------------------------------------------
SetCommand("Lay",
  function()
    if not UnitCanAttack("player", teammate) and IsInteractUnit(teammate) then
      UseSpell("Возложение рук", teammate)
    end
  end,
  function()
    if not InGCD() and not IsReadySpell("Возложение рук") then return true end
    return false
  end
)
------------------------------------------------------------------------------------------------------------------
SetCommand("sacra",
  function()
    if not UnitCanAttack("player", teammate) and IsInteractUnit(teammate) then
      UseSpell("Длань жертвенности", teammate)
    end
  end,
  function()
    if not InGCD() and not IsReadySpell("Длань жертвенности") then return true end
    return false
  end
)
------------------------------------------------------------------------------------------------------------------
SetCommand("free",
  function() return true end,
  function()
    local target = IsAlt() and teammate or "player"
    if not InInteractRange(target) then
       chat("free: !InInteractRange")
       return true
    end
    DoCommand("spell", "Длань свободы", target)
    return true
  end
)
------------------------------------------------------------------------------------------------------------------
SetCommand("repentance",
  function(target)
    UseSpell("Покаяние", target)
  end,
  function(target)
    if target == nil then target = "target" end
    if (not InGCD() and not IsReadySpell("Покаяние")) or not CanMagicAttack(target) or HasDebuff(ControlList, 3, target) then return true end
    return false
  end
)

------------------------------------------------------------------------------------------------------------------
SetCommand("stun",
  function() return true end,
  function()
    local target = IsAlt() and "focus" or "player"
    if not CanControl(target) then
       chat("stun: " .. CanControlInfo)
       return true
    end
    DoCommand("spell", "Молот правосудия", target)
    return true
  end
)
------------------------------------------------------------------------------------------------------------------
