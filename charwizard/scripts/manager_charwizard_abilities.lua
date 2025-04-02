--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local tStandardArray = {15,14,13,12,10,8};

function onInit()
	ActionsManager.registerResultHandler("charwizardabilityroll", CharWizardAbilitiesManager.onGenRoll);
end

function performGenRoll()
	for _,v in pairs(DataCommon.abilities) do
		CharWizardAbilitiesManager.setAbilityBase(v, 0);

		local rRoll = {
			sType = "charwizardabilityroll",
			sDesc = "[ABILITY SCORE GENERATION] " .. StringManager.capitalize(v),
			aDice = { expr = "4d6d1" },
			nMod = 0,
			sAbility = v,
		};
		ActionsManager.actionDirect(nil, "charwizardabilityroll", { rRoll }, {{}});
	end
end
function onGenRoll(rSource, _, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	Comm.deliverChatMessage(rMessage);

	CharWizardAbilitiesManager.setAbilityBase(rRoll.sAbility, ActionsManager.total(rRoll));
end

function setGenMethod(w)
	local sGenMethodLower = w.cb_genmethod.getValue():lower();
	local bStandardArray = (sGenMethodLower == "standard array");
	local bManual = (sGenMethodLower == "dice roll/manual entry");
	local bPointBuy = (sGenMethodLower == "point buy");

	local nBase = 0;
	if bPointBuy then
		nBase = 8;
	end
	for k,sAbility in ipairs(DataCommon.abilities) do
		if bStandardArray then
			CharWizardAbilitiesManager.setAbilityBase(sAbility, tStandardArray[k]);
		else
			CharWizardAbilitiesManager.setAbilityBase(sAbility, nBase);
		end
	end

	w.cb_genroll.setVisible(bManual);

	w.point_label.setVisible(bPointBuy);
	w.points_used.setVisible(bPointBuy);
	w.pointbuy_label.setVisible(bPointBuy);
	w.points_max.setVisible(bPointBuy);

	w.strength_genup.setVisible(bPointBuy);
	w.strength_gendown.setVisible(false);
	w.dexterity_genup.setVisible(bPointBuy);
	w.dexterity_gendown.setVisible(false);
	w.constitution_genup.setVisible(bPointBuy);
	w.constitution_gendown.setVisible(false);
	w.intelligence_genup.setVisible(bPointBuy);
	w.intelligence_gendown.setVisible(false);
	w.wisdom_genup.setVisible(bPointBuy);
	w.wisdom_gendown.setVisible(false);
	w.charisma_genup.setVisible(bPointBuy);
	w.charisma_gendown.setVisible(false);

	w.strength_genright.setVisible(not bPointBuy);
	w.dexterity_genleft.setVisible(not bPointBuy);
	w.dexterity_genright.setVisible(not bPointBuy);
	w.constitution_genleft.setVisible(not bPointBuy);
	w.constitution_genright.setVisible(not bPointBuy);
	w.intelligence_genleft.setVisible(not bPointBuy);
	w.intelligence_genright.setVisible(not bPointBuy);
	w.wisdom_genleft.setVisible(not bPointBuy);
	w.wisdom_genright.setVisible(not bPointBuy);
	w.charisma_genleft.setVisible(not bPointBuy);

	if bPointBuy then
		CharWizardAbilitiesManager.recalcAbilityPointsSpent(w);
	end
end

function setAbilityBase(sAbility, n)
	local tASI = CharWizardManager.getAbilityData();
	tASI[sAbility] = tASI[sAbility] or {};
	tASI[sAbility].score = n;

	CharWizardAbilitiesManager.updateAbilities();
end
function setAbilityMisc(sAbility, n)
	local tASI = CharWizardManager.getAbilityData();
	tASI[sAbility] = tASI[sAbility] or {};
	tASI[sAbility].misc = n;

	CharWizardAbilitiesManager.updateAbilities();
end

function updateAbilities()
	local tASI = CharWizardManager.getAbilityData();
	for _,sAbility in pairs(DataCommon.abilities) do
		tASI[sAbility] = tASI[sAbility] or {};
		tASI[sAbility].species = 0;
		tASI[sAbility].background = 0;
		tASI[sAbility].asi = 0;
	end

	if CharWizardBackgroundManager.isBackground2024() then
		local tBackground = CharWizardManager.getBackgroundData();
		for _,v in pairs(tBackground.abilityincrease or {}) do
			tASI[v.ability:lower()].background = v.mod or 0;
		end
	elseif not CharWizardSpeciesManager.isSpecies2024() then
		local tSpecies = CharWizardManager.getSpeciesData();
		for _,v in pairs(tSpecies.abilityincrease or {}) do
			tASI[v.ability:lower()].species = v.mod or 0;
		end
	end

	local tClassASI = CharWizardAbilitiesManager.collectASIAbilities();
	for k,v in pairs(tClassASI) do
		tASI[k:lower()].asi = v;
	end

	for _,sAbility in pairs(DataCommon.abilities) do
		tASI[sAbility].total = (tASI[sAbility].score or 10) +
				(tASI[sAbility].background or 0) +
				(tASI[sAbility].species or 0) +
				(tASI[sAbility].asi or 0) +
				(tASI[sAbility].misc or 0);
		tASI[sAbility].modifier = math.floor((tASI[sAbility].total - 10) / 2);
	end

	CharWizardAbilitiesManager.updateAbilitiesTotal();
end
function updateAbilitiesTotal()
	local w = CharWizardManager.getWizardAbilitiesWindow();
	if not w then
		return;
	end

	local tASI = CharWizardManager.getAbilityData();
	for _,sAbility in pairs(DataCommon.abilities) do
		w[sAbility .. "_base"].setValue(tASI[sAbility] and tASI[sAbility].score or 10);
		w[sAbility .. "_background"].setValue(tASI[sAbility] and tASI[sAbility].background or 0);
		w[sAbility .. "_species"].setValue(tASI[sAbility] and tASI[sAbility].species or 0);
		w[sAbility .. "_asi"].setValue(tASI[sAbility] and tASI[sAbility].asi or 0);

		local nTotal = tASI[sAbility] and tASI[sAbility].total or 10;
		w[sAbility .. "_total"].setValue(nTotal);
		if nTotal == 0 then
			w[sAbility .. "_modifier"].setValue("");
		else
			w[sAbility .. "_modifier"].setValue(string.format("%+d", tASI[sAbility] and tASI[sAbility].modifier or 0));
		end
	end
end

function collectASIAbilities()
	local tClassASI = {};
	local tClassData = CharWizardManager.getClassData();
	for _,vClass in pairs(tClassData) do
		for _,vFeature in pairs(vClass.features or {}) do
			for _,vLevel in pairs(vFeature) do
				for kVar, vVar in pairs(vLevel) do
					if kVar == "abilityincrease" then
						table.insert(tClassASI, vVar);
					end
				end
			end
		end
	end

	local tFinalASI = {};
	for _,v in ipairs(tClassASI) do
		for _,v2 in ipairs(v) do
			local sAbilityLower = v2.ability:lower();
			tFinalASI[sAbilityLower] = (tFinalASI[sAbilityLower] or 0) + v2.mod;
		end
	end
	return tFinalASI;
end

function handleAbilityPointBuy(w, sAbility, nMod)
	local tASI = CharWizardManager.getAbilityData();
	tASI[sAbility] = tASI[sAbility] or {};
	tASI[sAbility].score = (tASI[sAbility].score or 10) + nMod;
	CharWizardAbilitiesManager.updateAbilities();

	CharWizardAbilitiesManager.recalcAbilityPointsSpent(w);
	CharWizardManager.updateAlerts();
end
function recalcAbilityPointsSpent(w)
	local nPointTotal = 0;
	local nPointMax = w.points_max.getValue();

	for _,v in ipairs(DataCommon.abilities) do
		local nCurrStat = w[v .. "_base"].getValue();

		if nCurrStat >= 15 then
			nPointTotal = nPointTotal + 9;
		elseif nCurrStat == 14 then
			nPointTotal = nPointTotal + 7;
		elseif nCurrStat == 13 then
			nPointTotal = nPointTotal + 5;
		elseif nCurrStat == 12 then
			nPointTotal = nPointTotal + 4;
		elseif nCurrStat == 11 then
			nPointTotal = nPointTotal + 3;
		elseif nCurrStat == 10 then
			nPointTotal = nPointTotal + 2;
		elseif nCurrStat == 9 then
			nPointTotal = nPointTotal + 1;
		end
	end

	w.points_used.setValue(nPointTotal);

	for _,v in ipairs(DataCommon.abilities) do
		w[v .. "_genup"].setVisible(w.points_max.getValue() > 0 and w[v .. "_base"].getValue() < 15);
		w[v .. "_gendown"].setVisible(w[v .. "_base"].getValue() > 8);

		if nPointTotal == nPointMax then
			w[v .. "_genup"].setVisible(false);
		end
	end
end

function handleAbilitySwapRight(sAbility)
	if sAbility == "strength" then
		CharWizardAbilitiesManager.helperAbilitySwap("strength", "dexterity");
	elseif sAbility == "dexterity" then
		CharWizardAbilitiesManager.helperAbilitySwap("dexterity", "constitution");
	elseif sAbility == "constitution" then
		CharWizardAbilitiesManager.helperAbilitySwap("constitution", "intelligence");
	elseif sAbility == "intelligence" then
		CharWizardAbilitiesManager.helperAbilitySwap("intelligence", "wisdom");
	elseif sAbility == "wisdom" then
		CharWizardAbilitiesManager.helperAbilitySwap("wisdom", "charisma");
	end
	CharWizardAbilitiesManager.updateAbilities();
end
function handleAbilitySwapLeft(sAbility)
	if sAbility == "dexterity" then
		CharWizardAbilitiesManager.helperAbilitySwap("dexterity", "strength");
	elseif sAbility == "constitution" then
		CharWizardAbilitiesManager.helperAbilitySwap("constitution", "dexterity");
	elseif sAbility == "intelligence" then
		CharWizardAbilitiesManager.helperAbilitySwap("intelligence", "constitution");
	elseif sAbility == "wisdom" then
		CharWizardAbilitiesManager.helperAbilitySwap("wisdom", "intelligence");
	elseif sAbility == "charisma" then
		CharWizardAbilitiesManager.helperAbilitySwap("charisma", "wisdom");
	end
	CharWizardAbilitiesManager.updateAbilities();
end
function helperAbilitySwap(sAbility1, sAbility2)
	local tASI = CharWizardManager.getAbilityData();
	tASI[sAbility1] = tASI[sAbility1] or {};
	tASI[sAbility2] = tASI[sAbility2] or {};

	local nTemp = (tASI[sAbility1].score or 10);
	tASI[sAbility1].score = (tASI[sAbility2].score or 10);
	tASI[sAbility2].score = nTemp;
end
