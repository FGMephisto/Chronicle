-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	self.onSummaryChanged();
	self.update();
end
function onSummaryChanged()
	local nodeRecord = getDatabaseNode();
	local nLevel = DB.getValue(nodeRecord, "level", 0);
	local sSchool = DB.getValue(nodeRecord, "school", "");
	if (nLevel <= 0) and (sSchool == "") then
		summary.setValue("");
		return;
	end
	local sSource = DB.getValue(nodeRecord, "source", "");
	local bRitual = (DB.getValue(nodeRecord, "ritual", 0) ~= 0);

	local tOutput = {};
	if nLevel >= 0 then
		table.insert(tOutput, string.format("%s %d", Interface.getString("level"), nLevel));
	end
	if sSchool ~= "" then
		table.insert(tOutput, sSchool);
	end
	if #tOutput > 0 then
		table.insert(tOutput, Interface.getString("library_recordtype_single_spell"));
	end

	local tParenOutput = {};
	if sSource then
		table.insert(tParenOutput, sSource);
	end
	if bRitual then
		table.insert(tParenOutput, Interface.getString("spell_label_ritual"));
	end
	if #tParenOutput > 0 then
		table.insert(tOutput, string.format("(%s)", table.concat(tParenOutput, "; ")));
	end
	
	summary.setValue(table.concat(tOutput, " "));
end
function update()
	local bReadOnly = WindowManager.getReadOnlyState(getDatabaseNode());

	sub_summary_fields.setVisible(not bReadOnly);
	summary.setVisible(bReadOnly and not summary.isEmpty());
	divider.setVisible(WindowManager.getAnyControlVisible(self, { "sub_summary_fields", "summary", }))

	WindowManager.callSafeControlUpdate(self, "castingtime", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "range", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "components", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "duration", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "description", bReadOnly);

	WindowManager.callSafeControlUpdate(self, "sub_automation", bReadOnly);
end
