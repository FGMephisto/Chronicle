-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

CLASS_ARTIFICER = "artificer";
CLASS_BARBARIAN = "barbarian";
CLASS_BARD = "bard";
CLASS_FIGHTER = "fighter";
CLASS_MONK = "monk";
CLASS_PALADIN = "paladin";
CLASS_RANGER = "ranger";
CLASS_ROGUE = "rogue";
CLASS_SORCERER = "sorcerer";
CLASS_WIZARD = "wizard";

TRAIT_ARMORED_CASING = "armored casing";
TRAIT_CHAMELEON_CARAPACE = "chameleon carapace";
TRAIT_DWARVEN_TOUGHNESS = "dwarven toughness";
TRAIT_GNOME_CUNNING = "gnome cunning";
TRAIT_HIPPO_BUILD = "hippo build";
TRAIT_LITTLE_GIANT = "little giant";
TRAIT_LUCK = "luck";
TRAIT_LUCKY = "lucky";
TRAIT_NATURAL_ARMOR = "natural armor";
TRAIT_POWERFUL_BUILD = "powerful build";
TRAIT_RESOURCEFUL = "resourceful";

FEATURE_ABJURATION_SAVANT = "abjuration savant";
FEATURE_ASPECT_OF_THE_BEAR = "aspect of the bear";
FEATURE_DIVINATION_SAVANT = "divination savant";
FEATURE_DRACONIC_RESILIENCE = "draconic resilience";
FEATURE_ELDRITCH_INVOCATION_ELDRITCH_MIND = "eldritch invocation (eldritch mind)";
FEATURE_EVASION = "evasion";
FEATURE_EVOCATION_SAVANT = "evocation savant";
FEATURE_ILLUSION_SAVANT = "illusion savant";
FEATURE_IMPROVED_CRITICAL = "improved critical";
FEATURE_JACK_OF_ALL_TRADES = "jack of all trades";
FEATURE_RELIABLE_TALENT = "reliable talent";
FEATURE_SILVER_TONGUE = "silver tongue";
FEATURE_SUPERIOR_CRITICAL = "superior critical";
FEATURE_UNARMORED_DEFENSE = "unarmored defense";
FEATURE_BODY_AND_MIND = "body and mind";

FEAT_ARCHERY = "archery"; -- 2024
FEAT_DEFENSE = "defense"; -- 2024
FEAT_DRAGON_HIDE = "dragon hide"; -- 2014
FEAT_DUELING = "dueling"; -- 2024
FEAT_DURABLE = "durable"; -- 2014
FEAT_ELVEN_ACCURACY = "elven accuracy"; -- 2014
FEAT_GREAT_WEAPON_FIGHTING = "great weapon fighting"; -- 2024
FEAT_HEALER = "healer"; -- 2024
FEAT_MAGE_SLAYER = "mage slayer"; -- 2024 / 2014
FEAT_MEDIUM_ARMOR_MASTER = "medium armor master"; -- 2024 / 2014
FEAT_TOUGH = "tough"; -- 2024 / 2014
FEAT_THROWN_WEAPON_FIGHTING = "thrown weapon fighting"; -- 2024
FEAT_TWO_WEAPON_FIGHTING = "two-weapon fighting"; -- 2024
FEAT_WAR_CASTER = "war caster"; -- 2024 / 2014 

function onInit()
	ItemManager.setCustomCharAdd(CharManager.onCharItemAdd);
	ItemManager.setCustomCharRemove(CharManager.onCharItemDelete);

	if Session.IsHost then
		CharInventoryManager.enableInventoryUpdates();
		CharInventoryManager.enableSimpleLocationHandling();

		CharInventoryManager.registerFieldUpdateCallback("carried", CharManager.onCharInventoryArmorCalc);

		CharInventoryManager.registerFieldUpdateCallback("isidentified", CharManager.onCharInventoryArmorCalcIfCarried);
		CharInventoryManager.registerFieldUpdateCallback("bonus", CharManager.onCharInventoryArmorCalcIfCarried);
		CharInventoryManager.registerFieldUpdateCallback("ac", CharManager.onCharInventoryArmorCalcIfCarried);
		CharInventoryManager.registerFieldUpdateCallback("dexbonus", CharManager.onCharInventoryArmorCalcIfCarried);
		CharInventoryManager.registerFieldUpdateCallback("stealth", CharManager.onCharInventoryArmorCalcIfCarried);
		CharInventoryManager.registerFieldUpdateCallback("strength", CharManager.onCharInventoryArmorCalcIfCarried);
	end
end

-- Legacy
function outputUserMessage(sResource, ...)
	ChatManager.SystemMessageResource(sResource, ...);
end

--
--	CALLBACK REGISTRATIONS
--

function onCharItemAdd(nodeItem)
	local sTypeLower = StringManager.simplify(DB.getValue(DB.getPath(nodeItem, "type"), ""));
	if StringManager.contains({ "mountsandotheranimals", "waterbornevehicles", "tackharnessanddrawnvehicles" }, sTypeLower) then
		DB.setValue(nodeItem, "carried", "number", 0);
	else
		DB.setValue(nodeItem, "carried", "number", 1);
	end
	
	CharArmorManager.addToArmorDB(nodeItem);
	CharWeaponManager.addToWeaponDB(nodeItem);
end
function onCharItemDelete(nodeItem)
	CharArmorManager.removeFromArmorDB(nodeItem);
	CharWeaponManager.removeFromWeaponDB(nodeItem);
end

function onCharInventoryArmorCalcIfCarried(nodeItem, sField)
	if DB.getValue(nodeItem, "carried", 0) == 2 then
		CharManager.onCharInventoryArmorCalc(nodeItem, sField);
	end
end
function onCharInventoryArmorCalc(nodeItem, sField)
	if ItemManager.isArmor(nodeItem) then
		local nodeChar = DB.getChild(nodeItem, "...");
		CharArmorManager.calcItemArmorClass(nodeChar);
	end
end

--
-- ACTIONS
--

function rest(nodeChar, bLong)
	PowerManager.resetPowers(nodeChar, bLong);
	CharManager.resetHealth(nodeChar, bLong);
	if bLong then
		CombatManager2.reduceExhaustion(ActorManager.getCTNode(nodeChar));

		if CharManager.hasTrait(nodeChar, CharManager.TRAIT_RESOURCEFUL) then
			if DB.getValue(nodeChar, "inspiration", 0) <= 0 then
				DB.setValue(nodeChar, "inspiration", "number", 1);
			end
		end
	end
end
function resetHealth(nodeChar, bLong)
	local bResetWounds = false;
	local bResetTemp = false;
	local bResetHitDice = false;
	local bResetHalfHitDice = false;
	local bResetQuarterHitDice = false;
	
	local sOptHRHV = OptionsManager.getOption("HRHV");
	if sOptHRHV == "fast" then
		if bLong then
			bResetWounds = true;
			bResetTemp = true;
			bResetHitDice = true;
		else
			bResetQuarterHitDice = true;
		end
	elseif sOptHRHV == "slow" then
		if bLong then
			bResetTemp = true;
			bResetHalfHitDice = true;
		end
	else
		if bLong then
			bResetWounds = true;
			bResetTemp = true;
			bResetHalfHitDice = true;
		end
	end
	
	-- Reset health fields and conditions
	if bResetWounds then
		DB.setValue(nodeChar, "hp.wounds", "number", 0);
		DB.setValue(nodeChar, "hp.deathsavesuccess", "number", 0);
		DB.setValue(nodeChar, "hp.deathsavefail", "number", 0);
	end
	if bResetTemp then
		DB.setValue(nodeChar, "hp.temporary", "number", 0);
	end
	
	-- Reset all hit dice
	if bResetHitDice then
		for _,vClass in ipairs(DB.getChildList(nodeChar, "classes")) do
			DB.setValue(vClass, "hdused", "number", 0);
		end
	end

	-- Reset half or quarter of hit dice (assume biggest hit dice selected first)
	if bResetHalfHitDice or bResetQuarterHitDice then
		local nHDUsed, nHDTotal = CharManager.getClassHDUsage(nodeChar);
		if nHDUsed > 0 then
			local nHDRecovery;
			if bResetQuarterHitDice then
				nHDRecovery = math.max(math.floor(nHDTotal / 4), 1);
			else
				nHDRecovery = math.max(math.floor(nHDTotal / 2), 1);
			end
			if nHDRecovery >= nHDUsed then
				for _,vClass in ipairs(DB.getChildList(nodeChar, "classes")) do
					DB.setValue(vClass, "hdused", "number", 0);
				end
			else
				local nodeClassMax, nClassMaxHDSides, nClassMaxHDUsed;
				while nHDRecovery > 0 do
					nodeClassMax = nil;
					nClassMaxHDSides = 0;
					nClassMaxHDUsed = 0;
					
					for _,vClass in ipairs(DB.getChildList(nodeChar, "classes")) do
						local nClassHDUsed = DB.getValue(vClass, "hdused", 0);
						if nClassHDUsed > 0 then
							local aClassDice = DB.getValue(vClass, "hddie", {});
							if #aClassDice > 0 then
								local nClassHDSides = tonumber(aClassDice[1]:sub(2)) or 0;
								if nClassHDSides > 0 and nClassMaxHDSides < nClassHDSides then
									nodeClassMax = vClass;
									nClassMaxHDSides = nClassHDSides;
									nClassMaxHDUsed = nClassHDUsed;
								end
							end
						end
					end
					
					if nodeClassMax then
						if nHDRecovery >= nClassMaxHDUsed then
							DB.setValue(nodeClassMax, "hdused", "number", 0);
							nHDRecovery = nHDRecovery - nClassMaxHDUsed;
						else
							DB.setValue(nodeClassMax, "hdused", "number", nClassMaxHDUsed - nHDRecovery);
							nHDRecovery = 0;						
						end
					else
						break;
					end
				end
			end
		end
	end
end

function messageInspiration(nodeChar, nAdj)
	if not nodeChar or ((nAdj or 0) == 0) then
		return;
	end

	local msg = {
		sender = DB.getValue(nodeChar, "name", ""),
		icon = "charlist_inspiration",
		font = "systemfont",
		text = Interface.getString((nAdj > 0) and "char_message_inspiration_gained" or "char_message_inspiration_used"),
	};
	Comm.deliverChatMessage(msg);
end

--
-- LINK HANDLING
--

function onClassLinkPressed(nodeCharClass)
	local _, sRecord = DB.getValue(nodeCharClass, "shortcut", "", "");
	if CharManager.helperOpenLinkRecord("class", sRecord) then
		return true;
	end
	local sName = DB.getValue(nodeCharClass, "name", "");
	local bIs2024 = (DB.getValue(nodeCharClass, "version", "") == "2024");
	if CharManager.helperOpenAltLinkRecord("class", sName, bIs2024) then
		return true;
	end
	CharManager.helperOpenLinkRecordFail("class");
	return false;	
end
function onSubclassLinkPressed(nodeCharClass)
	local _, sRecord = DB.getValue(nodeCharClass, "specializationlink", "", "");
	if CharManager.helperOpenLinkRecord("class_specialization", sRecord) then
		return true;
	end
	local sName = DB.getValue(nodeCharClass, "specialization", "");
	local bIs2024 = (DB.getValue(nodeCharClass, "specializationversion", "") == "2024");
	if CharManager.helperOpenAltLinkRecord("class_specialization", sName, bIs2024) then
		return true;
	end
	CharManager.helperOpenLinkRecordFail("class_specialization");
	return false;	
end
function onBackgroundLinkPressed(nodeChar)
	local _, sRecord = DB.getValue(nodeChar, "backgroundlink", "", "");
	if CharManager.helperOpenLinkRecord("background", sRecord) then
		return true;
	end
	local sName = DB.getValue(nodeChar, "background", "");
	local bIs2024 = (DB.getValue(nodeChar, "backgroundversion", "") == "2024");
	if CharManager.helperOpenAltLinkRecord("background", sName, bIs2024) then
		return true;
	end
	CharManager.helperOpenLinkRecordFail("background");
	return false;	
end
function onSpeciesLinkPressed(nodeChar)
	local _, sRecord = DB.getValue(nodeChar, "racelink", "", "");
	if CharManager.helperOpenLinkRecord("race", sRecord) then
		return true;
	end
	local sName = DB.getValue(nodeChar, "racename", "");
	local bIs2024 = (DB.getValue(nodeChar, "raceversion", "") == "2024");
	if CharManager.helperOpenAltLinkRecord("race", sName, bIs2024) then
		return true;
	end
	CharManager.helperOpenLinkRecordFail("race");
	return false;
end
function onAncestryLinkPressed(nodeChar)
	local _, sRecord = DB.getValue(nodeChar, "subracelink", "", "");
	if CharManager.helperOpenLinkRecord("race_subrace", sRecord) then
		return true;
	end
	local sName = DB.getValue(nodeChar, "subracename", "");
	local bIs2024 = (DB.getValue(nodeChar, "subraceversion", "") == "2024");
	if CharManager.helperOpenAltLinkRecord("race_subrace", sName, bIs2024) then
		return true;
	end
	CharManager.helperOpenLinkRecordFail("race_subrace");
	return false;
end
function helperOpenLinkRecord(sRecordType, sRecord)
	if ((sRecord or "") == "") or ((sRecordType or "") == "") then
		return false;
	end
	local nodeRecord = DB.findNode(sRecord);
	if nodeRecord then
		local sDisplayClass = RecordDataManager.getRecordTypeDisplayClass(sRecordType, nodeRecord);
		Interface.openWindow(sDisplayClass, nodeRecord);
		return true;
	end
	return false;
end
function helperOpenAltLinkRecord(sRecordType, sName, bIs2024)
	if ((sName or "") == "") or ((sRecordType or "") == "") then
		return false;
	end
	local tFilters = {
		{ sField = "name", sValue = sName, bIgnoreCase = true, },
		{ sField = "version", sValue = (bIs2024 and "2024" or ""), },
	};
	local nodeRecord = RecordManager.findRecordByFilter(sRecordType, tFilters);
	if nodeRecord then
		local sDisplayClass = RecordDataManager.getRecordTypeDisplayClass(sRecordType, nodeRecord);
		Interface.openWindow(sDisplayClass, nodeRecord);
		return true;
	end
	return false;
end
function helperOpenLinkRecordFail(sRecordType)
	local sDisplay = LibraryData.getSingleDisplayText(sRecordType);
	ChatManager.SystemMessage(string.format(Interface.getString("char_error_missinglink"), sDisplay));
end

--
-- CHARACTER CHECKS
--

function hasFeat(nodeChar, s)
	return (CharManager.getFeatRecord(nodeChar, s) ~= nil);
end
function hasFeat2024(nodeChar, s)
	return (CharManager.getFeatRecord2024(nodeChar, s) ~= nil);
end
function hasFeat2014(nodeChar, s)
	return (CharManager.getFeatRecord2014(nodeChar, s) ~= nil);
end
function hasFeature(nodeChar, s)
	return (CharManager.getFeatureRecord(nodeChar, s) ~= nil);
end
function hasGroupPower(nodeChar, sGroup, s)
	return (CharManager.getGroupPowerRecord(nodeChar, sGroup, s) ~= nil);
end
function hasLanguage(nodeChar, s)
	return (CharManager.getLanguageRecord(nodeChar, s) ~= nil);
end
function hasSaveProficiency(nodeChar, s)
	if not nodeChar or ((s or "") == "") then
		return false;
	end
	local sLower = s:lower();
	if not StringManager.contains(DataCommon.abilities, sLower) then
		return false;
	end
	return (DB.getValue(nodeChar, "abilities." .. sLower .. ".saveprof", 0) == 1);
end
function hasSkill(nodeChar, s)
	return (CharManager.getSkillRecord(nodeChar, s) ~= nil);
end
function hasSkillProficiency(nodeChar, s)
	local nodeSkill = CharManager.getSkillRecord(nodeChar, s);
	if not nodeSkill then
		return false;
	end
	local nSkillProf = DB.getValue(nodeSkill, "prof", 0);
	return ((nSkillProf == 1) or (nSkillProf == 2));
end
function hasSkillExpertise(nodeChar, s)
	local nodeSkill = CharManager.getSkillRecord(nodeChar, s);
	if not nodeSkill then
		return false;
	end
	return (DB.getValue(nodeSkill, "prof", 0) == 2);
end
function hasTrait(nodeChar, s)
	return (CharManager.getTraitRecord(nodeChar, s) ~= nil);
end

--
-- CHARACTER DATA
--

function getAbility(nodeChar, s)
	if (s or "") == "" then
		return 0;
	end
	return DB.getValue(nodeChar, string.format("abilities.%s.score", s:lower()), 0);
end

function getLevel(nodeChar)
	if not nodeChar then
		return 0;
	end
	local nTotal = 0;
	for _,nodeClass in ipairs(DB.getChildList(nodeChar, "classes")) do
		local nClassLevel = DB.getValue(nodeClass, "level", 0);
		if nClassLevel > 0 then
			nTotal = nTotal + nClassLevel;
		end
	end
	return nTotal;
end
function getNextLevelXP(nodeChar)
	local nCharLevel = CharManager.getLevel(nodeChar);
	if nCharLevel < 2 then
		return 300;
	elseif nCharLevel == 2 then
		return 900;
	elseif nCharLevel == 3 then
		return 2700;
	elseif nCharLevel == 4 then
		return 6500;
	elseif nCharLevel == 5 then
		return 14000;
	elseif nCharLevel == 6 then
		return 23000;
	elseif nCharLevel == 7 then
		return 34000;
	elseif nCharLevel == 8 then
		return 48000;
	elseif nCharLevel == 9 then
		return 64000;
	elseif nCharLevel == 10 then
		return 85000;
	elseif nCharLevel == 11 then
		return 100000;
	elseif nCharLevel == 12 then
		return 120000;
	elseif nCharLevel == 13 then
		return 140000;
	elseif nCharLevel == 14 then
		return 165000;
	elseif nCharLevel == 15 then
		return 195000;
	elseif nCharLevel == 16 then
		return 225000;
	elseif nCharLevel == 17 then
		return 265000;
	elseif nCharLevel == 18 then
		return 305000;
	elseif nCharLevel == 19 then
		return 355000;
	end
	return 0;
end
function getClassLevel(nodeChar, s)
	local nodeCharClass = CharManager.getClassRecord(nodeChar, s, true);
	local nodeCharClass2 = CharManager.getClassRecord(nodeChar, s, false);

	local nResult = 0;
	if nodeCharClass then
		nResult = math.max(nResult, DB.getValue(nodeCharClass, "level", 0));
	end
	if nodeCharClass2 then
		nResult = math.max(nResult, DB.getValue(nodeCharClass2, "level", 0));
	end
	return nResult;
end
function getClassSummary(nodeChar, bShort)
	if not nodeChar then
		return "";
	end
	
	local tSorted = {};
	for _,nodeChild in ipairs(DB.getChildList(nodeChar, "classes")) do
		table.insert(tSorted, nodeChild);
	end
	table.sort(tSorted, function(a,b) return DB.getValue(a, "name", "") < DB.getValue(b, "name", ""); end);
			
	local tClasses = {};
	for _,nodeChild in pairs(tSorted) do
		local sClass = DB.getValue(nodeChild, "name", "");
		local nLevel = DB.getValue(nodeChild, "level", 0);
		if nLevel > 0 then
			if bShort then
				sClass = sClass:sub(1,3);
			end
			table.insert(tClasses, sClass .. " " .. math.floor(nLevel*100)*0.01);
		end
	end

	return table.concat(tClasses, " / ");
end
function getClassHDUsage(nodeChar)
	if not nodeChar then
		return 0, 0;
	end

	local nHD = 0;
	local nHDUsed = 0;
	
	for _,nodeChild in ipairs(DB.getChildList(nodeChar, "classes")) do
		local nLevel = DB.getValue(nodeChild, "level", 0);
		local nHDMult = #(DB.getValue(nodeChild, "hddie", {}));
		nHD = nHD + (nLevel * nHDMult);
		nHDUsed = nHDUsed + DB.getValue(nodeChild, "hdused", 0);
	end
	
	return nHDUsed, nHD;
end
function getSubclass(nodeChar, s, bSource2024)
	local nodeCharClass = CharManager.getClassRecord(nodeChar, s, bSource2024);
	if not nodeCharClass then
		return "";
	end

	local sSpecName = StringManager.trim(DB.getValue(nodeCharClass, "specialization", ""));
	if sSpecName ~= "" then
		return sSpecName;
	end

	local bIs2024 = (DB.getValue(nodeCharClass, "version", "") == "2024");
	if not bIs2024 then
		local tSubclassOptions = CharClassManager.getSubclassOptions(nodeCharClass);
		for _,vSubclass in ipairs(tSubclassOptions) do
			if CharManager.hasFeature(vSubclass.text) then
				return vSubclass.text;
			end
		end
	end

	return "";
end
function getSpellcastingData(nodeChar)
	local tCharClassMagicData = {};
	for _,vClass in ipairs(DB.getChildList(nodeChar, "classes")) do
		local nCasterLevelMult = DB.getValue(vClass, "casterlevelinvmult", 0);
		if nCasterLevelMult ~= 0 then
			local tClassMagicData = {
				sClassName = DB.getValue(vClass, "name", ""),
				nClassLevel = DB.getValue(vClass, "level", 0),
				nCasterLevelMult = nCasterLevelMult,
				bPactMagic = (DB.getValue(vClass, "casterpactmagic", 0) > 0),
				nCantrips = DB.getValue(vClass, "cantrips", 0),
				nKnown = DB.getValue(vClass, "spellsknown", 0),
				nPrepared = DB.getValue(vClass, "spellsprepared", 0),
				sAbility = DB.getValue(vClass, "spellability", ""),
			};
			if tClassMagicData.nCasterLevelMult > 0 then
				tClassMagicData.nSpellCastLevel = math.ceil(tClassMagicData.nClassLevel * (1 / tClassMagicData.nCasterLevelMult));
				if tClassMagicData.nCasterLevelMult > 1 then
					tClassMagicData.nMulticlassSpellCastLevel = math.floor(tClassMagicData.nClassLevel * (1 / tClassMagicData.nCasterLevelMult));
				else
					tClassMagicData.nMulticlassSpellCastLevel = tClassMagicData.nSpellCastLevel;
				end
			elseif tClassMagicData.nCasterLevelMult < 0 then
				tClassMagicData.nSpellCastLevel = math.ceil(tClassMagicData.nClassLevel  * (1 / -tClassMagicData.nCasterLevelMult));
				tClassMagicData.nMulticlassSpellCastLevel = tClassMagicData.nSpellCastLevel;
			end
			table.insert(tCharClassMagicData, tClassMagicData);
		end
	end
	return tCharClassMagicData;
end

function getClassRecord(nodeChar, s, bSource2024)
	if not nodeChar or (s or "") == "" then
		return nil;
	end

	local sLower = StringManager.simplify(s);
	for _,v in ipairs(DB.getChildList(nodeChar, "classes")) do
		if StringManager.simplify(DB.getValue(v, "name", "")) == sLower then
			if (DB.getValue(v, "version", "") == "2024") == bSource2024 then
				return v;
			end
		end
	end
	return nil;
end
function getFeatRecord(nodeChar, s)
	if not nodeChar or (s or "") == "" then
		return nil;
	end
	
	local sLower = StringManager.simplify(s);
	for _,v in ipairs(DB.getChildList(nodeChar, "featlist")) do
		if StringManager.simplify(DB.getValue(v, "name", "")) == sLower then
			return v;
		end
	end
	return nil;
end
function getFeatRecord2024(nodeChar, s)
	if not nodeChar or (s or "") == "" then
		return nil;
	end
	
	local sLower = StringManager.simplify(s);
	for _,v in ipairs(DB.getChildList(nodeChar, "featlist")) do
		if StringManager.simplify(DB.getValue(v, "name", "")) == sLower then
			if DB.getValue(v, "version", "") == "2024" then
				return v;
			end
		end
	end
	return nil;
end
function getFeatRecord2014(nodeChar, s)
	if not nodeChar or (s or "") == "" then
		return nil;
	end
	
	local sLower = StringManager.simplify(s);
	for _,v in ipairs(DB.getChildList(nodeChar, "featlist")) do
		if StringManager.simplify(DB.getValue(v, "name", "")) == sLower then
			if DB.getValue(v, "version", "") ~= "2024" then
				return v;
			end
		end
	end
	return nil;
end
function getFeatureRecord(nodeChar, s)
	if not nodeChar or (s or "") == "" then
		return nil;
	end
	
	local sLower = StringManager.simplify(s);
	for _,v in ipairs(DB.getChildList(nodeChar, "featurelist")) do
		if StringManager.simplify(DB.getValue(v, "name", "")) == sLower then
			return v;
		end
	end
	return nil;
end
function getFeatureRecord2014(nodeChar, s)
	if not nodeChar or (s or "") == "" then
		return nil;
	end
	
	local sLower = StringManager.simplify(s);
	for _,v in ipairs(DB.getChildList(nodeChar, "featurelist")) do
		if StringManager.simplify(DB.getValue(v, "name", "")) == sLower then
			if DB.getValue(v, "version", "") ~= "2024" then
				return v;
			end
		end
	end
	return nil;
end
function getGroupPowerRecord(nodeChar, sGroup, s)
	if not nodeChar or ((sGroup or "") == "") or (s or "") == "" then
		return nil;
	end
	
	local sGroupLower = StringManager.simplify(sGroup);
	local sLower = StringManager.simplify(s);
	for _,v in ipairs(DB.getChildList(nodeChar, "powers")) do
		if StringManager.simplify(DB.getValue(v, "group", "")) == sGroupLower and 
				StringManager.simplify(DB.getValue(v, "name", "")) == sLower then
			return v;
		end
	end
	return nil;
end
function getLanguageRecord(nodeChar, s)
	if not nodeChar or (s or "") == "" then
		return nil;
	end
	
	local sLower = StringManager.simplify(s);
	for _,v in ipairs(DB.getChildList(nodeChar, "languagelist")) do
		if StringManager.simplify(DB.getValue(v, "name", "")) == sLower then
			return v;
		end
	end
	return nil;
end
function getPowerGroupRecord(nodeChar, s)
	if not nodeChar then
		return nil;
	end

	local sLower = StringManager.simplify(s);
	for _,v in ipairs(DB.getChildList(nodeChar, "powergroup")) do
		if StringManager.simplify(DB.getValue(v, "name", "")) == sLower then
			return v;
		end
	end
	return nil;
end
function getSkillRecord(nodeChar, s, bCreate)
	if not nodeChar then
		return nil;
	end

	-- Get the list we are going to add to
	local nodeList = DB.createChild(nodeChar, "skilllist");
	if not nodeList then
		return nil;
	end

	-- Find or create the skill entry
	local nodeSkill;
	for _,nodeSkill in ipairs(DB.getChildList(nodeList)) do
		if DB.getValue(nodeSkill, "name", "") == s then
			return nodeSkill;
		end
	end

	if bCreate then
		nodeSkill = DB.createChild(nodeList);
		DB.setValue(nodeSkill, "name", "string", s);
		if DataCommon.skilldata[s] then
			DB.setValue(nodeSkill, "stat", "string", DataCommon.skilldata[s].stat);
		end
	end
	return nodeSkill;
end
function getTraitRecord(nodeChar, s)
	if not nodeChar or ((s or "") == "") then
		return nil;
	end
	
	local sLower = StringManager.simplify(s);
	for _,v in ipairs(DB.getChildList(nodeChar, "traitlist")) do
		if StringManager.simplify(DB.getValue(v, "name", "")) == sLower then
			return v;
		end
	end
	return nil;
end

function refreshNextLevelXP(nodeChar)
	if not nodeChar then
		return;
	end
	DB.setValue(nodeChar, "expneeded", "number", CharManager.getNextLevelXP(nodeChar))
end

--
-- CHARACTER ADDITIONS
--

function addAbilityAdjustment(nodeChar, sAbility, nAdj, nAbilityMax)
	if not nodeChar or ((sAbility or "") == "") or not nAdj then
		return false;
	end
	local sAbilityLower = StringManager.simplify(sAbility);
	if not StringManager.contains(DataCommon.abilities, sAbilityLower) then
		return false;
	end

	local sPath = "abilities." .. sAbilityLower .. ".score";
	local nCurrent = DB.getValue(nodeChar, sPath, 10);
	local nNewScore = nCurrent + nAdj;
	if nAbilityMax then
		nNewScore = math.max(math.min(nNewScore, nAbilityMax), nCurrent);
	end
	if nNewScore ~= nCurrent then
		DB.setValue(nodeChar, sPath, "number", nNewScore);
		ChatManager.SystemMessageResource("char_abilities_message_abilityadd", StringManager.capitalize(sAbility), nNewScore - nCurrent, DB.getValue(nodeChar, "name", ""));
	end
	return true;
end
function addHP(nodeChar, vHP)
	local nHP = tonumber(vHP) or 0;
	if not nodeChar or (nHP <= 0) then
		return false;
	end
	DB.setValue(nodeChar, "hp.total", "number", DB.getValue(nodeChar, "hp.total", 0) + nHP);
end
function setSize(nodeChar, s)
	if not nodeChar then
		return false;
	end
	DB.setValue(nodeChar, "size", "string", s or "Medium");
	return true;
end
function setSpeed(nodeChar, vSpeed)
	local nSpeed = tonumber(vSpeed) or 0;
	if not nodeChar or (nSpeed <= 0) then
		return false;
	end

	local nCurrSpeed = DB.getValue(nodeChar, "speed.base", 0);
	if nCurrSpeed >= nSpeed then
		return true;
	end
	DB.setValue(nodeChar, "speed.base", "number", nSpeed);
	ChatManager.SystemMessageResource("char_abilities_message_basespeedset", nSpeed, DB.getValue(nodeChar, "name", ""));
	return true;
end
function addSpeed(nodeChar, vSpeed)
	local nSpeed = tonumber(vSpeed) or 0;
	if not nodeChar or (nSpeed <= 0) then
		return false;
	end
	DB.setValue(nodeChar, "speed.misc", "number", DB.getValue(nodeChar, "speed.misc", 0) + nSpeed);
end
function addSpecialMove(nodeChar, s, vDist)
	local nDist = math.max(tonumber(vDist) or 0, 0);
	if not nodeChar or ((s or "") == "") then
		return false;
	end

	local sSpecialMove = StringManager.trim(DB.getValue(nodeChar, "speed.special", ""));
	local tSplit = StringManager.splitByPattern(sSpecialMove, ",", true);

	if nDist == 0 then
		if StringManager.contains(tSplit, s) then
			return true;
		end
		table.insert(tSplit, s);
	else
		local sNewMove = string.format("%s %d", s, nDist);
		local sPatternMove = string.format("^%s %%d+$", s);
		local bPatternMatch = false;
		for k,v in ipairs(tSplit) do
			local sPatternMatch = sSpecialMove:match(sPatternMove);
			if sPatternMatch then
				if (tonumber(sPatternMatch) or 0) >= nDist then
					return true;
				end
				tSplit[k] = sNewMove;
				bPatternMatch = true;
				break;
			end
		end
		if not bPatternMatch then
			table.insert(tSplit, sNewMove);
		end
	end

	DB.setValue(nodeChar, "speed.special", "string", table.concat(tSplit, ", "));
	return true;
end
function addSense(nodeChar, s, vDist)
	local nDist = tonumber(vDist) or 0;
	if not nodeChar or ((s or "") == "") or (nDist <= 0) then
		return false;
	end

	local sNewSense = string.format("%s %d", s, nDist);
	local sPatternSense = string.format("%s %%d+", s);

	local sSenses = StringManager.trim(DB.getValue(nodeChar, "senses", ""));
	local sPatternMatch = sSenses:match(sPatternSense);
	if sPatternMatch then
		if (tonumber(sPatternMatch) or 0) >= nDist then
			return true;
		end
		sSenses = sSenses:gsub(sPatternSense, sNewSense);
	elseif sSenses == "" then
		sSenses = sNewSense;
	else
		sSenses = string.format("%s, %s", sSenses, sNewSense);
	end
	DB.setValue(nodeChar, "senses", "string", sSenses);
	return true;
end
function addSaveProficiency(nodeChar, s)
	if not nodeChar or ((s or "") == "") then
		return false;
	end
	local sLower = s:lower();
	if not StringManager.contains(DataCommon.abilities, sLower) then
		return false;
	end

	DB.setValue(nodeChar, "abilities." .. sLower .. ".saveprof", "number", 1);
	ChatManager.SystemMessageResource("char_abilities_message_saveadd", s, DB.getValue(nodeChar, "name", ""));
	return true;
end
function addSkillProficiency(nodeChar, s)
	local nodeSkill = CharManager.getSkillRecord(nodeChar, s, true);
	if not nodeSkill then
		return nil;
	end

	local nCurrProf = DB.getValue(nodeSkill, "prof", 0);
	if (nCurrProf == 1) or (nCurrProf == 2) then
		return nodeSkill;
	end

	DB.setValue(nodeSkill, "prof", "number", 1);
	ChatManager.SystemMessageResource("char_abilities_message_skilladd", DB.getValue(nodeSkill, "name", ""), DB.getValue(nodeChar, "name", ""));
	return nodeSkill;
end
function increaseSkillProficiency(nodeChar, s, nIncrease)
	local nodeSkill = CharManager.getSkillRecord(nodeChar, s, true);
	if not nodeSkill then
		return nil;
	end

	local nProf = DB.getValue(nodeSkill, "prof", 0);
	if (nProf == 1) or ((nIncrease or 1) == 2) then
		DB.setValue(nodeSkill, "prof", "number", 2);
		ChatManager.SystemMessageResource("char_abilities_message_expertiseadd", DB.getValue(nodeSkill, "name", ""), DB.getValue(nodeChar, "name", ""));
	elseif nProf ~= 2 then
		DB.setValue(nodeSkill, "prof", "number", 1);
		ChatManager.SystemMessageResource("char_abilities_message_skilladd", DB.getValue(nodeSkill, "name", ""), DB.getValue(nodeChar, "name", ""));
	end
end
function addProficiency(nodeChar, sType, s)
	s = StringManager.trim(s);
	if ((s or "") == "") or (s == "None") then
		return nil;
	end

	local nodeList = DB.createChild(nodeChar, "proficiencylist");
	if not nodeList then
		return nil;
	end

	local sValue;
	if sType == "armor" then
		sValue = Interface.getString("char_label_addprof_armor");
	elseif sType == "weapons" then
		sValue = Interface.getString("char_label_addprof_weapon");
	else -- "tools"
		sValue = Interface.getString("char_label_addprof_tool");
	end
	sValue = string.format("%s: %s", sValue, s);

	for _,nodeProf in ipairs(DB.getChildList(nodeList)) do
		if DB.getValue(nodeProf, "name", "") == sValue then
			return nodeProf;
		end
	end
	
	local nodeEntry = DB.createChild(nodeList);
	DB.setValue(nodeEntry, "name", "string", sValue);

	ChatManager.SystemMessageResource("char_abilities_message_profadd", sValue, DB.getValue(nodeChar, "name", ""));
	return nodeEntry;
end
function addLanguage(nodeChar, s)
	local nodeList = DB.createChild(nodeChar, "languagelist");
	if not nodeList then
		return nil;
	end
	
	if s ~= "Choice" then
		for _,v in ipairs(DB.getChildList(nodeList)) do
			if DB.getValue(v, "name", "") == s then
				return v;
			end
		end
	end

	local nodeNew = DB.createChild(nodeList);
	DB.setValue(nodeNew, "name", "string", s);

	ChatManager.SystemMessageResource("char_abilities_message_languageadd", s, DB.getValue(nodeChar, "name", ""));
	return nodeNew;
end
function addFeat(nodeChar, s, tData)
	if not nodeChar or ((s or "") == "") then
		return nil;
	end

	local tFilters = {
		{ sField = "name", sValue = s, },
		{ sField = "version", sValue = (tData and tData.bSource2024 and "2024" or ""), },
	};
	local nodeFeat = RecordManager.findRecordByFilter("feat", tFilters);
	if not nodeFeat then
		return;
	end
	CharFeatManager.addFeat(nodeChar, DB.getPath(nodeFeat), { bWizard = tData and tData.bWizard });
end
function addPowerGroup(nodeChar, tData)
	if not nodeChar or not tData then
		return nil;
	end

	local nodePowerGroup = CharManager.getPowerGroupRecord(nodeChar, tData.sName);
	if nodePowerGroup then
		return nodePowerGroup;
	end

	nodePowerGroup = DB.createChild(DB.createChild(nodeChar, "powergroup"));

	DB.setValue(nodePowerGroup, "name", "string", tData.sName or "");
	if (tData.sCasterType or "") ~= "" then
		DB.setValue(nodePowerGroup, "castertype", "string", tData.sCasterType);
	end
	if (tData.sAbility or "") ~= "" then
		DB.setValue(nodePowerGroup, "stat", "string", tData.sAbility:lower());
	elseif tData.bChooseSpellAbility then
		CharBuildDropManager.chooseSpellGroupAbility(nodePowerGroup);
	end

	return nodePowerGroup;
end
function addSpell(nodeChar, tData)
	if not nodeChar or not tData or (((tData.sName or "") == "") and ((tData.sRecord or "") == "")) then
		return nil;
	end

	local nodeSpell;
	if (tData.sRecord or "" ~= "") then
		nodeSpell = DB.findNode(tData.sRecord);
	else
		local tFilters = {
			{ sField = "name", sValue = tData.sName, bIgnoreCase = true, },
			{ sField = "version", sValue = (tData.bSource2024 and "2024" or ""), },
		};
		nodeSpell = RecordManager.findRecordByFilter("spell", tFilters)
	end
	if not nodeSpell then
		return nil;
	end

	local nodeNew = PowerManager.addPower("power", nodeSpell, nodeChar, tData.sGroup);
	if not nodeNew then
		return nil;
	end

	if tData.bRitual then
		local sNewName = string.format("%s (%s)", DB.getValue(nodeNew, "name", ""), Interface.getString("spell_label_ritual"));
		DB.setValue(nodeNew, "name", "string", sNewName);
	end
	if tData.nPrepared and (tData.nPrepared > 0) and (DB.getValue(nodeNew, "level", 0) > 0) then
		DB.setValue(nodeNew, "prepared", "number", tData.nPrepared);
	end

	return nodeNew;
end
