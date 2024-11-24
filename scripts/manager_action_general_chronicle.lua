-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

function onInit()
	ActionsManager.registerModHandler("dice", modRoll);
	ActionsManager.registerResultHandler("dice", onRoll);
end

-- Adjusted
function modRoll(rSource, rTarget, rRoll)
	rRoll.rActor = rSource
	rRoll.nTest = #rRoll.aDice
	rRoll.nBonus = 0
	rRoll.nPenalty = 0

	-- Get Desktop modifications
	ActionsManager2.encodeDesktopMods(rRoll);
	
	-- if #(rRoll.aDice) == 1 and rRoll.aDice[1].type == "d20" then
		-- ActionsManager2.encodeAdvantage(rRoll);
	-- end

	-- Set maximum Bonus and Penalty Dice
	rRoll = ActionResult.capDice(rRoll);
end

-- Adjusted
function onRoll(rSource, rTarget, rRoll)
	ActionsManager2.decodeAdvantage(rRoll);

	-- Drop dice and process rRoll if Bonus or Penalty Dice have been part of the roll
	rRoll = ActionResult.DropDice(rRoll)

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	Comm.deliverChatMessage(rMessage);
end