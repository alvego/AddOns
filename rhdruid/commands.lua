-- Druid Rotation Helper by Timofeev Alexey
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
local tryMount = false
SetCommand("mount", 
    function() 
        if InGCD() or IsPlayerCasting() then return end

        if IsControlKeyDown() then
                
            if HasBuff("Облик кошки") and HasBuff("Крадущийся зверь") then
                RunMacroText("/cancelaura Крадущийся зверь")
                tryMount = true
                return
            end
            
            if not InCombatLockdown() and GetShapeshiftForm() ~= 0 and not (IsFalling() or IsSwimming()) then 
                RunMacroText("/cancelform") 
                tryMount = true
                return
            end
                       
            return
        end
        
        if InCombatLockdown() or IsArena() or IsAttack() or IsIndoors() or (IsFalling() and not IsFlyableArea() and not HasBuff("Облик кошки")) then 
            DoSpell("Облик кошки")
            tryMount = true
            return 
        end
           
        if InCombatLockdown() and not (IsFalling() and not IsFlyableArea()) and HasBuff("Облик кошки") then 
            DoSpell("Облик лютого медведя")
            tryMount = true
            return 
        end
           
        if InCombatLockdown() or not IsOutdoors() then return end
        local mount = "Огромный белый кодо"--"Стремительный белый рысак"
        if IsAltKeyDown() then mount = "Тундровый мамонт путешественника" end
        if not PlayerInPlace() then mount = "Походный облик" end
        if IsFlyableArea() and (not IsLeftControlKeyDown() or IsFalling()) then mount = "Облик стремительной птицы" end
        if IsSwimming() then mount = "Водный облик" end
        if UseMount(mount) then tryMount = true return end
        
    end, 
    function() 
        if tryMount then
            tryMount = false
            return true
        end
        return false 
    end
)
 
------------------------------------------------------------------------------------------------------------------
 SetCommand("starfall", 
   function() return DoSpell("Звездопад") end, 
   function() return not InGCD() and not IsReadySpell("Звездопад") end
)
