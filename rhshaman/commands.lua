-- Shaman Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
SetCommand("hero",

    function()
        local heroSpell = HasSpell("Героизм") and "Героизм" or "Жажда крови"
        return DoSpell(heroSpell)
    end,
    function()
        local heroSpell = HasSpell("Героизм") and "Героизм" or "Жажда крови"
        return not InGCD() and not IsReadySpell(heroSpell)
    end
)
