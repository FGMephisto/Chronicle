-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

--
--
function onInit()
	onSummaryChanged();
	update();
end

--
-- Adjusted
--
function onSummaryChanged()
	-- local sSize = size.getValue();
	-- local sType = type.getValue();
	-- local sAlign = alignment.getValue();
	
	-- local aText = {};
	-- if sSize ~= "" then
		-- table.insert(aText, sSize);
	-- end
	-- if sType ~= "" then
		-- table.insert(aText, sType);
	-- end
	-- local sText = table.concat(aText, " ");

	-- summary_label.setValue(sText);
end

--
-- Adjusted
--
function update()
	local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);

	local bSection1 = false;
	if Session.IsHost then
		if WindowManager.callSafeControlUpdate(self, "nonid_name", bReadOnly) then bSection1 = true; end;
	else
		WindowManager.callSafeControlUpdate(self, "nonid_name", bReadOnly, true);
	end
	-- divider.setVisible(bSection1);

	WindowManager.callSafeControlUpdate(self, "size", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "type", bReadOnly);
	-- summary_label.setVisible(bReadOnly);
end

--
-- Adjusted
--
function onDrop(x, y, draginfo)
	-- if WindowManager.getReadOnlyState(getDatabaseNode()) then
		-- return true;
	-- end
	-- if draginfo.isType("shortcut") then
		-- local sClass = draginfo.getShortcutData();
		-- local nodeSource = draginfo.getDatabaseNode();
		
		-- if sClass == "reference_spell" or sClass == "power" then
			-- addSpellDrop(nodeSource);
		-- elseif sClass == "reference_backgroundfeature" then
			-- addAction(DB.getValue(nodeSource, "name", ""), DB.getText(nodeSource, "text", ""));
		-- elseif sClass == "reference_classfeature" then
			-- addAction(DB.getValue(nodeSource, "name", ""), DB.getText(nodeSource, "text", ""));
		-- elseif sClass == "reference_feat" then
			-- addAction(DB.getValue(nodeSource, "name", ""), DB.getText(nodeSource, "text", ""));
		-- elseif sClass == "reference_racialtrait" or sClass == "reference_subracialtrait" then
			-- addTrait(DB.getValue(nodeSource, "name", ""), DB.getText(nodeSource, "text", ""));
		-- end
		-- return true;
	-- end
end

--
-- Adjusted
--
function addSpellDrop(nodeSource, bInnate)
	-- CampaignDataManager2.addNPCSpell(getDatabaseNode(), nodeSource, bInnate);
end

--
-- Adjusted
--
function addAction(sName, sDesc)
	-- local w = actions.createWindow();
	-- if w then
		-- w.name.setValue(sName);
		-- w.desc.setValue(sDesc);
	-- end
end

--
-- Adjusted
--
function addTrait(sName, sDesc)
	-- local w = traits.createWindow();
	-- if w then
		-- w.name.setValue(sName);
		-- w.desc.setValue(sDesc);
	-- end
end