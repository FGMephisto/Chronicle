-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

-- ===================================================================================================================
-- ===================================================================================================================
function action(draginfo)
	-- Get actor
	local nodeRecord = window.link.getTargetDatabaseNode();
	if not nodeRecord then
		return false;
	end

	local rActor = ActorManager.resolveActor(nodeRecord);
	if not rActor then
		return false;
	end

	-- Get the selected ability from the dropdown control
	local sAbility = window.pccheckselected.getValue();

	-- Handle empty fields
	if not sAbility or sAbility == "" then
		return false;
	end

	-- Convert to lower case and remove all spaces from the string
	local sStat = ActionsManager2.ConvertToTechnical(sAbility);

	-- Handing it over for roll execution
	ModifierManager.lock();
	ActionCheck.performPartySheetRoll(draginfo, rActor, sStat);
	ModifierManager.unlock(true);

	return true;
end

-- ===================================================================================================================
-- ===================================================================================================================
function onButtonPress()
	return action();
end

function onDragStart(button, x, y, draginfo)
	return action(draginfo);
end
