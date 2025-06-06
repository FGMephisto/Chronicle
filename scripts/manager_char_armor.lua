--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
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
			local sClassName = StringManager.simplify(DB.getValue(v, "name", ""));
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
	return CharManager.hasFeat2014(nodeChar, CharManager.FEAT_DRAGON_HIDE) or
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

function calcItemArmorClass(nodeChar)
	local nMainArmorTotal = 0;
	local nNaturalArmorTotal = 0;
	local nMainShieldTotal = 0;
	local sMainDexBonus = "";
	local nMainStealthDis = 0;
	local nMainStrRequired = 0;

	local nodeNaturalArmor = CharManager.getTraitRecord(nodeChar, CharManager.TRAIT_NATURAL_ARMOR);
	if nodeNaturalArmor then
		local sNaturalArmorDesc = DB.getText(nodeNaturalArmor, "text", ""):lower();
		if sNaturalArmorDesc:match("your dexterity modifier doesn't affect this number") then
			sMainDexBonus = "no";
		end
		local sNaturalArmorTotal = sNaturalArmorDesc:match("your ac is (%d+)");
		if not sNaturalArmorTotal then
			sNaturalArmorTotal = sNaturalArmorDesc:match("your base ac is (%d+)");
		end
		if not sNaturalArmorTotal then
			sNaturalArmorTotal = sNaturalArmorDesc:match("base ac of (%d+)");
		end
		if sNaturalArmorTotal then
			nNaturalArmorTotal = (tonumber(sNaturalArmorTotal) or 10) - 10;
		end
	end
	local nodeDragonHide = CharManager.getFeatRecord2014(nodeChar, CharManager.FEAT_DRAGON_HIDE);
	if nodeDragonHide then
		local sNaturalArmorDesc = DB.getText(nodeDragonHide, "text", ""):lower();
		local sNaturalArmorTotal = sNaturalArmorDesc:match("your ac as (%d+)");
		if sNaturalArmorTotal then
			local nNewNaturalArmorTotal = (tonumber(sNaturalArmorTotal) or 10) - 10;
			nNaturalArmorTotal = math.max(nNaturalArmorTotal, nNewNaturalArmorTotal);
		end
	end
	local nodeArmoredCasing = CharManager.getTraitRecord(nodeChar, CharManager.TRAIT_ARMORED_CASING);
	if nodeArmoredCasing then
		local sNaturalArmorDesc = DB.getText(nodeArmoredCasing, "text", ""):lower();
		local sNaturalArmorTotal = sNaturalArmorDesc:match("base armor class is (%d+)");
		if sNaturalArmorTotal then
			local nNewNaturalArmorTotal = (tonumber(sNaturalArmorTotal) or 10) - 10;
			nNaturalArmorTotal = math.max(nNaturalArmorTotal, nNewNaturalArmorTotal);
		end
	end
	local nodeChameleonCarapace = CharManager.getTraitRecord(nodeChar, CharManager.TRAIT_CHAMELEON_CARAPACE);
	if nodeChameleonCarapace then
		local sNaturalArmorDesc = DB.getText(nodeChameleonCarapace, "text", ""):lower();
		local sNaturalArmorTotal = sNaturalArmorDesc:match("base armor class of (%d+)");
		if sNaturalArmorTotal then
			local nNewNaturalArmorTotal = (tonumber(sNaturalArmorTotal) or 10) - 10;
			nNaturalArmorTotal = math.max(nNaturalArmorTotal, nNewNaturalArmorTotal);
		end
	end
	local nodeDraconicResilience = CharManager.getFeatureRecord2014(nodeChar, CharManager.FEATURE_DRACONIC_RESILIENCE);
	if nodeDraconicResilience then
		local sNaturalArmorDesc = DB.getText(nodeDraconicResilience, "text", ""):lower();
		local sNaturalArmorTotal = sNaturalArmorDesc:match("your ac equals (%d+)");
		if sNaturalArmorTotal then
			nNaturalArmorTotal = (tonumber(sNaturalArmorTotal) or 10) - 10;
		end
	end

	local bFeatMediumArmorMaster = CharManager.hasFeat(nodeChar, CharManager.FEAT_MEDIUM_ARMOR_MASTER);

	for _,vNode in ipairs(DB.getChildList(nodeChar, "inventorylist")) do
		if DB.getValue(vNode, "carried", 0) == 2 then
			if ItemManager.isArmor(vNode) then
				local bID = LibraryData.getIDState("item", vNode, true);

				if ItemManager.isShield(vNode) then
					if bID then
						nMainShieldTotal = nMainShieldTotal + DB.getValue(vNode, "ac", 0) + DB.getValue(vNode, "bonus", 0);
					else
						nMainShieldTotal = nMainShieldTotal + DB.getValue(vNode, "ac", 0);
					end
				else
					local bMediumArmor = false;
					local sSubType = DB.getValue(vNode, "subtype", "");
					if sSubType:lower():match("^heavy") then
						bHeavyArmor = true;
					elseif sSubType:lower():match("^medium") then
						bMediumArmor = true;
					else
						bLightArmor = true;
					end

					if bID then
						nMainArmorTotal = nMainArmorTotal + (DB.getValue(vNode, "ac", 0) - 10) + DB.getValue(vNode, "bonus", 0);
					else
						nMainArmorTotal = nMainArmorTotal + (DB.getValue(vNode, "ac", 0) - 10);
					end

					if sMainDexBonus ~= "no" then
						local sItemDexBonus = DB.getValue(vNode, "dexbonus", ""):lower();
						if sItemDexBonus:match("yes") then
							local nMaxBonus = tonumber(sItemDexBonus:match("max (%d)")) or 0;
							if nMaxBonus == 2 then
								if bFeatMediumArmorMaster and bMediumArmor then
									if sMainDexBonus == "" then
										sMainDexBonus = "max3";
									end
								else
									if sMainDexBonus == "" or sMainDexBonus == "max3" then
										sMainDexBonus = "max2";
									end
								end
							elseif nMaxBonus == 3 then
								if sMainDexBonus == "" then
									sMainDexBonus = "max3";
								end
							end
						else
							sMainDexBonus = "no";
						end
					end

					local sItemStealth = DB.getValue(vNode, "stealth", ""):lower();
					if sItemStealth == "disadvantage" then
						if not bFeatMediumArmorMaster or not bMediumArmor then
							nMainStealthDis = 1;
						end
					end

					local nItemStrRequired = tonumber(DB.getValue(vNode, "strength", ""):match("(%d+)")) or 0;
					if nItemStrRequired > 0 then
						nMainStrRequired = math.max(nMainStrRequired, nItemStrRequired);
					end
				end
			end
		end
	end

	if CharManager.hasFeat2024(nodeChar, CharManager.FEAT_DEFENSE) and (nMainArmorTotal > 0) then
		nMainArmorTotal = nMainArmorTotal + 1;
	end

	nMainArmorTotal = math.max(nMainArmorTotal, nNaturalArmorTotal);

	DB.setValue(nodeChar, "defenses.ac.armor", "number", nMainArmorTotal);
	DB.setValue(nodeChar, "defenses.ac.shield", "number", nMainShieldTotal);
	DB.setValue(nodeChar, "defenses.ac.dexbonus", "string", sMainDexBonus);
	DB.setValue(nodeChar, "defenses.ac.disstealth", "number", nMainStealthDis);
end
