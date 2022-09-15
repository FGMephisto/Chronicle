-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

-- ===================================================================================================================
-- ===================================================================================================================
function capDice(rRoll)
	-- Debug.chat("FN: alignDice in manager_action_result")
	rRoll.nTest = tonumber(rRoll.nTest)
	rRoll.nBonus = tonumber(rRoll.nBonus)
	rRoll.nPenalty = tonumber(rRoll.nPenalty)
	local nTotalDice = #rRoll.aDice

	-- Set minimum number of Test Die
	if rRoll.nTest < 0 then
		rRoll.nTest = 0
	end

	-- Determine # of dice added by user with drag-and-right-click
	local nTotalDice = #rRoll.aDice

	-- Add # of dice added by user with drag-and-right-click to bonus die
	if nTotalDice > rRoll.nTest + rRoll.nBonus then
		rRoll.nBonus = nTotalDice - rRoll.nTest
	end

	-- Cap maximum number of Bonus Die
	if rRoll.nBonus > rRoll.nTest then
		rRoll.nBonus = rRoll.nTest
	end

	-- Cap maximum number of Penalty Die
	if rRoll.nPenalty > rRoll.nTest then
		rRoll.nPenalty = rRoll.nTest
	end

	-- Reset nMod if no Test dice are left for roll
	if rRoll.nPenalty == rRoll.nTest then
		rRoll.nMod = 0
	end	

	-- Rebuild aDice with Test and Bonus dice
	rRoll.aDice = {}
	for i = 1, rRoll.nTest + rRoll.nBonus do
		table.insert(rRoll.aDice, {type = "d6"})
	end

	return rRoll
end

-- ===================================================================================================================
-- ===================================================================================================================
function DropDice(rRoll)
	-- Debug.chat("FN: DropDice in manager_action_result")
	rRoll.nBonus = tonumber(rRoll.nBonus)
	rRoll.nPenalty = tonumber(rRoll.nPenalty)
	local nDiceDrop = rRoll.nBonus + rRoll.nPenalty
	local nDiceProcessed = 0

	-- Drop dice and process rRoll if Bonus or Penalty Dice have been part of the roll
	if nDiceDrop > 0 then
		-- Run through dice values from 1 to 6
		for i = 1, 6, 1 do
			-- Check on all rolled dice
			for _, v in ipairs(rRoll.aDice) do
				-- Check for dice value and if there are still dice to be dropped
				if v.result == i and nDiceProcessed < nDiceDrop then
					v.backcolor = "#80808080"
					v.iconcolor = "#80FFFFFF"
					v.icon = "d6gicon"
					v.dropped = true
					nDiceProcessed = nDiceProcessed + 1
					
					-- Mark dice dropped in excess of all Bonus die as Penalty die
					if nDiceProcessed > rRoll.nBonus then
						v.icon = "d6ricon"
					end
				end
				-- End loop if all dice to-be-dropped were dropped
				if nDiceProcessed == nDiceDrop then
					break
				end
			end
			-- End loop if all dice to-be-dropped were dropped
			if nDiceProcessed == nDiceDrop then
				break
			end
		end
	end

	-- Determine and set roll total
	rRoll.nTotal = ActionsManager.total(rRoll)
	rRoll.aDice.Total = tostring(rRoll.nTotal)

	return rRoll
end

-- ===================================================================================================================
-- Determine degrees of success
-- ===================================================================================================================
function DetermineSuccessTest(rMessage, rRoll)
	-- Debug.chat("FN: DetermineSuccessTest in manager_action_result")
	local nTarget = tonumber(rRoll.nTarget) or 0
	local nTotal = ActionsManager.total(rRoll)

	rMessage.text = rMessage.text .. " (vs. " .. Interface.getString("dc_long") .. " " .. nTarget .. ")"

	if nTotal >= nTarget then
		if nTotal >= nTarget +15 then
			rMessage.text = rMessage.text .. " [" .. Interface.getString("success_test_degree_4") .. "]"
			rRoll.nDoS = 4
		elseif nTotal >= nTarget +10 then
			rMessage.text = rMessage.text .. " [" .. Interface.getString("success_test_degree_3") .. "]"
			rRoll.nDoS = 3
		elseif nTotal >= nTarget +5 then
			rMessage.text = rMessage.text .. " [" .. Interface.getString("success_test_degree_2") .. "]"
			rRoll.nDoS = 2
		elseif nTotal >= nTarget then
			rMessage.text = rMessage.text .. " [" .. Interface.getString("success_test_degree_1") .. "]"
			rRoll.nDoS = 1
		end
	else
		if nTotal < nTarget -4 then
			rMessage.text = rMessage.text .. " [" .. Interface.getString("failure_test_degree_2") .. "]"
			rRoll.nDoS = 1
		elseif nTotal < nTarget then
			rMessage.text = rMessage.text .. " [" .. Interface.getString("failure_test_degree_1") .. "]"
			rRoll.nDoS = 1
		end
	end

	return rMessage, rRoll
end

-- ===================================================================================================================
-- Determine degrees of attack
-- ===================================================================================================================
function DetermineSuccessAttack(rMessage, rRoll)
	-- Debug.chat("FN: DetermineSuccessAttack in manager_action_result")
	local nTarget = tonumber(rRoll.nDefenseVal) or 0
	local nTotal = ActionsManager.total(rRoll)

	rMessage.text = rMessage.text .. " (vs. " .. Interface.getString("dc_long") .. " " .. nTarget .. ")"

	-- ToDo: Make table.insert work with Interface.getString
	-- Why use table.insert?
	if nTotal >= nTarget then
		if nTotal >= nTarget +15 then
			-- rMessage.text = rMessage.text .. " [" .. Interface.getString("success_attack_degree_4") .. "]"
			-- table.insert(rRoll.aMessages, " [" .. Interface.getString("success_attack_degree_4") .. "]"")
			table.insert(rRoll.aMessages, "[HIT (4 Degrees)]")
			rRoll.sResult = "hit"
			rRoll.nDoS = 4
		elseif nTotal >= nTarget +10 then
			-- rMessage.text = rMessage.text .. " [" .. Interface.getString("success_attack_degree_3") .. "]"
			-- table.insert(rRoll.aMessages, " [" .. Interface.getString("success_attack_degree_4") .. "]")
			table.insert(rRoll.aMessages, "[HIT (3 Degrees)]")
			rRoll.sResult = "hit"
			rRoll.nDoS = 3
		elseif nTotal >= nTarget +5 then
			-- rMessage.text = rMessage.text .. " [" .. Interface.getString("success_attack_degree_2") .. "]"
			-- table.insert(rRoll.aMessages, " [" .. Interface.getString("success_attack_degree_4") .. "]")
			table.insert(rRoll.aMessages, "[HIT (2 Degrees)]")
			rRoll.sResult = "hit"
			rRoll.nDoS = 2
		elseif nTotal >= nTarget then
			-- rMessage.text = rMessage.text .. " [" .. Interface.getString("success_attack_degree_1") .. "]"
			-- table.insert(rRoll.aMessages, " [" .. Interface.getString("success_attack_degree_4") .. "]")
			table.insert(rRoll.aMessages, "[HIT (1 Degrees)]")
			rRoll.sResult = "hit"
			rRoll.nDoS = 1
		end
	else
		if nTotal < nTarget -4 then
			-- rMessage.text = rMessage.text .. " [" .. Interface.getString("failure_attack_degree_2") .. "]"
			-- table.insert(rRoll.aMessages, " [" .. Interface.getString("failure_attack_degree_2") .. "]")
			table.insert(rRoll.aMessages, "[Miss]")
			rRoll.sResult = "miss"
			rRoll.nDoS = 1
		elseif nTotal < nTarget then
			-- rMessage.text = rMessage.text .. " [" .. Interface.getString("failure_attack_degree_1") .. "]"
			-- table.insert(rRoll.aMessages, " [" .. Interface.getString("failure_attack_degree_1") .. "]")
			table.insert(rRoll.aMessages, "[Miss]")
			rRoll.sResult = "miss"
			rRoll.nDoS = 1
		end
	end

	return rMessage, rRoll
end