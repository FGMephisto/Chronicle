--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

-- TODO: Migrate more power page functionality to this script; and remove sheet lookups

--
-- CHARACTER SHEET DROPS
--

function addPowerDB(nodeChar, sClass, sRecord, sGroup)
	-- Validate parameters
	if not nodeChar then
		return false;
	end

	if StringManager.contains({ "reference_spell", "power", }, sClass) then
		sGroup = CharPowerManager.resolveSpellDropPowerGroup(nodeChar, sGroup);
	elseif StringManager.contains({ "reference_classfeature", "reference_racialtrait", "reference_feat", "ref_ability", }, sClass) then
		sGroup = nil;
	else
		return false;
	end

	CharPowerManager.pausePowerGroupUpdates(nodeChar);
	local nodeNewPower = PowerManager.addPower(sClass, DB.findNode(sRecord), nodeChar, sGroup);
	CharPowerManager.resumePowerGroupUpdates(nodeChar);

	if sGroup and nodeNewPower then
		local nodePowerGroup = CharManager.getPowerGroupRecord(nodeChar, sGroup);
		if nodePowerGroup and (DB.getValue(nodePowerGroup, "castertype", "") == "memorization") then
			DB.setValue(nodeNewPower, "prepared", "number", 1);
		end
	end

	local wChar = Interface.findWindow("charsheet", nodeChar);
	if wChar then
		local wTab = wChar.actions and wChar.actions.subwindow;
		if wTab then
			wTab.content.subwindow.actions.subwindow.updatePowerGroups();
		end
	end

	return true;
end

function resolveSpellDropPowerGroup(nodeChar, sGroup)
	if (sGroup or "") ~= "" then
		return sGroup;
	end

	local sSpellsBase = Interface.getString("char_spell_powergroup_base");
	for _,v in ipairs(DB.getChildList(nodeChar, "powergroup")) do
		local sGroupName = DB.getValue(v, "name", "");
		if StringManager.startsWith(sGroupName, sSpellsBase) then
			return sGroupName;
		end
	end

	return sSpellsBase;
end

--
--	POWER GROUP UPDATING
--

local _tPowerGroupUpdatePause = {};
function arePowerGroupUpdatesPaused(nodeChar)
	return _tPowerGroupUpdatePause[nodeChar] or false;
end
function pausePowerGroupUpdates(nodeChar)
	_tPowerGroupUpdatePause[nodeChar] = true;
end
function resumePowerGroupUpdates(nodeChar)
	_tPowerGroupUpdatePause[nodeChar] = nil;
end

--
--	POWER USAGE UPDATING
--

local _tPowerUsageUpdatePause = {};
function arePowerUsageUpdatesPaused(nodeChar)
	return _tPowerUsageUpdatePause[nodeChar] or false;
end
function pausePowerUsageUpdates(nodeChar)
	_tPowerUsageUpdatePause[nodeChar] = true;
end
function resumePowerUsageUpdates(nodeChar)
	_tPowerUsageUpdatePause[nodeChar] = nil;
end
