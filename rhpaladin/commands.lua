-- Paladin Rotation Helper by Alex Tim & Co
------------------------------------------------------------------------------------------------------------------
teammate = "Qo"
shieldUnit = "player"
------------------------------------------------------------------------------------------------------------------
SetCommand("switch",
    nil,
    nil,
    function()
      if shieldUnit == "player" then
        if InInteractRange(teammate) then
          shieldUnit = teammate
        end
      else
        shieldUnit = "player"
      end
      local name = UnitName(shieldUnit)
      Notify(name)
      chat(name)
      return true
    end
)
------------------------------------------------------------------------------------------------------------------

SetCommand("fear",
    function() --Apply true if done
        UpdateObjects()
        local target = nil --Вороная горгулья
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
    if not UnitCanAttack("player", teammate) and InInteractRange(teammate) then
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
    if not UnitCanAttack("player", teammate) and InInteractRange(teammate) then
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
  nil,
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
  nil,
  function()
    local target = IsAlt() and "focus" or "target"
    if not CanControl(target) then
       chat("stun: " .. CanControlInfo)
       return true
    end
    DoCommand("spell", "Молот правосудия", target)
    return true
  end
)
------------------------------------------------------------------------------------------------------------------
SetCommand("bop",
  function()
    if not UnitCanAttack("player", teammate) and InInteractRange(teammate) then
      UseSpell("Длань защиты", teammate)
    end
  end,
  function()
    if not InGCD() and not IsReadySpell("Длань защиты") then return true end
    return false
  end
)
------------------------------------------------------------------------------------------------------------------
SetCommand("shield",
  nil,
  function()
    local target = IsAlt() and teammate or "player"
    if not InInteractRange(target) then
       chat("free: !InInteractRange")
       return true
    end
    DoCommand("spell", "Священный щит", target)
    return true
  end
)
------------------------------------------------------------------------------------------------------------------
SetCommand("aignore",
  nil,
  function()
    if IsAlt() then
      wipe(AggroIgnored)
      chat("wipe AggroIgnored")
      return true
    end
    local name = UnitName("target")
    if not name then
      chat("target not exists")
      return true
    end
    if AggroIgnored[name] then
      AggroIgnored[name] = nil
      chat(name .. " remove from AggroIgnored")
    else
      AggroIgnored[name] = true;
      chat(name .. " add to AggroIgnored")
    end
    return true
  end
)
------------------------------------------------------------------------------------------------------------------
