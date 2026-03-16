--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--
--	Data
--

function getClassDataByName(sClassName)
	return CharWizardManager.getClassData()[sClassName or ""];
end
function isClass2024(sClassName)
	local tClassDataByName = CharWizardClassManager.getClassDataByName(sClassName);
	if not tClassDataByName then
		return false;
	end
	return tClassDataByName.bIs2024;
end
function isClassImport(sClassName)
	local tClassDataByName = CharWizardClassManager.getClassDataByName(sClassName);
	if not tClassDataByName then
		return false;
	end
	return (tClassDataByName.import == 1);
end
function getClassRecord(sClassName)
	local tClassDataByName = CharWizardClassManager.getClassDataByName(sClassName);
	if not tClassDataByName then
		return "";
	end
	return tClassDataByName.record or "";
end
function getClassNode(sClassName)
	local sRecord = CharWizardClassManager.getClassRecord(sClassName);
	if (sRecord or "") == "" then
		return nil;
	end
	return DB.findNode(sRecord);
end
function getClassWindow(sClassName)
	local tClassDataByName = CharWizardClassManager.getClassDataByName(sClassName);
	if not tClassDataByName then
		return nil;
	end
	return tClassDataByName.window;
end
function getClassLevel(sClassName)
	local tClassDataByName = CharWizardClassManager.getClassDataByName(sClassName);
	if not tClassDataByName then
		return 0;
	end
	return tClassDataByName.level or 0;
end
function setClassLevel(sClassName, n)
	local tClassDataByName = CharWizardClassManager.getClassDataByName(sClassName);
	if not tClassDataByName then
		return;
	end
	tClassDataByName.level = n or 0;
end
function setClassLevelUp(sClassName)
	local tClassDataByName = CharWizardClassManager.getClassDataByName(sClassName);
	if not tClassDataByName then
		return;
	end
	tClassDataByName.levelup = 1;
	tClassDataByName.level = tClassDataByName.level + 1;
end
function setClassLevelDown(sClassName)
	local tClassDataByName = CharWizardClassManager.getClassDataByName(sClassName);
	if not tClassDataByName then
		return;
	end
	tClassDataByName.levelup = nil;
	tClassDataByName.level = math.max(tClassDataByName.level - 1, 0);
end

function setSubclass(sClassName, s)
	local tClassDataByName = CharWizardClassManager.getClassDataByName(sClassName);
	if not tClassDataByName then
		return;
	end
	tClassDataByName.subclass = s;
end
function getSubclassNode(sClassName)
	local tClassDataByName = CharWizardClassManager.getClassDataByName(sClassName);
	if not tClassDataByName then
		return;
	end
	if (tClassDataByName.subclass or "") == "" then
		return nil;
	end
	return DB.findNode(tClassDataByName.subclass);
end
function getSubclassName(sClassName)
	local nodeSubclass = CharWizardClassManager.getSubclassNode(sClassName);
	if not nodeSubclass then
		return "";
	end
	return DB.getValue(nodeSubclass, "name", "");
end

function buildFeatureDataFromDecision(w)
	return {
		sClassName = WindowManager.getOuterControlValue(w, "class") or "",
		sName = WindowManager.getOuterControlValue(w, "feature") or "",
		nLevel = WindowManager.getOuterControlValue(w, "level") or 0,
	};
end
function addClassFeatureData(tFeatureData)
	if not tFeatureData then
		return;
	end
	local tClassDataByName = CharWizardClassManager.getClassDataByName(tFeatureData.sClassName);
	if not tClassDataByName then
		return;
	end
	tClassDataByName.features = tClassDataByName.features or {};
	tClassDataByName.features[tFeatureData.sName] = tClassDataByName.features[tFeatureData.sName] or {};
	tClassDataByName.features[tFeatureData.sName][tFeatureData.nLevel] = tClassDataByName.features[tFeatureData.sName][tFeatureData.nLevel] or {};
end
function hasClassFeatureData(tFeatureData)
	return (CharWizardClassManager.getClassFeatureData(tFeatureData) ~= nil);
end
function getClassFeatureData(tFeatureData)
	if not tFeatureData then
		return nil;
	end
	local tClassDataByName = CharWizardClassManager.getClassDataByName(tFeatureData.sClassName);
	if not tClassDataByName then
		return nil;
	end
	if not tClassDataByName.features then
		return nil;
	end
	if not tClassDataByName.features[tFeatureData.sName] then
		return nil;
	end
	return tClassDataByName.features[tFeatureData.sName][tFeatureData.nLevel];
end

function hasClassFeatureChoice(tFeatureData)
	if not tFeatureData then
		return false;
	end

	-- Check existing data for level up
	local nodeChar = CharWizardManager.getIdentityNode();
	if nodeChar then
		if CharManager.hasFeature(nodeChar, tFeatureData.sName) then
			return true;
		end
	end

	-- Check new data in wizard
	local tClassDataByName = CharWizardClassManager.getClassDataByName(tFeatureData.sClassName);
	if not tClassDataByName then
		return false;
	end
	for _,v in pairs(tClassDataByName.features or {}) do
		for _,v2 in pairs(v) do
			if StringManager.contains(v2.featurechoice or {}, tFeatureData.sName) then
				return true;
			end
		end
	end
	return false;
end

function addClassFeatureAbilityIncreases(tFeatureData, sAbility, nMod)
	if ((sAbility or "") == "") then
		return;
	end
	local tFeature = CharWizardClassManager.getClassFeatureData(tFeatureData);
	if not tFeature then
		return;
	end

	tFeature.abilityincrease = tFeature.abilityincrease or {};
	for _,v in pairs(tFeature.abilityincrease) do
		if v.ability:lower() == sAbility:lower() then
			v.mod = v.mod + nMod;
			return;
		end
	end

	table.insert(tFeature.abilityincrease, { ability = sAbility, mod = nMod } );
end
function clearClassFeatureAbilityIncreases(tFeatureData)
	local tFeature = CharWizardClassManager.getClassFeatureData(tFeatureData);
	if not tFeature then
		return;
	end
	tFeature.abilityincrease = {};
end
function setClassFeatureSaveProf(tFeatureData, tProf)
	if not tProf then
		return;
	end
	local tFeature = CharWizardClassManager.getClassFeatureData(tFeatureData);
	if not tFeature then
		return;
	end
	tFeature.saveprof = {};
	for _,v in pairs(tProf) do
		table.insert(tFeature.saveprof, v);
	end
end
function setClassFeatureArmorProf(tFeatureData, tProf)
	if not tProf then
		return;
	end
	local tFeature = CharWizardClassManager.getClassFeatureData(tFeatureData);
	if not tFeature then
		return;
	end
	tFeature.armorprof = {};
	for _,v in pairs(tProf) do
		table.insert(tFeature.armorprof, v);
	end
end
function addClassFeatureArmorProfChoice(tFeatureData, s)
	if (s or "") == "" then
		return;
	end
	local tFeature = CharWizardClassManager.getClassFeatureData(tFeatureData);
	if not tFeature then
		return;
	end
	tFeature.armorprofchoice = tFeature.armorprofchoice or {};
	table.insert(tFeature.armorprofchoice, s)
end
function clearClassFeatureArmorProfChoice(tFeatureData)
	local tFeature = CharWizardClassManager.getClassFeatureData(tFeatureData);
	if not tFeature then
		return;
	end
	tFeature.armorprofchoice = {};
end
function setClassFeatureWeaponProf(tFeatureData, tProf)
	if not tProf then
		return;
	end
	local tFeature = CharWizardClassManager.getClassFeatureData(tFeatureData);
	if not tFeature then
		return;
	end
	tFeature.weaponprof = {};
	for _,v in pairs(tProf) do
		table.insert(tFeature.weaponprof, v);
	end
end
function addClassFeatureWeaponProfChoice(tFeatureData, s)
	if (s or "") == "" then
		return;
	end
	local tFeature = CharWizardClassManager.getClassFeatureData(tFeatureData);
	if not tFeature then
		return;
	end
	tFeature.weaponprofchoice = tFeature.weaponprofchoice or {};
	table.insert(tFeature.weaponprofchoice, s)
end
function clearClassFeatureWeaponProfChoice(tFeatureData)
	local tFeature = CharWizardClassManager.getClassFeatureData(tFeatureData);
	if not tFeature then
		return;
	end
	tFeature.weaponprofchoice = {};
end
function setClassFeatureToolProf(tFeatureData, tProf)
	if not tProf then
		return;
	end
	local tFeature = CharWizardClassManager.getClassFeatureData(tFeatureData);
	if not tFeature then
		return;
	end
	tFeature.toolprof = {};
	for _,v in pairs(tProf) do
		table.insert(tFeature.toolprof, v);
	end
end
function addClassFeatureToolProfChoice(tFeatureData, s)
	if (s or "") == "" then
		return;
	end
	local tFeature = CharWizardClassManager.getClassFeatureData(tFeatureData);
	if not tFeature then
		return;
	end
	tFeature.toolprofchoice = tFeature.toolprofchoice or {};
	table.insert(tFeature.toolprofchoice, s)
end
function clearClassFeatureToolProfChoice(tFeatureData)
	local tFeature = CharWizardClassManager.getClassFeatureData(tFeatureData);
	if not tFeature then
		return;
	end
	tFeature.toolprofchoice = {};
end
function setClassFeatureSkills(tFeatureData, tSkills)
	if not tSkills then
		return;
	end
	local tFeature = CharWizardClassManager.getClassFeatureData(tFeatureData);
	if not tFeature then
		return;
	end
	tFeature.skill = {};
	for _,v in pairs(tSkills) do
		table.insert(tFeature.skill, v);
	end
end
function addClassFeatureSkillChoice(tFeatureData, s)
	if (s or "") == "" then
		return;
	end
	local tFeature = CharWizardClassManager.getClassFeatureData(tFeatureData);
	if not tFeature then
		return;
	end
	tFeature.skillchoice = tFeature.skillchoice or {};
	table.insert(tFeature.skillchoice, s)
end
function clearClassFeatureSkillChoice(tFeatureData)
	local tFeature = CharWizardClassManager.getClassFeatureData(tFeatureData);
	if not tFeature then
		return;
	end
	tFeature.skillchoice = {};
end
function setClassFeatureExpertises(tFeatureData, tExpertises)
	if not tExpertises then
		return;
	end
	local tFeature = CharWizardClassManager.getClassFeatureData(tFeatureData);
	if not tFeature then
		return;
	end
	tFeature.expertise = {};
	for _,v in pairs(tExpertises) do
		table.insert(tFeature.expertise, v);
	end
end
function addClassFeatureExpertiseChoice(tFeatureData, s)
	if (s or "") == "" then
		return;
	end
	local tFeature = CharWizardClassManager.getClassFeatureData(tFeatureData);
	if not tFeature then
		return;
	end
	tFeature.expertisechoice = tFeature.expertisechoice or {};
	table.insert(tFeature.expertisechoice, s)
end
function clearClassFeatureExpertiseChoice(tFeatureData)
	local tFeature = CharWizardClassManager.getClassFeatureData(tFeatureData);
	if not tFeature then
		return;
	end
	tFeature.expertisechoice = {};
end
function setClassFeatureLanguages(tFeatureData, tLanguages)
	if not tLanguages then
		return;
	end
	local tFeature = CharWizardClassManager.getClassFeatureData(tFeatureData);
	if not tFeature then
		return;
	end
	tFeature.language = {};
	for _,v in pairs(tLanguages) do
		table.insert(tFeature.language, v);
	end
end
function addClassFeatureLanguageChoice(tFeatureData, s)
	if (s or "") == "" then
		return;
	end
	local tFeature = CharWizardClassManager.getClassFeatureData(tFeatureData);
	if not tFeature then
		return;
	end
	tFeature.languagechoice = tFeature.languagechoice or {};
	table.insert(tFeature.languagechoice, s)
end
function clearClassFeatureLanguageChoice(tFeatureData)
	local tFeature = CharWizardClassManager.getClassFeatureData(tFeatureData);
	if not tFeature then
		return;
	end
	tFeature.languagechoice = {};
end
function clearClassFeatureFeatPath(tFeatureData)
	local tFeature = CharWizardClassManager.getClassFeatureData(tFeatureData);
	if not tFeature then
		return;
	end
	tFeature.featpath = nil;
end
function setClassFeatureFeatPath(tFeatureData, sPath)
	local tFeature = CharWizardClassManager.getClassFeatureData(tFeatureData);
	if not tFeature then
		return;
	end
	tFeature.featpath = sPath;
end
function clearClassFeatureChoiceSelections(tFeatureData)
	local tFeature = CharWizardClassManager.getClassFeatureData(tFeatureData);
	if not tFeature then
		return;
	end
	tFeature.featurechoice = {};
end
function addClassFeatureChoiceSelection(tFeatureData, s)
	if (s or "") == "" then
		return;
	end
	local tFeature = CharWizardClassManager.getClassFeatureData(tFeatureData);
	if not tFeature then
		return;
	end
	tFeature.featurechoice = tFeature.featurechoice or {};
	table.insert(tFeature.featurechoice, s);
end

function getStartingClassName()
	local tClassData = CharWizardManager.getClassData();
	for k,v in pairs(tClassData) do
		if v.nClassOrder == 1 then
			return k;
		end
	end
	return "";
end
function getStartingClassRecord()
	local tClassData = CharWizardManager.getClassData();
	for _,v in pairs(tClassData) do
		if v.nClassOrder == 1 then
			return v.record;
		end
	end
	return "";
end
function isStartingClass2024()
	return CharWizardClassManager.isClass2024(CharWizardClassManager.getStartingClassName());
end
function getStartingWealthRoll()
	local tStartingClassData = CharWizardManager.getStartingClassData();
	if not tStartingClassData then
		return "";
	end
	return tStartingClassData.wealthroll or "";
end
function setStartingWealthRoll(sWealthRoll)
	local tStartingClassData = CharWizardManager.getStartingClassData();
	if not tStartingClassData then
		return;
	end
	tStartingClassData.wealthroll = sWealthRoll;
end
function getStartingGold()
	local tStartingClassData = CharWizardManager.getStartingClassData();
	if not tStartingClassData then
		return;
	end
	return tStartingClassData.startinggold or 0;
end
function setStartingGold(n)
	local tStartingClassData = CharWizardManager.getStartingClassData();
	if not tStartingClassData then
		return;
	end
	tStartingClassData.startinggold = n;
end
function getStartingKitItems()
	local tStartingClassData = CharWizardManager.getStartingClassData();
	if not tStartingClassData then
		return {};
	end
	return tStartingClassData.items or {};
end
function setStartingKitItems(tClassItems)
	local tStartingClassData = CharWizardManager.getStartingClassData();
	if not tStartingClassData then
		return;
	end
	tStartingClassData.items = tClassItems;
end
function clearStartingKitItems()
	local tStartingClassData = CharWizardManager.getStartingClassData();
	if not tStartingClassData then
		return;
	end
	tStartingClassData.items = nil;
end
function getStartingKitOptions()
	local tStartingClassData = CharWizardManager.getStartingClassData();
	if not tStartingClassData then
		return {};
	end
	return tStartingClassData.kitoptions or {};
end
function setStartingKitOptions(tClassKitOptions)
	local tStartingClassData = CharWizardManager.getStartingClassData();
	if not tStartingClassData then
		return;
	end
	tStartingClassData.kitoptions = tClassKitOptions;
end
function clearStartingKitOptions()
	local tStartingClassData = CharWizardManager.getStartingClassData();
	if not tStartingClassData then
		return;
	end
	tStartingClassData.kitoptions = nil;
end

--
--	Window
--

function onAddClassSelectButton(wClassPage)
	local bIsClassSelectVisible = wClassPage.sub_classselection.isVisible();
	wClassPage.sub_classselection.setVisible(not bIsClassSelectVisible);

	if wClassPage.sub_classselection.isVisible() then
		wClassPage.button_addclass.setText(Interface.getString("charwizard_label_class_cancel"));
		wClassPage.sub_classselection.subwindow.buildClasses();
	else
		wClassPage.button_addclass.setText(Interface.getString("charwizard_label_class_add"));
	end
end
function onAddClassButton(wClass)
	local _,sClassRecord = wClass.shortcut.getValue();
	CharWizardClassManager.addClass(sClassRecord);

	local wClassPage = CharWizardManager.getWizardClassWindow();
	if CharWizardManager.isLevelUpData() then
		wClassPage.button_addclass.setVisible(false);
		for _,v in pairs(wClassPage.class_list.getWindows()) do
			v.levelup_button.setVisible(false);
			v.level_label.setVisible(true);
			v.level.setVisible(true);
		end
	end
	wClassPage.button_addclass.setText(Interface.getString("charwizard_label_class_add"));
end
function onDeleteClassButton(wClass)
	local bLevelUp = CharWizardManager.isLevelUpData();
	if bLevelUp then
		wClass.windowlist.window.button_addclass.setVisible(true);
		for _,v in pairs(wClass.windowlist.getWindows()) do
			v.levelup_button.setVisible(true);
			v.level_label.setVisible(false);
			v.level.setVisible(true);
		end
	end
	CharWizardClassManager.deleteClass(wClass, bLevelUp);
end
function onAddSubclassButton(wSubclass)
	local sClassName = WindowManager.getOuterControlValue(wSubclass, "class");
	local _, sSubclassRecord = wSubclass.shortcut.getValue();

	CharWizardClassManager.setSubclass(sClassName, sSubclassRecord);
	CharWizardClassManager.updateClass(sClassName, true);

	local wDecision = wSubclass.windowlist.window.parentcontrol.window;
	wDecision.choice.setValue(CharWizardClassManager.getSubclassName(sClassName));
	wDecision.choice.setVisible(true);
	wDecision.button_modify.setVisible(true);
	wDecision.sub_decision_choice.setVisible(false);
	wDecision.checkOutstandingDecisions();

	CharWizardManager.updateAlerts();
end
function onAddFeatClassButton(wFeat)
	local tFeatureData = CharWizardClassManager.buildFeatureDataFromDecision(wFeat);
	local sFeat = wFeat.name.getValue();
	local sFeatClass, sFeatPath = wFeat.shortcut.getValue();

	CharWizardClassManager.setClassFeatureFeatPath(tFeatureData, sFeatPath)
	CharWizardClassManager.updateClass(tFeatureData.sClassName);

	local wDecision = wFeat.windowlist.window.parentcontrol.window;
	wDecision.choice.setValue(sFeat);
	wDecision.choice.setVisible(true);
	wDecision.choicelink.setValue(sFeatClass, sFeatPath);
	wDecision.button_modify.setVisible(true);
	wDecision.sub_decision_choice.setVisible(false);
	wDecision.checkOutstandingDecisions();

	CharWizardManager.updateAlerts();
end

function onLevelUpClassButton(wClass)
	local sClassName = WindowManager.getOuterControlValue(wClass, "class");

	CharWizardClassManager.setClassLevelUp(sClassName);

	wClass.level.setValue(CharWizardClassManager.getClassLevel(sClassName));
	wClass.levelup_button.setVisible(false);
	wClass.cancellevelup_button.setVisible(true);
	wClass.button_features.setVisible(true);
	wClass.button_features.setValue(1);
	wClass.list_features.setVisible(true);

	CharWizardClassManager.updateClass(sClassName);

	wClass.windowlist.window.button_addclass.setVisible(false);
	for _,v in ipairs(wClass.windowlist.getWindows()) do
		if v ~= wClass then
			v.levelup_button.setVisible(false);
		end
	end

	CharWizardManager.updateAlerts();
end
function onCancelLevelUpClassButton(wClass)
	local sClassName = WindowManager.getOuterControlValue(wClass, "class");

	CharWizardClassManager.setClassLevelDown(sClassName);

	wClass.level.setValue(CharWizardClassManager.getClassLevel(sClassName));
	wClass.levelup_button.setVisible(true);
	wClass.cancellevelup_button.setVisible(false);
	wClass.button_features.setVisible(false);
	wClass.button_spells.setVisible(false);

	CharWizardClassManager.clearClassFeatures(sClassName);

	wClass.windowlist.window.button_addclass.setVisible(true);
	for _,v in ipairs(wClass.windowlist.getWindows()) do
		if v ~= wClass then
			v.levelup_button.setVisible(true);
		end
	end

	CharWizardManager.updateAlerts();
end
function onUpdateClassLevel(wClass)
	local sClassName = WindowManager.getOuterControlValue(wClass, "class");

	CharWizardClassManager.setClassLevel(sClassName, wClass.level.getValue());
	CharWizardClassManager.updateClass(sClassName);

	if wClass.sub_class_spells.subwindow then
		wClass.sub_class_spells.subwindow.updateTotals();
		wClass.sub_class_spells.subwindow.sub_spellslist.subwindow.buildFilters();
	end

	CharWizardManager.updateAlerts();
end

function addClass(sClassRecord)
	local sClassName = DB.getValue(DB.findNode(sClassRecord), "name", "");

	local wClassPage = CharWizardManager.getWizardClassWindow();
	local wClass = wClassPage.class_list.createWindow();
	wClass.class.setValue(sClassName);
	wClass.class.setVisible(true);
	wClass.level_label.setVisible(true);
	wClass.level.setVisible(true);
	wClass.idelete.setVisible(true);
	wClass.shortcut.setValue("reference_class", sClassRecord);

	if CharWizardManager.isLevelUpData() and CharWizardClassManager.isClassImport(sClassName) then
		CharWizardClassManager.addClassImport(wClass, sClassName, sClassRecord);
	else
		CharWizardClassManager.addClassStd(wClass, sClassName, sClassRecord);

		wClass.button_features.setVisible(true);
		wClass.button_features.setValue(1);
		wClass.list_features.setVisible(true);
	end

	wClassPage.sub_classselection.setVisible(false);
	wClassPage.button_addclass.setVisible(true);

	CharWizardManager.updateAlerts();
end
function addClassImport(wClass, sClassName, sClassRecord)
	local tClassData = CharWizardManager.getClassData();
	for _,v in pairs(tClassData) do
		v.levelup = nil;
	end

	tClassData[sClassName] = tClassData[sClassName] or {};

	local tClassDataByName = tClassData[sClassName];
	tClassDataByName.record = tClassDataByName.record or sClassRecord;
	tClassDataByName.level = tClassDataByName.level or 1;
	tClassDataByName.window = tClassDataByName.window or wClass;
	tClassDataByName.name = tClassDataByName.name or sClassName;

	wClass.level.setValue(tClassDataByName.level);
	wClass.level_up.setVisible(false);
	wClass.level_down.setVisible(false);
	wClass.level_label.setVisible(false);
	wClass.levelup_button.setVisible(true);
	wClass.idelete.setVisible(false);
	wClass.button_features.setVisible(false);

	CharWizardClassManager.updateClassLevels();
end
function addClassStd(wClass, sClassName, sClassRecord)
	local bMultiClass = CharWizardManager.hasClasses();
	local tClassData = CharWizardManager.getClassData();
	local nodeClass = DB.findNode(sClassRecord);
	local tClassDataByName = {
		record = sClassRecord,
		name = sClassName,
		level = 1,
		window = wClass,
		bIs2024 = (DB.getValue(nodeClass, "version", "") == "2024"),
	};

	if CharWizardManager.isLevelUpData() then
		tClassDataByName.levelup = 1;
	end
	tClassData[sClassName] = tClassDataByName

	if not bMultiClass then
		tClassDataByName.nClassOrder = 1;
		if tClassDataByName.bIs2024 then
			CharWizardClassManager.handleClassEquipmentKit2024();
		else
			CharWizardClassManager.handleClassEquipmentKit2014();
		end
	else
		local nCount = 0;
		for _,_ in pairs(tClassData) do
			nCount = nCount + 1;
		end
		tClassDataByName.nClassOrder = nCount;
	end

	CharWizardClassManager.populateClassProficiencies(wClass, nodeClass, bMultiClass);
	CharWizardClassManager.populateClassFeatures(sClassName);
	CharWizardClassManager.updateClass(sClassName);
end
function deleteClass(wClass, bLevelUp)
	local tClassData = CharWizardManager.getClassData();
	local sClassName = wClass.class.getValue();
	local tClassDataByName = tClassData[sClassName];

	local nDeleteClassOrder = 0;
	if tClassDataByName then
		nDeleteClassOrder = tClassDataByName.nClassOrder;
	end
	tClassData[sClassName] = nil;

	if not bLevelUp then
		if (nDeleteClassOrder > 0) and next(tClassData) then
			for _,v in pairs(tClassData) do
				if v.nClassOrder > nDeleteClassOrder then
					v.nClassOrder = v.nClassOrder - 1;
				end
			end
		end
		if not CharWizardManager.hasClasses() then
			local wClassPage = CharWizardManager.getWizardClassWindow();
			wClassPage.sub_classselection.setVisible(true);
			wClassPage.button_addclass.setVisible(false);
		end
		if (nDeleteClassOrder == 1) then
			CharWizardEquipmentManager.onClassClear();
			CharWizardClassManager.handleClassEquipmentKit();
			CharWizardEquipmentManager.onEquipmentPageUpdate();
		end
	end

	wClass.close();
	CharWizardManager.updateAlerts();
end

local bUpdatingClass = false;
function updateClass(sClassName, bNewSubclassAdd)
	if bUpdatingClass then
		return false;
	end

	bUpdatingClass = true;

	CharWizardClassManager.clearClassFeatures(sClassName);

	if bNewSubclassAdd or (CharWizardClassManager.getClassLevel(sClassName) > 1) then
		CharWizardClassManager.populateClassFeatures(sClassName, bNewSubclassAdd);
	end
	CharWizardClassManager.updateClassLevels();
	CharWizardClassManager.updateSpellSlots(sClassName);

	bUpdatingClass = false;
end
function clearClassFeatures(sClassName)
	local wClass = CharWizardClassManager.getClassWindow(sClassName);
	if not wClass then
		return;
	end
	local tClassDataByName = CharWizardClassManager.getClassDataByName(sClassName);
	if not tClassDataByName then
		return;
	end
	local sSubclass = CharWizardClassManager.getSubclassName(sClassName);

	local nClassLevel = tClassDataByName.level;
	local tRemoveWin = {};
	for _,wFeature in pairs(wClass.list_features.getWindows()) do
		local nFeatureLevel = wFeature.level.getValue();
		local _,sFeatureRecord = wFeature.shortcut.getValue();

		local bRemoveFeature;
		local sFeatureSubclass = StringManager.trim(DB.getValue(DB.findNode(sFeatureRecord), "specialization", ""));
		if sFeatureSubclass == "" then
			bRemoveFeature = (nFeatureLevel > nClassLevel);
		else
			bRemoveFeature = ((nFeatureLevel > nClassLevel) or (sFeatureSubclass ~= sSubclass));
		end

		if bRemoveFeature then
			tClassDataByName.features[wFeature.feature.getValue()] = nil;
			table.insert(tRemoveWin, wFeature);
		end
	end

	for _,wFeature in ipairs(tRemoveWin) do
		wFeature.close();
	end
end
function clearSubclassFeatures(sClassName)
	local wClass = CharWizardClassManager.getClassWindow(sClassName);
	if not wClass then
		return;
	end
	local tClassDataByName = CharWizardClassManager.getClassDataByName(sClassName);
	if not tClassDataByName then
		return;
	end
	local sRecord = CharWizardClassManager.getClassRecord(sClassName);
	if (sRecord or "") == "" then
		return;
	end
	local nodeSubclass = CharWizardClassManager.getSubclassNode(sClassName);
	local tRemoveWin = {};
	if nodeSubclass then
		local tRemoveFeatures = {};
		for _,nodeFeature in pairs(DB.getChildren(nodeSubclass, "features")) do
			local sFeatureName = DB.getValue(nodeFeature, "name", "");
			tRemoveFeatures[sFeatureName] = true;
		end
		for _,wFeature in pairs(wClass.list_features.getWindows()) do
			if tRemoveFeatures[wFeature.feature.getValue()] then
				tClassDataByName.features[wFeature.feature.getValue()] = nil;
				table.insert(tRemoveWin, wFeature);
			end
		end
	end
	for _,wFeature in ipairs(tRemoveWin) do
		wFeature.close();
	end
end
function updateClassLevels()
	if CharWizardManager.isLevelUpData() then
		return;
	end

	local wClassPage = CharWizardManager.getWizardClassWindow();
	local nTotalLevel = 0;
	for _,v in pairs(wClassPage.class_list.getWindows()) do
		local sClassName = v.class.getValue();
		local nClassLevel = v.level.getValue();
		v.level_down.setVisible(nClassLevel > 1);

		CharWizardClassManager.setClassLevel(sClassName, nClassLevel);
		CharWizardClassManager.updateClass(sClassName);

		nTotalLevel = nTotalLevel + nClassLevel;
	end
	for _,v in pairs(wClassPage.class_list.getWindows()) do
		v.level_up.setVisible(nTotalLevel < 20);
	end
end
function updateClassFeatures(wClass)
	for _,wFeature in ipairs(wClass.list_features.getWindows()) do
		local sFeatureType = StringManager.simplify(wFeature.feature.getValue()):gsub("level%d+", "");
		if StringManager.contains({ "skill", "language", "proficiency", "feat", "expertise", "asiclass", "featurechoice" }, sFeatureType) then
			for _,wDecision in ipairs(wFeature.list_decisions.getWindows()) do
				wDecision.decision_choice.clear();
				CharWizardClassManager.handleClassDecision(wDecision);
			end
		end
	end
end
function updateSpellSlots(sClassName)
	local tClassDataByName = CharWizardClassManager.getClassDataByName(sClassName);
	if not tClassDataByName then
		return;
	end

	local tCharMagicData = CharWizardClassManager.getCharWizardMagicData();
	tClassDataByName.spellslots = tCharMagicData.tSpellSlots;
	tClassDataByName.pactmagicslots = tCharMagicData.tPactMagicSlots;

	local wClass = CharWizardClassManager.getClassWindow(sClassName);
	local bCaster = ((tCharMagicData.nCasterLevel > 0) or (tCharMagicData.nPactMagicLevel > 0));
	if bCaster then
		local tClassMagicData = CharWizardClassManager.getCharWizardClassMagicData(sClassName);
		if tClassMagicData then
			tClassDataByName.cantrips = tClassMagicData.nCantrips or 0;
			tClassDataByName.knownspells = tClassMagicData.nKnown or 0;
			tClassDataByName.preparedspells = tClassMagicData.nPrepared or 0;
		end
	end
	if wClass then
		wClass.button_spells.setVisible(bCaster);
		wClass.sub_class_spells.subwindow.updateTotals();
	end
end

function populateClassProficiencies(wClass, nodeClass, bMultiClass)
	local tFeatureData = {
		sClassName = DB.getValue(nodeClass, "name", ""),
		sName = bMultiClass and "Proficiencies (Multiclass)" or "Proficiencies",
		nLevel = 0,
	};
	tFeatureData.bIs2024 = CharWizardClassManager.isClass2024(tFeatureData.sClassName);

	local tProficiencies;
	if bMultiClass then
		tProficiencies = DB.getChildren(nodeClass, "multiclassproficiencies");
	else
		tProficiencies = DB.getChildren(nodeClass, "proficiencies");
	end

	local wClassProf = wClass.list_features.createWindow();
	wClassProf.feature.setValue(tFeatureData.sName);
	wClassProf.level.setValue(tFeatureData.nLevel);

	CharWizardClassManager.addClassFeatureData(tFeatureData);

	local tOutput = {};

	local tProfNodes = {};
	for _,nodeProf in pairs(tProficiencies) do
		local sSourceType = StringManager.simplify(DB.getValue(nodeProf, "name", ""));
		if sSourceType == "" then
			sSourceType = DB.getName(nodeProf);
		end
		if not bMultiClass and (sSourceType == "savingthrows") then
			tProfNodes.savingthrows = nodeProf;
		elseif sSourceType == "skills" then
			tProfNodes.skills = nodeProf;
		elseif sSourceType == "armor" then
			tProfNodes.armor = nodeProf;
		elseif sSourceType == "weapons" then
			tProfNodes.weapons = nodeProf;
		elseif sSourceType == "tools" then
			tProfNodes.tools = nodeProf;
		end
	end

	if tProfNodes.savingthrows then
		CharWizardClassManager.helperAddClassSaveProf(wClassProf, tProfNodes.savingthrows, tFeatureData, tOutput);
	end
	if tProfNodes.skills then
		CharWizardClassManager.helperAddClassSkillProf(wClassProf, tProfNodes.skills, tFeatureData, tOutput);
	end
	if tProfNodes.armor then
		CharWizardClassManager.helperAddClassArmorProf(wClassProf, tProfNodes.armor, tFeatureData, tOutput);
	end
	if tProfNodes.weapons then
		CharWizardClassManager.helperAddClassWeaponProf(wClassProf, tProfNodes.weapons, tFeatureData, tOutput);
	end
	if tProfNodes.tools then
		CharWizardClassManager.helperAddClassToolProf(wClassProf, tProfNodes.tools, tFeatureData, tOutput);
	end

	wClassProf.feature_desc.setValue(table.concat(tOutput, ""));
end
function helperAddClassSaveProf(_, nodeProf, tFeatureData, tOutput)
	local sText = StringManager.trim(DB.getText(nodeProf, "text", ""));
	if (sText == "") or (sText:lower() == "none") then
		return;
	end

	table.insert(tOutput, string.format("<p><b>Saving Throws:</b> %s</p>", sText));

	CharWizardClassManager.setClassFeatureSaveProf(tFeatureData, CharBuildManager.parseAbilitiesFromString(sText));
end
function helperAddClassSkillProf(w, nodeProf, tFeatureData, tOutput)
	local sText = StringManager.trim(DB.getText(nodeProf, "text", ""));

	local tBase, tOptions, nPicks = CharBuildManager.parseSkillsField(sText, tFeatureData.bIs2024);
	if (#tBase == 0) and (nPicks == 0) then
		return;
	end

	table.insert(tOutput, string.format("<p><b>Skills:</b> %s</p>", StringManager.trim(DB.getText(nodeProf, "text", ""))));

	CharWizardClassManager.setClassFeatureSkills(tFeatureData, tBase);

	if nPicks >= #tOptions then
		for _,v in ipairs(tOptions) do
			CharWizardClassManager.addClassFeatureSkillChoice(tFeatureData, v);
		end
	else
		CharWizardDecisionManager.createDecisions(w, { sDecisionType = "skill", nPicks = nPicks, tOptions = tOptions, });
	end

	CharWizardDecisionManager.refreshOverallDecision("skill");
end
function helperAddClassArmorProf(w, nodeProf, tFeatureData, tOutput)
	local sText = StringManager.trim(DB.getText(nodeProf, "text", ""));

	local tBase, tOptions, nPicks = CharBuildManager.parseArmorField(sText, tFeatureData.bIs2024)
	if #tBase == 0 and nPicks == 0 then
		return;
	end

	table.insert(tOutput, string.format("<p><b>%s:</b> %s</p>", Interface.getString("char_label_addprof_armor"), sText));

	CharWizardClassManager.setClassFeatureArmorProf(tFeatureData, tBase);

	if nPicks >= #tOptions then
		for _,v in ipairs(tOptions) do
			CharWizardClassManager.addClassFeatureArmorProfChoice(tFeatureData, v);
		end
	else
		CharWizardDecisionManager.createDecisions(w, { sDecisionType = "armorprof", nPicks = nPicks, tOptions = tOptions, });
	end

	CharWizardDecisionManager.refreshOverallDecision("armorprof");
end
function helperAddClassWeaponProf(w, nodeProf, tFeatureData, tOutput)
	local sText = StringManager.trim(DB.getText(nodeProf, "text", ""));

	local tBase, tOptions, nPicks = CharBuildManager.parseWeaponField(sText, tFeatureData.bIs2024)
	if #tBase == 0 and nPicks == 0 then
		return;
	end

	table.insert(tOutput, string.format("<p><b>%s:</b> %s</p>", Interface.getString("char_label_addprof_weapon"), sText));

	CharWizardClassManager.setClassFeatureWeaponProf(tFeatureData, tBase);

	if nPicks >= #tOptions then
		for _,v in ipairs(tOptions) do
			CharWizardClassManager.addClassFeatureWeaponProfChoice(tFeatureData, v);
		end
	else
		CharWizardDecisionManager.createDecisions(w, { sDecisionType = "weaponprof", nPicks = nPicks, tOptions = tOptions, });
	end

	CharWizardDecisionManager.refreshOverallDecision("weaponprof");
end
function helperAddClassToolProf(w, nodeProf, tFeatureData, tOutput)
	local sText = StringManager.trim(DB.getText(nodeProf, "text", ""));

	local tBase, tOptions, nPicks = CharBuildManager.parseToolsField(sText, tFeatureData.bIs2024)
	if #tBase == 0 and nPicks == 0 then
		return;
	end

	table.insert(tOutput, string.format("<p><b>%s:</b> %s</p>", Interface.getString("char_label_addprof_tool"), sText));

	CharWizardClassManager.setClassFeatureToolProf(tFeatureData, tBase);

	if nPicks >= #tOptions then
		for _,v in ipairs(tOptions) do
			CharWizardClassManager.addClassFeatureToolProfChoice(tFeatureData, v);
		end
	else
		CharWizardDecisionManager.createDecisions(w, { sDecisionType = "toolprof", nPicks = nPicks, tOptions = tOptions, });
	end

	CharWizardDecisionManager.refreshOverallDecision("toolprof");
end

function populateClassFeatures(sClassName, bNewSubclassAdd)
	local sRecord = CharWizardClassManager.getClassRecord(sClassName);
	if (sRecord or "") == "" then
		return;
	end

	-- Class Features
	local sSubclass = CharWizardClassManager.getSubclassName(sClassName);
	local tAddFeatures = {};
	for _,nodeFeature in ipairs(DB.getChildList(DB.getPath(sRecord, "features"))) do
		if CharWizardClassManager.checkAddFeature(nodeFeature, sClassName, sSubclass, bNewSubclassAdd) then
			local sFeatureName = DB.getValue(nodeFeature, "name", "");
			tAddFeatures[sFeatureName] = { node = nodeFeature };
		end
	end

	-- Subclass Features
	local nodeSubclass = CharWizardClassManager.getSubclassNode(sClassName);
	if nodeSubclass then
		-- If Legacy subclass with old record format, need to go up a level to find features interleaved with main class
		local nodeSubclassFeatureSource;
		if DB.getPath(nodeSubclass):match("classdata") then
			nodeSubclassFeatureSource = DB.getChild(nodeSubclass, "...");
		else
			nodeSubclassFeatureSource = nodeSubclass;
		end
		for _,nodeFeature in pairs(DB.getChildren(nodeSubclassFeatureSource, "features")) do
			if CharWizardClassManager.checkAddFeature(nodeFeature, sClassName, sSubclass, bNewSubclassAdd) then
				local sFeatureName = DB.getValue(nodeFeature, "name", "");
				tAddFeatures[sFeatureName] = { node = nodeFeature, subclass = sSubclass };
			end
		end
	end

	for _,v in pairs(tAddFeatures) do
		CharWizardClassManager.addClassFeature(sClassName, v.node, sSubclass);
	end
end
function checkAddFeature(nodeFeature, sClassName, sSubclass, bNewSubclassAdd)
	local tFeatureData = {
		sClassName = sClassName,
		sName = DB.getValue(nodeFeature, "name", ""),
		nLevel = DB.getValue(nodeFeature, "level", 0),
		bIs2024 = CharWizardClassManager.isClass2024(sClassName),
	};

	-- Check if feature has already been added to the wizard class screen
	if CharWizardClassManager.hasClassFeatureData(tFeatureData) then
		return false;
	end

	-- Otherwise, check to see if the feature should be added, based on class level and specialization
	local bAddFeature = false;
	local sFeatureSubclass = StringManager.trim(DB.getValue(nodeFeature, "specialization", ""));
	local nClassLevel = CharWizardClassManager.getClassLevel(sClassName);
	local bLevelUp = CharWizardManager.isLevelUpData();
	if sFeatureSubclass == "" then
		if not bLevelUp and bNewSubclassAdd then
			bAddFeature = (tFeatureData.nLevel <= nClassLevel);
		else
			bAddFeature = (tFeatureData.nLevel == nClassLevel);
		end
	elseif StringManager.simplify(sFeatureSubclass) == StringManager.simplify(sSubclass) then
		if not bLevelUp and bNewSubclassAdd then
			bAddFeature = (tFeatureData.nLevel <= nClassLevel);
		else
			bAddFeature = (tFeatureData.nLevel == nClassLevel);
		end
	end

	return bAddFeature;
end
function addClassFeature(sClassName, nodeFeature)
	local wClass = CharWizardClassManager.getClassWindow(sClassName);
	if not wClass then
		return;
	end

	local tFeatureData = {
		sClassName = sClassName,
		sName = DB.getValue(nodeFeature, "name", ""),
		nLevel = DB.getValue(nodeFeature, "level", 0),
		bIs2024 = CharWizardClassManager.isClass2024(sClassName),
	};
	tFeatureData.sType = StringManager.simplify(tFeatureData.sName);

	CharWizardClassManager.addClassFeatureData(tFeatureData);

	local wClassFeature = wClass.list_features.createWindow();
	wClassFeature.feature.setValue(tFeatureData.sName);
	wClassFeature.level.setValue(tFeatureData.nLevel);
	wClassFeature.feature_desc.setValue(DB.getValue(nodeFeature, "text", ""));
	wClassFeature.shortcut.setValue("reference_classfeature", DB.getPath(nodeFeature));

	if tFeatureData.sType:match("subclass$") or (DB.getValue(nodeFeature, "specializationchoice", 0) > 0) then
		local w2 = CharWizardDecisionManager.createDecision(wClassFeature, { sDecisionType = "subclass", sDecisionClass = "decision_sub_subclass_choice", });
		w2.sub_decision_choice.subwindow.setClassName(tFeatureData.sClassName);
	elseif tFeatureData.sType == "abilityscoreimprovement" then
		CharWizardDecisionManager.createDecision(wClassFeature, { sDecisionType = "asiorfeat", });
	elseif tFeatureData.sType == "expertise" then
		CharWizardDecisionManager.createDecisions(wClassFeature, { sDecisionType = "expertise", nPicks = 2, });
		CharWizardDecisionManager.refreshExpertiseDecision();
	elseif tFeatureData.bIs2024 and CharWizardData.tBuildOptionsFeats2024[tFeatureData.sType] then
		CharWizardDecisionManager.createDecision(wClassFeature, { sDecisionType = "feat", sDecisionClass = "decision_sub_classfeat_choice", });
	else
		local bSkipTextParsing = CharWizardClassManager.handleFeatureChoices(wClassFeature, tFeatureData);

		if not bSkipTextParsing then
			local sFeatureText = wClassFeature.feature_desc.getText();
			CharWizardClassManager.handleFeatureSkills(wClassFeature, tFeatureData, sFeatureText);
			CharWizardClassManager.handleFeatureArmorProf(wClassFeature, tFeatureData, sFeatureText);
			CharWizardClassManager.handleFeatureWeaponProf(wClassFeature, tFeatureData, sFeatureText);
			CharWizardClassManager.handleFeatureToolProf(wClassFeature, tFeatureData, sFeatureText);
			CharWizardClassManager.handleFeatureLanguages(wClassFeature, tFeatureData, sFeatureText);
		end
	end
end
function handleFeatureChoices(wClassFeature, tFeatureData)
	if not tFeatureData or not tFeatureData.bIs2024 then
		return false;
	end
	local tAction = CharWizardDataAction.tBuildDataClass2024[tFeatureData.sType];
	if not tAction or not tAction.choicetype then
		return false;
	end

	if tAction.followon then
		return true;
	end
	if tAction.choicetype then
		local tFeatureChoices = CharWizardClassManager.collectFeatureChoicesByChoiceType(tFeatureData.sClassName, tAction.choicetype);
		if #tFeatureChoices > 0 then
			local tOptions = {};
			for _,v in ipairs(tFeatureChoices) do
				table.insert(tOptions, CharClassManager.getFeatureChoiceDisplayName(v));
			end
			local nPicks = tAction.choicenum or 1;
			for _ = 1, nPicks do
				CharWizardDecisionManager.createDecision(wClassFeature, { sDecisionType = "featurechoice", tOptions = tOptions });
			end
		end

		return true;
	end

	return false;
end

function collectFeatureChoicesByChoiceType(sClassName, sChoiceType, bFinalize)
	local tResults = {};

	local nodeClass = CharWizardClassManager.getClassNode(sClassName);
	CharWizardClassManager.helperCheckFeatureChoiceRecordOptions(sClassName, sChoiceType, bFinalize, nodeClass, tResults);

	local nodeSubclass = CharWizardClassManager.getSubclassNode(sClassName);
	CharWizardClassManager.helperCheckFeatureChoiceRecordOptions(sClassName, sChoiceType, bFinalize, nodeSubclass, tResults);

	return tResults;
end
function helperCheckFeatureChoiceRecordOptions(sClassName, sChoiceType, bFinalize, nodeRecord, tResults)
	if not nodeRecord then
		return;
	end
	for _,v in ipairs(DB.getChildList(nodeRecord, "featurechoices")) do
		CharWizardClassManager.helperCheckFeatureChoiceMatch(sClassName, sChoiceType, bFinalize, v, tResults);
	end
end
function helperCheckFeatureChoiceMatch(sClassName, sChoiceType, bFinalize, nodeChoice, tResults)
	if DB.getValue(nodeChoice, "choicetype", "") ~= sChoiceType then
		return;
	end
	if bFinalize then
		table.insert(tResults, nodeChoice);
		return;
	end

	local nLevel = DB.getValue(nodeChoice, "level", 0);
	if (nLevel > 0) and (nLevel > CharWizardClassManager.getClassLevel(sClassName)) then
		return;
	end

	local sPrereq = StringManager.trim(DB.getValue(nodeChoice, "prerequisite", ""));
	if sPrereq ~= "" then
		if not CharWizardClassManager.hasClassFeatureChoice({ sClassName = sClassName, sName = sPrereq, }) then
			return;
		end
	end

	local sOption = CharClassManager.getFeatureChoiceDisplayName(nodeChoice);
	local bHasFeatureChoice = CharWizardClassManager.hasClassFeatureChoice({ sClassName = sClassName, sName = sOption });
	if bHasFeatureChoice and (DB.getValue(nodeChoice, "repeatable", 0) ~= 1) then
		return;
	end
	table.insert(tResults, nodeChoice);
end
function updateFeatureExpertiseChoices(sClassName, w)
	local tProfs = CharWizardManager.collectSkills();
	if not CharWizardClassManager.isClass2024(sClassName) and (sClassName:lower() == "rogue") then
		table.insert(tProfs, "Thieves' Tools");
	end

	w.decision_choice.clear();

	for _,v in ipairs(tProfs) do
		w.decision_choice.add(v);
	end
end

function handleFeatureSkills(w, tFeatureData, sFeatureText)
	local tBase, tOptions, nPicks = CharBuildManager.getClassFeatureSkills(tFeatureData.sName, sFeatureText, tFeatureData.bIs2024);

	CharWizardClassManager.setClassFeatureSkills(tFeatureData, tBase);

	if nPicks >= #tOptions then
		for _,v in ipairs(tOptions) do
			CharWizardClassManager.addClassFeatureSkillChoice(tFeatureData, v);
		end
	else
		CharWizardDecisionManager.createDecisions(w, { sDecisionType = "skill", nPicks = nPicks, tOptions = tOptions, });
	end

	CharWizardDecisionManager.refreshOverallDecision("skill");
end
function handleFeatureArmorProf(w, tFeatureData, sFeatureText)
	local tBase, tOptions, nPicks = CharBuildManager.getClassFeatureArmorProf(tFeatureData.sName, sFeatureText, tFeatureData.bIs2024)

	CharWizardClassManager.setClassFeatureArmorProf(tFeatureData, tBase);

	if nPicks >= #tOptions then
		for _,v in ipairs(tOptions) do
			CharWizardClassManager.addClassFeatureArmorProfChoice(tFeatureData, v);
		end
	else
		CharWizardDecisionManager.createDecisions(w, { sDecisionType = "armorprof", nPicks = nPicks, tOptions = tOptions, });
	end

	CharWizardDecisionManager.refreshOverallDecision("armorprof");
end
function handleFeatureWeaponProf(w, tFeatureData, sFeatureText)
	local tBase, tOptions, nPicks = CharBuildManager.getClassFeatureWeaponProf(tFeatureData.sName, sFeatureText, tFeatureData.bIs2024)

	CharWizardClassManager.setClassFeatureWeaponProf(tFeatureData, tBase);

	if nPicks >= #tOptions then
		for _,v in ipairs(tOptions) do
			CharWizardClassManager.addClassFeatureWeaponProfChoice(tFeatureData, v);
		end
	else
		CharWizardDecisionManager.createDecisions(w, { sDecisionType = "weaponprof", nPicks = nPicks, tOptions = tOptions, });
	end

	CharWizardDecisionManager.refreshOverallDecision("weaponprof");
end
function handleFeatureToolProf(w, tFeatureData, sFeatureText)
	local tBase, tOptions, nPicks = CharBuildManager.getClassFeatureToolProf(tFeatureData.sName, sFeatureText, tFeatureData.bIs2024)

	CharWizardClassManager.setClassFeatureToolProf(tFeatureData, tBase);

	if nPicks >= #tOptions then
		for _,v in ipairs(tOptions) do
			CharWizardClassManager.addClassFeatureToolProfChoice(tFeatureData, v);
		end
	else
		CharWizardDecisionManager.createDecisions(w, { sDecisionType = "toolprof", nPicks = nPicks, tOptions = tOptions, });
	end

	CharWizardDecisionManager.refreshOverallDecision("toolprof");
end
function handleFeatureLanguages(w, tFeatureData, sFeatureText)
	local tBase, tOptions, nPicks = CharBuildManager.getClassFeatureLanguages(tFeatureData.sName, sFeatureText, tFeatureData.bIs2024)

	CharWizardClassManager.setClassFeatureLanguages(tFeatureData, tBase);

	if nPicks >= #tOptions then
		for _,v in ipairs(tOptions) do
			CharWizardClassManager.addClassFeatureLanguageChoice(tFeatureData, v);
		end
	else
		CharWizardDecisionManager.createDecisions(w, { sDecisionType = "language", nPicks = nPicks, tOptions = tOptions, });
	end

	CharWizardDecisionManager.refreshOverallDecision("language");
end

--
-- Spells
--

function getCharWizardMagicData()
	local tCharMagicData = {};
	for _,tClassData in pairs(CharWizardManager.getClassData()) do
		table.insert(tCharMagicData, CharWizardClassManager.helperGetCharWizardClassMagicData(tClassData));
	end
	tCharMagicData.nCasterLevel = CharClassManager.helperCalcSpellcastingLevel(tCharMagicData);
	tCharMagicData.nPactMagicLevel = CharClassManager.helperCalcPactMagicLevel(tCharMagicData);
	tCharMagicData.tSpellSlots = CharClassManager.helperGetSpellcastingSlotChange(0, tCharMagicData.nCasterLevel);
	tCharMagicData.tPactMagicSlots = CharClassManager.helperGetPactMagicSlotChange(0, tCharMagicData.nPactMagicLevel);
	return tCharMagicData;
end
function getCharWizardClassMagicData(sClassName)
	local tClassData = CharWizardClassManager.getClassDataByName(sClassName);
	return CharWizardClassManager.helperGetCharWizardClassMagicData(tClassData);
end
function helperGetCharWizardClassMagicData(tClassData)
	if not tClassData or ((tClassData.record or "") == "") then
		return nil;
	end
	local nodeClass = DB.findNode(tClassData.record);
	if not nodeClass then
		return nil;
	end

	local tData = {};
	tData.sClassName = DB.getValue(nodeClass, "name", "");
	tData.nClassLevel = tClassData.level or 0;
	tData.sSubclass = CharWizardClassManager.getSubclassName(tData.sClassName);

	for _,nodeFeature in pairs(DB.getChildren(nodeClass, "features")) do
		if DB.getValue(nodeFeature, "level", 0) <= tData.nClassLevel then
			local sFeatureSubclass = DB.getValue(nodeFeature, "specialization", "");
			local bAdd = ((sFeatureSubclass == "") or (StringManager.simplify(sFeatureSubclass) == StringManager.simplify(tData.sSubclass)));
			if bAdd then
				local sFeatureName = DB.getValue(nodeFeature, "name", "");
				local sSourceNameLower = StringManager.simplify(sFeatureName);
				local bSpellcasting = (sSourceNameLower == "spellcasting");
				tData.bPactMagic = (sSourceNameLower == "pactmagic");
				if (bSpellcasting or tData.bPactMagic) then
					tData.nodeSource = nodeFeature;
					tData.bSource2024 = (DB.getValue(nodeClass, "version", "") == "2024");
					break;
				end
			end
		end
	end
	if not tData.nodeSource then
		local nodeSubclass = CharWizardClassManager.getSubclassNode(tData.sClassName);
		if nodeSubclass then
			for _,nodeFeature in pairs(DB.getChildren(nodeSubclass, "features")) do
				if DB.getValue(nodeFeature, "level", 0) <= tData.nClassLevel then
					local sFeatureName = DB.getValue(nodeFeature, "name", "");
					local sSourceNameLower = StringManager.simplify(sFeatureName);
					local bSpellcasting = (sSourceNameLower == "spellcasting");
					tData.bPactMagic = (sSourceNameLower == "pactmagic");
					if (bSpellcasting or tData.bPactMagic) then
						tData.nodeSource = nodeFeature;
						tData.bSource2024 = (DB.getValue(nodeSubclass, "version", "") == "2024");
						break;
					end
				end
			end
		end
	end
	if not tData.nodeSource then
		return nil;
	end

	tData.tAbilities = {};
	local tASI = CharWizardManager.getAbilityData();
	for _,sAbility in pairs(DataCommon.abilities) do
		tData.tAbilities[sAbility] = tASI[sAbility] and tASI[sAbility].total or 10;
	end

	local tClassMagicData = CharBuildManager.getClassFeatureSpellcastingData(tData);

	tClassMagicData.bPactMagic = tData.bPactMagic;
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

	return tClassMagicData;
end

--
--	Decisions
--

local _bUpdatingDecision = false
function processClassDecision(wDecision)
	if _bUpdatingDecision then
		return
	end
	_bUpdatingDecision = true;

	CharWizardClassManager.handleClassDecision(wDecision);
	for _,v in ipairs(CharWizardManager.getWizardClassWindow().class_list.getWindows()) do
		CharWizardClassManager.updateClassFeatures(v);
	end

	_bUpdatingDecision = false;

	CharWizardManager.updateAlerts();
end
function resetClassDecision(wDecision)
	local sDecisionType = wDecision.decisiontype.getValue();
	if sDecisionType == "subclass" then
		local sClassName = WindowManager.getOuterControlValue(wDecision.windowlist, "class");
		CharWizardClassManager.clearSubclassFeatures(sClassName);
		CharWizardClassManager.setSubclass(sClassName, nil);
		CharWizardClassManager.updateClass(sClassName, false);
	elseif sDecisionType == "feat" then
		local tFeatureData = CharWizardClassManager.buildFeatureDataFromDecision(wDecision);
		CharWizardClassManager.clearClassFeatureFeatPath(tFeatureData);
	end

	wDecision.choice.setValue();
	wDecision.button_modify.setVisible(false);
	wDecision.sub_decision_choice.setVisible(true);

	CharWizardAbilitiesManager.updateAbilities();
	CharWizardDecisionManager.refreshOverallDecisions();
	CharWizardManager.updateAlerts();
end

function handleClassDecision(wDecision)
	local sDecisionType = wDecision.decisiontype.getValue();
	if sDecisionType == "asiorfeat" then
		CharWizardClassManager.handleASIOrFeatDecision(wDecision);
	elseif sDecisionType == "asiclassoption" then
		CharWizardClassManager.handleClassASIOptionDecision(wDecision)
	elseif sDecisionType == "asiclass" then
		CharWizardClassManager.handleClassASIDecision(wDecision)
	elseif sDecisionType == "feat" then
		CharWizardClassManager.handleClassFeatDecision(wDecision)
	elseif sDecisionType == "skill" then
		CharWizardClassManager.handleClassSkillDecision(wDecision)
	elseif sDecisionType == "expertise" then
		CharWizardClassManager.handleClassExpertiseDecision(wDecision)
	elseif sDecisionType == "language" then
		CharWizardClassManager.handleClassLanguageDecision(wDecision)
	elseif sDecisionType == "armorprof" then
		CharWizardClassManager.handleClassArmorProfDecision(wDecision)
	elseif sDecisionType == "weaponprof" then
		CharWizardClassManager.handleClassWeaponProfDecision(wDecision)
	elseif sDecisionType == "toolprof" then
		CharWizardClassManager.handleClassToolProfDecision(wDecision)
	elseif sDecisionType == "featurechoice" then
		CharWizardClassManager.handleClassFeatureChoiceDecision(wDecision)
	end
end
function handleASIOrFeatDecision(wDecision)
	local tFeatureData = CharWizardClassManager.buildFeatureDataFromDecision(wDecision);

	CharWizardClassManager.clearClassFeatureAbilityIncreases(tFeatureData);
	CharWizardClassManager.clearClassFeatureFeatPath(tFeatureData);

	for _,w in pairs(wDecision.windowlist.getWindows()) do
		if w.decisiontype.getValue() == "asiclass" or w.decisiontype.getValue() == "asiclassoption" or w.decisiontype.getValue() == "feat" then
			w.close();
		end
	end

	local sOption = wDecision.decision_choice.getValue():lower();
	if sOption == "ability score increase" then
		CharWizardDecisionManager.createDecision(wDecision.windowlist.window, { sDecisionType = "asiclassoption", });
	elseif sOption == "feat" then
		CharWizardDecisionManager.createDecision(wDecision.windowlist.window, { sDecisionType = "feat", sDecisionClass = "decision_sub_classfeat_choice", });
	end

	CharWizardAbilitiesManager.updateAbilities();
end
function handleClassASIOptionDecision(wDecision)
	local tFeatureData = CharWizardClassManager.buildFeatureDataFromDecision(wDecision);

	CharWizardClassManager.clearClassFeatureAbilityIncreases(tFeatureData);

	for _,w in pairs(wDecision.windowlist.getWindows()) do
		if w.decisiontype.getValue() == "asiclass" then
			w.close();
		end
	end

	local sOption = wDecision.decision_choice.getValue():lower();
	if sOption:match("option 1") then
		CharWizardDecisionManager.createDecision(wDecision.windowlist.window, { sDecisionType = "asiclass", nAdj = 2 });
	else
		for _ = 1, 2 do
			CharWizardDecisionManager.createDecision(wDecision.windowlist.window, { sDecisionType = "asiclass", nAdj = 1 });
		end
	end

	CharWizardAbilitiesManager.updateAbilities();
end
function handleClassASIDecision(wDecision)
	local tFeatureData = CharWizardClassManager.buildFeatureDataFromDecision(wDecision);

	CharWizardClassManager.clearClassFeatureAbilityIncreases(tFeatureData);
	CharWizardClassManager.clearClassFeatureFeatPath(tFeatureData);

	local tAbilityIncreases = CharWizardDecisionManager.processFeatureAbilityDecision(wDecision);
	for sAbility,nMod in pairs(tAbilityIncreases) do
		CharWizardClassManager.addClassFeatureAbilityIncreases(tFeatureData, sAbility, nMod);
	end

	CharWizardAbilitiesManager.updateAbilities();
end
function handleClassFeatDecision(wDecision)
	local tFeatureData = CharWizardClassManager.buildFeatureDataFromDecision(wDecision);
	local sFeat = wDecision.choice.getValue();
	local _,sFeatPath = wDecision.choicelink.getValue();

	CharWizardClassManager.clearClassFeatureAbilityIncreases(tFeatureData);
	CharWizardClassManager.setClassFeatureFeatPath(tFeatureData, sFeatPath);

	wDecision.button_modify.setVisible(sFeat ~= "");
	wDecision.sub_decision_choice.setVisible(sFeat == "");

	CharWizardManager.updateAlerts();

	for _,w in pairs(wDecision.windowlist.getWindows()) do
		if w.decisiontype.getValue() == "asiclass" then
			w.close();
		end
	end
end
function handleClassSkillDecision(wDecision)
	local tFeatureData = CharWizardClassManager.buildFeatureDataFromDecision(wDecision);

	CharWizardClassManager.clearClassFeatureSkillChoice(tFeatureData);

	local tMap = CharWizardDecisionManager.processSkillDecision(wDecision);
	for _,s in pairs(tMap) do
		CharWizardClassManager.addClassFeatureSkillChoice(tFeatureData, s);
	end

	CharWizardDecisionManager.refreshExpertiseDecision();
end
function handleClassExpertiseDecision(wDecision)
	local tFeatureData = CharWizardClassManager.buildFeatureDataFromDecision(wDecision);

	CharWizardClassManager.clearClassFeatureExpertiseChoice(tFeatureData);

	local tMap = CharWizardDecisionManager.processExpertiseDecision(wDecision);
	for _,s in pairs(tMap) do
		CharWizardClassManager.addClassFeatureExpertiseChoice(tFeatureData, s);
	end
end
function handleClassArmorProfDecision(wDecision)
	local tFeatureData = CharWizardClassManager.buildFeatureDataFromDecision(wDecision);

	CharWizardClassManager.clearClassFeatureArmorProfChoice(tFeatureData);

	local tMap = CharWizardDecisionManager.processArmorProfDecision(wDecision);
	for _,s in pairs(tMap) do
		CharWizardClassManager.addClassFeatureArmorProfChoice(tFeatureData, s);
	end
end
function handleClassWeaponProfDecision(wDecision)
	local tFeatureData = CharWizardClassManager.buildFeatureDataFromDecision(wDecision);

	CharWizardClassManager.clearClassFeatureWeaponProfChoice(tFeatureData);

	local tMap = CharWizardDecisionManager.processWeaponProfDecision(wDecision);
	for _,s in pairs(tMap) do
		CharWizardClassManager.addClassFeatureWeaponProfChoice(tFeatureData, s);
	end
end
function handleClassToolProfDecision(wDecision)
	local tFeatureData = CharWizardClassManager.buildFeatureDataFromDecision(wDecision);

	CharWizardClassManager.clearClassFeatureToolProfChoice(tFeatureData);

	local tMap = CharWizardDecisionManager.processToolProfDecision(wDecision);
	for _,s in pairs(tMap) do
		CharWizardClassManager.addClassFeatureToolProfChoice(tFeatureData, s);
	end
end
function handleClassLanguageDecision(wDecision)
	local tFeatureData = CharWizardClassManager.buildFeatureDataFromDecision(wDecision);

	CharWizardClassManager.clearClassFeatureLanguageChoice(tFeatureData);

	local tMap = CharWizardDecisionManager.processLanguageDecision(wDecision);
	for _,s in pairs(tMap) do
		CharWizardClassManager.addClassFeatureLanguageChoice(tFeatureData, s);
	end
end
function handleClassFeatureChoiceDecision(wDecision)
	local tFeatureData = CharWizardClassManager.buildFeatureDataFromDecision(wDecision);

	CharWizardClassManager.clearClassFeatureChoiceSelections(tFeatureData);
	CharWizardClassManager.clearClassFeatureFeatPath(tFeatureData);

	for _,w in pairs(wDecision.windowlist.getWindows()) do
		if w.decisiontype.getValue() == "feat" then
			w.close();
		end
	end

	local tMap = CharWizardDecisionManager.processFeatureChoiceDecision(wDecision);
	for _,s in pairs(tMap) do
		CharWizardClassManager.addClassFeatureChoiceSelection(tFeatureData, s);
		if s == "Fighting Style" then
			CharWizardDecisionManager.createDecision(wDecision.windowlist.window, { sDecisionType = "feat", sDecisionClass = "decision_sub_classfeat_choice", });
		end
	end
end

--
-- Equipment Kit
--

function handleClassEquipmentKit()
	if CharWizardClassManager.isStartingClass2024() then
		CharWizardClassManager.handleClassEquipmentKit2024();
	else
		CharWizardClassManager.handleClassEquipmentKit2014();
	end
end
function handleClassEquipmentKit2024()
	local sClassRecord = CharWizardClassManager.getStartingClassRecord();
	if (sClassRecord or "") == "" then
		CharWizardManager.setStartingGold();
		CharWizardClassManager.clearStartingKitOptions();
		return;
	end

	local tOptions = {};
	for _,nodeOption in ipairs(DB.getChildList(DB.getPath(sClassRecord, "startingequipmentlist"))) do
		local tItems = { items = {}, };

		local nWealth = DB.getValue(nodeOption, "wealth", 0);
		if nWealth > 0 then
			tItems.wealth = nWealth;
		end

		for _,nodeItem in ipairs(DB.getChildList(nodeOption, "items")) do
			local nCount = DB.getValue(nodeItem, "count", 0);
			table.insert(tItems.items, { item = nodeItem, count = nCount });
		end

		table.insert(tOptions, tItems);
	end

	CharWizardManager.setStartingGold();
	CharWizardClassManager.setStartingKitOptions(tOptions);
end

local tSelections = {};
function handleClassEquipmentKit2014()
	local tInnateItems = {};
	local tKitOptions = {};
	local sWealthRoll = 0;

	local sClassName = CharWizardClassManager.getStartingClassName();

	local sClassNameLower = sClassName:lower();
	local tStartingKit = CharWizardData.charwizard_starting_equipment[sClassNameLower] or {};
	if tStartingKit and next(tStartingKit) then
		sWealthRoll = tStartingKit.starting_wealth;

		if tStartingKit.included then
			for _,vItem in ipairs(tStartingKit.included) do
				local tItemFilters = {
					{ sField = "name", sValue = vItem.item, bIgnoreCase = true, },
					{ sField = "version", sValue = "", },
				};
				local nodeItem = RecordManager.findRecordByFilter("item", tItemFilters);
				if nodeItem then
					table.insert(tInnateItems, { item = nodeItem, count = vItem.count });
				end
			end
		end

		if tStartingKit.choices then
			for _,vChoice in ipairs(tStartingKit.choices) do
				tSelections = {};
				for _,vItem in ipairs(vChoice) do
					if vItem.selection then
						local tItemFilters = {
							{ sField = "subtype", sValue = vItem.selection, bIgnoreCase = true, },
							{ sField = "version", sValue = "", },
						};
						RecordManager.callForEachRecordByFilter("item", tItemFilters, CharWizardClassManager.handleKitSelectionItem, vItem.count);
					end
					if vItem.item then
						local tItemFilters = {
							{ sField = "name", sValue = vItem.item, bIgnoreCase = true, },
							{ sField = "version", sValue = "", },
						};
						local nodeItem = RecordManager.findRecordByFilter("item", tItemFilters);
						if nodeItem then
							table.insert(tSelections, { item = nodeItem, count = vItem.count });
						end
					end
				end
				if #tSelections > 0 then
					table.insert(tKitOptions, tSelections);
				end
			end
		end
	end

	CharWizardClassManager.setStartingWealthRoll(sWealthRoll);
	CharWizardClassManager.setStartingKitItems(tInnateItems);
	CharWizardClassManager.setStartingKitOptions(tKitOptions);
end
function handleKitSelectionItem(nodeItem, nCount)
	if StringManager.trim(DB.getValue(nodeItem, "properties", "")):match("magic") then
		return;
	end
	table.insert(tSelections, { item = nodeItem, count = nCount });
end

--
-- Spells
--

function addClassKnownSpell(w)
	local sClassName = WindowManager.getOuterControlValue(w, "class");
	local tClassDataByName = CharWizardClassManager.getClassDataByName(sClassName);
	if not tClassDataByName then
		return;
	end
	tClassDataByName.spell = tClassDataByName.spell or {};

	local _, sRecord = w.shortcut.getValue();
	table.insert(tClassDataByName.spell, sRecord);

	local wKnownSpells = w.windowlist.window.parentcontrol.window.sub_spellsknownlist.subwindow;
	local wAvailableSpells = w.windowlist.window;
	wKnownSpells.buildRecords();
	wAvailableSpells.buildSpells();
end
function removeClassKnownSpell(w)
	local sClassName = WindowManager.getOuterControlValue(w, "class");
	local tClassDataByName = CharWizardClassManager.getClassDataByName(sClassName);
	if not tClassDataByName then
		return;
	end

	local _, sRecord = w.shortcut.getValue();
	for k,v in pairs(tClassDataByName.spell or {}) do
		if sRecord == v then
			table.remove(tClassDataByName.spell, k);
			break;
		end
	end

	local wKnownSpells = w.windowlist.window;
	local wAvailableSpells = w.windowlist.window.parentcontrol.window.sub_spellslist.subwindow;
	wKnownSpells.buildRecords();
	wAvailableSpells.buildSpells();
	wAvailableSpells.buildFilters();
end
