-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	update();
end

function updateControl(sControl, bReadOnly, bForceHide)
	if not self[sControl] then
		return false;
	end
		
	return self[sControl].update(bReadOnly, bForceHide);
end

function updateAbility(sControl, bReadOnly, bShow)
	local c = self[sControl];
	if c then
		c.setReadOnly(bReadOnly);
		c.setVisible(bShow);
	end

	c = self[sControl .. "_label"];
	if c then
		c.setVisible(bShow);
	end

	c = self[sControl .. "_modtext"];
	if c then
		c.setVisible(bShow);
	end

	c = self[sControl .. "_abilitycheck"];
	if c then
		c.setVisible(bShow);
	end

	c = self[sControl .. "_abilitysave"];
	if c then
		c.setVisible(bShow);
	end
end

function update()
	local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
	local bID = LibraryData.getIDState("npc", nodeRecord);

	local bSection1 = false;
	if Session.IsHost then
		if updateControl("nonid_name", bReadOnly) then bSection1 = true; end;
	else
		updateControl("nonid_name", bReadOnly, true);
	end
	divider.setVisible(bSection1);

	type.setReadOnly(bReadOnly);
	updateControl("size", bReadOnly);
	updateControl("cost", bReadOnly);
	updateControl("crew", bReadOnly);
	updateControl("cargo", bReadOnly);

	ac.setReadOnly(bReadOnly);
	actext.setReadOnly(bReadOnly);
	hp.setReadOnly(bReadOnly);
	damagethreshold.setReadOnly(bReadOnly);
	mishapthreshold.setReadOnly(bReadOnly);
	if bReadOnly then
		local bShowMishap = (mishapthreshold.getValue() > 0);
		mishapthreshold.setVisible(bShowMishap);
		mishapthreshold_label.setVisible(bShowMishap);
	else
		mishapthreshold.setVisible(true);
		mishapthreshold_label.setVisible(true);
	end
	updateControl("speed", bReadOnly);

	local bSectionSpecialDef = false;
	if updateControl("damagevulnerabilities", bReadOnly) then bSectionSpecialDef = true; end;
	if updateControl("damageresistances", bReadOnly) then bSectionSpecialDef = true; end;
	damageimmunities.setReadOnly(bReadOnly);
	disablestandarddamageimmunities.setReadOnly(bReadOnly);
	conditionimmunities.setReadOnly(bReadOnly);
	disablestandardconditionimmunities.setReadOnly(bReadOnly);
	if bReadOnly then
		local bShowDmgImmune = not damageimmunities.isEmpty() or not disablestandarddamageimmunities.isEmpty();
		damageimmunities.setVisible(bShowDmgImmune);
		disablestandarddamageimmunities.setVisible(bShowDmgImmune);
		damageimmunities_label.setVisible(bShowDmgImmune);
		local bShowCondImmune = not conditionimmunities.isEmpty() or not disablestandardconditionimmunities.isEmpty();
		conditionimmunities.setVisible(bShowCondImmune);
		disablestandardconditionimmunities.setVisible(bShowCondImmune);
		conditionimmunities_label.setVisible(bShowCondImmune);
		if bShowDmgImmune or bShowCondImmune then
			bSectionSpecialDef = true;
		end
	else
		damageimmunities.setVisible(true);
		disablestandarddamageimmunities.setVisible(true);
		damageimmunities_label.setVisible(true);
		conditionimmunities.setVisible(true);
		disablestandardconditionimmunities.setVisible(true);
		conditionimmunities_label.setVisible(true);
	end
	divider_specialdef.setVisible(bSectionSpecialDef);
	
	local bShowAbilities = not bReadOnly or 
			((strength.getValue() ~= 10) or (constitution.getValue() ~= 10) or (dexterity.getValue() ~= 10) or
			(intelligence.getValue() ~= 0) or (wisdom.getValue() ~= 0) or (charisma.getValue() ~= 0));
	updateAbility("strength", bReadOnly, bShowAbilities);
	updateAbility("constitution", bReadOnly, bShowAbilities);
	updateAbility("dexterity", bReadOnly, bShowAbilities);
	updateAbility("intelligence", bReadOnly, bShowAbilities);
	updateAbility("wisdom", bReadOnly, bShowAbilities);
	updateAbility("charisma", bReadOnly, bShowAbilities);
	divider_ability.setVisible(bShowAbilities);

	updateControl("traits", bReadOnly);
	updateControl("components", bReadOnly);
end

function onDrop(x, y, draginfo)
	if WindowManager.getReadOnlyState(getDatabaseNode()) then
		return true;
	end
	if draginfo.isType("shortcut") then
		local sClass = draginfo.getShortcutData();
		if sClass == "item" then
			local nodeSource = draginfo.getDatabaseNode();
			local sTypeLower = StringManager.trim(DB.getValue(nodeSource, "type", "")):lower();

			if sTypeLower == "vehicle component" or sTypeLower == "vehicle component upgrade" then
				addComponent(nodeSource);
				return true;
			end
		end
	end
end
function addComponent(nodeSource)
	if not nodeSource then
		return;
	end

	local sName = DB.getValue(nodeSource, "name", "");
	local nodeComponents = DB.createChild(getDatabaseNode(), "components");
	local nodeEntry = DB.createChild(nodeComponents);

	DB.copyNode(nodeSource, nodeEntry);
	DB.setValue(nodeEntry, "locked", "number", 1);
	DB.setValue(nodeEntry, "shortcut", "windowreference", "item", DB.getPath(nodeEntry));
end
