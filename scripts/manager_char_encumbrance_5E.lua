--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onTabletopInit()
	if Session.IsHost then
		GameManager.addEventFunction("onActorEncumbranceLimitChanged", CharEncumbranceManager5E.updateEncumbranceLimit);
		GameManager.addEventFunction("onActorSizeChanged", CharEncumbranceManager5E.onSizeChanged);
		DB.addHandler("charsheet.*.abilities.strength.score", "onUpdate", CharEncumbranceManager5E.onStrengthChange);
		DB.addHandler("charsheet.*.featurelist.*.name", "onUpdate", CharEncumbranceManager5E.onAbilityFieldChange);
		DB.addHandler("charsheet.*.featurelist", "onChildDeleted", CharEncumbranceManager5E.onAbilityDelete);
		DB.addHandler("charsheet.*.traitlist.*.name", "onUpdate", CharEncumbranceManager5E.onAbilityFieldChange);
		DB.addHandler("charsheet.*.traitlist", "onChildDeleted", CharEncumbranceManager5E.onAbilityDelete);

		GameManager.addEventFunction("onActorEncumbranceChanged", CharEncumbranceManager5E.onEncumbranceChanged);

		CombatManager.setCustomDeleteCombatantEffectHandler(CharEncumbranceManager5E.onActorEffectDelete);
		CombatManager.addAllCombatantEffectFieldChangeHandler("isactive", "onUpdate", CharEncumbranceManager5E.onActorEffectFieldUpdate);
		CombatManager.addAllCombatantEffectFieldChangeHandler("label", "onUpdate", CharEncumbranceManager5E.onActorEffectFieldUpdate);

		OptionsManager.registerCallback("HREN", CharEncumbranceManager5E.onOptionChanged);
		CharEncumbranceManager5E.onOptionChanged();
	end
end

function onOptionChanged()
	for _,nodeChar in ipairs(DB.getChildList("charsheet")) do
		CharEncumbranceManager5E.updateEncumbranceLimit(nodeChar);
	end
end

function onActorEffectDelete(nodeCT)
	CharEncumbranceManager5E.updateEncumbranceLimit(nodeCT);
end
function onActorEffectFieldUpdate(nodeField)
	local nodeEffect = DB.getParent(nodeField);
	EffectIndexManager.clearEffectData(nodeEffect);
	CharEncumbranceManager5E.updateEncumbranceLimit(DB.getChild(nodeEffect, "..."));
end

--
--	ENCUMBRANCE LIMIT HANDLING
--

function onSizeChanged(rActor)
	CharEncumbranceManager5E.updateEncumbranceLimit(rActor);
end

function onStrengthChange(nodeField)
	local nodeChar = DB.getChild(nodeField, "....");
	CharEncumbranceManager5E.updateEncumbranceLimit(nodeChar);
end
function onAbilityFieldChange(nodeField)
	local nodeChar = DB.getChild(nodeField, "....");
	CharEncumbranceManager5E.updateEncumbranceLimit(nodeChar);
end
function onAbilityDelete(nodeList)
	local nodeChar = DB.getChild(nodeList, "..");
	CharEncumbranceManager5E.updateEncumbranceLimit(nodeChar);
end

function updateEncumbranceLimit(vActor)
	local rActor = ActorManager.resolveActor(vActor);
	if not rActor then
		return;
	end
	if not ActorManager.hasInventory(rActor) then
		return;
	end
	if not ActorManager.isOwner(rActor) then
		return;
	end
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not nodeActor then
		return;
	end

	local nStat = DB.getValue(nodeActor, "abilities.strength.score", 10);
	nStat = nStat + EffectManager.getBonusMod(rActor, "CARRY");
	local nEncLimit = math.max(nStat, 0) * 5;

	nEncLimit = nEncLimit * CharEncumbranceManager5E.getEncumbranceMult(rActor);

	DB.setValue(nodeActor, "encumbrance.encumbered", "number", nEncLimit);
	DB.setValue(nodeActor, "encumbrance.encumberedheavy", "number", nEncLimit * 2);
	DB.setValue(nodeActor, "encumbrance.max", "number", nEncLimit * 3);
	DB.setValue(nodeActor, "encumbrance.liftpushdrag", "number", nEncLimit * 6);

	CharEncumbranceManager5E.onEncumbranceChanged(rActor);
end
function getEncumbranceMult(vActor)
	local rActor = ActorManager.resolveActor(vActor);
	local nActorSize = ActorCommonManager.getSize(rActor);

	if ActorManager5E.hasTrait(rActor, CharManager.TRAIT_POWERFUL_BUILD) or
			ActorManager5E.hasTrait(rActor, CharManager.TRAIT_HIPPO_BUILD) or
			ActorManager5E.hasTrait(rActor, CharManager.TRAIT_LITTLE_GIANT) or
			ActorManager5E.hasTrait(rActor, CharManager.TRAIT_EQUINE_BUILD) or
			ActorManager5E.hasTrait(rActor, CharManager.TRAIT_BEAST_OF_BURDEN) then
		nActorSize = nActorSize + 1;
	-- EN LevelUp
	elseif ActorManager5E.hasTrait(rActor, CharManager.TRAIT_HEAVY_LIFTER) then
		nActorSize = nActorSize + 1;
	end

	local nMult = 1; -- Both Small and Medium use a multiplier of 1
	if nActorSize == -2 then
		nMult = 0.5;
	elseif nActorSize > 0 then
		nMult = 2 ^ nActorSize;
	end

	if ActorManager5E.hasFeature(rActor, CharManager.FEATURE_ASPECT_OF_THE_BEAR) then
		nMult = nMult * 2;
	end

	local nEffectCarryMult = EffectManager.getBonusMod(rActor, "CARRYMULT");
	if nEffectCarryMult ~= 0 then
		nMult = nMult * nEffectCarryMult;
	end

	return nMult;
end

--
--	ENCUMBRANCE STATE HANDLING
--

function onEncumbranceChanged(vActor)
	CharEncumbranceManager5E.refreshEncumbranceState(vActor);
end

function refreshEncumbranceState(vActor)
	local rActor = ActorManager.resolveActor(vActor);
	if not ActorManager.hasInventory(rActor) then
		return;
	end

	local nEncumbranceLevel = CharEncumbranceManager5E.calcEncumbranceLevel(rActor);
	CharEncumbranceManager5E.setEncumbranceLevel(rActor, nEncumbranceLevel);
end
function calcEncumbranceLevel(rActor)
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not nodeActor then
		return 0;
	end

	if OptionsManager.isOption("HREN", "off") then
		return 0;
	end

	local nLoad = GameManager.getRecordFieldValue(rActor, "encload", 0);

	if nLoad > DB.getValue(nodeActor, "encumbrance.liftpushdrag", 0) then
		return 4;
	elseif nLoad > DB.getValue(nodeActor, "encumbrance.max", 0) then
		return 3;
	elseif OptionsManager.isOption("HREN", "variant") then
		if nLoad > DB.getValue(nodeActor, "encumbrance.encumberedheavy", 0) then
			return 2;
		elseif nLoad > DB.getValue(nodeActor, "encumbrance.encumbered", 0) then
			return 1;
		end
	end
	return 0;
end
function setEncumbranceLevel(rActor, nLevel)
	local sState = "";
	if nLevel == 4 then
		sState = Interface.getString("encumbrance_overmax");
	elseif nLevel == 3 then		
		sState = Interface.getString("encumbrance_overcap");
	elseif nLevel == 2 then		
		sState = Interface.getString("encumbrance_encumbered_heavy");
	elseif nLevel == 1 then		
		sState = Interface.getString("encumbrance_encumbered");
	end
	GameManager.setRecordFieldValue(rActor, "enclevel", "number", nLevel);
	GameManager.setRecordFieldValue(rActor, "encstate", "string", sState);
end

function isHeavilyEncumbered(rActor)
	if not OptionsManager.isOption("HREN", "variant") then
		return false;
	end
	return (GameManager.getRecordFieldValue(rActor, "enclevel", 0) >= 2);
end
