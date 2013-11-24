-- Paladin Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
local freedomItem
local freedomSpell = "Каждый за себя"
SetCommand("freedom", 
   function() 
       if HasSpell(freedomSpell) then
           DoSpell(freedomSpell)
           return
       end
       UseEquippedItem(freedomItem) 
   end, 
   function() 
       if IsPlayerCasting() then return true end
       if HasSpell(freedomSpell) and (not InGCD() and not IsReadySpell(freedomSpell)) then return true end
       if freedomItem == nil then
          freedomItem = (UnitFactionGroup("player") == "Horde" and "Медальон Орды" or "Медальон Альянса")
       end
       return not IsEquippedItem(freedomItem) or (not InGCD() and not IsReadyItem(freedomItem)) 
   end
)

------------------------------------------------------------------------------------------------------------------
SetCommand("vp", 
   function() return DoSpell("Волшебный поток") end, 
   function() return not InGCD() and not IsReadySpell("Волшебный поток") end
)

------------------------------------------------------------------------------------------------------------------
SetCommand("free", 
  function(target) 
    UseSpell("Длань свободы", target)
  end, 
  function(target) 
    if not InGCD() and not IsReadySpell("Длань свободы") then return true end
    return false 
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
  function(target) 
    UseSpell("Молот правосудия", target)
  end, 
  function(target) 
    if target == nil then target = "target" end
    if (not InGCD() and not IsReadySpell("Молот правосудия")) or not CanControl(target) or HasBuff("Незыблемость льда", 0.1 , target) then return true end
    return false 
  end
)

------------------------------------------------------------------------------------------------------------------
-- /run DoCommand("sv", "Омниссия")
SetCommand("sv", 
   function(target) 
      if target == nil then target = "target" end
      print("Боп на " .. target .. "!")
      RunMacroText("/cast [@".. target .."] Длань защиты")
   end, 
   function(target) 
      if target == nil then target = "target" end
      return (not InGCD() and not IsReadySpell("Длань защиты")) or HasBuff("Длань защиты", 1, target) 
   end
)

------------------------------------------------------------------------------------------------------------------
SetCommand("svs", 
   function()
      if UnitExists("focus") and UnitName("focus") == "Вороная горгулья" then
         DoSpell("Изгнание зла","focus") end
      else
         RunMacroText("/targetexact [harm,nodead] Вороная горгулья")
         if UnitExists("target") and UnitName("target") == "Вороная горгулья" then RunMacroText("/focus target") end
         RunMacroText("/targetlasttarget")
      else
   end, 
   function() 
      if not IsReadySpell("Изгнание зла") then
         if UnitExists("focus") and UnitName("focus") == "Вороная горгулья" then RunMacroText("/clearfocus") end
         return true
      end
      return false
   end
)

------------------------------------------------------------------------------------------------------------------
SetCommand("fg", 
   function()
      if UnitExists("focus") and UnitName("focus") == "Вороная горгулья" then
         DoSpell("Очищение","focus") end
      else
         RunMacroText("/targetexact [help,nodead] Вороная горгулья")
         if UnitExists("target") and UnitName("target") == "Вороная горгулья" then RunMacroText("/focus target") end
         RunMacroText("/targetlasttarget")
      else
   end, 
   function() 
      if not IsSpellInUse("Очищение", 1) then
         if UnitExists("focus") and UnitName("focus") == "Вороная горгулья" then RunMacroText("/clearfocus") end
         return true
      end
      return false
   end
)
------------------------------------------------------------------------------------------------------------------
SetCommand("def", 
   function() DoSpell("Священная жертва") end, 
   function() return HasBuff("Священная жертва") end
)

------------------------------------------------------------------------------------------------------------------
SetCommand("hp", 
   function() DoSpell("Печать Света") end, 
   function() return not InGCD() and HasBuff("Печать Света") end
)

------------------------------------------------------------------------------------------------------------------
SetCommand("dd", 
   function() DoSpell("Печать праведности") end, 
   function() return not InGCD() and HasBuff("Печать праведности") end
)

------------------------------------------------------------------------------------------------------------------
SetCommand("cl", 
   function() end, 
   function() return not InGCD() and DoSpell("Очищение","Омниссия") end
)

------------------------------------------------------------------------------------------------------------------
SetCommand("ff", 
   function() return DoSpell("Изгнание зла","mouseover") end,
   function() return not IsReadySpell("Изгнание зла") end
)

------------------------------------------------------------------------------------------------------------------
SetCommand("salva", 
   function() return DoSpell("Длань спасения","mouseover") end, 
   function() return not InGCD() and not IsReadySpell("Длань спасения") end
)