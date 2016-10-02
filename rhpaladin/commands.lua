-- Paladin Rotation Helper by Timofeev Alexey & Co
------------------------------------------------------------------------------------------------------------------
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
----------------------------------------------------------------------------------------------------------------
