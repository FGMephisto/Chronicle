-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

function addToArmorDB(nodeItem)
	-- Parameter validation
	if not ItemManager.isArmor(nodeItem) then
		return;
	end
	local bIsShield = ItemManager.isShield(nodeItem);
	
	-- Determine whether to auto-equip armor
	local bArmorAllowed = true;
	local bShieldAllowed = true;
	local nodeChar = DB.getChild(nodeItem, "...");
	if CharArmorManager.hasNaturalArmor(nodeChar) then
		bArmorAllowed = false;
		bShieldAllowed = true;
	end
	if CharManager.hasFeature(nodeChar, CharManager.FEATURE_UNARMORED_DEFENSE) then
		bArmorAllowed = false;
		
		for _,v in ipairs(DB.getChildList(nodeChar, "classes")) do
			local sClassName = StringManager.trim(DB.getValue(v, "name", "")):lower();
			if (sClassName == CharManager.CLASS_BARBARIAN) then
				break;
			elseif (sClassName == CharManager.CLASS_MONK) then
				bShieldAllowed = false;
				break;
			end
		end
	end
	if (bArmorAllowed and not bIsShield) or (bShieldAllowed and bIsShield) then
		local bArmorEquipped = false;
		local bShieldEquipped = false;
		for _,v in ipairs(DB.getChildList(nodeItem, "..")) do
			if DB.getValue(v, "carried", 0) == 2 then
				if ItemManager.isArmor(v) then
					if ItemManager.isShield(v) then
						bShieldEquipped = true;
					else
						bArmorEquipped = true;
					end
				end
			end
		end
		if bShieldAllowed and bIsShield and not bShieldEquipped then
			DB.setValue(nodeItem, "carried", "number", 2);
		elseif bArmorAllowed and not bIsShield and not bArmorEquipped then
			DB.setValue(nodeItem, "carried", "number", 2);
		end
	end
end

function removeFromArmorDB(nodeItem)
	-- Parameter validation
	if not ItemManager.isArmor(nodeItem) then
		return;
	end
	
	-- If this armor was worn, recalculate AC
	if DB.getValue(nodeItem, "carried", 0) == 2 then
		DB.setValue(nodeItem, "carried", "number", 1);
	end
end

function hasNaturalArmor(nodeChar)
	return CharManager.hasFeat(nodeChar, CharManager.FEAT_DRAGON_HIDE) or
		CharManager.hasTrait(nodeChar, CharManager.TRAIT_NATURAL_ARMOR) or 
		CharManager.hasTrait(nodeChar, CharManager.TRAIT_ARMORED_CASING) or 
		CharManager.hasTrait(nodeChar, CharManager.TRAIT_CHAMELEON_CARAPACE);
end
function isNaturalArmorTrait(s)
	if not s then
		return false;
	end
	local tTraits = {
		CharManager.TRAIT_NATURAL_ARMOR,
		CharManager.TRAIT_ARMORED_CASING,
		CharManager.TRAIT_CHAMELEON_CARAPACE,
	};
	return StringManager.contains(tTraits, s:lower());
end

--
-- Adjusted
--
function calcItemArmorClass(nodeChar)
	local nAR = 0;
	local nAP = 0;

	for _,vNode in ipairs(DB.getChildList(nodeChar, "inventorylist")) do
		if DB.getValue(vNode, "carried", 0) == 2 then
			if ItemManager.isArmor(vNode) then
				local bID = LibraryData.getIDState("item", vNode, true);
				if bID then
					nAR = nAR + DB.getValue(vNode, "armor_rating", 0);
					nAP = nAP + DB.getValue(vNode, "armor_penalty", 0);
				else
					nAR = 0
					nAP = 0;
				end
			end
		end
	end
	
	DB.setValue(nodeChar, "defenses.armor.rating", "number", nAR);
	DB.setValue(nodeChar, "defenses.armor.penalty", "number", nAP);
end
