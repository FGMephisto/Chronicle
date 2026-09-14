--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function addToArmorDB(nodeItem)
	if not ItemManager.isArmor(nodeItem) then
		return;
	end

	local bArmorEquipped = false;
	for _, v in ipairs(DB.getChildList(nodeItem, "..")) do
		if DB.getValue(v, "carried", 0) == 2 and ItemManager.isArmor(v) then
			bArmorEquipped = true;
			break;
		end
	end
	if not bArmorEquipped then
		DB.setValue(nodeItem, "carried", "number", 2);
	end
end

function removeFromArmorDB(nodeItem)
	if not ItemManager.isArmor(nodeItem) then
		return;
	end

	if DB.getValue(nodeItem, "carried", 0) == 2 then
		DB.setValue(nodeItem, "carried", "number", 1);
	end
end

--
-- CHRONICLE CUSTOM SYSTEMS
--

function calcItemArmorClass(nodeChar)
	local nAR = 0;
	local nAP = 0;

	for _, vNode in ipairs(DB.getChildList(nodeChar, "inventorylist")) do
		if DB.getValue(vNode, "carried", 0) == 2 and ItemManager.isArmor(vNode) then
			local bID = LibraryData.getIDState("item", vNode, true);
			if bID then
				nAR = nAR + DB.getValue(vNode, "armor_rating", 0);
				nAP = nAP + DB.getValue(vNode, "armor_penalty", 0);
			end
		end
	end

	DB.setValue(nodeChar, "defenses.armor.rating", "number", nAR);
	DB.setValue(nodeChar, "defenses.armor.penalty", "number", nAP);
end
