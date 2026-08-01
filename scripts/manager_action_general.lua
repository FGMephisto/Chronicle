--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	ActionsManager.registerModHandler("dice", ActionGeneral.modRoll);
	ActionsManager.registerPostRollHandler("dice", ActionGeneral.onRoll);
end

function modRoll(_, _, rRoll)
	if #(rRoll.aDice) == 1 and rRoll.aDice[1].type == "d20" then
		ActionD20.encodeAdvantage(rRoll);
	end
	return true;
end

function onRoll(rSource, rRoll)
	ActionD20.decodeAdvantage(rRoll);
end
