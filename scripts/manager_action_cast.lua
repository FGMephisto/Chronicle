--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	ActionsManager.registerTargetingHandler("cast", ActionCore.onTargeting);
	ActionsManager.registerResultHandler("cast", ActionCast.onCast);
end

function getRoll(rActor, rAction)
	local rRoll = {
		sType = "cast",
		sDesc = ActionCore.encodeActionText(rAction, "action_cast_tag"),
		aDice = {},
		nMod = 0,
		tActionTags = rAction.tActionTags,
	};
	if rAction.nodeAction and ActorManager.isFaction(rActor, "friend") then
		local nodePower = DB.getChild(rAction.nodeAction, "...");
		if nodePower then
			local nUpcast = PowerManager5E.getSpellUpcast(nodePower);
			if nUpcast > 0 then
				rRoll.sDesc = StringManager.appendLine(rRoll.sDesc, string.format("[UPCAST: %+d]", nUpcast));
			end
			local tSelections = ActionsChoiceManager.getPowerChoiceSelectionsDisplayList(nodePower);
			if #tSelections > 0 then
				for _,s in ipairs(tSelections) do
					rRoll.sDesc = StringManager.appendLine(rRoll.sDesc, string.format("[CHOICE: %s]", s));
				end
			end
		end
	end
	return rRoll;
end

function onCast(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll, { sIcon = "action_cast", rTarget = rTarget, });
	Comm.deliverChatMessage(rMessage);
end
