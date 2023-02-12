-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

-- ===================================================================================================================
-- Adjusted
-- ===================================================================================================================
function action(draginfo)
	local aParty = {};

	for _,v in pairs(window.list.getWindows()) do
		local rActor = ActorManager.resolveActor(v.link.getTargetDatabaseNode());
		if rActor then
			table.insert(aParty, rActor);
		end
	end

	if #aParty == 0 then
		aParty = nil;
	end

	local sAbilityStat = DB.getValue("partysheet.checkselected", ""):lower();
	
	ModifierManager.lock();
	for _,v in pairs(aParty) do
		-- Convert to lower case and removing all spaces from the string
		ActionCheck.performPartySheetRoll(nil, v, ActionsManager2.ConvertToTechnical(sAbilityStat));
	end
	ModifierManager.unlock(true);

	return true;
end

-- ===================================================================================================================
-- ===================================================================================================================
function onButtonPress()
	return action();
end			
