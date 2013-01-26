-- Sova Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
SetCommand("free", 
   function() return DoSpell("Длань свободы") end, 
   function() return HasBuff("Длань свободы") 
      or (not InGCD() and not IsReadySpell("Длань свободы")) end
)

------------------------------------------------------------------------------------------------------------------
SetCommand("freedom", 
   function() return DoSpell("Каждый за себя") end, 
   function() return not InGCD() and not IsReadySpell("Каждый за себя") end
)

------------------------------------------------------------------------------------------------------------------
SetCommand("repentance", 
   function() return DoSpell("Покаяние") end, 
   function() return (not InGCD() and not IsReadySpell("Покаяние")) or not CanControl() end
)

------------------------------------------------------------------------------------------------------------------
SetCommand("stun", 
   function() return DoSpell("Молот правосудия") end, 
   function() return (not InGCD() and not IsReadySpell("Молот правосудия")) 
      or not CanControl() and not HasBuff("Незыблемость льда", 0.1 , "target") end
)

------------------------------------------------------------------------------------------------------------------
SetCommand("frepentance", 
   function() return DoSpell("Покаяние","focus") end, 
   function() return (not InGCD() and not IsReadySpell("Покаяние")) or not CanControl("focus") end
)

------------------------------------------------------------------------------------------------------------------
SetCommand("fstun", 
   function() return DoSpell("Молот правосудия","focus") end, 
   function() return (not InGCD() and not IsReadySpell("Молот правосудия")) 
      or not CanControl("focus") and not HasBuff("Незыблемость льда", 0.1, "focus") end
)

------------------------------------------------------------------------------------------------------------------
SetCommand("sv", 
   function() return DoSpell("Длань защиты","Ириха") end, 
   function() return not InForbearance("Ириха") and not InGCD() and not IsReadySpell("Длань защиты") end
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
   function() return not InGCD() and DoSpell("Очищение","Ириха") end
)
