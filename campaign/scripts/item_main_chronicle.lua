-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

function onInit()
	self.update();
end

function onTypeChanged()
	self.update();
end
function onVersionChanged()
	self.update();
end

function update()
	local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
	local bID = LibraryData.getIDState("item", nodeRecord);

	WindowManager.callSafeControlUpdate(self, "sub_nonid", bReadOnly, bID);
	WindowManager.callSafeControlUpdate(self, "sub_standard", bReadOnly, bID);
	WindowManager.callSafeControlUpdate(self, "sub_type", bReadOnly, bID);
	WindowManager.callSafeControlUpdate(self, "sub_pack", bReadOnly, bID);

	if bReadOnly then
		description.setVisible(bID and not description.isEmpty());
	else
		description.setVisible(bID);
	end
	description.setReadOnly(bReadOnly);
end

function onDrop(x, y, draginfo)
	local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
	if bReadOnly then
		return false;
	end
	return ItemManager.handleAnyDropOnItemRecord(nodeRecord, draginfo);
end

-- Added
function onClose()
	self.update()

	local nodeRecord = getDatabaseNode()
	local bWeapon = ItemManager.isWeapon(nodeRecord)
	local bArmor = ItemManager.isArmor(nodeRecord)

	if not bArmor then
		DB.deleteChild(nodeRecord, "armor_penalty")
		DB.deleteChild(nodeRecord, "armor_rating")
	end

	if not bWeapon then
		DB.deleteChild(nodeRecord, "weapon_dmg_ability")
		DB.deleteChild(nodeRecord, "weapon_dmg_bonus")
		DB.deleteChild(nodeRecord, "weapon_dmg_string")
		DB.deleteChild(nodeRecord, "weapon_speciality")
		DB.deleteChild(nodeRecord, "weapon_training")
		DB.deleteChild(nodeRecord, "weapon_qualities")
	end
end