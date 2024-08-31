-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onTabletopInit()
	RecordShareManager.setWindowClassCallback("ref_ability", handleAbilityShare);
	RecordShareManager.setRecordTypeCallback("item", handleItemShare);
	RecordShareManager.setRecordTypeCallback("spell", handleSpellShare);
end

function handleAbilityShare(node, tOutput)
	RecordShareManager.onShareRecordBasic(Interface.getString("skill_label_ability"), node, tOutput);
end
function handleItemShare(node, tOutput)
	if LibraryData.getIDState("item", node, true) then
		local sItemType = StringManager.trim(DB.getText(node, "type", ""));
		table.insert(tOutput, string.format("%s - %s", sItemType, DB.getText(node, "name", "")));
		table.insert(tOutput, "");
		table.insert(tOutput, string.format("%s: %s", Interface.getString("item_label_cost"), DB.getText(node, "cost", 0)));
		table.insert(tOutput, string.format("%s: %s", Interface.getString("item_label_weight"), DB.getText(node, "weight", 0)));

		if sItemType == "Weapon" then
			table.insert(tOutput, "");
			table.insert(tOutput, string.format("%s: %s", Interface.getString("item_label_damage"), DB.getText(node, "damage", "")));
			table.insert(tOutput, string.format("%s: %s", Interface.getString("item_label_properties"), DB.getText(node, "properties", "")));
		elseif sItemType == "Armor" then
			table.insert(tOutput, "");
			table.insert(tOutput, string.format("%s: %s", Interface.getString("item_label_ac"), DB.getText(node, "ac", 10)));
		end

		local sText = DB.getText(node, "description", "");
		if sText ~= "" then
			table.insert(tOutput, "");
			table.insert(tOutput, sText);
		end
	else
		RecordShareManager.onShareRecordTypeUnidentified("item", node, tOutput);
	end
end
function handleSpellShare(node, tOutput)
	table.insert(tOutput, string.format("%s - %s", LibraryData.getSingleDisplayText("spell"), DB.getText(node, "name", "")));
	table.insert(tOutput, "");
	table.insert(tOutput, string.format("%s: %s", Interface.getString("level"), DB.getText(node, "level", 0) .. " " .. DB.getText(node, "school", "")));
	table.insert(tOutput, "");
	table.insert(tOutput, string.format("%s: %s", Interface.getString("spell_label_castingtime"), DB.getText(node, "castingtime", "")));
	table.insert(tOutput, string.format("%s: %s", Interface.getString("spell_label_range"), DB.getText(node, "range", "")));
	table.insert(tOutput, string.format("%s: %s", Interface.getString("spell_label_components"), DB.getText(node, "components", "")));
	table.insert(tOutput, string.format("%s: %s", Interface.getString("spell_label_duration"), DB.getText(node, "duration", "")));

	local sText = DB.getText(node, "description", "");
	if sText ~= "" then
		table.insert(tOutput, "");
		table.insert(tOutput, sText);
	end

	local sSource = DB.getText(node, "source", "");
	if sSource ~= "" then
		table.insert(tOutput, "");
		table.insert(tOutput, string.format("%s: %s", Interface.getString("spell_label_source"), sSource));
	end
end
