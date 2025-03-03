-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

-- Adjusted
function onTabletopInit()
	-- DB.addHandler("charsheet.*.size", "onUpdate", CharEncumbranceManager5E.onSizeChange);
	-- DB.addHandler("charsheet.*.abilities.strength.score", "onUpdate", CharEncumbranceManager5E.onStrengthChange);
	-- DB.addHandler("charsheet.*.featurelist.*.name", "onUpdate", CharEncumbranceManager5E.onAbilityFieldChange);
	-- DB.addHandler("charsheet.*.featurelist", "onChildDeleted", CharEncumbranceManager5E.onAbilityDelete);
	-- DB.addHandler("charsheet.*.traitlist.*.name", "onUpdate", CharEncumbranceManager5E.onAbilityFieldChange);
	-- DB.addHandler("charsheet.*.traitlist", "onChildDeleted", CharEncumbranceManager5E.onAbilityDelete);
end

-- Adjusted
function onSizeChange(nodeField)
	-- local nodeChar = DB.getChild(nodeField, "..");
	-- CharEncumbranceManager5E.updateEncumbranceLimit(nodeChar);
end

-- Adjusted
function onStrengthChange(nodeField)
	-- local nodeChar = DB.getChild(nodeField, "....");
	-- CharEncumbranceManager5E.updateEncumbranceLimit(nodeChar);
end

-- Adjusted
function onAbilityFieldChange(nodeField)
	-- local nodeChar = DB.getChild(nodeField, "....");
	-- CharEncumbranceManager5E.updateEncumbranceLimit(nodeChar);
end

-- Adjusted
function onAbilityDelete(nodeList)
	-- local nodeChar = DB.getChild(nodeList, "..");
	-- CharEncumbranceManager5E.updateEncumbranceLimit(nodeChar);
end

-- Adjusted
function updateEncumbranceLimit(nodeChar)
	-- if not DB.isOwner(nodeChar) then
		-- return;
	-- end
	
	-- local nStat = DB.getValue(nodeChar, "abilities.strength.score", 10);
	-- local nEncLimit = math.max(nStat, 0) * 5;

	-- nEncLimit = nEncLimit * CharEncumbranceManager5E.getEncumbranceMult(nodeChar);
	
	-- DB.setValue(nodeChar, "encumbrance.encumbered", "number", nEncLimit);
	-- DB.setValue(nodeChar, "encumbrance.encumberedheavy", "number", nEncLimit * 2);
	-- DB.setValue(nodeChar, "encumbrance.max", "number", nEncLimit * 3);
	-- DB.setValue(nodeChar, "encumbrance.liftpushdrag", "number", nEncLimit * 6);
end

-- Adjusted
function getEncumbranceMult(nodeChar)
	-- local rActor = ActorManager.resolveActor(nodeChar);
	-- local nActorSize = ActorCommonManager.getCreatureSizeDnD5(rActor);

	-- if CharManager.hasTrait(nodeChar, CharManager.TRAIT_POWERFUL_BUILD) then
		-- nActorSize = nActorSize + 1;
	-- elseif CharManager.hasTrait(nodeChar, CharManager.TRAIT_HIPPO_BUILD) then
		-- nActorSize = nActorSize + 1;
	-- elseif CharManager.hasTrait(nodeChar, CharManager.TRAIT_LITTLE_GIANT) then
		-- nActorSize = nActorSize + 1;
	-- end
	
	-- local nMult = 1; -- Both Small and Medium use a multiplier of 1
	-- if nActorSize == -2 then
		-- nMult = 0.5;
	-- elseif nActorSize > 0 then
		-- nMult = 2 ^ nActorSize;
	-- end

	-- if CharManager.hasFeature(nodeChar, CharManager.FEATURE_ASPECT_OF_THE_BEAR) then
		-- nMult = nMult * 2;
	-- end
	
	-- return nMult;
end

-- Added
function calcItemBulk(nodeChar)
	-- Debug.chat("FN: calcItemBulk in manager_char_encumberance")
	local nBulkTotal = 0
	local nCount, nBulk

	for _,vNode in pairs(DB.getChildren(nodeChar, "inventorylist")) do
		if DB.getValue(vNode, "carried", 0) == 2 then
			nCount = DB.getValue(vNode, "count", 0)

			-- Get item quantities
			if nCount < 1 then
				nCount = 1
			end

			nBulk = DB.getValue(vNode, "bulk", 0)
			nBulkTotal = nBulkTotal + (nCount * nBulk)
		end
	end

	-- Set values
	DB.setValue(nodeChar, "encumbrance.bulk", "number", nBulkTotal)
	DB.setValue(nodeChar, "encumbrance.bulkhalved", "number", math.floor(nBulkTotal/2))
end