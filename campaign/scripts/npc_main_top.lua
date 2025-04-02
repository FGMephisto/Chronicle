--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	self.onSummonChanged();
	self.onSummonDataChanged();
	self.onSummaryChanged();
	self.onInitChanged();
end

function onVersionChanged()
	self.onSummonChanged();
end
function onSummonChanged()
	self.update();
end
function onSummonDataChanged()
	local nodeRecord = getDatabaseNode();
	local bIs2024 = (DB.getValue(nodeRecord, "version", "") == "2024");
	local bSummon = bIs2024 and (DB.getValue(nodeRecord, "summon", 0) ~= 0);
	if bSummon then
		local nAC = DB.getValue(nodeRecord, "summon_ac_base", 0) +
				(DB.getValue(nodeRecord, "summon_ac_mod", 0) * DB.getValue(nodeRecord, "summon_level", 0));
		local nHP = DB.getValue(nodeRecord, "summon_hp_base", 0) +
				(DB.getValue(nodeRecord, "summon_hp_mod", 0) * math.max(DB.getValue(nodeRecord, "summon_level", 0) -
				DB.getValue(nodeRecord, "summon_hp_mod_threshold", 0)));
		DB.setValue(nodeRecord, "ac", "number", nAC);
		DB.setValue(nodeRecord, "hp", "number", nHP);
	end
end
function onSummonPowerDataChanged()
	CombatManager2.onNPCSummonPowerDataChanged(getDatabaseNode());
end

function onSummaryChanged()
	local nodeRecord = getDatabaseNode();

	local tFirstSummary = {};
	local sSize = DB.getValue(nodeRecord, "size", "");
	if sSize ~= "" then
		table.insert(tFirstSummary, sSize);
	end
	local sType = DB.getValue(nodeRecord, "type", "");
	if sType ~= "" then
		table.insert(tFirstSummary, sType);
	end
	local sFirstSummary = table.concat(tFirstSummary, " ");

	local tSecondSummary = {};
	if sFirstSummary ~= "" then
		table.insert(tSecondSummary, sFirstSummary);
	end
	local sAlign = DB.getValue(nodeRecord, "alignment", "");
	if sAlign ~= "" then
		table.insert(tSecondSummary, sAlign);
	end

	summary.setValue(table.concat(tSecondSummary, ", "));
end

function onInitChanged()
	if not initmod then
		return;
	end

	local nAbility = dexterity.getValue();
	local nMod = math.floor((nAbility - 10) / 2);
	initmod.setValue(nMod + initmiscmod.getValue());
end

function update()
	local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);

	local bIs2024 = (DB.getValue(nodeRecord, "version", "") == "2024");
	local bSummon = bIs2024 and (DB.getValue(nodeRecord, "summon", 0) ~= 0);

	sub_summary_fields.setVisible(not bReadOnly);
	summary.setVisible(bReadOnly);

	WindowManager.callSafeControlUpdate(self, "ac", bReadOnly or bSummon);
	WindowManager.callSafeControlUpdate(self, "actext", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "hp", bReadOnly or bSummon);
	WindowManager.callSafeControlUpdate(self, "hd", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "damagethreshold", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "speed", bReadOnly);
end
