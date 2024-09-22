-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	local nodeWeapon = getDatabaseNode();
	local nodeChar = DB.getChild(nodeWeapon, "...");
	DB.addHandler(nodeWeapon, "onChildUpdate", onDataChanged);
	DB.addHandler(DB.getPath(nodeChar, "abilities.*.score"), "onUpdate", onDataChanged);
	DB.addHandler(DB.getPath(nodeChar, "weapon.twoweaponfighting"), "onUpdate", onDataChanged);

	self.onDataChanged();
end

function onClose()
	local nodeWeapon = getDatabaseNode();
	local nodeChar = DB.getChild(nodeWeapon, "...");
	DB.removeHandler(nodeWeapon, "onChildUpdate", onDataChanged);
	DB.removeHandler(DB.getPath(nodeChar, "abilities.*.score"), "onUpdate", onDataChanged);
	DB.removeHandler(DB.getPath(nodeChar, "weapon.twoweaponfighting"), "onUpdate", onDataChanged);
end

local m_sClass = "";
local m_sRecord = "";
function onLinkChanged()
	local node = getDatabaseNode();
	local sClass, sRecord = DB.getValue(node, "shortcut", "", "");
	if sClass ~= m_sClass or sRecord ~= m_sRecord then
		m_sClass = sClass;
		m_sRecord = sRecord;
		
		local sInvList = DB.getPath(DB.getChild(node, "..."), "inventorylist") .. ".";
		if sRecord:sub(1, #sInvList) == sInvList then
			carried.setLink(DB.findNode(DB.getPath(sRecord, "carried")));
		end
	end
end

function onDataChanged()
	self.onLinkChanged();
	self.onAttackChanged();
	self.onDamageChanged();
	
	local bRanged = (type.getValue() ~= 0);
	label_ammo.setVisible(bRanged);
	maxammo.setVisible(bRanged);
	ammocounter.setVisible(bRanged);
end
function onAttackChanged()
	local nodeWeapon = getDatabaseNode();
	local nodeChar = DB.getChild(nodeWeapon, "...")

	local nMod = CharWeaponManager.getAttackBonus(nodeChar, nodeWeapon);
	attackview.setValue(nMod);
end
function onDamageChanged()
	local nodeWeapon = getDatabaseNode();
	local nodeChar = DB.getChild(nodeWeapon, "...")
	
	local sDamage = CharWeaponManager.buildDamageString(nodeChar, nodeWeapon);
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
