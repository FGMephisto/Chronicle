-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

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

	-- Get the selected skill from the dropdown control
	local sSkill = window.pcskillselected.getValue();

	-- Handle empty fields
	if not sSkill or sSkill == "" then
		return false;
	end

	-- Handing it over for roll execution
	ModifierManager.lock();
	ActionSkill.performPartySheetRoll(draginfo, rActor, sSkill);
	ModifierManager.unlock(true);

	return true;
end

function onButtonPress()
	return action();
end

function onDragStart(button, x, y, draginfo)
	return action(draginfo);
end