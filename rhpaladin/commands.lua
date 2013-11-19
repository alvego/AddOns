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
if not InGCD() and not IsReadySpell("Покаяние") then return true end
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
if (not InGCD() and not IsReadySpell("Молот правосудия")) or not CanControl() or HasBuff("Незыблемость льда", 0.1 , "target") then return true end
return false 
end
)

------------------------------------------------------------------------------------------------------------------
SetCommand("sv", 
   function() 
      print("Боб на Омника!")
      --RunMacroText("/target Ириха")
      RunMacroText("/cast [@Омниссия] Длань защиты")
      --RunMacroText("/targetlasttarget")
   end, 
   function() return HasBuff("Длань защиты", 1, "Ириха") end
)

------------------------------------------------------------------------------------------------------------------
SetCommand("svs", 
   function()
      RunMacroText("/targetexact вороная горгулья")
      DoSpell("Изгнание зла","target")
      RunMacroText("/targetlasttarget")
   end, 
   function() return not IsReadySpell("Изгнание зла") end
)

------------------------------------------------------------------------------------------------------------------
SetCommand("def", 
   function() return DoSpell("Священная жертва") end, 
   function() return HasBuff("Священная жертва", 1) end
)

------------------------------------------------------------------------------------------------------------------
SetCommand("hp", 
   function() return DoSpell("Печать Света") end, 
   function() return not InGCD() and HasBuff("Печать Света") end
)

------------------------------------------------------------------------------------------------------------------
SetCommand("dd", 
   function() return DoSpell("Печать праведности") end, 
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