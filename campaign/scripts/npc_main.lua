-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	self.onSummaryChanged();
	self.update();
	registerMenuItem(Interface.getString("npc_menu_parsespells"), "radial_magicwand", 7);
end

function onMenuSelection(selection)
	if selection == 7 then
		CampaignDataManager2.updateNPCSpells(getDatabaseNode());
	end
end

function onSummaryChanged()
	local sSize = size.getValue();
	local sType = type.getValue();
	local sAlign = alignment.getValue();
	
	local aText = {};
	if sSize ~= "" then
		table.insert(aText, sSize);
	end
	if sType ~= "" then
		table.insert(aText, sType);
	end
	local sText = table.concat(aText, " ");

	if sAlign ~= "" then
		if sText ~= "" then
			sText = sText .. ", " .. sAlign;
		else
			sText = sAlign;
		end
	end
	
	summary_label.setValue(sText);
end

function update()
	local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);

	WindowManager.callSafeControlUpdate(self, "size", bReadOnly, bReadOnly);
	WindowManager.callSafeControlUpdate(self, "type", bReadOnly, bReadOnly);
	WindowManager.callSafeControlUpdate(self, "alignment", bReadOnly, bReadOnly);
	summary_label.setVisible(bReadOnly);
	
	ac.setReadOnly(bReadOnly);
	actext.setReadOnly(bReadOnly);
	hp.setReadOnly(bReadOnly);
	hd.setReadOnly(bReadOnly);
	WindowManager.callSafeControlUpdate(self, "damagethreshold", bReadOnly);
	speed.setReadOnly(bReadOnly);
	
	WindowManager.callSafeControlUpdate(self, "strength", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "constitution", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "dexterity", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "intelligence", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "wisdom", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "charisma", bReadOnly);

	WindowManager.callSafeControlUpdate(self, "savingthrows", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "skills", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "damagevulnerabilities", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "damageresistances", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "damageimmunities", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "conditionimmunities", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "senses", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "languages", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "challengerating", bReadOnly);
	
	cr.setReadOnly(bReadOnly);
	xp.setReadOnly(bReadOnly);
	
	WindowManager.callSafeControlUpdate(self, "traits", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "actions", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "bonusactions", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "reactions", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "legendaryactions", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "lairactions", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "innatespells", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "spells", bReadOnly);
end

function onDrop(x, y, draginfo)
	if WindowManager.getReadOnlyState(getDatabaseNode()) then
		return true;
	end
	if draginfo.isType("shortcut") then
		local sClass = draginfo.getShortcutData();
		local nodeSource = draginfo.getDatabaseNode();
		
		if sClass == "reference_spell" or sClass == "power" then
			addSpellDrop(nodeSource);
		elseif sClass == "reference_backgroundfeature" then
			addAction(DB.getValue(nodeSource, "name", ""), DB.getText(nodeSource, "text", ""));
		elseif sClass == "reference_classfeature" then
			addAction(DB.getValue(nodeSource, "name", ""), DB.getText(nodeSource, "text", ""));
		elseif sClass == "reference_feat" then
			addAction(DB.getValue(nodeSource, "name", ""), DB.getText(nodeSource, "text", ""));
		elseif sClass == "reference_racialtrait" or sClass == "reference_subracialtrait" then
			addTrait(DB.getValue(nodeSource, "name", ""), DB.getText(nodeSource, "text", ""));
		end
		return true;
	end
end
function addSpellDrop(nodeSource, bInnate)
	CampaignDataManager2.addNPCSpell(getDatabaseNode(), nodeSource, bInnate);
end
function addAction(sName, sDesc)
	local w = actions.createWindow();
	if w then
		w.name.setValue(sName);
		w.desc.setValue(sDesc);
	end
end
function addTrait(sName, sDesc)
	local w = traits.createWindow();
	if w then
		w.name.setValue(sName);
		w.desc.setValue(sDesc);
	end
end
