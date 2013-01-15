-- Shaman Rotation Helper by Timofeev Alexey
------------------------------------------------------------------------------------------------------------------
SetCommand("hero", 
    function() 
        if DoSpell("Героизм") then
            echo("Гера!",1)
        end
    end, 
    function() 
        return not InCombatLockdown() or HasDebuff("Изнеможение", 1, "player") or not IsSpellNotUsed("Героизм", 1) 
    end
)

------------------------------------------------------------------------------------------------------------------
SetCommand("frostshock", 
    function() 
        if DoSpell("Ледяной шок", "target") then
            echo("Ледяной шок!", 1)
        end
    end, 
    function() 
        return not InCombatLockdown() or not CanControl("target") or HasDebuff("Ледяной шок", 0,1, "target") or not IsSpellNotUsed("Ледяной шок", 1) 
    end
)

------------------------------------------------------------------------------------------------------------------
SetCommand("wolf", 
    function() 
        if DoSpell("Дух дикого волка") then
            echo("Волки!", 1)
        end
    end, 
    function() 
        return not CanControl("target") or not IsSpellNotUsed("Дух дикого волка", 1) 
    end
)

------------------------------------------------------------------------------------------------------------------
SetCommand("root", 
    function() 
        echo("Root!",1)
        return TryTotems()
    end, 
    function() 
        if ForceRoot then
            if HasTotem("Тотем оков земли") then
                ForceRoot = false
                return true
            end
        else
            ForceRoot = true
        end
        return false  
    end
)

------------------------------------------------------------------------------------------------------------------
SetCommand("hex", 
    function() 
--[[        if HasSpell("Природная стремительность") then 
            DoSpell("Природная стремительность") 
        end]]
        echo("Сглаз",1)
        return DoSpell("Сглаз", "target")
    end, 
    function() 
        if not CanControl("target") or not IsSpellNotUsed("Сглаз", 1)  then return true end
        if not UnitIsPlayer("target") then
            local creatureType = UnitCreatureType("target")
            if creatureType ~= "Гуманоид" or creatureType ~= "Животное" then return true end
        end
        return false
    end
)
------------------------------------------------------------------------------------------------------------------
SetCommand("freedom", 
    function() return UseEquippedItem("Медальон Альянса") end, 
    function() local item = "Медальон Альянса" return IsPlayerCasting() or not IsEquippedItem(item) or (not InGCD() and not IsReadyItem(item)) end
)

------------------------------------------------------------------------------------------------------------------
local tryMount = false
SetCommand("mount", 
    function() 
        if (IsLeftControlKeyDown() or IsSwimming()) and not HasBuff("Хождение по воде", 1, "player") and DoSpell("Хождение по воде", "player") then return end
        if InCombatLockdown() or IsArena() or not PlayerInPlace() then
            return DoSpell("Призрачный волк") 
        end
        if InGCD() or IsPlayerCasting() or InCombatLockdown() or not IsOutdoors() then return false end
        local mount = "Стремительный белый рысак"
        if IsFlyableArea() and not IsLeftControlKeyDown() then mount = "Черный дракон" end
        if IsAltKeyDown() then mount = "Тундровый мамонт путешественника" end
        if UseMount(mount) then tryMount = true return end
    end, 
    function() 
        if (HasBuff("Призрачный волк") or IsMounted() or CanExitVehicle()) then return true end
        if tryMount then
            tryMount = false
            return true
        end
        return false 
    end
)

------------------------------------------------------------------------------------------------------------------
SetCommand("dismount", 
    function() 
        if HasBuff("Призрачный волк") then RunMacroText("/cancelaura Призрачный волк") return end
        if CanExitVehicle() then VehicleExit() return end
        if IsMounted() then Dismount() return end 
    end, 
    function() 
        return not (HasBuff("Призрачный волк") or IsMounted() or CanExitVehicle())
    end
)

------------------------------------------------------------------------------------------------------------------
SetCommand("totems", 
    function() 
        echo("Тотемы!",1)
        return TryTotems(true)
    end, 
    function() 
        if InCombatLockdown() and not NeedTotems then 
            NeedTotems = true
            return true
        end
        if GetTime() - TotemTime < 1  then
            return true
        end
        return false
    end
)

SetCommand("untotems", 
    function() 
        echo("Убрать Тотемы!",1)
        return DoSpell("Возвращение тотемов")
    end, 
    function() 
        if NeedTotems then
            NeedTotems = false
        end
        return TotemCount() < 1 or not IsSpellNotUsed("Возвращение тотемов", 1)
    end
)
