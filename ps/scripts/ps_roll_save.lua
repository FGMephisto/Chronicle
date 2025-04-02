--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function action()
	local tParty = PartyManager.getPartyActors();
	if #tParty == 0 then
		return true;
	end

	local sSave = DB.getValue("partysheet.saveselected", ""):lower();

	ModifierManager.lock();
	for _,v in pairs(tParty) do
		ActionSave.performPartySheetRoll(nil, v, sSave);
	end
	ModifierManager.unlock(true);
	return true;
end

function onButtonPress()
	return self.action();
end
