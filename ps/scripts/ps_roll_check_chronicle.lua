-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

-- ===================================================================================================================
-- ===================================================================================================================
function action(draginfo)
	local aParty = {}

	for _,v in pairs(window.list.getWindows()) do
		local rActor = ActorManager.resolveActor(v.link.getTargetDatabaseNode())
		if rActor then
			table.insert(aParty, rActor)
		end
	end

	if #aParty == 0 then
		aParty = nil
	end

	local sAbility = DB.getValue("partysheet.checkselected", ""):lower()

	-- Convert to lower case and removing all spaces from the string
	local sStat = ActionsManager2.ConvertToTechnical(sAbility)
	
	ModifierManager.lock()
	for _,v in pairs(aParty) do
		ActionCheck.performPartySheetRoll(nil, v, sStat)
	end
	ModifierManager.unlock(true)

	return true
end

-- ===================================================================================================================
-- ===================================================================================================================
function onButtonPress()
	return action()
end			
