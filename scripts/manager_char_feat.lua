-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function addFeat(nodeChar, sRecord, tData)
	local rAdd = CharBuildDropManager.helperBuildAddStructure(nodeChar, "reference_feat", sRecord, tData);
	CharFeatManager.helperAddFeatMain(rAdd);
end

function getFeatName(rAdd)
	return DB.getValue(rAdd.nodeSource, "name", "");
end
function getFeatPowerGroup(rAdd)
	return Interface.getString("char_feat_powergroup");
end
function getFeatSpellGroup(rAdd)
	return Interface.getString("char_spell_powergroup"):format(CharFeatManager.getFeatName(rAdd));
end

function helperAddFeatMain(rAdd)
	CharBuildDropManager.addFeature(rAdd);
end
function checkFeatSkipAdd(rAdd)
	-- Skip if feat already exists, and is not repeatable
	if DB.getValue(rAdd.nodeSource, "repeatable", 0) ~= 1 then
		if CharManager.hasFeat(rAdd.nodeChar, rAdd.sSourceName) then
			return true;
		end
	end

	return false;
end
function addFeatStandard(rAdd)
	local nodeFeatList = DB.createChild(rAdd.nodeChar, "featlist");
	if not nodeFeatList then
		return nil;
	end

	local nodeNewFeat = DB.createChildAndCopy(nodeFeatList, rAdd.nodeSource);
	if not nodeNewFeat then
		return nil;
	end
	DB.setValue(nodeNewFeat, "locked", "number", 1);

	ChatManager.SystemMessageResource("char_abilities_message_featadd", rAdd.sSourceName, rAdd.sCharName);
	return nodeNewFeat;
end
function checkFeatSpecialHandling(rAdd)
	if not rAdd then
		return true;
	end

	if rAdd.bSource2024 then
		return CharFeatManager.helperCheckFeatSpecialHandling2024(rAdd);
	else
		return CharFeatManager.helperCheckFeatSpecialHandling2014(rAdd);
	end
end
function helperCheckFeatSpecialHandling2024(rAdd)
	if rAdd.bWizard then
		return true;
	end

	if rAdd.sSourceType == "abilityscoreimprovement" then
		CharBuildDropManager.pickAbilityAdjust(rAdd.nodeChar, rAdd.bSource2024);
	elseif StringManager.contains({ "magicinitiatecleric", "magicinitiatedruid", "magicinitiatewizard" }, rAdd.sSourceType) then
		CharFeatManager.helperAddFeatMagicInitiateDrop2024(rAdd);
	elseif rAdd.sSourceType == "skilled" then
		CharFeatManager.helperAddFeatSkilledDrop2024(rAdd);
	elseif rAdd.sSourceType == "feytouched" then
		CharFeatManager.helperAddFeatFeyTouchedDrop2024(rAdd);
	elseif rAdd.sSourceType == "keenmind" then
		CharFeatManager.helperAddFeatKeenMindDrop2024(rAdd);
	elseif rAdd.sSourceType == "observant" then
		CharFeatManager.helperAddFeatObservantDrop2024(rAdd);
	elseif rAdd.sSourceType == "resilient" then
		CharFeatManager.helperAddFeatResilientDrop2024(rAdd);
	elseif rAdd.sSourceType == "ritualcaster" then
		CharFeatManager.helperAddFeatRitualCasterDrop2024(rAdd);
	elseif rAdd.sSourceType == "shadowtouched" then
		CharFeatManager.helperAddFeatShadowTouchedDrop2024(rAdd);
	elseif rAdd.sSourceType == "skillexpert" then
		CharFeatManager.helperAddFeatSkillExpertDrop2024(rAdd);
	elseif rAdd.sSourceType == "telekinetic" then
		CharFeatManager.helperAddFeatTelekineticDrop2024(rAdd);
	elseif rAdd.sSourceType == "telepathic" then
		CharFeatManager.helperAddFeatTelepathicDrop2024(rAdd);
	elseif rAdd.sSourceType == "boonofskill" then
		CharFeatManager.helperAddFeatBoonOfSkillDrop2024(rAdd);
	elseif rAdd.sSourceType == "tough" then
		CharFeatManager.applyTough(rAdd.nodeChar, true);
	else
		CharFeatManager.helperCheckAbilityAdjustments2024(rAdd);
		CharFeatManager.helperCheckMisc2024(rAdd);
		if StringManager.contains({ "mediumarmormaster", "defense", }, rAdd.sSourceType) then
			CharArmorManager.calcItemArmorClass(rAdd.nodeChar);
		end
		return false;
	end
	return true;
end
function helperCheckFeatSpecialHandling2014(rAdd)
	if rAdd.bWizard then
		return true;
	end

	if rAdd.sSourceType == "resilient" then
		CharFeatManager.helperAddFeatResilientDrop2024(rAdd);
	elseif rAdd.sSourceType == "tough" then
		CharFeatManager.applyTough(rAdd.nodeChar, true);
	elseif rAdd.sSourceType == "dragonhide" then
		if CharManager.hasFeature(rAdd.nodeChar, CharManager.FEATURE_UNARMORED_DEFENSE) then
			DB.setValue(rAdd.nodeChar, "defenses.ac.stat2", "string", "");
		end
		CharArmorManager.calcItemArmorClass(rAdd.nodeChar);
	else
		CharFeatManager.helperCheckAbilityAdjustments2014(rAdd);
		CharFeatManager.helperCheckMisc2014(rAdd);
		if StringManager.contains({ "mediumarmormaster", }, rAdd.sSourceType) then
			CharArmorManager.calcItemArmorClass(rAdd.nodeChar);
		end
		return false;
	end
	return true;
end

function helperCheckAbilityAdjustments2024(rAdd)
	if not CharBuildDropManager.helperBuildGetText(rAdd) then
		return;
	end

	-- PHB - Actor, Crossbow Expert, Defensive Duelist, Durable, Great Weapon Master, Keen Mind, 
	-- PHB - Sharpshooter, Shield Master, Skulker, Slasher, 
	-- PHB - Boon of Energy Resistance, Boon of Fortitude, Boon of Recovery, Boon of Speed, 
	local sAbility, sAdj, sMax = rAdd.sSourceText:match("[Ii]ncrease your (%w+) score by (%d+), to a maximum of (%d+)");
	if sAbility then
		CharManager.addAbilityAdjustment(rAdd.nodeChar, sAbility, tonumber(sAdj) or 1, tonumber(sMax) or 20);
		return;
	end

	-- PHB - Athlete, Charger, Chef, Crusher, Dual Wielder, Grappler, Heavily Armored, Heavy Armor Master, 
	-- PHB - Inspiring Leader, Lightly Armored, Mage Slayer, Martial Weapon Training, Medium Armor Master, 
	-- PHB - Moderately Armored, Observant, Polearm Master, Sentinel, Speedy, Weapon Master,
	-- PHB - Boon of Combat Prowess, Boon of Irresistible Offense, 
	local sAbility1, sAbility2, sAdj, sMax = rAdd.sSourceText:match("[Ii]ncrease your (%w+) or (%w+) score by (%d+), to a maximum of (%d+)");
	if sAbility1 then
		local tOptions = { sAbility1, sAbility2, };
		local tData = { nAbilityAdj = tonumber(sAdj) or 1, nAbilityMax = tonumber(sMax) or 20, };
		CharBuildDropManager.pickAbility(rAdd.nodeChar, tOptions, 1, tData);
		return;
	end

	-- PHB - Piercer
	local sAbility1, sAbility2, sAdj, sMax = rAdd.sSourceText:match("[Ii]ncrease your (%w+) or (%w+) by (%d+), to a maximum of (%d+)");
	if sAbility1 then
		local tOptions = { sAbility1, sAbility2, };
		local tData = { nAbilityAdj = tonumber(sAdj) or 1, nAbilityMax = tonumber(sMax) or 20, };
		CharBuildDropManager.pickAbility(rAdd.nodeChar, tOptions, 1, tData);
		return;
	end

	-- PHB - Elemental Adept, Fey-Touched, Mounted Combatant, Ritual Caster, Shadow-Touched, Telekinetic, 
	-- PHB - Telepathic, War Caster, 
	-- PHB - Boon of Dimensional Travel, Boon of Fate, Boon of Spell Recall, Boon of Truesight, 
	local sAbility1, sAbility2, sAbility3, sAdj, sMax = rAdd.sSourceText:match("[Ii]ncrease your (%w+), (%w+), or (%w+) score by (%d+), to a maximum of (%d+)");
	if sAbility1 then
		local tOptions = { sAbility1, sAbility2, sAbility3, };
		local tData = { nAbilityAdj = tonumber(sAdj) or 1, nAbilityMax = tonumber(sMax) or 20, };
		CharBuildDropManager.pickAbility(rAdd.nodeChar, tOptions, 1, tData);
		return;
	end

	-- PHB - Boon of the Night Spirit, 
	local sAbility1, sAbility2, sAbility3, sAbility4, sAdj, sMax = rAdd.sSourceText:match("[Ii]ncrease your (%w+), (%w+), (%w+), or (%w+) score by (%d+), to a maximum of (%d+)");
	if sAbility1 then
		local tOptions = { sAbility1, sAbility2, sAbility3, sAbility4, };
		local tData = { nAbilityAdj = tonumber(sAdj) or 1, nAbilityMax = tonumber(sMax) or 20, };
		CharBuildDropManager.pickAbility(rAdd.nodeChar, tOptions, 1, tData);
		return;
	end

	-- PHB - Skill Expert, 
	local sAdj, sMax = rAdd.sSourceText:match("[Ii]ncrease one ability score of your choice by (%d+), to a maximum of (%d+)");
	if sAdj then
		local tData = { nAbilityAdj = tonumber(sAdj) or 1, nAbilityMax = tonumber(sMax) or 20, };
		CharBuildDropManager.pickAbility(rAdd.nodeChar, nil, 1, tData);
		return;
	end
end
function helperCheckMisc2024(rAdd)
	if not CharBuildDropManager.helperBuildGetText(rAdd) then
		return;
	end

	-- Initiative proficiency
	-- PHB - Alert
	if rAdd.sSourceText:match("When you roll Initiative, you can add your Proficiency Bonus") then
		DB.setValue(rAdd.nodeChar, "initiative.prof", "number", 1);
	end

	-- PHB - Blind Fighting, Skulker
	local sDist = rAdd.sSourceText:match("You have Blindsight with a range of (%d+) feet")
	if sDist then
		CharManager.addSense(rAdd.nodeChar, "Blindsight", sDist);
	end

	-- PHB - Epic Boon of Truesight
	local sDist = rAdd.sSourceText:match("You have Truesight with a range of (%d+) feet")
	if sDist then
		CharManager.addSense(rAdd.nodeChar, "Truesight", sDist);
	end

	-- PHB - Speedy, Boon of Speed
	local sSpeed = rAdd.sSourceText:match("Your Speed increases by (%d+) feet")
	if sSpeed then
		CharManager.addSpeed(rAdd.nodeChar, sSpeed);
	end

	-- PHB - Epic Boon of Fortitude
	local sHP = rAdd.sSourceText:match("Your Hit Point maximum increases by (%d+)")
	if sHP then
		CharManager.addHP(rAdd.nodeChar, sHP);
	end
end

-- Feat - 2024 - Origin
function helperAddFeatMagicInitiateDrop2024(rAdd)
	CharBuildDropManager.pickSpellGroupAbility(rAdd, CharFeatManager.helperOnMagicInitiateFeatSelect);
end
function helperOnMagicInitiateFeatSelect(rAdd)
	local sClassName;
	if rAdd.sSourceType == "magicinitiatecleric" then
		sClassName = "Cleric";
	elseif rAdd.sSourceType == "magicinitiatedruid" then
		sClassName = "Druid";
	elseif rAdd.sSourceType == "magicinitiatewizard" then
		sClassName = "Wizard";
	else
		return;
	end

	rAdd.sSpellGroup = CharFeatManager.getFeatSpellGroup(rAdd);
	CharManager.addPowerGroup(rAdd.nodeChar, { sName = rAdd.sSpellGroup, bChooseSpellAbility = true });

	local tFilters = {
		{ sField = "version", sValue = "2024", },
		{ sField = "level", sValue = "0", },
	};
	local tData = {
		sClassName = sClassName,
		sGroup = rAdd.sSpellGroup,
		bWizard = rAdd.bWizard,
		bSource2024 = rAdd.bSource2024,
		sPickType = "cantrip",
	};
	CharBuildDropManager.pickSpellByFilter(rAdd, tFilters, 2, tData);

	local tFilters = {
		{ sField = "version", sValue = "2024", },
		{ sField = "level", sValue = "1", },
	};
	local tData = {
		sClassName = sClassName,
		sGroup = rAdd.sSpellGroup,
		bWizard = rAdd.bWizard,
		bSource2024 = rAdd.bSource2024,
		sPickType = "prepared",
	};
	CharBuildDropManager.pickSpellByFilter(rAdd, tFilters, 1, tData);
end
function helperAddFeatSkilledDrop2024(rAdd)
	local nPicks = 3;
	local tSkillOptions = CharBuildDropManager.getSkillProficiencyOptions(rAdd.nodeChar);
	local tFilters = {
		{ sField = "version", sValue = "2024", },
		{ sField = "type", sValue = "Tools", bIgnoreCase = true, },
	};
	local tToolOptions = RecordManager.getRecordOptionsByFilter("item", tFilters, true);

	local tOptions = {};
	for _,v in ipairs(tSkillOptions) do
		table.insert(tOptions, v);
	end
	for _,v in ipairs(tToolOptions) do
		table.insert(tOptions, v);
	end

	local tDialogData = {
		title = Interface.getString("char_build_title_selectprofs"),
		msg = Interface.getString("char_build_message_selectprofs"):format(nPicks),
		options = tOptions,
		min = nPicks,
		callback = CharFeatManager.helperOnSkilledFeatSelect,
		custom = { nodeChar = rAdd.nodeChar, tSkillOptions = tSkillOptions, tToolOptions = tToolOptions, },
	};
	DialogManager.requestSelectionDialog(tDialogData);
end
function helperOnSkilledFeatSelect(tSelection, tData)
	for _,s in ipairs(tSelection) do
		local bHandled = false;
		for _,v in ipairs(tData.tSkillOptions) do
			if v.text == s then
				bHandled = true;
				CharManager.addSkillProficiency(tData.nodeChar, s);
				break;
			end
		end
		if not bHandled then
			for _,v in ipairs(tData.tToolOptions) do
				if v.text == s then
					CharManager.addProficiency(tData.nodeChar, "tools", s);
					break;
				end
			end
		end
	end
end

-- Feat - 2024 - General
function helperAddFeatFeyTouchedDrop2024(rAdd)
	rAdd.bSpellGroupAbilityIncrease = true;
	CharBuildDropManager.pickSpellGroupAbility(rAdd, CharFeatManager.helperOnFeyTouchedFeatSelect);
end
function helperOnFeyTouchedFeatSelect(rAdd)
	CharManager.addAbilityAdjustment(rAdd.nodeChar, rAdd.sSpellGroupAbility, 1, 20);

	CharManager.addSpell(rAdd.nodeChar, { sName = "Misty Step", sGroup = rAdd.sSpellGroup, bSource2024 = true, nPrepared = 1, });

	local tFilters = {
		{ sField = "version", sValue = "2024", },
		{ sField = "level", sValue = "1", },
		{ sField = "school", tValues = { "Divination", "Enchantment", }, bIgnoreCase = true, },
	};
	CharBuildDropManager.pickSpellByFilter(rAdd, tFilters, 1, { sPickType = "prepared", });
end
function helperAddFeatKeenMindDrop2024(rAdd)
	CharManager.addAbilityAdjustment(rAdd.nodeChar, "intelligence", 1, 20);
	CharBuildDropManager.pickSkillIncrease(rAdd.nodeChar, { "Arcana", "History", "Investigation", "Nature", "Religion", });
end
function helperAddFeatObservantDrop2024(rAdd)
	CharBuildDropManager.pickAbility(rAdd.nodeChar, { "Intelligence", "Wisdom", }, 1, { nAbilityAdj = 1, nAbilityMax = 20, });
	CharBuildDropManager.pickSkillIncrease(rAdd.nodeChar, { "Insight", "Investigation", "Perception" });
end
function helperAddFeatResilientDrop2024(rAdd)
	local tAbilities = {};
	for _,sAbility in ipairs(DataCommon.abilities) do
		if DB.getValue(rAdd.nodeChar, string.format("abilities.%s.saveprof", sAbility), 0) == 0 then
			table.insert(tAbilities, StringManager.capitalize(sAbility));
		end
	end

	if #tAbilities == 0 then
		return;
	end
	if #tAbilities == 1 then
		CharFeatManager.helperOnResilientFeatSelect(tAbilities, { nodeChar = nodeChar, });
		return;
	end

	local tDialogData = {
		title = Interface.getString("char_build_title_selectabilityincrease"),
		msg = Interface.getString("char_build_message_selectabilityincrease"):format(1, 1),
		options = tAbilities,
		callback = CharFeatManager.helperOnResilientFeatSelect2024,
		custom = { nodeChar = rAdd.nodeChar, },
	};
	DialogManager.requestSelectionDialog(tDialogData);
end
function helperOnResilientFeatSelect2024(tSelection, tData)
	for _,s in ipairs(tSelection) do
		CharManager.addAbilityAdjustment(tData.nodeChar, s:lower(), 1, 20);
		CharManager.addSaveProficiency(tData.nodeChar, s:lower());
	end
end
function helperAddFeatRitualCasterDrop2024(rAdd)
	rAdd.bSpellGroupAbilityIncrease = true;
	CharBuildDropManager.pickSpellGroupAbility(rAdd, CharFeatManager.helperOnRitualCasterFeatSelect);
end
function helperOnRitualCasterFeatSelect(rAdd)
	CharManager.addAbilityAdjustment(rAdd.nodeChar, rAdd.sSpellGroupAbility, 1, 20);

	local nPicks = DB.getValue(rAdd.nodeChar, "profbonus", 2)
	local tFilters = {
		{ sField = "version", sValue = "2024", },
		{ sField = "ritual", sValue = "1", },
	};
	CharBuildDropManager.pickSpellByFilter(rAdd, tFilters, nPicks, { sPickType = "prepared", });
end
function helperAddFeatShadowTouchedDrop2024(rAdd)
	rAdd.bSpellGroupAbilityIncrease = true;
	CharBuildDropManager.pickSpellGroupAbility(rAdd, CharFeatManager.helperOnShadowTouchedFeatSelect);
end
function helperOnShadowTouchedFeatSelect(rAdd)
	CharManager.addAbilityAdjustment(rAdd.nodeChar, rAdd.sSpellGroupAbility, 1, 20);

	CharManager.addSpell(rAdd.nodeChar, { sName = "Invisibility", sGroup = rAdd.sSpellGroup, bSource2024 = true, nPrepared = 1, });

	local tFilters = {
		{ sField = "version", sValue = "2024", },
		{ sField = "level", sValue = "1", },
		{ sField = "school", tValues = { "Illusion", "Necromancy", }, bIgnoreCase = true, },
	};
	CharBuildDropManager.pickSpellByFilter(rAdd, tFilters, 1, { sPickType = "prepared", });
end
function helperAddFeatSkillExpertDrop2024(rAdd)
	CharBuildDropManager.pickAbility(rAdd.nodeChar, nil, 1, { nAbilityAdj = 1, nAbilityMax = 20, });
	
	local tDialogData = {
		title = Interface.getString("char_build_title_selectprofs"),
		msg = Interface.getString("char_build_message_selectprofs"):format(1),
		options = CharBuildDropManager.getSkillProficiencyOptions(rAdd.nodeChar),
		callback = CharFeatManager.helperOnSkillExpertFeatSelect,
		custom = { nodeChar = rAdd.nodeChar, },
	};
	DialogManager.requestSelectionDialog(tDialogData);
end
function helperOnSkillExpertFeatSelect(tSelection, tData)
	for _,s in ipairs(tSelection) do
		CharManager.addSkillProficiency(tData.nodeChar, s);
	end

	CharBuildDropManager.pickSkillExpertise(tData.nodeChar);
end
function helperAddFeatTelekineticDrop2024(rAdd)
	rAdd.bSpellGroupAbilityIncrease = true;
	CharBuildDropManager.pickSpellGroupAbility(rAdd, CharFeatManager.helperOnTelekineticFeatSelect);
end
function helperOnTelekineticFeatSelect(rAdd)
	CharManager.addAbilityAdjustment(rAdd.nodeChar, rAdd.sSpellGroupAbility, 1, 20);
	CharManager.addSpell(rAdd.nodeChar, { sName = "Mage Hand", sGroup = rAdd.sSpellGroup, bSource2024 = true, });
end
function helperAddFeatTelepathicDrop2024(rAdd)
	rAdd.bSpellGroupAbilityIncrease = true;
	CharBuildDropManager.pickSpellGroupAbility(rAdd, CharFeatManager.helperOnTelepathicFeatSelect);
end
function helperOnTelepathicFeatSelect(rAdd)
	CharManager.addAbilityAdjustment(rAdd.nodeChar, rAdd.sSpellGroupAbility, 1, 20);
	CharManager.addSpell(rAdd.nodeChar, { sName = "Detect Thoughts", sGroup = rAdd.sSpellGroup, bSource2024 = true, nPrepared = 1, });
end

-- Feat - 2024 - Epic Boon
function helperAddFeatBoonOfSkillDrop2024(rAdd)
	CharBuildDropManager.pickAbility(rAdd.nodeChar, nil, 1, { nAbilityAdj = 1, nAbilityMax = 30, });

	for s,_ in pairs(DataCommon.skilldata) do
		CharManager.addSkillProficiency(rAdd.nodeChar, s);
	end
	CharBuildDropManager.pickSkillExpertise(rAdd.nodeChar);
end

function helperCheckAbilityAdjustments2014(rAdd)
	if not rAdd or rAdd.bWizard then
		return;
	end
	if not CharBuildDropManager.helperBuildGetText(rAdd) then
		return;
	end

	-- Ability increase
	-- PHB - Actor, Durable, Heavily Armored, Heavy Armor Master, Keen Mind, Linguist
	-- XGtE - Dwarven Fortitude, Infernal Constitution
	local sAbility, nAdj, sAbilityMax = rAdd.sSourceText:match("[Ii]ncrease your (%w+) score by (%d+), to a maximum of (%d+)");
	if sAbility then
		local nAbilityAdj = tonumber(nAdj) or 1;
		local nAbilityMax = tonumber(sAbilityMax) or 20;
		CharManager.addAbilityAdjustment(rAdd.nodeChar, sAbility, nAbilityAdj, nAbilityMax);
		return;
	end

	-- PHB - Athlete, Lightly Armored, Moderately Armored, Observant, Tavern Brawler, Weapon Master
	-- XGtE - Fade Away, Fey Teleportation, Flames of Phlegethos, Orcish Fury, Squat Nimbleness
	local sAbility1, sAbility2, nAdj, sAbilityMax = rAdd.sSourceText:match("[Ii]ncrease your (%w+) or (%w+) score by (%d+), to a maximum of (%d+)");
	if sAbility1 and sAbility2 then
		local tOptions = { sAbility1, sAbility2, };
		local tData = { nAbilityAdj = tonumber(sAdj) or 1, nAbilityMax = tonumber(sMax) or 20, };
		CharBuildDropManager.pickAbility(rAdd.nodeChar, tOptions, 1, tData);
		return;
	end

	-- XGtE - Dragon Fear, Dragon Hide, Second Chance
	local sAbility1, sAbility2, sAbility3, nAdj, sAbilityMax = rAdd.sSourceText:match("[Ii]ncrease your (%w+), (%w+), or (%w+) score by (%d+), to a maximum of (%d+)");
	if sAbility1 and sAbility2 and sAbility3 then
		local tOptions = { sAbility1, sAbility2, sAbility3, };
		local tData = { nAbilityAdj = tonumber(sAdj) or 1, nAbilityMax = tonumber(sMax) or 20, };
		CharBuildDropManager.pickAbility(rAdd.nodeChar, tOptions, 1, tData);
		return;
	end

	-- XGtE - Elven Accuracy
	local sAbility1, sAbility2, sAbility3, sAbility4, nAdj, sAbilityMax = rAdd.sSourceText:match("[Ii]ncrease your (%w+), (%w+), (%w+), or (%w+) score by (%d+), to a maximum of (%d+)");
	if sAbility1 and sAbility2 and sAbility3 and sAbility4 then
		local tOptions = { sAbility1, sAbility2, sAbility3, sAbility4, };
		local tData = { nAbilityAdj = tonumber(sAdj) or 1, nAbilityMax = tonumber(sMax) or 20, };
		CharBuildDropManager.pickAbility(rAdd.nodeChar, tOptions, 1, tData);
		return;
	end
end
function helperCheckMisc2014(rAdd)
	if not rAdd or rAdd.bWizard then
		return;
	end
	if not CharBuildDropManager.helperBuildGetText(rAdd) then
		return;
	end

	-- Initiative increase
	-- PHB - Alert
	local sInitAdj = rAdd.sSourceText:match("gain a ([+-]?%d+) bonus to initiative");
	if sInitAdj then
		nInitAdj = tonumber(sInitAdj) or 0;
		if nInitAdj ~= 0 then
			DB.setValue(rAdd.nodeChar, "initiative.misc", "number", DB.getValue(rAdd.nodeChar, "initiative.misc", 0) + nInitAdj);
			ChatManager.SystemMessageResource("char_abilities_message_initadd", nInitAdj, DB.getValue(rAdd.nodeChar, "name", ""));
		end
	end
	
	-- Passive perception increase
	-- PHB - Observant
	local sPassiveAdj = rAdd.sSourceText:match("have a ([+-]?%d+) bonus to your passive [Ww]isdom %([Pp]erception%)");
	if sPassiveAdj then
		nPassiveAdj = tonumber(sPassiveAdj) or 0;
		if nPassiveAdj ~= 0 then
			DB.setValue(rAdd.nodeChar, "perceptionmodifier", "number", DB.getValue(rAdd.nodeChar, "perceptionmodifier", 0) + nPassiveAdj);
			ChatManager.SystemMessageResource("char_abilities_message_passiveadd", nPassiveAdj, DB.getValue(rAdd.nodeChar, "name", ""));
		end
	end
	
	-- Speed increase
	-- PHB - Mobile
	-- XGtE - Squat Nimbleness
	local sSpeedAdj = rAdd.sSourceText:match("[Yy]our speed increases by (%d+) feet");
	if not sSpeedAdj then
		sSpeedAdj = rAdd.sSourceText:match("[Ii]ncrease your walking speed by (%d+) feet");
	end
	nSpeedAdj = tonumber(sSpeedAdj) or 0;
	if nSpeedAdj > 0 then
		CharManager.addSpeed(rAdd.nodeChar, nSpeedAdj);
		ChatManager.SystemMessageResource("char_abilities_message_basespeedadj", nSpeedAdj, DB.getValue(rAdd.nodeChar, "name", ""));
	end
end

function applyTough(nodeChar, bInitialAdd)
	local nAddHP = 2;
	if bInitialAdd then
		nAddHP = CharManager.getLevel(nodeChar) * 2;
	end
	
	local nHP = DB.getValue(nodeChar, "hp.total", 0);
	nHP = nHP + nAddHP;
	DB.setValue(nodeChar, "hp.total", "number", nHP);
	
	ChatManager.SystemMessageResource("char_abilities_message_hpaddfeat", StringManager.capitalizeAll(CharManager.FEAT_TOUGH), DB.getValue(nodeChar, "name", ""), nAddHP);
end
