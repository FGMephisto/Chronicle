-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function addFeat(nodeChar, sClass, sRecord, bWizard)
	local rAdd = CharManager.helperBuildAddStructure(nodeChar, sClass, sRecord, bWizard);
	if not rAdd then
		return;
	end

	CharFeatManager.helperAddFeatMain(rAdd);
end
function helperAddFeatMain(rAdd)
	-- Make sure feat hasn't already been added
	if CharManager.hasFeat(rAdd.nodeChar, rAdd.sSourceName) then
		return;
	end

	-- Add standard feature record
	CharFeatManager.helperAddFeatStandard(rAdd);

	-- Special handling
	local sNameLower = rAdd.sSourceName:lower();
	if sNameLower == CharManager.FEAT_TOUGH then
		CharFeatManager.applyTough(rAdd.nodeChar, true);
	else
		if not rAdd.bWizard then
			CharFeatManager.checkFeatAdjustments(rAdd.nodeChar, DB.getText(rAdd.nodeSource, "text", ""));
		end
		
		if (sNameLower == CharManager.FEAT_DRAGON_HIDE) then
			if CharManager.hasFeature(rAdd.nodeChar, CharManager.FEATURE_UNARMORED_DEFENSE) then
				DB.setValue(rAdd.nodeChar, "defenses.ac.stat2", "string", "");
			end
			CharArmorManager.calcItemArmorClass(rAdd.nodeChar);
		elseif (sNameLower == CharManager.FEAT_MEDIUM_ARMOR_MASTER) then
			CharArmorManager.calcItemArmorClass(rAdd.nodeChar);
		end
	end
	
	return true;
end
function helperAddFeatStandard(rAdd)
	local nodeFeatList = DB.createChild(rAdd.nodeChar, "featlist");
	if not nodeFeatList then
		return nil;
	end

	local nodeNewFeat = DB.createChildAndCopy(nodeFeatList, rAdd.nodeSource);
	if not nodeNewFeat then
		return nil;
	end

	DB.setValue(nodeNewFeat, "locked", "number", 1);
	CharManager.outputUserMessage("char_abilities_message_featadd", rAdd.sSourceName, rAdd.sCharName);

	return nodeNewFeat;
end

function checkFeatAdjustments(nodeChar, sText)
	-- Ability increase
	-- PHB - Actor, Durable, Heavily Armored, Heavy Armor Master, Keen Mind, Linguist
	-- XGtE - Dwarven Fortitude, Infernal Constitution
	local sAbility, nAdj, sAbilityMax = sText:match("[Ii]ncrease your (%w+) score by (%d+), to a maximum of (%d+)");
	if sAbility then
		local nAbilityAdj = tonumber(nAdj) or 1;
		local nAbilityMax = tonumber(sAbilityMax) or 20;
		CharManager.addAbilityAdjustment(nodeChar, sAbility, nAbilityAdj, nAbilityMax);
	else
		-- PHB - Athlete, Lightly Armored, Moderately Armored, Observant, Tavern Brawler, Weapon Master
		-- XGtE - Fade Away, Fey Teleportation, Flames of Phlegethos, Orcish Fury, Squat Nimbleness
		local sAbility1, sAbility2, nAdj, sAbilityMax = sText:match("[Ii]ncrease your (%w+) or (%w+) score by (%d+), to a maximum of (%d+)");
		if sAbility1 and sAbility2 then
			local nAbilityAdj = tonumber(nAdj) or 1;
			local nAbilityMax = tonumber(sAbilityMax) or 20;
			local tAbilitySelect = { { aAbilities = { sAbility1, sAbility2 }, nAbilityAdj = nAbilityAdj, nAbilityMax = nAbilityMax } };
			CharManager.onAbilitySelectDialog(nodeChar, tAbilitySelect);
		else
			-- XGtE - Dragon Fear, Dragon Hide, Second Chance
			local sAbility1, sAbility2, sAbility3, nAdj, sAbilityMax = sText:match("[Ii]ncrease your (%w+), (%w+), or (%w+) score by (%d+), to a maximum of (%d+)");
			if sAbility1 and sAbility2 and sAbility3 then
				local nAbilityAdj = tonumber(nAdj) or 1;
				local nAbilityMax = tonumber(sAbilityMax) or 20;
				local tAbilitySelect = { { aAbilities = { sAbility1, sAbility2, sAbility3 }, nAbilityAdj = nAbilityAdj, nAbilityMax = nAbilityMax } };
				CharManager.onAbilitySelectDialog(nodeChar, tAbilitySelect);
			else
				-- XGtE - Elven Accuracy
				local sAbility1, sAbility2, sAbility3, sAbility4, nAdj, sAbilityMax = sText:match("[Ii]ncrease your (%w+), (%w+), (%w+), or (%w+) score by (%d+), to a maximum of (%d+)");
				if sAbility1 and sAbility2 and sAbility3 and sAbility4 then
					local nAbilityAdj = tonumber(nAdj) or 1;
					local nAbilityMax = tonumber(sAbilityMax) or 20;
					local tAbilitySelect = { { aAbilities = { sAbility1, sAbility2, sAbility3, sAbility4 }, nAbilityAdj = nAbilityAdj, nAbilityMax = nAbilityMax } };
					CharManager.onAbilitySelectDialog(nodeChar, tAbilitySelect);
				else
					-- PHB - Resilient
					local nAdj, sAbilityMax = sText:match("[Ii]ncrease the chosen ability score by (%d+), to a maximum of (%d+)");
					if nAdj and sAbilityMax then
						local nAbilityAdj = tonumber(nAdj) or 1;
						local nAbilityMax = tonumber(sAbilityMax) or 20;
						local tAbilitySelect = { { nAbilityAdj = nAbilityAdj, nAbilityMax = nAbilityMax, bSaveProfAdd = true } };
						CharManager.onAbilitySelectDialog(nodeChar, tAbilitySelect);
					end
				end
			end
		end
	end
	
	-- Armor proficiency
	-- PHB - Heavily Armored, Moderately Armored, Lightly Armored
	local sArmorProf = sText:match("gain proficiency with (%w+) armor and shields");
	if sArmorProf then
		CharManager.addProficiency(nodeChar, "armor", StringManager.capitalize(sArmorProf) .. ", shields");
	else
		sArmorProf = sText:match("gain proficiency with (%w+) armor");
		if sArmorProf then
			CharManager.addProficiency(nodeChar, "armor", StringManager.capitalize(sArmorProf));
		end
	end
	
	-- Weapon proficiency
	-- PHB - Tavern Brawler, Weapon Master
	if sText:match("are proficient with improvised weapons") then
		CharManager.addProficiency(nodeChar, "weapons", "Improvised");
	else
		local sWeaponProfChoices = sText:match("gain proficiency with (%w+) weapons? of your choice");
		if sWeaponProfChoices then
			local nWeaponProfChoices = CharManager.convertSingleNumberTextToNumber(sWeaponProfChoices);
			if nWeaponProfChoices > 0 then
				CharManager.addProficiency(nodeChar, "weapons", "Choice (x" .. nWeaponProfChoices .. ")");
			end
		end
	end
	
	-- Skill proficiency
	-- XGtE - Prodigy
	if sText:match("one skill proficiency of your choice") then
		CharManager.pickSkills(nodeChar, nil, 1);
	else
		-- XGtE - Squat Nimbleness
		local sSkillProf, sSkillProf2 = sText:match("gain proficiency in the (%w+) or (%w+) skill");
		if sSkillProf and sSkillProf2 then
			CharManager.pickSkills(nodeChar, { sSkillProf, sSkillProf2 }, 1);
		else
			-- PHB - Skilled
			local sSkillPicks = sText:match("gain proficiency in any combination of (%w+) skills or tools");
			local nSkillPicks = CharManager.convertSingleNumberTextToNumber(sSkillPicks);
			if nSkillPicks > 0 then
				CharManager.pickSkills(nodeChar, nil, nSkillPicks);
			end
		end
	end
	
	-- Tool proficiency
	-- XGtE - Prodigy
	if sText:match("one tool proficiency of your choice") then
		CharManager.addProficiency(nodeChar, "tools", "Choice");
	end
	
	-- Extra language choices
	-- PHB - Linguist
	local sLanguagePicks = sText:match("learn (%w+) languages? of your choice");
	if sLanguagePicks then
		local nPicks = CharManager.convertSingleNumberTextToNumber(sLanguagePicks);
		if nPicks == 1 then
			CharManager.addLanguage(nodeChar, "Choice");
		elseif nPicks > 1 then
			CharManager.addLanguage(nodeChar, "Choice (x" .. nPicks .. ")");
		end
	else
		-- Known languages
		-- XGtE - Fey Teleportation
		local sLanguage = sText:match("learn to speak, read, and write (%w+)");
		if sLanguage then
			CharManager.addLanguage(nodeChar, sLanguage);
		else
			-- Known languages
			-- XGtE - Prodigy
			if sText:match("fluency in one language of your choice") then
				CharManager.addLanguage(nodeChar, "Choice");
			end
		end
	end
	
	-- Initiative increase
	-- PHB - Alert
	local sInitAdj = sText:match("gain a ([+-]?%d+) bonus to initiative");
	if sInitAdj then
		nInitAdj = tonumber(sInitAdj) or 0;
		if nInitAdj ~= 0 then
			DB.setValue(nodeChar, "initiative.misc", "number", DB.getValue(nodeChar, "initiative.misc", 0) + nInitAdj);
			CharManager.outputUserMessage("char_abilities_message_initadd", nInitAdj, DB.getValue(nodeChar, "name", ""));
		end
	end
	
	-- Passive perception increase
	-- PHB - Observant
	local sPassiveAdj = sText:match("have a ([+-]?%d+) bonus to your passive [Ww]isdom %([Pp]erception%)");
	if sPassiveAdj then
		nPassiveAdj = tonumber(sPassiveAdj) or 0;
		if nPassiveAdj ~= 0 then
			DB.setValue(nodeChar, "perceptionmodifier", "number", DB.getValue(nodeChar, "perceptionmodifier", 0) + nPassiveAdj);
			CharManager.outputUserMessage("char_abilities_message_passiveadd", nPassiveAdj, DB.getValue(nodeChar, "name", ""));
		end
	end
	
	-- Speed increase
	-- PHB - Mobile
	-- XGtE - Squat Nimbleness
	local sSpeedAdj = sText:match("[Yy]our speed increases by (%d+) feet");
	if not sSpeedAdj then
		sSpeedAdj = sText:match("[Ii]ncrease your walking speed by (%d+) feet");
	end
	nSpeedAdj = tonumber(sSpeedAdj) or 0;
	if nSpeedAdj > 0 then
		DB.setValue(nodeChar, "speed.misc", "number", DB.getValue(nodeChar, "speed.misc", 0) + nSpeedAdj);
		CharManager.outputUserMessage("char_abilities_message_basespeedadj", nSpeedAdj, DB.getValue(nodeChar, "name", ""));
	end
end
function applyTough(nodeChar, bInitialAdd)
	local nAddHP = 2;
	if bInitialAdd then
		nAddHP = CharClassManager.getCharLevel(nodeChar) * 2;
	end
	
	local nHP = DB.getValue(nodeChar, "hp.total", 0);
	nHP = nHP + nAddHP;
	DB.setValue(nodeChar, "hp.total", "number", nHP);
	
	CharManager.outputUserMessage("char_abilities_message_hpaddfeat", StringManager.capitalizeAll(CharManager.FEAT_TOUGH), DB.getValue(nodeChar, "name", ""), nAddHP);
end
