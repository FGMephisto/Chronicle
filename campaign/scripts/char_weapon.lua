--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	self.onLinkChanged();
	self.onLockModeChanged(WindowManager.getWindowReadOnlyState(self));

	local nodeWeapon = getDatabaseNode();
	local nodeChar = DB.getChild(nodeWeapon, "...");
	DB.addHandler(DB.getPath(nodeWeapon, "shortcut"), "onUpdate", self.onLinkChanged);
	DB.addHandler(DB.getPath(nodeWeapon, "type"), "onUpdate", self.onTypeChanged);
	DB.addHandler(nodeWeapon, "onChildUpdate", self.onDataChanged);
	DB.addHandler(DB.getPath(nodeChar, "abilities.*.score"), "onUpdate", self.onDataChanged);
	DB.addHandler(DB.getPath(nodeChar, "weapon.twoweaponfighting"), "onUpdate", self.onDataChanged);
end
function onClose()
	local nodeWeapon = getDatabaseNode();
	local nodeChar = DB.getChild(nodeWeapon, "...");
	DB.removeHandler(DB.getPath(nodeWeapon, "shortcut"), "onUpdate", self.onLinkChanged);
	DB.removeHandler(DB.getPath(nodeWeapon, "type"), "onUpdate", self.onTypeChanged);
	DB.removeHandler(nodeWeapon, "onChildUpdate", self.onDataChanged);
	DB.removeHandler(DB.getPath(nodeChar, "abilities.*.score"), "onUpdate", self.onDataChanged);
	DB.removeHandler(DB.getPath(nodeChar, "weapon.twoweaponfighting"), "onUpdate", self.onDataChanged);
end

function onLockModeChanged(bReadOnly)
	local tFields = { "type", "name", "idelete", };
	WindowManager.callSafeControlsSetLockMode(self, tFields, bReadOnly);
	--local tFields = { "handling", };
	--WindowManager.callSafeControlsSetLockMode(self, tFields, bReadOnly);

	local sMode = DB.getValue(WindowManager.getTopWindow(self).getDatabaseNode(), "powermode", "");
	WindowManager.callSafeControlsSetVisible(self, { "carried", }, not bReadOnly or (sMode == "preparation"));

	self.onTypeChanged();
	self.onDataChanged();
end
function onModeChanged()
	self.onLockModeChanged(WindowManager.getWindowReadOnlyState(self));
end

local _sClass = "";
local _sRecord = "";
function onLinkChanged()
	local node = getDatabaseNode();
	local sClass, sRecord = DB.getValue(node, "shortcut", "", "");
	if sClass ~= _sClass or sRecord ~= _sRecord then
		_sClass = sClass;
		_sRecord = sRecord;

		local sInvList = DB.getPath(DB.getChild(node, "..."), "inventorylist") .. ".";
		if sRecord:sub(1, #sInvList) == sInvList then
			carried.setLink(DB.findNode(DB.getPath(sRecord, "carried")));
		end
	end
end
function onTypeChanged()
	local node = getDatabaseNode();
	local bRanged = ((DB.getValue(node, "type", 0) ~= 0) and ((DB.getValue(node, "maxammo", 0) ~= 0) or (not WindowManager.getWindowReadOnlyState(self))));
	if bRanged then
		sub_ranged.setValue("char_weapon_ranged", node);
	else
		sub_ranged.setValue("", "");
	end
end
function onProfChanged()
	self.onAttackChanged();
end

function onDataChanged()
	self.onAttackChanged();
	self.onDamageChanged();

	local node = getDatabaseNode();
	local bShowMastery = ((DB.getValue(node, "masteryknown", 0) == 1) and (DB.getValue(node, "mastery", "") ~= ""));
	if bShowMastery then
		sub_mastery.setValue("char_weapon_mastery", node);
	else
		sub_mastery.setValue("", "");
	end
end
function onAttackChanged()
	local nodeWeapon = getDatabaseNode();
	local nodeChar = DB.getChild(nodeWeapon, "...")

	local nMod = CharWeaponManager.getAttackBonus(nodeChar, nodeWeapon);
	button_attack.setTooltipText(string.format("%s: %+d", Interface.getString("action_attack_tag"), nMod));
	attackview.setValue(string.format("%+d", nMod));
end
function onDamageChanged()
	local nodeWeapon = getDatabaseNode();
	local nodeChar = DB.getChild(nodeWeapon, "...")

	local sDamage = CharWeaponManager.buildDamageString(nodeChar, nodeWeapon);
	button_damage.setTooltipText(string.format("%s: %s", Interface.getString("action_damage_tag"), sDamage));
	damageview.setValue(sDamage);
end

function onAttackAction(draginfo)
	local nodeWeapon = getDatabaseNode();
	local nodeChar = DB.getChild(nodeWeapon, "...")

	-- Build basic attack action record
	local rAction = CharWeaponManager.buildAttackAction(nodeChar, nodeWeapon);

	-- Decrement ammo
	if rAction.range == "R" then
		CharWeaponManager.decrementAmmo(nodeChar, nodeWeapon);
	end

	-- Perform action
	local rActor = ActorManager.resolveActor(nodeChar);
	ActionAttack.performRoll(draginfo, rActor, rAction);
	return true;
end
function onDamageAction(draginfo)
	local nodeWeapon = getDatabaseNode();
	local nodeChar = DB.getChild(nodeWeapon, "...")

	-- Build basic damage action record
	local rAction = CharWeaponManager.buildDamageAction(nodeChar, nodeWeapon);

	-- Perform damage action
	local rActor = ActorManager.resolveActor(nodeChar);
	ActionDamage.performRoll(draginfo, rActor, rAction);
	return true;
end
