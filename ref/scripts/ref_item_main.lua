-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	update();
end

function update()
	local nodeRecord = getDatabaseNode();
	
	local bWeapon = ItemManager.isWeapon(nodeRecord);
	local bArmor = ItemManager.isArmor(nodeRecord);
	local sTypeLower = StringManager.trim(DB.getValue(nodeRecord, "type", "")):lower();
	local bArcaneFocus = (sTypeLower == "rod") or (sTypeLower == "staff") or (sTypeLower == "wand");
	
	local bSection3 = false;
	if WindowManager.callSafeControlUpdate(self, "cost", true) then bSection3 = true; end
	if WindowManager.callSafeControlUpdate(self, "weight", true) then bSection3 = true; end
	
	local bSection4 = false;
	if WindowManager.callSafeControlUpdate(self, "bonus", true, not (bWeapon or bArmor or bArcaneFocus)) then bSection4 = true; end
	if WindowManager.callSafeControlUpdate(self, "damage", true, not bWeapon) then bSection4 = true; end
	
	if WindowManager.callSafeControlUpdate(self, "ac", true, not bArmor) then bSection4 = true; end
	if WindowManager.callSafeControlUpdate(self, "dexbonus", true, not bArmor) then bSection4 = true; end
	if WindowManager.callSafeControlUpdate(self, "strength", true, not bArmor) then bSection4 = true; end

	if WindowManager.callSafeControlUpdate(self, "properties", true, not (bWeapon or bArmor)) then bSection4 = true; end
	
	divider3.setVisible(bSection3 and bSection4);
end
