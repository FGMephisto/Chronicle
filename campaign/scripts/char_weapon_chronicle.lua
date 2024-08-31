-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

WEAPON_PROP_TWOHANDED = "twohanded"
WEAPON_PROP_OFFHAND = "offhand"
WEAPON_PROP_DEFENSIVE = "defensive"

--
-- Adjusted
--
function onInit()
	local nodeWeapon = getDatabaseNode();
	local nodeChar = DB.getChild(nodeWeapon, "...");

	DB.addHandler(nodeWeapon, "onChildUpdate", onDataChanged);
	DB.addHandler(DB.getPath(nodeChar, "abilities.*.score"), "onUpdate", onDataChanged);
	DB.addHandler(DB.getPath(nodeChar, "skilllist"), "onChildUpdate", onDataChanged);

	onDataChanged();
end


--
-- Adjusted
--
function onClose()
	local nodeWeapon = getDatabaseNode();
	local nodeChar = DB.getChild(nodeWeapon, "...");

	DB.removeHandler(nodeWeapon, "onChildUpdate", onDataChanged);
	DB.removeHandler(DB.getPath(nodeChar, "abilities.*.score"), "onUpdate", onDataChanged);
	DB.removeHandler(DB.getPath(nodeChar, "skilllist"), "onChildUpdate", onDataChanged);
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

--
-- Adjusted
--
function onDataChanged()
	-- Debug.chat("FN: onDataChanged in char_weapon")
	-- Update Attack Attribute and show/hide ammo UI
	local nodeWeapon = getDatabaseNode()
	local nWeaponType = DB.getValue(nodeWeapon, "wpn_type", 0)
	local sStat = DB.getValue(nodeWeapon, "atk_stat")

	if nWeaponType == 0 then
		if sStat ~= "fighting" then
			DB.setValue(nodeWeapon, "atk_stat", "string", Interface.getString("fighting"))
		end
		label_ammo.setVisible(false)
		maxammo.setVisible(false)
		ammocounter.setVisible(false)
	else
		if sStat ~= "marksmanship" then
			DB.setValue(nodeWeapon, "atk_stat", "string", Interface.getString("marksmanship"))
		end
		label_ammo.setVisible(true)
		maxammo.setVisible(true)
		ammocounter.setVisible(true)
	end

	-- Run update functions
	onLinkChanged()
	onAttackChanged()
	onDamageChanged()
	updateDefenseBonus()
end

--
-- Adjusted
--
function onAttackChanged()
	local nodeWeapon = getDatabaseNode();
	local nodeChar = DB.getChild(nodeWeapon, "...")
	local nMod = DB.getValue(nodeWeapon, "atk_mod", 0)
	local nStat, nSkill, nPenalty, nBonus = CharWeaponManager.getAttackBonus(nodeChar, nodeWeapon)

	-- Ensure values are stored as numbers
	nStat = tonumber(nStat)
	nSkill = tonumber(nSkill)
	nPenalty = tonumber(nPenalty)
	nBonus = tonumber(nBonus)
	nMod = tonumber(nMod)

	-- Get weapon data
	local nWeaponHandling = DB.getValue(nodeWeapon, "wpn_handling", 0)
	local sWeaponGrade = DB.getValue(nodeWeapon, "wpn_grade", "")
	local sWeaponQualities = DB.getValue(nodeWeapon, "wpn_qualities", "")

	-- Check Weapon Grade
	if sWeaponGrade == "Poor" then
		nPenalty = nPenalty + 1
	elseif sWeaponGrade == "Superior" then
		nBonus = nBonus + 1
	elseif sWeaponGrade == "Extraordinary" then
		nBonus = nBonus + 1
	end

	-- Check if a two-handed weapon is used with one hand only and apply penalty dice accordingly
	if CharWeaponManager.checkProperty(sWeaponQualities, WEAPON_PROP_TWOHANDED) == true and nWeaponHandling ~= 1 then
		nPenalty = nPenalty + 2
	end

	-- Update controls
	atk_dice_test.setValue(nStat);
	atk_dice_bonus.setValue(nSkill);
	atk_dice_penalty.setValue(nPenalty);
	atk_total.setValue(nMod + nBonus);
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

function onDamageChanged()
	local nodeWeapon = getDatabaseNode();
	local nodeChar = DB.getChild(nodeWeapon, "...")

	-- Get weapon damage
	local nDamage = tonumber(CharWeaponManager.buildDamageString(nodeChar, nodeWeapon));

	-- Set control value
	dmg_total.setValue(nDamage);
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

--
-- Added
--
function updateDefenseBonus()
	-- Debug.chat("FN: updateDefenseBonus in char_weapon")
	local nodeWeapon = getDatabaseNode()
	local nodeChar = DB.getChild(nodeWeapon, "...")
	local nDefenseBonus = 0
	local nPropertyValue = 0

	for _, vNode in pairs(DB.getChildren(nodeChar, "weaponlist")) do
		if DB.getValue(vNode, "carried", 0) == 2 then
			if DB.getValue(vNode, "wpn_handling", 0) == 3 then
				sWeaponQualities = DB.getValue(vNode, "wpn_qualities", "")
				nPropertyValue = CharWeaponManager.getPropertyValue(sWeaponQualities, WEAPON_PROP_DEFENSIVE)

				if nPropertyValue then
					nDefenseBonus = nDefenseBonus + nPropertyValue
				end
			end
		end
	end

	-- Get values and calculate total defense
	local nDefenseTotal = DB.getValue(nodeChar, "abilities.agility.score")
	nDefenseTotal = nDefenseTotal + DB.getValue(nodeChar, "abilities.athletics.score")
	nDefenseTotal = nDefenseTotal + DB.getValue(nodeChar, "abilities.awareness.score")
	nDefenseTotal = nDefenseTotal + nDefenseBonus
	nDefenseTotal = nDefenseTotal + DB.getValue(nodeChar, "defenses.ac.misc")

	-- Set values
	DB.setValue(nodeChar, "defenses.ac.bonus", "number", nDefenseBonus)
	DB.setValue(nodeChar, "defenses.ac.total", "number", nDefenseTotal)
end