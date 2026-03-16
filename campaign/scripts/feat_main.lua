--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	self.onSummaryChanged();
	self.onLockModeChanged(WindowManager.getWindowReadOnlyState(self));
end
function onSummaryChanged()
	local nodeRecord = getDatabaseNode();

	local tOutput = {};

	local sCategory = DB.getValue(nodeRecord, "category", "");
	if sCategory ~= "" then
		table.insert(tOutput, sCategory);
	end

	table.insert(tOutput, Interface.getString("library_recordtype_single_feat"));

	local tPrereq = {};
	local nLevel = DB.getValue(nodeRecord, "level", 0);
	if nLevel > 1 then
		table.insert(tPrereq, string.format("%s %d+", Interface.getString("level"), nLevel));
	end
	local sPrereq = DB.getValue(nodeRecord, "prerequisite", "");
	if sPrereq ~= "" then
		table.insert(tPrereq, sPrereq);
	end
	if #tPrereq > 0 then
		local sSummary = string.format("(%s: %s)", Interface.getString("record_label_prerequisite"), table.concat(tPrereq, "; "));
		table.insert(tOutput, sSummary);
	end

	local bRepeatable = (DB.getValue(nodeRecord, "repeatable", 0) ~= 0);
	if bRepeatable then
		table.insert(tOutput, string.format("(%s)", Interface.getString("feat_label_repeatable")));
	end

	summary.setValue(table.concat(tOutput, " "));
end
function onLockModeChanged(bReadOnly)
	sub_summary_fields.setVisible(not bReadOnly);
	summary.setVisible(bReadOnly and not summary.isEmpty());
	divider.setVisible(WindowManager.getAnyControlVisible(self, { "sub_summary_fields", "summary", }))

	WindowManager.callSafeControlSetLockMode(self, "text", bReadOnly);
end
