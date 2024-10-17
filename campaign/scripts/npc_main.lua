-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	self.update();
	registerMenuItem(Interface.getString("npc_menu_parsespells"), "radial_magicwand", 7);
end

function onMenuSelection(selection)
	if selection == 7 then
		CampaignDataManager2.updateNPCSpells(getDatabaseNode());
	end
end

function onVersionChanged()
	self.update();
end
function onSummonChanged()
	self.update();
end

function update()
	local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
	
	if sub_summon then
		local bSummon = (DB.getValue(nodeRecord, "summon", 0) ~= 0);
		if (bSummon or not bReadOnly) then
			if sub_summon.isEmpty() then
				sub_summon.setValue("npc_combat_summon_2024", nodeRecord);
			end
		else
			sub_summon.setValue("", "");
		end
		WindowManager.callSafeControlUpdate(self, "sub_summon", bReadOnly);
	end

	WindowManager.callSafeControlUpdate(self, "sub_top", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "sub_abilities", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "sub_bottom", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "sub_action", bReadOnly);
end

function onDrop(x, y, draginfo)
	if WindowManager.getReadOnlyState(getDatabaseNode()) then
		return true;
	end
	if draginfo.isType("shortcut") then
		local sClass = draginfo.getShortcutData();
		local nodeSource = draginfo.getDatabaseNode();
		
		if sClass == "reference_spell" or sClass == "power" then
			self.addSpellDrop(nodeSource);
		elseif sClass == "reference_racialtrait" or sClass == "reference_subracialtrait" then
			self.addTrait(DB.getValue(nodeSource, "name", ""), DB.getText(nodeSource, "text", ""));
		elseif sClass == "reference_backgroundfeature" then
			self.addAction(DB.getValue(nodeSource, "name", ""), DB.getText(nodeSource, "text", ""));
		elseif sClass == "reference_classfeature" or sClass == "reference_classfeaturechoice" then
			self.addAction(DB.getValue(nodeSource, "name", ""), DB.getText(nodeSource, "text", ""));
		elseif sClass == "reference_feat" then
			self.addAction(DB.getValue(nodeSource, "name", ""), DB.getText(nodeSource, "text", ""));
		end
		return true;
	end
end
function addSpellDrop(nodeSource, bInnate)
	CampaignDataManager2.addNPCSpell(getDatabaseNode(), nodeSource, bInnate);
end
function addTrait(sName, sDesc)
	local nodeTrait = DB.createChild(DB.getPath(getDatabaseNode(), "traits"));
	if nodeTrait then
		DB.setValue(nodeTrait, "name", "string", sName);
		DB.setValue(nodeTrait, "desc", "string", sDesc);
	end
end
function addAction(sName, sDesc)
	local nodeTrait = DB.createChild(DB.getPath(getDatabaseNode(), "actions"));
	if nodeTrait then
		DB.setValue(nodeTrait, "name", "string", sName);
		DB.setValue(nodeTrait, "desc", "string", sDesc);
	end
end
