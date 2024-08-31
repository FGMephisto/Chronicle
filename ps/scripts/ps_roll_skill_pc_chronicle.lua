-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

--
--
function action(draginfo)
	-- Get actor
	local rActor = ActorManager.resolveActor(window.link.getTargetDatabaseNode())

	-- Get the selected skill from the button control
	local sSkill = window.pcskillselected.getValue()

	-- Handle empty fields
	if sSkill == nil then
		return false;
	end
	
	-- Handing it over for roll execution
	ModifierManager.lock()
	ActionSkill.performPartySheetRoll(nil, rActor, sSkill)
	ModifierManager.unlock(true)

	return true;
end

--
--
function onButtonPress()
	return action();
end