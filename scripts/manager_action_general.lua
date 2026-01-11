--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	ActionsManager.registerModHandler("dice", ActionGeneral.modRoll);
	ActionsManager.registerResultHandler("dice", ActionGeneral.onRoll);
end

function modRoll(_, _, rRoll)
	ActionsManager2.encodeDesktopMods(rRoll);

	if #(rRoll.aDice) == 1 and rRoll.aDice[1].type == "d20" then
		ActionsManager2.encodeAdvantage(rRoll);
	end
	return true;
end

function onRoll(rSource, _, rRoll)
	ActionsManager2.decodeAdvantage(rRoll);

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	Comm.deliverChatMessage(rMessage);
end

