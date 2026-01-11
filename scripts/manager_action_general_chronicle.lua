-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

function onInit()
	ActionsManager.registerModHandler("dice", ActionGeneral.modRoll);
	ActionsManager.registerResultHandler("dice", ActionGeneral.onRoll);
end

function modRoll(rSource, rTarget, rRoll) -- Adjusted
	-- Debug.chat("FN: modRoll in manager_action_general")
	rRoll.rActor = rSource
	rRoll.nTest = #rRoll.aDice
	rRoll.nBonus = 0
	rRoll.nPenalty = 0

	-- Get Desktop modifications
	ActionsManager2.encodeDesktopMods(rRoll);

	-- Set maximum Bonus and Penalty Dice
	rRoll = ActionResult.capDice(rRoll);
end

function onRoll(rSource, rTarget, rRoll) -- Adjusted
	-- Debug.chat("FN: onRoll in manager_action_general")
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	-- Drop dice and process rRoll if Bonus or Penalty Dice have been part of the roll
	rRoll = ActionResult.DropDice(rRoll)

	Comm.deliverChatMessage(rMessage);
end