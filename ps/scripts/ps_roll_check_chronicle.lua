-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

-- ===================================================================================================================
-- Adjusted
-- ===================================================================================================================
function action(draginfo)
	local tParty = PartyManager.getPartyActors();
	if #tParty == 0 then
		return true;
	end

	local sAbilityStat = DB.getValue("partysheet.checkselected", ""):lower();
	
	ModifierManager.lock();
	for _,v in pairs(tParty) do
		-- Convert to lower case and removing all spaces from the string
		ActionCheck.performPartySheetRoll(nil, v, StringManager.simplify(sAbilityStat));
	end
	ModifierManager.unlock(true);
	return true;
end

function onButtonPress()
	return action();
end
