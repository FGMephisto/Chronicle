-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System.
--

-- ===================================================================================================================
-- ===================================================================================================================
function addToArmorDB(nodeItem)
	-- Debug.chat("FN: addToArmorDB in manager_char_armor")
	-- Parameter validation
	if not ItemManager.isArmor(nodeItem) then
		return
	end

	-- Determine whether to auto-equip armor
	local bArmorAllowed = true
	local nodeChar = nodeItem.getChild("...")

	if bArmorAllowed then
		local bArmorEquipped = false
		for _,v in pairs(DB.getChildren(nodeItem, "..")) do
			if DB.getValue(v, "carried", 0) == 2 then
				if ItemManager.isArmor(v) then
					bArmorEquipped = true
				end
			end
		end
		if bArmorAllowed and not bArmorEquipped then
			DB.setValue(nodeItem, "carried", "number", 2)
		end
	end
end

-- ===================================================================================================================
-- ===================================================================================================================
function removeFromArmorDB(nodeItem)
	-- Debug.chat("FN: removeFromArmorDB in manager_char_armor")
	-- Parameter validation
	if not ItemManager.isArmor(nodeItem) then
		return
	end
	
	-- If this armor was worn, recalculate AC
	if DB.getValue(nodeItem, "carried", 0) == 2 then
		DB.setValue(nodeItem, "carried", "number", 1)
	end
end

-- ===================================================================================================================
-- ===================================================================================================================
function calcItemArmorClass(nodeChar)
	-- Debug.chat("FN: calcItemArmorClass in manager_char_armor")
	local nAR = 0
	local nAP = 0

	for _,vNode in pairs(DB.getChildren(nodeChar, "inventorylist")) do
		if DB.getValue(vNode, "carried", 0) == 2 then
			if ItemManager.isArmor(vNode) then
				local bID = LibraryData.getIDState("item", vNode, true)
				if bID then
					nAR = nAR + DB.getValue(vNode, "armor_rating", 0)
					nAP = nAP + DB.getValue(vNode, "armor_penalty", 0)
				else
					nAR = 0
					nAP = 0
				end
			end
		end
	end
	
	DB.setValue(nodeChar, "defenses.armor.rating", "number", nAR)
	DB.setValue(nodeChar, "defenses.armor.penalty", "number", nAP)
end
