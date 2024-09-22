-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	local nodeChar = DB.getChild(window.getDatabaseNode(), "...");
	DB.addHandler(DB.getPath(nodeChar, "abilities.*.score"), "onUpdate", onSourceUpdate);
	DB.addHandler(DB.getPath(nodeChar, "profbonus"), "onUpdate", onSourceUpdate);

	addSource("stat", "string");
	addSource("prof");
	addSourceWithOp("misc", "+");

	super.onInit();
end

function onClose()
	local nodeChar = DB.getChild(window.getDatabaseNode(), "...");
	DB.removeHandler(DB.getPath(nodeChar, "abilities.*.score"), "onUpdate", onSourceUpdate);
	DB.removeHandler(DB.getPath(nodeChar, "profbonus"), "onUpdate", onSourceUpdate);
end

function onSourceUpdate(node)
	local nValue = calculateSources();

	local nodeSkill = window.getDatabaseNode();
	local nodeChar = DB.getChild(nodeSkill, "...");

	local sAbility = DB.getValue(nodeSkill, "stat", "");
	if sAbility ~= "" then
		local nScore = DB.getValue(nodeChar, "abilities." .. sAbility .. ".score", 0)
		nValue = nValue + math.floor((nScore - 10) / 2);
	end
	
	local nProf = DB.getValue(nodeSkill, "prof", 0);
	if nProf == 1 then
		nValue = nValue + DB.getValue(nodeChar, "profbonus", 2);
	elseif nProf == 2 then
		nValue = nValue + (2 * DB.getValue(nodeChar, "profbonus", 2));
	elseif nProf == 3 then
		nValue = nValue + math.floor(DB.getValue(nodeChar, "profbonus", 2) / 2);
	end
	
	setValue(nValue);
end

function action(draginfo)
	local nodeSkill = window.getDatabaseNode();
	local nodeChar = DB.getChild(nodeSkill, "...");
	local rActor = ActorManager.resolveActor(nodeChar);
	ActionSkill.performRoll(draginfo, rActor, nodeSkill);
	return true;
end

function onDragStart(button, x, y, draginfo)
	return action(draginfo);
end
	
function onDoubleClick(x,y)
	return action();
end
