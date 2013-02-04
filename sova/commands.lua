-- Sova Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
SetCommand("starfall", 
   function() return DoSpell("Звездопад") end, 
   function() return not InGCD() and not IsReadySpell("Звездопад") end
)
