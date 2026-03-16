--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	GameManager.setFunction("onDamagePostGetRoll", ActionDamage.onPostGetRoll);
	GameManager.setFunction("onDamagePostModRoll", ActionDamage.onPostModRoll);
	GameManager.setMultiKeyFunction("onHealthApplyType", "recovery", ActionDamage.applyRecovery);
	GameManager.setFunction("onHealthPostApply", ActionDamage.onPostApply);

	GameManager.setOption("critical", "5E");
	GameManager.setOption("deathsave", "5E");
	GameManager.setOption("dmgmishap", "5E");
	GameManager.setOption("dmgthreshold", "5E");
	GameManager.setOption("regeneration", "5E");
	GameManager.setOption("systemshock", "5E");
	
	ActionDamageD20.registerStandardDamageHealHandlers();
end

--
--	GET ROLL
--

-- Add auto target handling
function onPostGetRoll(rActor, rAction, rRoll)
	ActionDamage.applyCritMetaToRoll(rActor, rAction, rRoll);
end
function applyCritMetaToRoll(rActor, rAction, rRoll)
	if not rRoll or not rRoll.clauses or not rRoll.clauses[1] then
		return;
	end

	local nCritDice = 0;
	if rRoll.bWeapon and ActorManager.isPC(rActor) then
		local nodeActor = ActorManager.getCreatureNode(rActor);
		if nodeActor then
			if rRoll.sRange == "R" then
				nCritDice = DB.getValue(nodeActor, "weapon.critdicebonus.ranged", 0);
			else
				nCritDice = DB.getValue(nodeActor, "weapon.critdicebonus.melee", 0);
			end
		end
	end
	if nCritDice > 0 then
		rRoll.clauses[1].nExtraCritDice = nCritDice;
	end
end

--
--	MOD ROLL
--

function onPostModRoll(rSource, rTarget, rRoll)
	ActionsManager2.encodeDesktopMods(rRoll);
end

--
--	DAMAGE APPLICATION
--

function applyRecovery(rSource, rTarget, rRoll, tApplyData)
	-- Determine whether HD available
	local nClassHD = 0;
	local nClassHDMult = 0;
	local nClassHDUsed = 0;
	local sClassNode = rRoll.sDesc:match("%[NODE:([^]]+)%]");
	if ActorManager.isPC(rTarget) and sClassNode then
		local nodeClass = DB.findNode(sClassNode);
		if nodeClass then
			nClassHD = DB.getValue(nodeClass, "level", 0);
			nClassHDMult = #(DB.getValue(nodeClass, "hddie", {}));
			nClassHDUsed = DB.getValue(nodeClass, "hdused", 0);
		end
	end
	if (nClassHD * nClassHDMult) <= nClassHDUsed then
		rRoll.tResults = {};
		table.insert(tApplyData.tNotifications, "[INSUFFICIENT HIT DICE FOR THIS CLASS]");
		return;
	end

	ActionHealthD20.applyHeal(rSource, rTarget, rRoll, tApplyData);

	-- Decrement HD used
	if ActorManager.isPC(rTarget) and sClassNode then
		local nodeClass = DB.findNode(sClassNode);
		if nodeClass then
			DB.setValue(nodeClass, "hdused", "number", nClassHDUsed + 1);
		end
	end
end

function onPostApply(rSource, rTarget, rRoll, tApplyData)
	ActionHealthD20.onPostApplyDefault(rSource, rTarget, rRoll, tApplyData);

	if tApplyData.sType ~= "damage" then
		return;
	end

	-- Check for required concentration checks
	if (tApplyData.nConcentrationDamage or 0) > 0 and ActionSave.hasConcentrationEffects(rTarget) then
		if tApplyData.tHealth["hp"].nWounds < tApplyData.tHealth["hp"].nTotal then
			local tData;
			if ActorManager5E.hasRollFeat(rSource, CharManager.FEAT_MAGE_SLAYER) then
				tData = { bDIS = true, sAddText = "[MAGE SLAYER]", };
			end
			local nTargetDC = math.max(math.floor(tApplyData.nConcentrationDamage / 2), 10);
			ActionSave.performConcentrationRoll(nil, rTarget, nTargetDC, tData);
		else
			ActionSave.expireConcentrationEffects(rTarget);
		end
	end
end
