-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

-- Adjusted
function onInit()
	ItemManager.isPack = isPack;

	ItemManager.isArmor = isArmor;
	ItemManager.isShield = isShield;
	ItemManager.isWeapon = isWeapon;

	ItemManager.registerCleanupTransferHandler(handleItemCleanupOnTransfer);

	-- Replacing CoreRPG function with new function
	-- ToDo Check if it can be removed
	-- ItemManager.getItemSourceType = getItemSourceTypeChronicle
end

function isPack(nodeItem)
	local sTypeLower = StringManager.trim(DB.getValue(nodeItem, "type", "")):lower();
	local sSubtypeLower = StringManager.trim(DB.getValue(nodeItem, "subtype", "")):lower();

	local bIsPack = false;
	if StringManager.startsWith(sTypeLower, "equipment pack") then
		bIsPack = true;
	elseif StringManager.startsWith(sSubtypeLower, "equipment pack") then
		bIsPack = true;
	end
	return bIsPack;
end

function isArmor(nodeItem)
	local sTypeLower = StringManager.trim(DB.getValue(nodeItem, "type", "")):lower();
	return (sTypeLower == "armor");
end

function isShield(nodeItem)
	local sSubtypeLower = StringManager.trim(DB.getValue(nodeItem, "subtype", "")):lower();
	return (sSubtypeLower == "shield");
end

function isWeapon(nodeItem)
	local sTypeLower = StringManager.trim(DB.getValue(nodeItem, "type", "")):lower();
	local sSubtypeLower = StringManager.trim(DB.getValue(nodeItem, "subtype", "")):lower();

	if (sSubtypeLower == "weapon") and (sTypeLower ~= "vehicle component") and (sTypeLower ~= "vehicle component upgrade") then
		sSubtypeLower = sTypeLower;
		sTypeLower = "weapon";
	end

	local bIsWeapon = ((sTypeLower == "weapon") and (sSubtypeLower ~= "ammunition"));
	return bIsWeapon;
end

function handleItemCleanupOnTransfer(rSourceItem, rTempItem, rTargetItem)
	if rSourceItem.sClass ~= "item" then
		if rSourceItem.sClass == "reference_magicitem" then
			DB.setValue(rTempItem.node, "isidentified", "number", 0);
		else
			DB.setValue(rTempItem.node, "isidentified", "number", 1);
		end
	end
end

-- Test
function getItemSourceTypeChronicle(vNode)
	local sPath = nil;
	if type(vNode) == "databasenode" then
		sPath = DB.getPath(vNode);
	elseif type(vNode) == "string" then
		sPath = vNode;
	end
	if not sPath then
		return "";
	end

	local sRecordType = RecordDataManager.getRecordTypeFromRecordPath(sPath);
	if sRecordType ~= "" then
		if RecordDataManager.getRecordTypeOption(sRecordType, "bInventory") then
			return sRecordType;
		end
		return "";
	end

	sRecordType = RecordDataManager.getRecordTypeFromListPath(sPath);
	if sRecordType ~= "" then
		if sRecordType == "item" then
			return sRecordType;
		end
		return "";
	end

	local sParentPath = RecordDataManager.getListPathFromRecordPath(sPath);
	if StringManager.contains({"partysheet", "partysheet.treasureparcelitemlist"}, sPath) or 
			StringManager.contains({"partysheet", "partysheet.treasureparcelitemlist"}, sParentPath) then
		return "partysheet";
	end
	if (sPath == "temp") or (sParentPath == "temp") then
		return "temp";
	end

	for _,sRecordType in ipairs(RecordDataManager.getRecordTypes()) do
		if RecordDataManager.getRecordTypeOption(sRecordType, "bInventory") then
			local tItemPaths = ItemManager.getInventoryPaths(sRecordType);
			for _,sDataPath in ipairs(RecordDataManager.getDataPaths(sRecordType)) do
				for _,sList in ipairs(tItemPaths) do
					local sListPath = string.format("%s.*.%s", sDataPath, sList);
					if UtilityManager.isPathMatch(sListPath, sPath) or UtilityManager.isPathMatch(sListPath, sParentPath) then
						return sRecordType;
					end
				end
			end
		end
	end

	if CombatManager.isTrackerCT(sPath) then
		local sCTPath = CombatManager.getTrackerPath(CombatManager.getTrackerKeyFromCT(sPath));
		local sCTListPath = string.format("%s.*.*", sCTPath);
		if UtilityManager.isPathMatch(sCTListPath, sPath) then
			local sPathSansList = StringManager.splitByPattern(sPath, "%.");
			sPathSansList[#sPathSansList] = nil;
			local sCTRecord = table.concat(sPathSansList, ".");
			sRecordType = RecordDataManager.getRecordTypeFromRecordPath(table.concat(sPathSansList, "."));
			if sRecordType ~= "" then
				if RecordDataManager.getRecordTypeOption(sRecordType, "bInventory") then
					return sRecordType;
				end
				return "";
			end
		end
	end

	return "";
end

-- Added
function getItemSourceTypeChronicle2(vNode)
	local sPath = nil;

	if type(vNode) == "databasenode" then
		sPath = DB.getPath(vNode);
	elseif type(vNode) == "string" then
		sPath = vNode;
	end

	if not sPath then
		return "";
	end

	for _,vMapping in ipairs(LibraryData.getMappings("charsheet")) do
		if StringManager.startsWith(sPath, vMapping) then
			return "charsheet";
		end
		-- Added to allow drops for NPC
		if StringManager.startsWith(sPath, "npc") then
			return "charsheet";
		end
		-- Added to allow drops for Combat Tracker
		if StringManager.startsWith(sPath, "combattracker") then
			return "charsheet";
		end
	end

	for _,vMapping in ipairs(LibraryData.getMappings("item")) do
		if StringManager.startsWith(sPath, vMapping) then
			return "item";
		end
	end

	for _,vMapping in ipairs(LibraryData.getMappings("treasureparcel")) do
		if StringManager.startsWith(sPath, vMapping) then
			return "treasureparcel";
		end
	end

	if StringManager.startsWith(sPath, "partysheet") then
		return "partysheet";
	end

	if StringManager.startsWith(sPath, "temp") then
		return "temp";
	end

	return "";
end