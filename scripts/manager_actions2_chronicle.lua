-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

-- ===================================================================================================================
-- Process modifiers added on the desktop via buttons
-- ===================================================================================================================
function encodeDesktopMods(rRoll)
	-- Debug.chat("FN: encodeDesktopMods in manager_action2")
	local aAddDesc = {}
	local nAddTest = 0
	local nAddBonus = 0
	local nAddPenalty = 0

	-- Process Test dice modifiers
	if ModifierManager.getKey("PLUS1") then
		nAddTest = nAddTest + 1
	end

	if ModifierManager.getKey("PLUS2") then
		nAddTest = nAddTest + 2
	end

	if ModifierManager.getKey("PLUS4") then
		nAddTest = nAddTest + 4
	end

	-- If Test dice are selected, process them
	if nAddTest > 0 then
		rRoll.nTest = rRoll.nTest + nAddTest
		table.insert(aAddDesc, "[+" .. nAddTest .. "D] ")
		for i = 1, nAddTest do
			table.insert(rRoll.aDice, {type = "d6"})
		end
	end

	-- Process Bonus dice modifiers
	if ModifierManager.getKey("BONUS1") then
		nAddBonus = nAddBonus + 1
	end

	if ModifierManager.getKey("BONUS2") then
		nAddBonus = nAddBonus + 2
	end

	if ModifierManager.getKey("BONUS4") then
		nAddBonus = nAddBonus + 4
	end

	-- If Bonus dice are selected, process them
	if nAddBonus > 0 then
		rRoll.nBonus = rRoll.nBonus + nAddBonus
		table.insert(aAddDesc, "[+" .. nAddBonus .. "B] ")
		for i = 1, nAddBonus do
			table.insert(rRoll.aDice, {type = "d6"})
		end

	end

	-- Process Penalty dice modifiers
	if ModifierManager.getKey("MINUS1") then
		nAddPenalty = nAddPenalty + 1
	end

	if ModifierManager.getKey("MINUS2") then
		nAddPenalty = nAddPenalty + 2
	end

	if ModifierManager.getKey("MINUS4") then
		nAddPenalty = nAddPenalty + 4
	end

	-- If Penalty dice are selected, process them
	if nAddPenalty > 0 then
		rRoll.nPenalty = rRoll.nPenalty + nAddPenalty
		table.insert(aAddDesc, "[-" .. nAddPenalty .. "P] ")
	end

	-- Concatenate description strings and add to rRoll.sDesc
	if #aAddDesc > 0 then
		rRoll.sDesc = rRoll.sDesc .. "\n" .. table.concat(aAddDesc)
	end
end

-- ===================================================================================================================
-- Process modifiers resulting from wounds, injuries or fatigue
-- ===================================================================================================================
function encodeHealthMods(rActor, rRoll)
	local aAddDesc = {}

	-- Failsafe
	if not rActor then
		return
	end

	-- Consider Wounds
	local nTrauma = ActorManager5E.getHealthTrauma(rActor)
	if nTrauma > 0 then
		rRoll.nPenalty = rRoll.nPenalty + nTrauma
		table.insert(aAddDesc, "[Wounded -" .. nTrauma .. "P] ")
	end

	-- Consider Injuries
	local nInjuries = ActorManager5E.getHealthInjuries(rActor)
	if nInjuries > 0 then
		rRoll.nMod = rRoll.nMod - nInjuries
		table.insert(aAddDesc, "[Injuried -" .. nInjuries .. "] ")
	end

	-- Consider Fatigue
	local nFatigue = ActorManager5E.getHealthFatigue(rActor)
	if nFatigue > 0 then
		rRoll.nMod = rRoll.nMod - nFatigue
		table.insert(aAddDesc, "[Fatigued -" .. nFatigue .. "] ")
	end

	-- Concatenate description strings and add to rRoll.sDesc
	if #aAddDesc > 0 then
		rRoll.sDesc = rRoll.sDesc .. "\n" .. table.concat(aAddDesc)
	end
end

-- ===================================================================================================================
-- Process modifiers resulting from armor
-- ===================================================================================================================
function encodeArmorMods(rRoll)
	local aAddDesc = {}

	if StringManager.contains({ "agility" }, rRoll.sStat) then
		-- Process Armor Penalty
		if rRoll.nAP > 0 then
			rRoll.nMod = rRoll.nMod - rRoll.nAP
			table.insert(aAddDesc, "[Armor Penalty -" .. rRoll.nAP .. "] ")
		end

		-- Concatenate description strings and add to rRoll.sDesc
		if #aAddDesc > 0 then
			rRoll.sDesc = rRoll.sDesc .. "\n" .. table.concat(aAddDesc)
		end
	end
end

-- ===================================================================================================================
-- Convert input to lower case and removing all spaces from the string
-- ===================================================================================================================
function ConvertToTechnical(sInput)
	local sOutput = sInput:gsub("%s+", ""):lower()
	return sOutput
end