--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	self.update();
end
function VisDataCleared()
	self.update();
end
function InvisDataAdded()
	self.update();
end

function update()
	local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);

	local bWeapon = ItemManager.isWeapon(nodeRecord);
	local bArmor = ItemManager.isArmor(nodeRecord);
	local sTypeLower = StringManager.trim(DB.getValue(nodeRecord, "type", "")):lower();
	local bArcaneFocus = (sTypeLower == "rod") or (sTypeLower == "staff") or (sTypeLower == "wand");

	local bSection = false;
	if WindowManager.callSafeControlUpdate(self, "type", bReadOnly) then bSection = true; end
	if WindowManager.callSafeControlUpdate(self, "subtype", bReadOnly) then bSection = true; end
	if WindowManager.callSafeControlUpdate(self, "rarity", bReadOnly) then bSection = true; end

	local bSection2 = false;
	if WindowManager.callSafeControlUpdate(self, "cost", bReadOnly) then bSection2 = true; end
	if WindowManager.callSafeControlUpdate(self, "weight", bReadOnly) then bSection2 = true; end

	local bSection3 = false;
	if WindowManager.callSafeControlUpdate(self, "bonus", bReadOnly, not (bWeapon or bArmor or bArcaneFocus)) then bSection3 = true; end
	if WindowManager.callSafeControlUpdate(self, "damage", bReadOnly, not bWeapon) then bSection3 = true; end

	if WindowManager.callSafeControlUpdate(self, "ac", bReadOnly, not bArmor) then bSection3 = true; end
	if WindowManager.callSafeControlUpdate(self, "dexbonus", bReadOnly, not bArmor) then bSection3 = true; end
	if WindowManager.callSafeControlUpdate(self, "strength", bReadOnly, not bArmor) then bSection3 = true; end
	if WindowManager.callSafeControlUpdate(self, "stealth", bReadOnly, not bArmor) then bSection3 = true; end

	if WindowManager.callSafeControlUpdate(self, "properties", bReadOnly, not (bWeapon or bArmor)) then bSection3 = true; end

	description.setReadOnly(bReadOnly);

	divider.setVisible(bSection and bSection2);
	divider2.setVisible((bSection or bSection2) and bSection3);
	divider3.setVisible(bSection or bSection2 or bSection3);
end
