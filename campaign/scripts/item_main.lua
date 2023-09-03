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

function onDrop(x, y, draginfo)
	local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
	if bReadOnly then
		return false;
	end
	return ItemManager.handleAnyDropOnItemRecord(nodeRecord, draginfo);
end

function update()
	local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
	local bID = LibraryData.getIDState("item", nodeRecord);
	
	local bWeapon = ItemManager.isWeapon(nodeRecord);
	local bArmor = ItemManager.isArmor(nodeRecord);
	local sTypeLower = StringManager.trim(DB.getValue(nodeRecord, "type", "")):lower();
	local bArcaneFocus = (sTypeLower == "rod") or (sTypeLower == "staff") or (sTypeLower == "wand");
	local bVehicleComponent = (sTypeLower == "vehicle component");
	local bLegacyVehicle = (sTypeLower == "waterborne vehicles") or (sTypeLower == "mounts and other animals");
	
	local bSection1 = false;
	if Session.IsHost then
		if WindowManager.callSafeControlUpdate(self, "nonid_name", bReadOnly) then bSection1 = true; end;
	else
		WindowManager.callSafeControlUpdate(self, "nonid_name", bReadOnly, true);
	end
	if (Session.IsHost or not bID) then
		if WindowManager.callSafeControlUpdate(self, "nonidentified", bReadOnly) then bSection1 = true; end;
	else
		WindowManager.callSafeControlUpdate(self, "nonidentified", bReadOnly, true);
	end

	local bSection2 = false;
	if WindowManager.callSafeControlUpdate(self, "type", bReadOnly, not bID) then bSection2 = true; end
	if WindowManager.callSafeControlUpdate(self, "subtype", bReadOnly, not bID) then bSection2 = true; end
	if WindowManager.callSafeControlUpdate(self, "rarity", bReadOnly, not (bID and not bVehicleComponent)) then bSection2 = true; end
	
	local bSection3 = false;
	if WindowManager.callSafeControlUpdate(self, "cost", bReadOnly, not bID) then bSection3 = true; end
	if WindowManager.callSafeControlUpdate(self, "weight", bReadOnly, not (bID and not bVehicleComponent)) then bSection3 = true; end

	local bSection4 = true;
	if Session.IsHost or bID then 
		if bWeapon then
			type_stats.setValue("item_main_weapon", nodeRecord);
		elseif bArmor then
			type_stats.setValue("item_main_armor", nodeRecord);
		elseif bArcaneFocus then
			type_stats.setValue("item_main_arcanefocus", nodeRecord);
		elseif bVehicleComponent then
			type_stats.setValue("item_main_vehicle", nodeRecord);
		elseif bLegacyVehicle then
			type_stats.setValue("item_main_vehicle_legacy", nodeRecord);
		else
			type_stats.setValue("", "");
			bSection4 = false;
		end
	else
		type_stats.setValue("", "");
		bSection4 = false;
	end
	type_stats.update(bReadOnly, bID);

	local bSection5 = false;
	if bReadOnly then
		description.setVisible(bID and not description.isEmpty());
		bSection5 = (description.isVisible())
	else
		description.setVisible(bID);
		bSection5 = bID;
	end
	description.setReadOnly(bReadOnly);
	
	divider.setVisible(bSection1 and bSection2);
	divider2.setVisible((bSection1 or bSection2) and bSection3);
	divider3.setVisible((bSection1 or bSection2 or bSection3) and bSection4);
	divider4.setVisible((bSection1 or bSection2 or bSection3 or bSection4) and bSection5);

	if Session.IsHost or bID then 
		if ItemManager.isPack(nodeRecord) then
			type_lists.setValue("item_main_subitems", nodeRecord);
		elseif bVehicleComponent then
			type_lists.setValue("item_main_vehicle_actions", nodeRecord);
		else
			type_lists.setValue("", "");
		end
	else
		type_lists.setValue("", "");
	end
	type_lists.update(bReadOnly);
end
