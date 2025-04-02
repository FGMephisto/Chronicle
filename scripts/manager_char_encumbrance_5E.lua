--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onTabletopInit()
	DB.addHandler("charsheet.*.size", "onUpdate", CharEncumbranceManager5E.onSizeChange);
	DB.addHandler("charsheet.*.abilities.strength.score", "onUpdate", CharEncumbranceManager5E.onStrengthChange);
	DB.addHandler("charsheet.*.featurelist.*.name", "onUpdate", CharEncumbranceManager5E.onAbilityFieldChange);
	DB.addHandler("charsheet.*.featurelist", "onChildDeleted", CharEncumbranceManager5E.onAbilityDelete);
	DB.addHandler("charsheet.*.traitlist.*.name", "onUpdate", CharEncumbranceManager5E.onAbilityFieldChange);
	DB.addHandler("charsheet.*.traitlist", "onChildDeleted", CharEncumbranceManager5E.onAbilityDelete);
end

function onSizeChange(nodeField)
	local nodeChar = DB.getChild(nodeField, "..");
	CharEncumbranceManager5E.updateEncumbranceLimit(nodeChar);
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

function updateEncumbranceLimit(nodeChar)
	if not DB.isOwner(nodeChar) then
		return;
	end

	local nStat = DB.getValue(nodeChar, "abilities.strength.score", 10);
	local nEncLimit = math.max(nStat, 0) * 5;

	nEncLimit = nEncLimit * CharEncumbranceManager5E.getEncumbranceMult(nodeChar);

	DB.setValue(nodeChar, "encumbrance.encumbered", "number", nEncLimit);
	DB.setValue(nodeChar, "encumbrance.encumberedheavy", "number", nEncLimit * 2);
	DB.setValue(nodeChar, "encumbrance.max", "number", nEncLimit * 3);
	DB.setValue(nodeChar, "encumbrance.liftpushdrag", "number", nEncLimit * 6);
end
function getEncumbranceMult(nodeChar)
	local rActor = ActorManager.resolveActor(nodeChar);
	local nActorSize = ActorCommonManager.getCreatureSizeDnD5(rActor);

	if CharManager.hasTrait(nodeChar, CharManager.TRAIT_POWERFUL_BUILD) then
		nActorSize = nActorSize + 1;
	elseif CharManager.hasTrait(nodeChar, CharManager.TRAIT_HIPPO_BUILD) then
		nActorSize = nActorSize + 1;
	elseif CharManager.hasTrait(nodeChar, CharManager.TRAIT_LITTLE_GIANT) then
		nActorSize = nActorSize + 1;
	end

	local nMult = 1; -- Both Small and Medium use a multiplier of 1
	if nActorSize == -2 then
		nMult = 0.5;
	elseif nActorSize > 0 then
		nMult = 2 ^ nActorSize;
	end

	if CharManager.hasFeature(nodeChar, CharManager.FEATURE_ASPECT_OF_THE_BEAR) then
		nMult = nMult * 2;
	end

	return nMult;
end

