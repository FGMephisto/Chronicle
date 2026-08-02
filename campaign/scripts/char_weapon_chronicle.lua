--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

WEAPON_PROP_TWOHANDED = "twohanded"
WEAPON_PROP_OFFHAND = "offhand"
WEAPON_PROP_DEFENSIVE = "defensive"

-- Adjusted
function onInit()
	self.onLinkChanged();
	self.onLockModeChanged(WindowManager.getWindowReadOnlyState(self));

	local nodeWeapon = getDatabaseNode();
	local nodeChar = DB.getChild(nodeWeapon, "...");
	DB.addHandler(DB.getPath(nodeWeapon, "shortcut"), "onUpdate", self.onLinkChanged);
	DB.addHandler(DB.getPath(nodeWeapon, "type"), "onUpdate", self.onTypeChanged);																			   
	DB.addHandler(nodeWeapon, "onChildUpdate", self.onDataChanged);
	DB.addHandler(DB.getPath(nodeChar, "abilities.*.score"), "onUpdate", onDataChanged);
	DB.addHandler(DB.getPath(nodeChar, "skilllist"), "onChildUpdate", onDataChanged);
end
function onClose()
	local nodeWeapon = getDatabaseNode();
	local nodeChar = DB.getChild(nodeWeapon, "...");
	DB.removeHandler(DB.getPath(nodeWeapon, "shortcut"), "onUpdate", onLinkChanged);
	DB.removeHandler(DB.getPath(nodeWeapon, "type"), "onUpdate", self.onTypeChanged);																				  
	DB.removeHandler(nodeWeapon, "onChildUpdate", onDataChanged);
	DB.removeHandler(DB.getPath(nodeChar, "abilities.*.score"), "onUpdate", onDataChanged);
	DB.removeHandler(DB.getPath(nodeChar, "skilllist"), "onChildUpdate", onDataChanged);
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
	local nodeWeapon = getDatabaseNode();

	local nWeaponType = DB.getValue(nodeWeapon, "wpn_type", 0);
	local sStat = DB.getValue(nodeWeapon, "atk_stat", "");

	if nWeaponType == 0 then
		if sStat ~= "fighting" then
			DB.setValue(nodeWeapon, "atk_stat", "string", Interface.getString("fighting"));
		end
	else
		if sStat ~= "marksmanship" then
			DB.setValue(nodeWeapon, "atk_stat", "string", Interface.getString("marksmanship"));
		end
	end

	self.onLinkChanged();
	self.onAttackChanged();
	self.onDamageChanged();
	self.updateDefenseBonus();
end
function onAttackChanged()
	local nodeWeapon = getDatabaseNode();
	local nodeChar = DB.getChild(nodeWeapon, "...")

	local nMod = DB.getValue(nodeWeapon, "atk_mod", 0);
	local nStat, nSkill, nPenalty, nBonus = CharWeaponManager.getAttackBonus(nodeChar, nodeWeapon);

	nStat = tonumber(nStat) or 0;
	nSkill = tonumber(nSkill) or 0;
	nPenalty = tonumber(nPenalty) or 0;
	nBonus = tonumber(nBonus) or 0;
	nMod = tonumber(nMod) or 0;

	local nWeaponHandling = DB.getValue(nodeWeapon, "wpn_handling", 0);
	local sWeaponGrade = DB.getValue(nodeWeapon, "wpn_grade", "");
	local sWeaponQualities = DB.getValue(nodeWeapon, "wpn_qualities", "");

	if sWeaponGrade == "Poor" then
		nPenalty = nPenalty + 1;
	elseif sWeaponGrade == "Superior" then
		nBonus = nBonus + 1;
	elseif sWeaponGrade == "Extraordinary" then
		nBonus = nBonus + 1;
	end

	if CharWeaponManager.checkProperty(sWeaponQualities, WEAPON_PROP_TWOHANDED) == true and nWeaponHandling ~= 1 then
		nPenalty = nPenalty + 2;
	end

	if atk_dice_test then atk_dice_test.setValue(nStat); end
	if atk_dice_bonus then atk_dice_bonus.setValue(nSkill); end
	if atk_dice_penalty then atk_dice_penalty.setValue(nPenalty); end
	if atk_total then atk_total.setValue(nMod + nBonus); end
end
function onDamageChanged()
	local nodeWeapon = getDatabaseNode();
	local nodeChar = DB.getChild(nodeWeapon, "...")

	local nDamage = tonumber(CharWeaponManager.buildDamageString(nodeChar, nodeWeapon)) or 0;
	-- button_damage.setTooltipText(string.format("%s: %s", Interface.getString("action_damage_tag"), sDamage));

	dmg_total.setValue(nDamage);
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
	ActionDamageD20.performRoll(draginfo, rActor, rAction);
	return true;
end

function updateDefenseBonus()
	local nodeWeapon = getDatabaseNode();
	if not nodeWeapon then return; end
	local nodeChar = DB.getChild(nodeWeapon, "...");
	if not nodeChar then return; end

	local nDefenseBonus = 0;
	local nPropertyValue = 0;

	for _, vNode in pairs(DB.getChildren(nodeChar, "weaponlist")) do
		if DB.getValue(vNode, "carried", 0) == 2 then
			if DB.getValue(vNode, "wpn_handling", 0) == 3 then
				local sWeaponQualities = DB.getValue(vNode, "wpn_qualities", "");
				nPropertyValue = CharWeaponManager.getPropertyValue(sWeaponQualities, WEAPON_PROP_DEFENSIVE);

				if nPropertyValue then
					nDefenseBonus = nDefenseBonus + nPropertyValue;
				end
			end
		end
	end

	local nDefenseTotal = DB.getValue(nodeChar, "abilities.agility.score", 0);
	nDefenseTotal = nDefenseTotal + DB.getValue(nodeChar, "abilities.athletics.score", 0);
	nDefenseTotal = nDefenseTotal + DB.getValue(nodeChar, "abilities.awareness.score", 0);
	nDefenseTotal = nDefenseTotal + nDefenseBonus;
	nDefenseTotal = nDefenseTotal + DB.getValue(nodeChar, "defenses.ac.misc", 0);

	DB.setValue(nodeChar, "defenses.ac.bonus", "number", nDefenseBonus);
	DB.setValue(nodeChar, "defenses.ac.total", "number", nDefenseTotal);
end