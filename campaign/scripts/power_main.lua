-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	onSummaryChanged();
	update();
end

function onSummaryChanged()
	local nLevel = level.getValue();
	local sSchool = school.getValue();
	
	local aText = {};
	if nLevel > 0 then
		table.insert(aText, Interface.getString("level") .. " " .. nLevel);
	end
	if sSchool ~= "" then
		table.insert(aText, sSchool);
	end
	if nLevel == 0 then
		table.insert(aText, Interface.getString("spell_label_cantrip"));
	end
	if ritual.getValue() ~= 0 then
		table.insert(aText, "(" .. Interface.getString("spell_label_ritual") .. ")");
	end
	
	summary_label.setValue(StringManager.capitalize(table.concat(aText, " ")));
end

function update()
	local bReadOnly = WindowManager.getReadOnlyState(getDatabaseNode());

	local bSection1 = false;
	if WindowManager.callSafeControlUpdate(self, "shortdescription", bReadOnly) then bSection1 = true; end;
	
	local bSection2 = false;
	if WindowManager.callSafeControlUpdate(self, "level", bReadOnly, bReadOnly) then bSection2 = true; end;
	if WindowManager.callSafeControlUpdate(self, "school", bReadOnly, bReadOnly) then bSection2 = true; end;
	if WindowManager.callSafeControlUpdate(self, "ritual", bReadOnly, bReadOnly) then bSection2 = true; end;
	if (not bReadOnly) or (level.getValue() == 0 and school.getValue() == "") then
		summary_label.setVisible(false);
	else
		summary_label.setVisible(true);
		bSection2 = true;
	end
	
	local bSection3 = false;
	if WindowManager.callSafeControlUpdate(self, "castingtime", bReadOnly) then bSection3 = true; end;
	if WindowManager.callSafeControlUpdate(self, "range", bReadOnly) then bSection3 = true; end;
	if WindowManager.callSafeControlUpdate(self, "components", bReadOnly) then bSection3 = true; end;
	if WindowManager.callSafeControlUpdate(self, "duration", bReadOnly) then bSection3 = true; end;
	if WindowManager.callSafeControlUpdate(self, "description", bReadOnly) then bSection3 = true; end;

	local bSection4 = false;
	if WindowManager.callSafeControlUpdate(self, "source", bReadOnly) then bSection4 = true; end;
	
	divider.setVisible(bSection1 and bSection2);
	divider2.setVisible((bSection1 or bSection2) and bSection3);
	divider3.setVisible((bSection1 or bSection2 or bSection3) and bSection4);
end
