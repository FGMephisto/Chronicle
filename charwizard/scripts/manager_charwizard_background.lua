--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--
--	Data
--

function getBackgroundRecord()
	local tBackground = CharWizardManager.getBackgroundData();
	return tBackground.background;
end
function getBackgroundNode()
	local sRecord = CharWizardBackgroundManager.getBackgroundRecord();
	if (sRecord or "") == "" then
		return nil;
	end
	return DB.findNode(sRecord);
end
function setBackgroundRecord(v)
	local nodeRecord;
	if type(v) == "databasenode" then
		nodeRecord = v;
	elseif type(v) == "string" then
		nodeRecord = DB.findNode(v);
	end
	if not nodeRecord then
		CharWizardManager.clearBackgroundData();
		return;
	end

	local tBackground = CharWizardManager.getBackgroundData();
	local bIs2024 = (DB.getValue(nodeRecord, "version", "") == "2024");
	tBackground.background = DB.getPath(nodeRecord);
	tBackground.bIs2024 = bIs2024;

	if bIs2024 then
		CharWizardBackgroundManager.handleBackgroundEquipmentKit2024();
	else
		CharWizardBackgroundManager.handleBackgroundEquipmentKit2014();
	end

	CharWizardEquipmentManager.onEquipmentPageUpdate();

	CharWizardManager.updateAlerts();
end
function isBackground2024()
	local tBackground = CharWizardManager.getBackgroundData();
	return tBackground.bIs2024;
end

function handleBackgroundEquipmentKit2024()
	local tBackground = CharWizardManager.getBackgroundData();
	local nodeEquipment = DB.createChild(DB.findNode(tBackground.background), "equipmentlist");

	local tOptions = {};
	for _,nodeOption in ipairs(DB.getChildList(nodeEquipment)) do
		local tItems = {};
		local nWealth = DB.getValue(nodeOption, "wealth", 0);
		if nWealth > 0 then
			tItems.wealth = nWealth;
		end

		tItems.items = {};
		for _,nodeItem in ipairs(DB.getChildList(nodeOption, "items")) do
			local nCount = DB.getValue(nodeItem, "count", 0);
			table.insert(tItems.items, { item = nodeItem, count = nCount });
		end

		table.insert(tOptions, tItems);
	end

	CharWizardBackgroundManager.setBackgroundStartingKitOptions(tOptions);
end
function handleBackgroundEquipmentKit2014()
	local tBackground = CharWizardManager.getBackgroundData();
	local sEquipment = DB.getValue(DB.findNode(tBackground.background), "equipment", "");

	local nGold = CharWizardBackgroundManager.parseBackgroundGold2014(sEquipment);
	CharWizardBackgroundManager.setBackgroundStartingGold(nGold);

	local tInnate, tChoices = CharWizardBackgroundManager.parseBackgroundEquipmentKitItems2014(sEquipment);
	CharWizardBackgroundManager.setBackgroundStartingKitItems(tInnate);
	CharWizardBackgroundManager.setBackgroundStartingKitOptions(tChoices);
end
function parseBackgroundGold2014(s)
	local tSplitEquipment = StringManager.split(s, ",");
	for _,vItem in pairs(tSplitEquipment) do
		local tText = { "pouch containing", "purse containing", "(%d+) gp" };
		for _,sMatch in ipairs(tText) do
			if vItem:match(sMatch) then
				return tonumber(vItem:match("(%d+) gp"));
			end
		end
	end

	return 0;
end
function parseBackgroundEquipmentKitItems2014(s)
	local tItems = {};
	local tChoices = {};

	local tSplitEquipment = StringManager.split(s, ",");
	for _,vItem in pairs(tSplitEquipment) do
		local tInnate = {};

		-- Clothes
		if vItem:match("common clothes") or vItem:match("commoner's clothes") then
			table.insert(tInnate, "clothes, common");
		elseif vItem:match("traveler's clothes") then
			table.insert(tInnate, "clothes, traveler's");
		elseif vItem:match("fine clothes") then
			table.insert(tInnate, "clothes, fine");
		elseif vItem:match("vestments") then
			table.insert(tInnate, "clothes, vestments");
		elseif vItem:match("costume") then
			table.insert(tInnate, "clothes, costume");
		end

		-- Items
		local tSimple = { "blanket", "block and tackle", "book", "carpenter's tools",
			"crowbar", "dagger", "disguise kit", "emblem", "fishing tackle", "forgery kit",
			"healer's kit", "herbalism kit", "hammer", "horn", "incense", "manacles",
			"poisoner's kit", "pouch", "robe", "staff", "shovel", "tent", "tinderbox",
			"torch",
		};
		for _,v in ipairs(tSimple) do
			if vItem:match(v) then
				table.insert(tInnate, v);
			end
		end

		if vItem:match("belaying pin") then
			table.insert(tInnate, "club");
		end
		if vItem:match("bullseye lantern") then
			table.insert(tInnate, "lantern, bullseye");
		end
		if vItem:match("ink") then
			table.insert(tInnate, "ink (1-ounce bottle)");
		end
		if vItem:match("iron pot") then
			table.insert(tInnate, "pot, iron");
		end
		if vItem:match("miner's pick") then
			table.insert(tInnate, "pick, miner's");
		end
		if vItem:match("parchment") then
			table.insert(tInnate, "parchment (one sheet)");
		end
		if vItem:match("pen ") or vItem:match("quill") or vItem == "pen" then
			table.insert(tInnate, "ink pen");
		end
		if vItem:match("silk rope") then
			table.insert(tInnate, "rope, silk (50 Feet)");
		end

		for _,v in ipairs(tInnate) do
			local tItemFilters = {
				{ sField = "name", sValue = v, bIgnoreCase = true, },
				{ sField = "version", sValue = "", },
			};
			local nodeItem = RecordManager.findRecordByFilter("item", tItemFilters);
			if nodeItem then
				table.insert(tItems, { item = nodeItem, count = 1 });
			end
		end

		-- Choices
		if vItem:match("set of bone dice or deck of cards") or vItem:match("gaming set") then
			local tMappings = LibraryData.getMappings("item");
			local aChoicesLocal = {};
			for _,sMapping in ipairs(tMappings) do
				for _,vGlobalItem in pairs(DB.getChildrenGlobal(sMapping)) do
					local sMatch = StringManager.trim(DB.getValue(vGlobalItem, "subtype", ""));
					local sProperties = StringManager.trim(DB.getValue(vGlobalItem, "properties", ""))
					local bMagic = sProperties:match("magic");

					if sMatch:lower() == "gaming set" and not bMagic then
						table.insert(aChoicesLocal, { item = vGlobalItem, count = 1 });
					end
				end
			end

			table.insert(tChoices, aChoicesLocal);
		end

		if vItem:match("artisan") then
			local tMappings = LibraryData.getMappings("item");
			local aChoicesLocal = {};
			for _,sMapping in ipairs(tMappings) do
				for _,vGlobalItem in pairs(DB.getChildrenGlobal(sMapping)) do
					local sMatch = StringManager.trim(DB.getValue(vGlobalItem, "subtype", ""));
					local sProperties = StringManager.trim(DB.getValue(vGlobalItem, "properties", ""))
					local bMagic = sProperties:match("magic");

					if sMatch:lower() == "artisan's tools" and not bMagic then
						table.insert(aChoicesLocal, { item = vGlobalItem, count = 1 });
					end
				end
			end

			table.insert(tChoices, aChoicesLocal);
		end

		if vItem:match("holy symbol") then
			local tMappings = LibraryData.getMappings("item");
			local aChoicesLocal = {};
			for _,sMapping in ipairs(tMappings) do
				for _,vGlobalItem in pairs(DB.getChildrenGlobal(sMapping)) do
					local sMatch = StringManager.trim(DB.getValue(vGlobalItem, "subtype", ""));
					local sProperties = StringManager.trim(DB.getValue(vGlobalItem, "properties", ""))
					local bMagic = sProperties:match("magic");

					if sMatch:lower() == "holy symbol" and not bMagic then
						table.insert(aChoicesLocal, { item = vGlobalItem, count = 1 });
					end
				end
			end

			table.insert(tChoices, aChoicesLocal);
		end

		if vItem:match("musical instrument") then
			local tMappings = LibraryData.getMappings("item");
			local aChoicesLocal = {};
			for _,sMapping in ipairs(tMappings) do
				for _,vGlobalItem in pairs(DB.getChildrenGlobal(sMapping)) do
					local sMatch = StringManager.trim(DB.getValue(vGlobalItem, "subtype", ""));
					local sProperties = StringManager.trim(DB.getValue(vGlobalItem, "properties", ""))
					local bMagic = sProperties:match("magic");

					if sMatch:lower() == "musical instrument" and not bMagic then
						table.insert(aChoicesLocal, { item = vGlobalItem, count = 1 });
					end
				end
			end
			table.insert(tChoices, aChoicesLocal);
		end
	end

	return tItems, tChoices
end

function getBackgroundStartingGold()
	local tBackground = CharWizardManager.getBackgroundData();
	if not tBackground then
		return 0;
	end
	return tBackground.backgroundwealth or 0;
end
function setBackgroundStartingGold(nWealth)
	local tBackground = CharWizardManager.getBackgroundData();
	if not tBackground then
		return;
	end
	tBackground.backgroundwealth = nWealth;
end
function getBackgroundStartingKitItems()
	local tBackground = CharWizardManager.getBackgroundData();
	if not tBackground then
		return {};
	end
	return tBackground.backgrounditems or {};
end
function setBackgroundStartingKitItems(tBackgroundItems)
	local tBackground = CharWizardManager.getBackgroundData();
	if not tBackground then
		return;
	end
	tBackground.backgrounditems = nil;
	tBackground.backgrounditems = tBackgroundItems;
end
function getBackgroundStartingKitOptions()
	local tBackground = CharWizardManager.getBackgroundData();
	if not tBackground then
		return {};
	end

	return tBackground.backgrounditemchoices or {};
end
function setBackgroundStartingKitOptions(tBackgroundOptions)
	local tBackground = CharWizardManager.getBackgroundData();
	if not tBackground then
		return;
	end
	tBackground.backgrounditemchoices = nil;
	tBackground.backgrounditemchoices = tBackgroundOptions;
end
function setBackgroundFeat(s)
	local tBackground = CharWizardManager.getBackgroundData();
	tBackground.feat = s;
end
function setBackgroundFeatPath(sPath)
	local tBackground = CharWizardManager.getBackgroundData();
	tBackground.featpath = sPath;
end
function addBackgroundAbilityIncreases(sAbility, nMod)
	if ((sAbility or "") == "") then
		return;
	end
	local tBackground = CharWizardManager.getBackgroundData();

	tBackground.abilityincrease = tBackground.abilityincrease or {};
	for _,v in ipairs(tBackground.abilityincrease) do
		if v.ability:lower() == sAbility:lower() then
			v.mod = v.mod + nMod;
			return;
		end
	end
	table.insert(tBackground.abilityincrease, { ability = sAbility, mod = nMod } );
end
function clearBackgroundAbilityIncreases()
	local tBackground = CharWizardManager.getBackgroundData();
	tBackground.abilityincrease = {};
end
function setBackgroundBaseSkills(tSkills)
	local tBackground = CharWizardManager.getBackgroundData();
	tBackground.skill = {};
	for _,v in pairs(tSkills) do
		table.insert(tBackground.skill, v);
	end
end
function addBackgroundSkillChoice(s)
	if (s or "") == "" then
		return;
	end
	local tBackground = CharWizardManager.getBackgroundData();
	tBackground.skillchoice = tBackground.skillchoice or {};
	if StringManager.contains(tBackground.skillchoice, s) then
		return;
	end
	table.insert(tBackground.skillchoice, s);
end
function clearBackgroundSkillChoice()
	local tBackground = CharWizardManager.getBackgroundData();
	tBackground.skillchoice = {};
end
function setBackgroundBaseTools(tTools)
	local tBackground = CharWizardManager.getBackgroundData();
	tBackground.toolprof = {};
	for _,v in pairs(tTools) do
		table.insert(tBackground.toolprof, v);
	end
end
function addBackgroundToolChoice(s)
	if (s or "") == "" then
		return;
	end
	local tBackground = CharWizardManager.getBackgroundData();
	tBackground.toolprofchoice = tBackground.toolprofchoice or {};
	if StringManager.contains(tBackground.toolprofchoice, s) then
		return;
	end
	table.insert(tBackground.toolprofchoice, s);
end
function clearBackgroundToolChoice()
	local tBackground = CharWizardManager.getBackgroundData();
	tBackground.toolprofchoice = {};
end
function setBackgroundBaseLanguages(tLanguages)
	local tBackground = CharWizardManager.getBackgroundData();
	tBackground.language = {};
	for _,v in pairs(tLanguages) do
		table.insert(tBackground.language, v);
	end
end
function addBackgroundLanguageChoice(s)
	if (s or "") == "" then
		return;
	end
	local tBackground = CharWizardManager.getBackgroundData();
	tBackground.languagechoice = tBackground.languagechoice or {};
	if StringManager.contains(tBackground.languagechoice, s) then
		return;
	end
	table.insert(tBackground.languagechoice, s);
end
function clearBackgroundLanguageChoice()
	local tBackground = CharWizardManager.getBackgroundData();
	tBackground.languagechoice = {};
end

--
--	Window
--

function processBackground(w)
	local _, sRecord = w.shortcut.getValue();
	CharWizardBackgroundManager.setBackgroundRecord(sRecord);

	local wBackground = CharWizardManager.getWizardBackgroundWindow();
	wBackground.sub_backgroundselection.setVisible(false);
	wBackground.button_changebackground.setVisible(true);
	wBackground.list_features.setVisible(true);
	wBackground.background_select_header.setValue(DB.getValue(DB.findNode(sRecord), "name", ""):upper());

	CharWizardBackgroundManager.updateBackgroundFeatures();

	CharWizardManager.updateAlerts();
end
function resetBackground()
	CharWizardManager.clearBackgroundData();
	CharWizardEquipmentManager.onEquipmentPageUpdate();

	local wBackground = CharWizardManager.getWizardBackgroundWindow();
	wBackground.sub_backgroundselection.setVisible(true);
	wBackground.button_changebackground.setVisible(false);
	wBackground.list_features.setVisible(false);
	wBackground.list_features.closeAll();
	wBackground.background_select_header.setValue();

	CharWizardEquipmentManager.onBackgroundClear();

	CharWizardAbilitiesManager.updateAbilities();
	CharWizardDecisionManager.refreshOverallDecisions();
	CharWizardManager.updateAlerts();
end

function updateBackgroundFeatures()
	local nodeBackground = CharWizardBackgroundManager.getBackgroundNode();
	if not nodeBackground then
		return;
	end
	local bIs2024 = CharWizardBackgroundManager.isBackground2024();

	CharWizardBackgroundManager.handleBackgroundAbilities(nodeBackground, bIs2024);
	CharWizardBackgroundManager.handleBackgroundSkills(nodeBackground, bIs2024);
	CharWizardBackgroundManager.handleBackgroundTools(nodeBackground, bIs2024);
	CharWizardBackgroundManager.handleBackgroundLanguages(nodeBackground, bIs2024);
	CharWizardBackgroundManager.handleBackgroundFeat(nodeBackground, bIs2024);
	CharWizardBackgroundManager.handleBackgroundFeatures(nodeBackground, bIs2024);
end
function handleBackgroundAbilities(nodeBackground, bIs2024)
	if not nodeBackground or not bIs2024 then
		return;
	end
	local wBackground = CharWizardManager.getWizardBackgroundWindow();
	if not wBackground then
		return;
	end

	local s = DB.getValue(nodeBackground, "abilities", "");
	if s == "" then
		return;
	end

	local w2 = wBackground.list_features.createWindow();
	w2.feature.setValue("Abilities");
	w2.feature_desc.setValue(s);
	CharWizardDecisionManager.createDecision(w2, { sDecisionType = "asibackgroundoption", });
end
function handleBackgroundSkills(nodeBackground, bIs2024)
	if not nodeBackground then
		return;
	end
	local wBackground = CharWizardManager.getWizardBackgroundWindow();
	if not wBackground then
		return;
	end

	local s = DB.getValue(nodeBackground, "skill", "");
	if s == "" then
		return;
	end
	local w2 = wBackground.list_features.createWindow();
	w2.feature.setValue("Skill");
	w2.feature_desc.setValue(s);

	local tBase, tOptions, nPicks = CharBuildManager.parseSkillsField(s, bIs2024);

	CharWizardBackgroundManager.setBackgroundBaseSkills(tBase);

	if nPicks >= #tOptions then
		for _,v in ipairs(tOptions) do
			CharWizardBackgroundManager.addBackgroundSkillChoice(v);
		end
	else
		CharWizardDecisionManager.createDecisions(w2, { sDecisionType = "skill", nPicks = nPicks, tOptions = tOptions, });
	end

	CharWizardDecisionManager.refreshOverallDecision("skill");
	CharWizardDecisionManager.refreshExpertiseDecision();
end
function handleBackgroundTools(nodeBackground, bIs2024)
	if not nodeBackground then
		return;
	end
	local wBackground = CharWizardManager.getWizardBackgroundWindow();
	if not wBackground then
		return;
	end

	local s = DB.getValue(nodeBackground, "tool", "");
	if s == "" then
		return;
	end

	local w2 = wBackground.list_features.createWindow();
	w2.feature.setValue("Proficiency");
	w2.feature_desc.setValue(s);

	local tBase, tOptions, nPicks = CharBuildManager.parseToolsField(s, bIs2024);

	CharWizardBackgroundManager.setBackgroundBaseTools(tBase);

	if nPicks >= #tOptions then
		for _,v in ipairs(tOptions) do
			CharWizardBackgroundManager.addBackgroundToolChoice(v);
		end
	else
		CharWizardDecisionManager.createDecisions(w2, { sDecisionType = "toolprof", nPicks = nPicks, tOptions = tOptions, });
	end

	CharWizardDecisionManager.refreshOverallDecision("toolprof");
end
function handleBackgroundLanguages(nodeBackground, bIs2024)
	if not nodeBackground or bIs2024 then
		return;
	end
	local wBackground = CharWizardManager.getWizardBackgroundWindow();
	if not wBackground then
		return;
	end

	local s = DB.getValue(nodeBackground, "languages", "");
	if s == "" then
		return;
	end

	local w2 = wBackground.list_features.createWindow();
	w2.feature.setValue("Languages");
	w2.feature_desc.setValue(s);

	local tBase, tOptions, nPicks = CharBuildManager.parseLanguagesField(s, bIs2024);

	CharWizardBackgroundManager.setBackgroundBaseLanguages(tBase);

	if nPicks >= #tOptions then
		for _,v in ipairs(tOptions) do
			CharWizardBackgroundManager.addBackgroundLanguageChoice(v);
		end
	else
		CharWizardDecisionManager.createDecisions(w2, { sDecisionType = "language", nPicks = nPicks, tOptions = tOptions, });
	end

	CharWizardDecisionManager.refreshOverallDecision("language");
end
function handleBackgroundFeat(nodeBackground, bIs2024)
	if not nodeBackground then
		return;
	end
	local wBackground = CharWizardManager.getWizardBackgroundWindow();
	if not wBackground then
		return;
	end

	local s = DB.getValue(nodeBackground, "feat", "");
	if s ~= "" then
		local w2 = wBackground.list_features.createWindow();
		w2.feature.setValue("Feat");
		w2.feature_desc.setValue(s);
		CharWizardBackgroundManager.setBackgroundFeat(s);
		return;
	end

	if bIs2024 then
		local w2 = wBackground.list_features.createWindow();
		w2.feature.setValue("Feat");
		w2.feature_desc.setVisible(false);
		CharWizardDecisionManager.createDecision(w2, { sDecisionType = "feat", sDecisionClass = "decision_sub_backgroundfeat_choice", });
	end
end
function handleBackgroundFeatures(nodeBackground, bIs2024)
	if not nodeBackground or not bIs2024 then
		return;
	end
	local wBackground = CharWizardManager.getWizardBackgroundWindow();
	if not wBackground then
		return;
	end

	for _,nodeFeature in pairs(DB.getChildren(nodeBackground, "features")) do
		local w2 = wBackground.list_features.createWindow();
		w2.feature.setValue(DB.getValue(nodeFeature, "name", ""));
		w2.shortcut.setValue("reference_backgroundfeature", DB.getPath(nodeFeature));
		w2.feature_desc.setValue(DB.getValue(nodeFeature, "text", ""));
	end
end

--
-- Decisions
--

local _bUpdatingDecision = false;
function processBackgroundDecision(w)
	if _bUpdatingDecision then
		return;
	end
	_bUpdatingDecision = true;

	local sDecisionType = w.decisiontype.getValue();
	if sDecisionType == "asibackgroundoption" then
		CharWizardBackgroundManager.processBackgroundDecisionASIOption(w);
	elseif sDecisionType == "asibackground" then
		CharWizardBackgroundManager.processBackgroundDecisionASI(w);
	elseif sDecisionType == "skill" then
		CharWizardBackgroundManager.processBackgroundDecisionSkill(w);
	elseif sDecisionType == "language" then
		CharWizardBackgroundManager.processBackgroundDecisionLanguage(w);
	elseif sDecisionType == "toolprof" then
		CharWizardBackgroundManager.processBackgroundDecisionTool(w);
	end

	_bUpdatingDecision = false;

	CharWizardManager.updateAlerts();
end
function processBackgroundDecisionASIOption(wDecision)
	local wFeature = wDecision.windowlist.window;
	CharWizardBackgroundManager.clearBackgroundAbilityIncreases();

	for _,w in pairs(wDecision.windowlist.getWindows()) do
		if w.decisiontype.getValue() == "asibackground" then
			w.close();
		end
	end

	local tAbilities = {};
	local nodeBackground = CharWizardBackgroundManager.getBackgroundNode();
	if nodeBackground then
		tAbilities = CharBuildManager.parseAbilitiesFromString(DB.getValue(nodeBackground, "abilities", ""));
	end

	local sDecisionChoice = wDecision.decision_choice.getValue():lower();
	if sDecisionChoice:match("option 1") then
		if #tAbilities > 1 then
			CharWizardDecisionManager.createDecision(wFeature, { sDecisionType = "asibackground", nAdj = 2, tOptions = tAbilities, });
			CharWizardDecisionManager.createDecision(wFeature, { sDecisionType = "asibackground", nAdj = 1, tOptions = tAbilities, });
		elseif #tAbilities == 1 then
			CharWizardDecisionManager.createDecision(wFeature, { sDecisionType = "asibackground", nAdj = 2, tOptions = { tAbilities[1] }, });
			CharWizardDecisionManager.createDecision(wFeature, { sDecisionType = "asibackground", nAdj = 1, });
		else
			CharWizardDecisionManager.createDecision(wFeature, { sDecisionType = "asibackground", nAdj = 2, });
			CharWizardDecisionManager.createDecision(wFeature, { sDecisionType = "asibackground", nAdj = 1, });
		end
	else
		if #tAbilities > 3 then
			CharWizardDecisionManager.createDecisions(wFeature, { sDecisionType = "asibackground", nAdj = 1, nPicks = 3, tOptions = tAbilities, });
		elseif #tAbilities == 3 then
			CharWizardBackgroundManager.addBackgroundAbilityIncreases(tAbilities[1], 1);
			CharWizardBackgroundManager.addBackgroundAbilityIncreases(tAbilities[2], 1);
			CharWizardBackgroundManager.addBackgroundAbilityIncreases(tAbilities[3], 1);
		elseif #tAbilities == 2 then
			CharWizardDecisionManager.createDecision(wFeature, { sDecisionType = "asibackground", nAdj = 1, tOptions = { tAbilities[1] }, });
			CharWizardDecisionManager.createDecision(wFeature, { sDecisionType = "asibackground", nAdj = 1, tOptions = { tAbilities[2] }, });
			CharWizardDecisionManager.createDecision(wFeature, { sDecisionType = "asibackground", nAdj = 1, });
		elseif #tAbilities == 1 then
			CharWizardDecisionManager.createDecision(wFeature, { sDecisionType = "asibackground", nAdj = 1, tOptions = { tAbilities[1] }, });
			CharWizardDecisionManager.createDecision(wFeature, { sDecisionType = "asibackground", nAdj = 1, });
			CharWizardDecisionManager.createDecision(wFeature, { sDecisionType = "asibackground", nAdj = 1, });
		else
			CharWizardDecisionManager.createDecisions(wFeature, { sDecisionType = "asibackground", nAdj = 1, nPicks = 3, });
		end
	end

	CharWizardAbilitiesManager.updateAbilities();
end
function processBackgroundDecisionASI(wDecision)
	CharWizardBackgroundManager.clearBackgroundAbilityIncreases();

	local tAbilityMap = CharWizardDecisionManager.processAbilityDecision(wDecision, true);
	for sAbility,nMod in pairs(tAbilityMap) do
		CharWizardBackgroundManager.addBackgroundAbilityIncreases(sAbility, nMod);
	end

	CharWizardAbilitiesManager.updateAbilities();
end
function processBackgroundDecisionSkill(wDecision)
	CharWizardBackgroundManager.clearBackgroundSkillChoice();

	local tMap = CharWizardDecisionManager.processSkillDecision(wDecision);
	for _,s in pairs(tMap) do
		CharWizardBackgroundManager.addBackgroundSkillChoice(s);
	end

	CharWizardDecisionManager.refreshExpertiseDecision();
end
function processBackgroundDecisionLanguage(wDecision)
	CharWizardBackgroundManager.clearBackgroundLanguageChoice();

	local tMap = CharWizardDecisionManager.processLanguageDecision(wDecision);
	for _,s in pairs(tMap) do
		CharWizardBackgroundManager.addBackgroundLanguageChoice(s);
	end
end
function processBackgroundDecisionTool(wDecision)
	CharWizardBackgroundManager.clearBackgroundToolChoice();

	local tMap = CharWizardDecisionManager.processToolProfDecision(wDecision);
	for _,s in pairs(tMap) do
		CharWizardBackgroundManager.addBackgroundToolChoice(s);
	end
end

function onAddFeatBackgroundButton(wFeat)
	local sFeat = wFeat.name.getValue();
	local sFeatClass, sFeatPath = wFeat.shortcut.getValue();

	CharWizardBackgroundManager.setBackgroundFeatPath(sFeatPath);

	local wDecision = wFeat.windowlist.window.parentcontrol.window;
	wDecision.choice.setValue(sFeat);
	wDecision.choice.setVisible(true);
	wDecision.choicelink.setValue(sFeatClass, sFeatPath);
	wDecision.button_modify.setVisible(true);
	wDecision.sub_decision_choice.setVisible(false);
	wDecision.checkOutstandingDecisions();

	CharWizardManager.updateAlerts();
end
function resetBackgroundDecisionFeat(wDecision)
	CharWizardBackgroundManager.setBackgroundFeatPath();

	wDecision.choice.setValue();
	wDecision.choicelink.setValue();
	wDecision.button_modify.setVisible(false);
	wDecision.sub_decision_choice.setVisible(true);
	WindowManager.callInnerWindowFunction(wDecision, "buildFeats");

	CharWizardManager.updateAlerts();
end
