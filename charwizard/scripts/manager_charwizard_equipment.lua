--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	ActionsManager.registerResultHandler("charwizardwealthroll", CharWizardEquipmentManager.onWealthRoll);
end
--
--	STARTING KIT UI
--

function onEquipmentPageUpdate()
	CharWizardEquipmentManager.onKitUpdate();
	CharWizardEquipmentManager.onWealthUpdate();
end

function getWizardEquipmentKitWindow()
	local wEquipment = CharWizardManager.getWizardEquipmentWindow();
	if not wEquipment then
		return nil;
	end
	return wEquipment.sub_equipment_startingkit.subwindow;
end
function getWizardEquipmentWealthWindow()
	local wEquipment = CharWizardManager.getWizardEquipmentWindow();
	if not wEquipment then
		return nil;
	end
	return wEquipment.sub_equipment_startingwealth.subwindow;
end

function onBackgroundClear()
	CharWizardEquipmentManager.onBackgroundKitClear();
	CharWizardEquipmentManager.onBackgroundWealthClear();
end
function onClassClear()
	CharWizardEquipmentManager.onClassKitClear();
	CharWizardEquipmentManager.onClassWealthClear();
	CharWizardEquipmentManager.onRolledWealthClear();
end

function updateKitVisibility()
	local wEquipment = CharWizardManager.getWizardEquipmentWindow();
	if not wEquipment then
		return;
	end

	local bShowKits = CharWizardClassManager.isStartingClass2024() or (CharWizardManager.getStartingGold() == 0);
	wEquipment.sub_equipment_startingkit.setVisible(bShowKits);
end

--
--	KIT
--

function onKitUpdate()
	CharWizardEquipmentManager.onBackgroundKitUpdate();
	CharWizardEquipmentManager.onClassKitUpdate();
end

function onBackgroundKitUpdate()
	local wEquipmentKit = CharWizardEquipmentManager.getWizardEquipmentKitWindow();
	if not wEquipmentKit then
		return;
	end

	if wEquipmentKit.backgroundkit_items.isEmpty() then
		CharWizardEquipmentManager.helperUpdateBackgroundKitItems(wEquipmentKit);
	end
	local tBackgroundOptions = CharWizardBackgroundManager.getBackgroundStartingKitOptions();
	if (wEquipmentKit.list_backgroundkit.getWindowCount() == 0) and (#tBackgroundOptions > 0) then
		if CharWizardBackgroundManager.isBackground2024() then
			local wChoices = wEquipmentKit.list_backgroundkit.createWindow();
			wChoices.type.setValue("Choice");
			wChoices.type.setVisible(true);
			wChoices.setData2024(tBackgroundOptions, "background");
			wChoices.alert.setVisible(true);
		else
			for i = 1, #tBackgroundOptions do
				local wChoices = wEquipmentKit.list_backgroundkit.createWindow();
				wChoices.type.setValue("Choice #" .. i);
				wChoices.type.setVisible(true);
				wChoices.setData(tBackgroundOptions[i], "background");
				wChoices.alert.setVisible(true);
			end
		end
	end
end
function helperUpdateBackgroundKitItems(wEquipmentKit)
	if not wEquipmentKit then
		return;
	end

	local tBackgroundItems = CharWizardBackgroundManager.getBackgroundStartingKitItems();
	local tItems = {};
	for _,v in ipairs(tBackgroundItems) do
		local sName = DB.getValue(v.item, "name", "");
		local nCount = DB.getValue(v.item, "count", 0);
		local sItem = "";
		if nCount > 1 then
			sItem = ("%s %s"):format(nCount, sName);
		else
			sItem = ("%s"):format(sName);
		end
		table.insert(tItems, sItem);
	end

	wEquipmentKit.backgroundkit_items.setValue(table.concat(tItems, ", "));
end
function resetBackgroundKitItems()
	local wEquipmentKit = CharWizardEquipmentManager.getWizardEquipmentKitWindow();
	if not wEquipmentKit then
		return;
	end
	wEquipmentKit.backgroundkit_items.setValue("");
end
function onBackgroundKitClear()
	local wEquipmentKit = CharWizardEquipmentManager.getWizardEquipmentKitWindow();
	if not wEquipmentKit then
		return;
	end
	wEquipmentKit.backgroundkit_items.setValue("");
	wEquipmentKit.list_backgroundkit.closeAll();
end

function onClassKitUpdate()
	local wEquipmentKit = CharWizardEquipmentManager.getWizardEquipmentKitWindow();
	if not wEquipmentKit then
		return;
	end

	local tClassOptions = CharWizardClassManager.getStartingKitOptions();
	if wEquipmentKit.classkit_items.isEmpty() and CharWizardClassManager.hasClasses() then
		CharWizardEquipmentManager.helperUpdateClassKitItems(wEquipmentKit);
	end
	if (wEquipmentKit.list_classkit.getWindowCount() == 0) and (#tClassOptions > 0) then
		if CharWizardClassManager.isStartingClass2024() then
			local wChoices = wEquipmentKit.list_classkit.createWindow();
			wChoices.type.setValue("Choice");
			wChoices.type.setVisible(true);
			wChoices.setData2024(tClassOptions, "class");
			wChoices.alert.setVisible(true);
		else
			for i = 1, #tClassOptions do
				local wChoices = wEquipmentKit.list_classkit.createWindow();
				wChoices.type.setValue("Choice #" .. i);
				wChoices.type.setVisible(true);
				wChoices.setData(tClassOptions[i], "class");
				wChoices.alert.setVisible(true);
			end
		end
	end
end
function helperUpdateClassKitItems(wEquipmentKit)
	if not wEquipmentKit then
		return;
	end

	local bIs2024 = CharWizardClassManager.isStartingClass2024();
	local tItems = {};
	for _,v in ipairs(CharWizardClassManager.getStartingKitItems()) do
		local sName = "";
		local nCount = 0;
		if bIs2024 then
			sName = DB.getValue(v.item, "name", "");
			nCount = DB.getValue(v.item, "count", 0);
		else
			sName = DB.getValue(v.item, "name", "");
			nCount = v.count;
		end
		local sItem = "";
		if nCount > 1 then
			sItem = ("%s %s"):format(nCount, sName);
		else
			sItem = ("%s"):format(sName);
		end
		table.insert(tItems, sItem);
	end

	wEquipmentKit.classkit_items.setValue(table.concat(tItems, ", "));
end
function resetClassKitItems()
	local wEquipmentKit = CharWizardEquipmentManager.getWizardEquipmentKitWindow();
	if not wEquipmentKit then
		return;
	end
	wEquipmentKit.classkit_items.setValue("");
end
function onClassKitClear()
	local wEquipmentKit = CharWizardEquipmentManager.getWizardEquipmentKitWindow();
	if not wEquipmentKit then
		return;
	end
	wEquipmentKit.classkit_items.setValue("");
	wEquipmentKit.list_classkit.closeAll();
end

function processKitSelection(w)
	local bIs2024 = CharWizardClassManager.isStartingClass2024();
	if bIs2024 then
		CharWizardEquipmentManager.processKitSelection2024(w);
	else
		CharWizardEquipmentManager.processKitSelection2014(w);
	end

	w.windowlist.window.selection.setValue(w.name.getValue());
	w.windowlist.window.button_modify.setVisible(true);
	w.windowlist.setVisible(false);

	CharWizardEquipmentManager.onEquipmentPageUpdate();
	CharWizardManager.updateAlerts();
end
function processKitSelection2024(w)
	local sKitType = WindowManager.callOuterWindowFunction(w, "getKitType");
	local tOptions = WindowManager.callOuterWindowFunction(w, "getAllRecords");
	local tSelection = {};
	local nChoice = 0;
	for k,v in ipairs({ "A", "B", "C" }) do
		local sName = w.name.getValue(); 
		if sName:match("^" .. v) then
			nChoice = k;
			break;
		end
	end

	local tItems = tOptions[nChoice].tOption.items;
	local nWealth = tOptions[nChoice].tOption.wealth;
	if sKitType == "class" then
		if tItems and next(tItems) then
			CharWizardClassManager.setStartingKitItems(tItems);
		end
		if nWealth then
			CharWizardClassManager.setStartingGold(nWealth);
		end
	end
	if sKitType == "background" then
		if tItems and next(tItems) then
			CharWizardBackgroundManager.setBackgroundStartingKitItems(tItems);
		end
		if nWealth then
			CharWizardBackgroundManager.setBackgroundStartingGold(nWealth);
		end
	end
end
function processKitSelection2014(w)
	local sKitType = WindowManager.callOuterWindowFunction(w, "getKitType");
	local _,sItemRecord = w.link.getValue();
	local tItems = {};
	if sKitType == "class" then
		tItems = CharWizardClassManager.getStartingKitItems();
	end
	if sKitType == "background" then
		tItems = CharWizardBackgroundManager.getBackgroundStartingKitItems();
	end

	local bHanded = true;
	local tFinalItems = {};
	for _,v in ipairs(tItems) do
		if DB.getPath(v.item) == sItemRecord then
			v.count = v.count + 1;
			bHandled = true;
		end
		table.insert(tFinalItems, v);
	end
	if not bHandled then
		table.insert(tFinalItems, { item = DB.findNode(sItemRecord), count = 1 });
	end

	if sKitType == "class" then
		CharWizardEquipmentManager.resetClassKitItems();
		CharWizardClassManager.setStartingKitItems(tFinalItems);
	end
	if sKitType == "background" then
		CharWizardEquipmentManager.resetBackgroundKitItems();
		CharWizardBackgroundManager.setBackgroundStartingKitItems(tFinalItems);
	end

	w.windowlist.window.selectionlink.setValue(sItemRecord);
end

function resetKitSelection(w)
	local bIs2024 = WindowManager.callOuterWindowFunction(w, "is2024");
	if bIs2024 then
		CharWizardEquipmentManager.resetKitSelection2024(w)
	else
		CharWizardEquipmentManager.resetKitSelection2014(w)
	end

	w.selection.setValue();
	w.selectionlink.setValue();
	w.button_modify.setVisible(false);

	w.list.setVisible(true);
	ListManager.refreshDisplayList(w);

	CharWizardEquipmentManager.onEquipmentPageUpdate();
	CharWizardManager.updateAlerts();
end
function resetKitSelection2024(w)
	local sKitType = w.getKitType();
	if sKitType == "background" then
		CharWizardBackgroundManager.setBackgroundStartingKitItems();
		CharWizardBackgroundManager.setBackgroundStartingGold();
		CharWizardEquipmentManager.onBackgroundWealthClear();
		CharWizardEquipmentManager.resetBackgroundKitItems();
	end
	if sKitType == "class" then
		CharWizardClassManager.clearStartingKitItems();
		CharWizardClassManager.setStartingGold();
		CharWizardEquipmentManager.onClassWealthClear();
		CharWizardEquipmentManager.resetClassKitItems();
	end
end
function resetKitSelection2014(w)
	local sKitType = w.getKitType();
	local sItemRecord = w.selectionlink.getValue();
	local tItems = {};
	if sKitType == "class" then
		tItems = CharWizardClassManager.getStartingKitItems();
	end
	if sKitType == "background" then
		tItems = CharWizardBackgroundManager.getBackgroundStartingKitItems();
	end

	local tFinalItems = {};
	for _,v in ipairs(tItems) do
		if DB.getPath(v.item) == sItemRecord then
			if v.count > 1 then
				v.count = v.count - 1;
				table.insert(tFinalItems, v);
			end
		else
			table.insert(tFinalItems, v);
		end
	end

	if sKitType == "class" then
		CharWizardEquipmentManager.resetClassKitItems();
		CharWizardClassManager.setStartingKitItems(tFinalItems);
	end
	if sKitType == "background" then
		CharWizardEquipmentManager.resetBackgroundKitItems();
		CharWizardBackgroundManager.setBackgroundStartingKitItems(tFinalItems);
	end
end

--
--	WEALTH
--

local _bUpdateWealth = false;
function onWealthUpdate()
	if _bUpdateWealth then
		return;
	end
	_bUpdateWealth = true;

	CharWizardEquipmentManager.onRolledWealthUpdate();
	CharWizardEquipmentManager.onClassWealthUpdate();
	CharWizardEquipmentManager.onBackgroundWealthUpdate();
	CharWizardEquipmentManager.updateTotalWealth();

	CharWizardManager.updateAlerts();
	
	_bUpdateWealth = false;
end

function onRolledWealthUpdate()
	local wEquipmentWealth = CharWizardEquipmentManager.getWizardEquipmentWealthWindow();
	if not wEquipmentWealth then
		return;
	end

	local bIs2024 = CharWizardClassManager.isStartingClass2024();

	wEquipmentWealth.rolledwealth_label.setVisible(not bIs2024);
	wEquipmentWealth.rolledwealth.setVisible(not bIs2024);
	wEquipmentWealth.button_rolledwealth.setVisible(not bIs2024);
	wEquipmentWealth.string_rolledwealth.setVisible(not bIs2024);
	wEquipmentWealth.button_rolledwealth_clear.setVisible(not bIs2024);

	if bIs2024 then
		wEquipmentWealth.string_rolledwealth.setValue();
		wEquipmentWealth.rolledwealth.setValue(0);
	else
		if wEquipmentWealth.string_rolledwealth.isEmpty() and CharWizardClassManager.hasClasses() then
			local sRoll = CharWizardClassManager.getStartingWealthRoll();
			if (sRoll or "") ~= "" then
				wEquipmentWealth.string_rolledwealth.setValue(sRoll);
			end
		end
	end
	CharWizardEquipmentManager.updateKitVisibility();
end
function setRolledWealth(n)
	local wEquipmentWealth = CharWizardEquipmentManager.getWizardEquipmentWealthWindow();
	if not wEquipmentWealth then
		return;
	end
	wEquipmentWealth.rolledwealth.setValue(n);
end
function onRolledWealthClear()
	local wEquipmentWealth = CharWizardEquipmentManager.getWizardEquipmentWealthWindow();
	if not wEquipmentWealth then
		return;
	end
	wEquipmentWealth.rolledwealth.setValue(0);
	wEquipmentWealth.string_rolledwealth.setValue("");
end
function onRolledWealthChanged(n)
	CharWizardManager.setStartingGold(n);
	CharWizardEquipmentManager.onWealthUpdate();
end

function onBackgroundWealthUpdate()
	local wEquipmentWealth = CharWizardEquipmentManager.getWizardEquipmentWealthWindow();
	if not wEquipmentWealth then
		return;
	end

	local bHasRolledWealth = (CharWizardManager.getStartingGold() ~= 0);

	wEquipmentWealth.backgroundwealth_label.setVisible(not bHasRolledWealth);
	wEquipmentWealth.backgroundgold.setVisible(not bHasRolledWealth);

	if bHasRolledWealth or ((CharWizardBackgroundManager.getBackgroundRecord() or "") == "") then
		wEquipmentWealth.backgroundgold.setValue(0);
	elseif wEquipmentWealth.backgroundgold.getValue() == 0 then
		wEquipmentWealth.backgroundgold.setValue(CharWizardBackgroundManager.getBackgroundStartingGold());
	end
end
function onBackgroundWealthClear()
	local wEquipmentWealth = CharWizardEquipmentManager.getWizardEquipmentWealthWindow();
	if not wEquipmentWealth then
		return;
	end
	wEquipmentWealth.backgroundgold.setValue(0);
end
function onBackgroundWealthChanged(n)
	CharWizardEquipmentManager.onWealthUpdate();
end

function onClassWealthUpdate()
	local wEquipmentWealth = CharWizardEquipmentManager.getWizardEquipmentWealthWindow();
	if not wEquipmentWealth then
		return;
	end

	local bHasRolledWealth = (CharWizardManager.getStartingGold() ~= 0);

	wEquipmentWealth.classwealth_label.setVisible(not bHasRolledWealth);
	wEquipmentWealth.classgold.setVisible(not bHasRolledWealth);
	
	if bHasRolledWealth or not CharWizardClassManager.hasClasses() then
		wEquipmentWealth.classgold.setValue(0);
	elseif wEquipmentWealth.classgold.getValue() == 0 then
		wEquipmentWealth.classgold.setValue(CharWizardClassManager.getStartingGold());
	end
end
function onClassWealthClear()
	local wEquipmentWealth = CharWizardEquipmentManager.getWizardEquipmentWealthWindow();
	if not wEquipmentWealth then
		return;
	end
	wEquipmentWealth.classgold.setValue(0);
end
function onClassWealthChanged(n)
	CharWizardEquipmentManager.onWealthUpdate();
end

function handleWealthRoll()
	local wEquipmentWealth = CharWizardEquipmentManager.getWizardEquipmentWealthWindow();
	if not wEquipmentWealth then
		return;
	end

	local rRoll = {
		sType = "charwizardwealthroll",
		sDesc = "[STARTING WEALTH GENERATION]",
		aDice = { expr = wEquipmentWealth.string_rolledwealth.getValue():gsub("[xX]", "*"), },
		nMod = 0
	};
	ActionsManager.actionDirect(nil, "charwizardwealthroll", { rRoll }, {{}});
	return true
end
function onWealthRoll(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	Comm.deliverChatMessage(rMessage);

	CharWizardEquipmentManager.setRolledWealth(ActionsManager.total(rRoll));
	return true;
end
function handleWealthRollClear()
	local wEquipmentWealth = CharWizardEquipmentManager.getWizardEquipmentWealthWindow();
	if not wEquipmentWealth then
		return;
	end
	wEquipmentWealth.rolledwealth.setValue(0);
end

function setDefaultCurrencies(w)
	local tEquipment = CharWizardManager.getEquipmentData();
	tEquipment.currency = tEquipment.currency or {};

	local bEdit = w.getName():match("edit");
	for _,v in pairs(CurrencyManager.getCurrencies()) do
		local wNewCurrency = w.createWindow();
		wNewCurrency.name.setValue(v);

		if not bEdit then
			table.insert(tEquipment.currency, { name = v, count = 0, edit = 0 });
		end
	end
end

function updateTotalWealth()
	local tEquipment = CharWizardManager.getEquipmentData();
	local wEquipmentWealth = CharWizardEquipmentManager.getWizardEquipmentWealthWindow();
	if not tEquipment or not wEquipmentWealth then
		return;
	end

	local nRolledGold = wEquipmentWealth.rolledwealth.getValue();
	local nClassGold = wEquipmentWealth.classgold.getValue();
	local nBackgroundGold = wEquipmentWealth.backgroundgold.getValue();
	for _,wCurrency in ipairs(wEquipmentWealth.currencylist.getWindows()) do
		local sCurrency = wCurrency.name.getValue();
		for _,vCurrency in pairs(tEquipment.currency or {}) do
			if vCurrency.name == sCurrency then
				local nTotal = vCurrency.edit or 0;
				if sCurrency == "GP" then
					if nRolledGold > 0 then
						nTotal = nTotal + nRolledGold;
					else
						nTotal = nTotal + nClassGold + nBackgroundGold;
					end
				end
				vCurrency.count = nTotal;
				wCurrency.amount.setValue(nTotal);
				break;
			end
		end
	end
end
local _bUpdateEditCurrency = false;
function updateEditWealthAmount(sCurrency, nCurrency)
	if _bUpdateEditCurrency then
		return;
	end
	_bUpdateEditCurrency = true;
	local tEquipment = CharWizardManager.getEquipmentData();
	for _,v in pairs(tEquipment.currency or {}) do
		if v.name == w.name.getValue() then
			v.edit = w.amount.getValue();
			CharWizardEquipmentManager.updateTotalWealth();
			break;
		end
	end
	_bUpdateEditCurrency = false;
end
