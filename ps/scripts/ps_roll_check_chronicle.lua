-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function action()
	local tParty = PartyManager.getPartyActors();
	if #tParty == 0 then
		return true;
	end

	local sAbilityStat = DB.getValue("partysheet.checkselected", "");
	if not sAbilityStat or sAbilityStat == "" then
		return true;
	end

	-- Convert to lower case and remove all spaces (e.g. "Animal Handling" -> "animalhandling")
	local sCheck = ActionsManager2.ConvertToTechnical(sAbilityStat);

	ModifierManager.lock();
	for _,v in pairs(tParty) do
		ActionCheck.performPartySheetRoll(nil, v, sCheck);
	end
	ModifierManager.unlock(true);

	return true;
end

function onButtonPress()
	return action();
end
