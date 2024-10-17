-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYINIT = "applyinit";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYINIT, handleApplyInit);

	ActionsManager.registerModHandler("init", modRoll);
	ActionsManager.registerResultHandler("init", onResolve);
end

function handleApplyInit(msgOOB)
	local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
	local nTotal = tonumber(msgOOB.nTotal) or 0;

	DB.setValue(ActorManager.getCTNode(rSource), "initresult", "number", nTotal);
end
function notifyApplyInit(rSource, nTotal)
	if not rSource then
		return;
	end
	
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYINIT;
	
	msgOOB.nTotal = nTotal;

	msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);

	Comm.deliverOOBMessage(msgOOB, "");
end

--
--	ROLL BUILD/MOD/RESOLVE
--

function getRoll(rActor, bSecret)
	local rRoll = ActionsManager2.setupD20RollBuild("init", rActor, bSecret);
	ActionInit.setupRollBuild(rRoll, rActor);
	ActionsManager2.finalizeD20RollBuild(rRoll);
	return rRoll;
end
function performRoll(draginfo, rActor, bSecretRoll)
	local rRoll = getRoll(rActor, bSecretRoll);
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function modRoll(rSource, rTarget, rRoll)
	ActionCheck.modRoll(rSource, rTarget, rRoll);
end

function onResolve(rSource, rTarget, rRoll)
	ActionCheck.onRoll(rSource, rTarget, rRoll);
end

--
--	ROLL BUILDING HELPERS
--

function setupRollBuild(rRoll, rActor)
	table.insert(rRoll.tNotifications, "[INIT]");

	-- Determine the modifier and ability to use for this roll
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if nodeActor then
		if ActorManager.isPC(rActor) then
			rRoll.nMod = DB.getValue(nodeActor, "initiative.total", 0);

			-- Check for armor non-proficiency
			if DB.getValue(nodeActor, "defenses.ac.prof", 1) == 0 then
				rRoll.bDIS = true;
				table.insert(rRoll.tNotifications, Interface.getString("roll_msg_armor_nonprof"));
			end
		else
			rRoll.nMod = DB.getValue(nodeActor, "init", 0);
		end
	end
end

--
--	OTHER
--

-- Used in combat manager script to get initiative adjustments for automatic initiative
-- Returns effect existence, effect dice, effect mod, effect advantage, effect disadvantage
function getEffectAdjustments(rActor)
	local rRoll = {
		bEffects = false,
		tEffectDice = {},
		nEffectMod = 0,
		tCheckFilter = { "dexterity" },
	};
	ActionCheck.applyEffectsToRollMod(rRoll, rActor);
	return rRoll.bEffects, rRoll.tEffectDice, rRoll.nEffectMod, rRoll.bADV, rRoll.bDIS;
end
