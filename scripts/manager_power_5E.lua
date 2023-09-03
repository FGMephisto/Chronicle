-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	local tPowerHandlers = {
		fnGetActorNode = PowerManager5E.getPowerActorNode,
		fnParse = PowerManager5E.parsePower,
		fnUpdateDisplay = PowerManager5E.updatePowerDisplay,
	};
	PowerManagerCore.registerPowerHandlers(tPowerHandlers);

	local tPowerActionHandlers = {
		fnGetButtonIcons = PowerManager5E.getActionButtonIcons,
		fnGetText = PowerManager5E.getActionText,
		fnGetTooltip = PowerManager5E.getActionTooltip,
		fnPerform = PowerManager5E.performAction,
	};
	PowerActionManagerCore.registerActionType("", tPowerActionHandlers);
	PowerActionManagerCore.registerActionType("cast", {});
	PowerActionManagerCore.registerActionType("damage", {});
	PowerActionManagerCore.registerActionType("heal", {});
	PowerActionManagerCore.registerActionType("effect", {});
end

function getPowerActorNode(node)
	return DB.getChild(node, "...");
end
function parsePower(node)
	PowerManager.parsePCPower(node);
end
function updatePowerDisplay(w)
	if w.minisheet then
		return;
	end
	if not w.header or not w.header.subwindow then
		return;
	end
	if not w.header.subwindow.group or not w.header.subwindow.shortdescription or not w.header.subwindow.actionsmini then
		return;
	end

	local nodeActor = PowerManagerCore.getPowerActorNode(w.getDatabaseNode());
	local sDisplayMode = DB.getValue(nodeActor, "powerdisplaymode", "");
	if sDisplayMode == "summary" then
		w.header.subwindow.group.setVisible(false);
		w.header.subwindow.shortdescription.setVisible(true);
		w.header.subwindow.actionsmini.setVisible(false);
	elseif sDisplayMode == "action" then
		w.header.subwindow.group.setVisible(false);
		w.header.subwindow.shortdescription.setVisible(false);
		w.header.subwindow.actionsmini.setVisible(true);
	else
		w.header.subwindow.group.setVisible(true);
		w.header.subwindow.shortdescription.setVisible(false);
		w.header.subwindow.actionsmini.setVisible(false);
	end
end

function getActionButtonIcons(node, tData)
	if tData.sType == "cast" then
		if tData.sSubRoll == "atk" then
			return "button_action_attack", "button_action_attack_down";
		elseif tData.sSubRoll == "save" then
			return "button_roll", "button_roll_down";
		end
		return "button_roll", "button_roll_down";
	elseif tData.sType == "damage" then
		return "button_action_damage", "button_action_damage_down";
	elseif tData.sType == "heal" then
		return "button_action_heal", "button_action_heal_down";
	elseif tData.sType == "effect" then
		return "button_action_effect", "button_action_effect_down";
	end
	return "", "";
end
function getActionText(node, tData)
	if tData.sType == "cast" then
		local sAttack, sSave = PowerManager.getPCPowerCastActionText(node);
		if tData.sSubRoll == "atk" then
			return sAttack;
		elseif tData.sSubRoll == "save" then
			return sSave;
		end
		return "";
	elseif tData.sType == "damage" then
		return PowerManager.getPCPowerDamageActionText(node);
	elseif tData.sType == "heal" then
		return PowerManager.getPCPowerHealActionText(node);
	elseif tData.sType == "effect" then
		return PowerActionManagerCore.getActionEffectText(node, tData);
	end
	return "";
end
function getActionTooltip(node, tData)
	if tData.sType == "cast" then
		if tData.sSubRoll == "atk" then
			return string.format("%s: %s", Interface.getString("power_tooltip_attack"), PowerActionManagerCore.getActionText(node, tData));
		elseif tData.sSubRoll == "save" then
			return string.format("%s: %s", Interface.getString("power_tooltip_save"), PowerActionManagerCore.getActionText(node, tData));
		end
		local tTooltip = {};
		table.insert(tTooltip, Interface.getString("power_tooltip_cast"));
		local sAttack, sSave = PowerManager.getPCPowerCastActionText(node);
		if sAttack ~= "" then
			table.insert(tTooltip, string.format("%s: %s", Interface.getString("power_tooltip_attack"), sAttack));
		end
		if sSave ~= "" then
			table.insert(tTooltip, string.format("%s: %s", Interface.getString("power_tooltip_save"), sSave));
		end
		return table.concat(tTooltip, "\r");
	elseif tData.sType == "damage" then
		return string.format("%s: %s", Interface.getString("power_tooltip_damage"), PowerActionManagerCore.getActionText(node, tData));
	elseif tData.sType == "heal" then
		return string.format("%s: %s", Interface.getString("power_tooltip_heal"), PowerActionManagerCore.getActionText(node, tData));
	elseif tData.sType == "effect" then
		return PowerActionManagerCore.getActionEffectTooltip(node, tData);
	end
	return "";
end
function performAction(node, tData)
	PowerManager.performPCPowerAction(tData.draginfo, node, tData and tData.sSubRoll);
end
