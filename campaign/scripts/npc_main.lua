-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	onSummaryChanged();
	update();
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

function updateControl(sControl, bReadOnly, bForceHide)
	if not self[sControl] then
		return false;
	end
		
	return self[sControl].update(bReadOnly, bForceHide);
end

function update()
	local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);

	local bSection1 = false;
	if Session.IsHost then
		if updateControl("nonid_name", bReadOnly) then bSection1 = true; end;
	else
		updateControl("nonid_name", bReadOnly, true);
	end
	divider.setVisible(bSection1);

	updateControl("size", bReadOnly, bReadOnly);
	updateControl("type", bReadOnly, bReadOnly);
	updateControl("alignment", bReadOnly, bReadOnly);
	summary_label.setVisible(bReadOnly);
	
	ac.setReadOnly(bReadOnly);
	actext.setReadOnly(bReadOnly);
	hp.setReadOnly(bReadOnly);
	hd.setReadOnly(bReadOnly);
	updateControl("damagethreshold", bReadOnly);
	speed.setReadOnly(bReadOnly);
	
	updateControl("strength", bReadOnly);
	updateControl("constitution", bReadOnly);
	updateControl("dexterity", bReadOnly);
	updateControl("intelligence", bReadOnly);
	updateControl("wisdom", bReadOnly);
	updateControl("charisma", bReadOnly);

	updateControl("savingthrows", bReadOnly);
	updateControl("skills", bReadOnly);
	updateControl("damagevulnerabilities", bReadOnly);
	updateControl("damageresistances", bReadOnly);
	updateControl("damageimmunities", bReadOnly);
	updateControl("conditionimmunities", bReadOnly);
	updateControl("senses", bReadOnly);
	updateControl("languages", bReadOnly);
	updateControl("challengerating", bReadOnly);
	
	cr.setReadOnly(bReadOnly);
	xp.setReadOnly(bReadOnly);
	
	updateControl("traits", bReadOnly);
	updateControl("actions", bReadOnly);
	updateControl("bonusactions", bReadOnly);
	updateControl("reactions", bReadOnly);
	updateControl("legendaryactions", bReadOnly);
	updateControl("lairactions", bReadOnly);
	updateControl("innatespells", bReadOnly);
	updateControl("spells", bReadOnly);
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
