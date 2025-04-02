--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	self.onXPChanged();
	self.onBackgroundChanged();
	self.onSpeciesChanged();
	CharManager.refreshNextLevelXP(getDatabaseNode());
	self.onLockModeChanged(WindowManager.getWindowReadOnlyState(self));
end

function onLockModeChanged(bReadOnly)
	local tFieldsTop = { "background", "race", };
	local tFieldsAbility = { "strength", "dexterity", "constitution", "intelligence", "wisdom", "charisma", };
	local tFieldsSave = { "strengthsave", "dexteritysave", "constitutionsave", "intelligencesave", "wisdomsave", "charismasave", };
	local tFieldsSaveProf = { "strengthsaveprof", "dexteritysaveprof", "constitutionsaveprof", "intelligencesaveprof", "wisdomsaveprof", "charismasaveprof", };
	local tFieldsHealth = { "hp", };
	--local tFieldsHealth = { "wounds", "temphp", "deathsavesuccess", "deathsavefail", };

	WindowManager.callSafeControlsSetLockMode(self, tFieldsTop, bReadOnly);
	WindowManager.callSafeControlsSetLockMode(self, tFieldsAbility, bReadOnly);
	WindowManager.callSafeControlsSetLockMode(self, tFieldsSave, bReadOnly);
	WindowManager.callSafeControlsSetLockMode(self, tFieldsSaveProf, bReadOnly);
	WindowManager.callSafeControlsSetLockMode(self, tFieldsHealth, bReadOnly);
end

function onHealthChanged()
	wounds.setColor(ActorManager5E.getPCSheetWoundColor(getDatabaseNode()));
end
function onXPChanged()
	local nLevel = level.getValue();
	local nXPNeeded = expneeded.getValue();
	local nXP = exp.getValue();
	local bShowLevelAdd = ((nLevel == 0) or ((nXPNeeded > 0) and (nXP >= nXPNeeded)));
	button_classlevel_add.setVisible(bShowLevelAdd);
end
function onBackgroundChanged()
	button_background_add.setVisible(background.isEmpty());
end
function onSpeciesChanged()
	button_species_add.setVisible(race.isEmpty());
end

function onDrop(_, _, draginfo)
	if draginfo.isType("shortcut") then
		local sClass, sRecord = draginfo.getShortcutData();
		if StringManager.contains({ "reference_class", "reference_race", "reference_subrace", "reference_background", "reference_feat", }, sClass) then
			return CharBuildDropManager.addInfoDB(getDatabaseNode(), sClass, sRecord);
		end
	end
end

function onInitAction(draginfo)
	local rActor = ActorManager.resolveActor(getDatabaseNode());
	ActionInit.performRoll(draginfo, rActor);
	return true;
end
function onCheckAction(draginfo, sCheck)
	if (sCheck or "") == "" then
		return false;
	end
	local rActor = ActorManager.resolveActor(getDatabaseNode());
	ActionCheck.performRoll(draginfo, rActor, sCheck);
	return true;
end
function onSaveAction(draginfo, sSave)
	if (sSave or "") == "" then
		return false;
	end
	local rActor = ActorManager.resolveActor(getDatabaseNode());
	ActionSave.performRoll(draginfo, rActor, sSave);
	return true;
end
