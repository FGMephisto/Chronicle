-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System1
--

-- ===================================================================================================================
-- ===================================================================================================================
function action(draginfo)
	-- Get actor
	local rActor = ActorManager.resolveActor(window.link.getTargetDatabaseNode())

	-- Get the selected ability from the button control
	local sAbility = window.pccheckselected.getValue()

	-- Handle empty fields
	if sAbility == nil then
		return false
	end

	-- Convert to lower case and removing all spaces from the string
	local sStat = ActionsManager2.ConvertToTechnical(sAbility)

	-- Handing it over for roll execution
	ModifierManager.lock()
	ActionCheck.performPartySheetRoll(nil, rActor, sStat)
	ModifierManager.unlock(true)

	return true
end

-- ===================================================================================================================
-- ===================================================================================================================
function onButtonPress()
	return action();
end			
