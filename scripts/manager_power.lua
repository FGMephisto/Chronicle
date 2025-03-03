-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

SPELL_LEVELS = 9;

-------------------
-- POWER MANAGEMENT
-------------------

function resetPowers(nodeCaster, bLong)
	local aListGroups = {};
	
	-- Build list of power groups
	for _,vGroup in ipairs(DB.getChildList(nodeCaster, "powergroup")) do
		local sGroup = DB.getValue(vGroup, "name", "");
		if not aListGroups[sGroup] then
			local rGroup = {};
			rGroup.sName = sGroup;
			rGroup.sType = DB.getValue(vGroup, "castertype", "");
			rGroup.nUses = DB.getValue(vGroup, "uses", 0);
			rGroup.sUsesPeriod = DB.getValue(vGroup, "usesperiod", "");
			rGroup.nodeGroup = vGroup;
			
			aListGroups[sGroup] = rGroup;
		end
	end
	
	-- Reset power usage
	for _,vPower in ipairs(DB.getChildList(nodeCaster, "powers")) do
		local bReset = true;
		local bPartial = false;

		local sGroup = DB.getValue(vPower, "group", "");
		local rGroup = aListGroups[sGroup];
		local bCaster = (rGroup and rGroup.sType ~= "");
		
		if not bCaster then
			if rGroup and (rGroup.nUses > 0) then
				if rGroup.sUsesPeriod == "once" then
					bReset = false;
				elseif not bLong then
					if rGroup.sUsesPeriod ~= "enc" then
						bReset = false;
						if rGroup.sUsesPeriod == "dual" then
							bPartial = true;
						end
					end
				end
			else
				local sPowerUsesPeriod = DB.getValue(vPower, "usesperiod", "");
				if sPowerUsesPeriod == "once" then
					bReset = false;
				elseif not bLong then
					if sPowerUsesPeriod ~= "enc" then
						bReset = false;
						if sPowerUsesPeriod == "dual" then
							bPartial = true;
						end
					end
				end
			end
		end
		
		if bReset then
			DB.setValue(vPower, "cast", "number", 0);
		elseif bPartial then
			DB.setValue(vPower, "cast", "number", math.max(DB.getValue(vPower, "cast", 0) - 1, 0));
		end
	end
	
	-- Reset spell slots
	for i = 1, SPELL_LEVELS do
		DB.setValue(nodeCaster, "powermeta.pactmagicslots" .. i .. ".used", "number", 0);
	end
	if bLong then
		for i = 1, SPELL_LEVELS do
			DB.setValue(nodeCaster, "powermeta.spellslots" .. i .. ".used", "number", 0);
		end
	end
end

function addPower(sClass, nodeSource, nodeCreature, sGroup)
	-- Validate
	if not nodeSource or not nodeCreature then
		return nil;
	end
	
	-- Create the powers list entry
	local nodePowers = DB.createChild(nodeCreature, "powers");
	if not nodePowers then
		return nil;
	end
	
	-- Create the new power entry
	local nodeNewPower = DB.createChildAndCopy(nodePowers, nodeSource);
	if not nodeNewPower then
		return nil;
	end
	
	-- Determine group setting
	if sGroup then
		DB.setValue(nodeNewPower, "group", "string", sGroup);
	end
	
	-- Class specific handling
	if sClass ~= "reference_spell" and sClass ~= "power" then
		-- Remove level data
		DB.deleteChild(nodeNewPower, "level");
		
		-- Copy text to description
		local nodeText = DB.getChild(nodeNewPower, "text");
		if nodeText then
			local nodeDesc = DB.createChild(nodeNewPower, "description", "formattedtext");
			DB.copyNode(nodeText, nodeDesc);
			DB.deleteNode(nodeText);
		end
	end
	
	-- Set locked state for editing detailed record
	DB.setValue(nodeNewPower, "locked", "number", 1);
	
	-- Parse power details to create actions
	if DB.getChildCount(nodeNewPower, "actions") == 0 then
		PowerManager.parsePCPower(nodeNewPower);
	end

	-- If PC, then make sure all spells are visible
	if ActorManager.isPC(nodeCreature) then
		DB.setValue(nodeCreature, "powermode", "string", "standard");
	end
	
	return nodeNewPower;
end

-------------------------
-- POWER ACTION DISPLAY
-------------------------

function getPCPowerActionOutputOrder(nodeAction)
	if not nodeAction then
		return 1;
	end
	local nodeActionList = DB.getParent(nodeAction);
	if not nodeActionList then
		return 1;
	end
	
	-- First, pull some ability attributes
	local sType = DB.getValue(nodeAction, "type", "");
	local nOrder = DB.getValue(nodeAction, "order", 0);
	
	-- Iterate through list node
	local nOutputOrder = 1;
	for _, v in ipairs(DB.getChildList(nodeActionList)) do
		if DB.getValue(v, "type", "") == sType then
			if DB.getValue(v, "order", 0) < nOrder then
				nOutputOrder = nOutputOrder + 1;
			end
		end
	end
	
	return nOutputOrder;
end
function getPCPowerAction(nodeAction, sSubRoll)
	if not nodeAction then
		return;
	end
	local nodePower = DB.getChild(nodeAction, "...");
	local rActor = ActorManager.resolveActor(PowerManagerCore.getPowerActorNode(nodePower));
	if not rActor then
		return;
	end
	
	local rAction = {};
	rAction.type = DB.getValue(nodeAction, "type", "");
	rAction.label = DB.getValue(nodeAction, "...name", "");
	rAction.order = PowerManager.getPCPowerActionOutputOrder(nodeAction);
	
	if rAction.type == "cast" then
		rAction.subtype = sSubRoll;
		rAction.onmissdamage = DB.getValue(nodeAction, "onmissdamage", "");
		
		local sAttackType = DB.getValue(nodeAction, "atktype", "");
		if sAttackType ~= "" then
			if sAttackType == "melee" then
				rAction.range = "M";
			else
				rAction.range = "R";
			end
			
			rAction.modifier = DB.getValue(nodeAction, "atkmod", 0);
			local sAttackBase = DB.getValue(nodeAction, "atkbase", "");
			if sAttackBase == "fixed" then
				rAction.base = "fixed";
			elseif sAttackBase == "ability" then
				rAction.base = "";
				rAction.stat = DB.getValue(nodeAction, "atkstat", "");
				rAction.prof = DB.getValue(nodeAction, "atkprof", 1);
				rAction.modifier = DB.getValue(nodeAction, "atkmod", 0);
			else
				rAction.base = "group";
			end
		end
		
		local sSaveType = DB.getValue(nodeAction, "savetype", "");
		if sSaveType ~= "" then
			rAction.save = sSaveType;
			rAction.savemod = DB.getValue(nodeAction, "savedcmod", 0);
			if DB.getValue(nodeAction, "savemagic", 0) == 1 then
				rAction.magic = true;
			end
			local sSaveBase = DB.getValue(nodeAction, "savedcbase", "");
			if sSaveBase == "fixed" then
				rAction.savebase = "fixed";
			elseif sSaveBase == "ability" then
				rAction.savebase = "";
				rAction.savestat = DB.getValue(nodeAction, "savedcstat", "");
				rAction.saveprof = DB.getValue(nodeAction, "savedcprof", 1);
				rAction.savemod = rAction.savemod + 8;
			else
				rAction.savebase = "group";
				rAction.savemod = rAction.savemod + 8;
			end
		else
			rAction.save = "";
		end
		
	elseif rAction.type == "damage" then
		rAction.clauses = {};
		local aDamageNodes = UtilityManager.getNodeSortedChildren(nodeAction, "damagelist");
		for _,v in ipairs(aDamageNodes) do
			local sAbility = DB.getValue(v, "stat", "");
			local nMult = DB.getValue(v, "statmult", 1);
			local aDice = DB.getValue(v, "dice", {});
			local nMod = DB.getValue(v, "bonus", 0);
			local sDmgType = DB.getValue(v, "type", "");
			
			table.insert(rAction.clauses, { dice = aDice, stat = sAbility, statmult = nMult, modifier = nMod, dmgtype = sDmgType });
		end
		
	elseif rAction.type == "heal" then
		rAction.sTargeting = DB.getValue(nodeAction, "healtargeting", "");
		rAction.subtype = DB.getValue(nodeAction, "healtype", "");
		
		rAction.clauses = {};
		local aHealNodes = UtilityManager.getNodeSortedChildren(nodeAction, "heallist");
		for _,v in ipairs(aHealNodes) do
			local sAbility = DB.getValue(v, "stat", "");
			local nMult = DB.getValue(v, "statmult", 1);
			local aDice = DB.getValue(v, "dice", {});
			local nMod = DB.getValue(v, "bonus", 0);
			
			table.insert(rAction.clauses, { dice = aDice, stat = sAbility, statmult = nMult, modifier = nMod });
		end
		
	elseif rAction.type == "effect" then
		rAction.sName = DB.getValue(nodeAction, "label", "");

		rAction.sApply = DB.getValue(nodeAction, "apply", "");
		rAction.sTargeting = DB.getValue(nodeAction, "targeting", "");
		
		rAction.nDuration = DB.getValue(nodeAction, "durmod", 0);
		rAction.sUnits = DB.getValue(nodeAction, "durunit", "");
	end
	
	return rAction, rActor;
end

function performPCPowerAction(draginfo, nodeAction, sSubRoll)
	local rAction, rActor = PowerManager.getPCPowerAction(nodeAction, sSubRoll);
	if rAction then
		PowerManager.performAction(draginfo, rActor, rAction, DB.getChild(nodeAction, "..."));
	end
end

function getPCPowerCastActionText(nodeAction)
	local sAttack = "";
	local sSave = "";

	local rAction, rActor = PowerManager.getPCPowerAction(nodeAction);
	if rAction then
		PowerManager.evalAction(rActor, DB.getChild(nodeAction, "..."), rAction);
		
		if (rAction.range or "") ~= "" then
			if rAction.range == "R" then
				sAttack = Interface.getString("ranged");
			else
				sAttack = Interface.getString("melee");
			end
			if rAction.modifier ~= 0 then
				sAttack = string.format("%s %+d", sAttack, rAction.modifier);
			end
		end
		if (rAction.save or "") ~= "" then
			sSave = StringManager.capitalize(rAction.save:sub(1,3)) .. " DC " .. rAction.savemod;
			if rAction.onmissdamage == "half" then
				sSave = sSave .. " (H)";
			end
		end
	end
	
	return sAttack, sSave;
end
function getPCPowerDamageActionText(nodeAction)
	local aOutput = {};
	local rAction, rActor = PowerManager.getPCPowerAction(nodeAction);
	if rAction then
		PowerManager.evalAction(rActor, DB.getChild(nodeAction, "..."), rAction);
		
		local aDamage = ActionDamage.getDamageStrings(rAction.clauses);
		for _,rDamage in ipairs(aDamage) do
			local sDice = StringManager.convertDiceToString(rDamage.aDice, rDamage.nMod);
			if rDamage.sType ~= "" then
				table.insert(aOutput, string.format("%s %s", sDice, rDamage.sType));
			else
				table.insert(aOutput, sDice);
			end
		end
	end
	return table.concat(aOutput, " + ");
end
function getPCPowerHealActionText(nodeAction)
	local sHeal = "";
	
	local rAction, rActor = PowerManager.getPCPowerAction(nodeAction);
	if rAction then
		PowerManager.evalAction(rActor, DB.getChild(nodeAction, "..."), rAction);
		
		local aHealDice = {};
		local nHealMod = 0;
		for _,vClause in ipairs(rAction.clauses) do
			for _,vDie in ipairs(vClause.dice) do
				table.insert(aHealDice, vDie);
			end
			nHealMod = nHealMod + vClause.modifier;
		end
		
		sHeal = StringManager.convertDiceToString(aHealDice, nHealMod);
		if DB.getValue(nodeAction, "healtype", "") == "temp" then
			sHeal = sHeal .. " temporary";
		end
		if DB.getValue(nodeAction, "healtargeting", "") == "self" then
			sHeal = sHeal .. " [SELF]";
		end
	end
	
	return sHeal;
end

-------------------------
-- POWER USAGE
-------------------------

function getPowerGroupRecord(rActor, nodePower, bNPCInnate)
	local aPowerGroup = nil;
	local bInnate = false;
	
	local sNodeType, nodeActor = ActorManager.getTypeAndNode(rActor);
	if sNodeType == "pc" then
		local nodePowerGroup = nil;
		local sGroup = DB.getValue(nodePower, "group", "");
		for _,v in ipairs(DB.getChildList(nodeActor, "powergroup")) do
			if DB.getValue(v, "name", "") == sGroup then
				nodePowerGroup = v;
			end
		end
		if nodePowerGroup then
			aPowerGroup = {};

			aPowerGroup.sStat = DB.getValue(nodePowerGroup, "stat", "");

			aPowerGroup.nAtkProf = DB.getValue(nodePowerGroup, "atkprof", 1);
			aPowerGroup.sAtkStat = DB.getValue(nodePowerGroup, "atkstat", "");
			if aPowerGroup.sAtkStat == "" then
				aPowerGroup.sAtkStat = aPowerGroup.sStat;
			end
			aPowerGroup.nAtkMod = DB.getValue(nodePowerGroup, "atkmod", 0);
			
			aPowerGroup.nSaveDCProf = DB.getValue(nodePowerGroup, "saveprof", 1);
			aPowerGroup.sSaveDCStat = DB.getValue(nodePowerGroup, "savestat", "");
			if aPowerGroup.sSaveDCStat == "" then
				aPowerGroup.sSaveDCStat = aPowerGroup.sStat;
			end
			aPowerGroup.nSaveDCMod = DB.getValue(nodePowerGroup, "savemod", 0);
		end
	else
		if nodePower then
			bInnate = (DB.getName(DB.getChild(nodePower, "..")) == "innatespells");
		else
			bInnate = bNPCInnate;
		end
			
		local nodeTrait = nil;
		for _,v in ipairs(DB.getChildList(nodeActor, "actions")) do
			local sTraitName = StringManager.simplify(DB.getValue(v, "name", ""));
			if bInnate and sTraitName:match("^spellcasting") then
				nodeTrait = v;
				break;
			end
		end
		if not nodeTrait then
			for _,v in ipairs(DB.getChildList(nodeActor, "traits")) do
				local sTraitName = StringManager.simplify(DB.getValue(v, "name", ""));
				if not bInnate and sTraitName:match("^spellcasting") then
					nodeTrait = v;
					break;
				elseif bInnate and sTraitName:match("^innatespellcasting") then
					nodeTrait = v;
					break;
				end
			end
		end
		if nodeTrait then
			aPowerGroup = {};
			aPowerGroup.bInnate = bInnate; 
			
			local sDesc = DB.getValue(nodeTrait, "desc", ""):lower();
			aPowerGroup.sStat = sDesc:match("spellcasting ability is (%w+)") or sDesc:match("using (%w+) as the spellcasting ability") or "";
			
			aPowerGroup.nAtkProf = 1;
			aPowerGroup.sAtkStat = aPowerGroup.sStat;
			aPowerGroup.nAtkMod = 0;
			local nFixedAtk = tonumber(sDesc:match("([+-]?%d+) to hit with spell attacks")) or nil;
			if nFixedAtk then
				local nTempMod = ActorManager5E.getAbilityBonus(rActor, aPowerGroup.sStat) + ActorManager5E.getAbilityBonus(rActor, "prf");
				aPowerGroup.nAtkMod = nFixedAtk - nTempMod;
			end

			aPowerGroup.nSaveDCProf = 1;
			aPowerGroup.sSaveDCStat = aPowerGroup.sStat;
			aPowerGroup.nSaveDCMod = 0;
			local nFixedSaveDC = tonumber(sDesc:match("spell save dc (%d+)")) or nil;
			if nFixedSaveDC then
				local nTempMod = 8 + ActorManager5E.getAbilityBonus(rActor, aPowerGroup.sStat) + ActorManager5E.getAbilityBonus(rActor, "prf");
				aPowerGroup.nSaveDCMod = nFixedSaveDC - nTempMod;
			end
			
			if not nodePower then
				local aLines = StringManager.split(DB.getValue(nodeTrait, "desc", ""), "\n");
				for _,sLine in ipairs(aLines) do
					local sLineLower = sLine:lower();
					local nLevel = -1;
					if bInnate then
						if sLineLower:match("^at will") then
							nLevel = 0;
						else
							nLevel = tonumber(sLineLower:match("^([1-9]) ?[\\/] ?day")) or -1;
						end
					else
						nLevel = tonumber(sLineLower:match("^([1-9])[snrt][tdh] level")) or -1;
						if nLevel > 0 then
							
						elseif nLevel == -1 and sLineLower:match("^cantrips") then
							nLevel = 0;
						end
					end
					if nLevel >= 0 then
						local aSpells = StringManager.split(sLine:match(":(.*)$"), ",", true);
						if nLevel > 0 then
							local nSlots = tonumber(sLineLower:match("%((%d+) slots?%)")) or 0;
							if nSlots > 0 then
								aSpells["slots"] = nSlots;
							end
						end
						if #aSpells > 0 then
							aPowerGroup[nLevel] = aSpells;
						end
					end
				end
			end
		end
	end
	
	if not aPowerGroup and nodePower then
		if sNodeType ~= "pc" then
			local nodeNPCGroup = DB.getParent(nodePower);
			if nodeNPCGroup and StringManager.isWord(nodeNPCGroup.getName, { "innatespells", "spells" }) then
				if bInnate then
					ChatManager.SystemMessage(Interface.getString("power_error_innatespellcastingnotfound"));
				else
					ChatManager.SystemMessage(Interface.getString("power_error_spellcastingnotfound"));
				end
			end
		end
	end
	
	return aPowerGroup;
end

function evalAction(rActor, nodePower, rAction)
	local aPowerGroup = nil;

	if (rAction.type == "cast") or (rAction.type == "attack") then
		if (rAction.base or "") == "group" then
			if not aPowerGroup then
				aPowerGroup = PowerManager.getPowerGroupRecord(rActor, nodePower);
			end
			if aPowerGroup then
				rAction.stat = aPowerGroup.sAtkStat;
				rAction.prof = aPowerGroup.nAtkProf;
				rAction.modifier = (rAction.modifier or 0) + aPowerGroup.nAtkMod;
			end
		end
		if (rAction.stat or "") == "base" then
			if not aPowerGroup then
				aPowerGroup = PowerManager.getPowerGroupRecord(rActor, nodePower);
			end
			if aPowerGroup then
				rAction.stat = aPowerGroup.sStat or "";
			end
		end
		if (rAction.stat or "") ~= "" then
			rAction.modifier = (rAction.modifier or 0) + ActorManager5E.getAbilityBonus(rActor, rAction.stat);
		end
		if (rAction.prof or 0) == 1 then
			rAction.modifier = (rAction.modifier or 0) + ActorManager5E.getAbilityBonus(rActor, "prf");
		end
	end
	
	if (rAction.type == "cast") or (rAction.type == "powersave") then
		if (rAction.save or "") == "base" then
			if not aPowerGroup then
				aPowerGroup = PowerManager.getPowerGroupRecord(rActor, nodePower);
			end
			if aPowerGroup then
				rAction.save = aPowerGroup.sStat or "";
			end
		end
		if (rAction.savebase or "") == "group" then
			if not aPowerGroup then
				aPowerGroup = PowerManager.getPowerGroupRecord(rActor, nodePower);
			end
			if aPowerGroup then
				rAction.savestat = aPowerGroup.sSaveDCStat;
				rAction.saveprof = aPowerGroup.nSaveDCProf;
				rAction.savemod = (rAction.savemod or 8) + aPowerGroup.nSaveDCMod;
			end
		end
		if (rAction.savestat or "") == "base" then
			if not aPowerGroup then
				aPowerGroup = PowerManager.getPowerGroupRecord(rActor, nodePower);
			end
			if aPowerGroup then
				rAction.savestat = aPowerGroup.sSaveDCStat or "";
			end
		end
		if (rAction.savestat or "") ~= "" then
			rAction.savemod = (rAction.savemod or 8) + ActorManager5E.getAbilityBonus(rActor, rAction.savestat);
		end
		if (rAction.saveprof or 0) == 1 then
			rAction.savemod = (rAction.savemod or 8) + ActorManager5E.getAbilityBonus(rActor, "prf");
		end
	end
	
	if (rAction.type == "damage") or (rAction.type == "heal") then
		for _,vClause in ipairs(rAction.clauses) do
			if (vClause.stat or "") ~= "" then
				if vClause.stat == "base" then
					if not aPowerGroup then
						aPowerGroup = PowerManager.getPowerGroupRecord(rActor, nodePower);
					end
					if aPowerGroup then
						local nAbilityBonus = ActorManager5E.getAbilityBonus(rActor, aPowerGroup.sStat);
						local nMult = vClause.statmult or 1;
						if nAbilityBonus > 0 and nMult ~= 1 then
							nAbilityBonus = math.floor(nMult * nAbilityBonus);
						end
						vClause.modifier = vClause.modifier + nAbilityBonus;
						vClause.stat = aPowerGroup.sStat;
					end
				else
					local nAbilityBonus = ActorManager5E.getAbilityBonus(rActor, vClause.stat);
					local nMult = vClause.statmult or 1;
					if nAbilityBonus > 0 and nMult ~= 1 then
						nAbilityBonus = math.floor(nMult * nAbilityBonus);
					end
					vClause.modifier = vClause.modifier + nAbilityBonus;
				end
			end
		end
	end

	if (rAction.type == "effect") then
		if rAction.sName:match("%[BASE%]") then
			if not aPowerGroup then
				aPowerGroup = PowerManager.getPowerGroupRecord(rActor, nodePower);
			end
			if aPowerGroup and aPowerGroup.sStat and DataCommon.ability_ltos[aPowerGroup.sStat] then
				rAction.sName =  rAction.sName:gsub("%[BASE%]", string.format("[%s]", DataCommon.ability_ltos[aPowerGroup.sStat]));
			end
		end
		rAction.sName = EffectManager5E.evalEffect(rActor, rAction.sName);
	end
end

function performAction(draginfo, rActor, rAction, nodePower)
	if not rActor or not rAction then
		return false;
	end
	
	evalAction(rActor, nodePower, rAction);

	local rRolls = {};
	if rAction.type == "cast" then
		rAction.subtype = (rAction.subtype or "");
		if rAction.subtype == "" then
			table.insert(rRolls, ActionPower.getPowerCastRoll(rActor, rAction));
		end
		if ((rAction.subtype == "") or (rAction.subtype == "atk")) and rAction.range then
			table.insert(rRolls, ActionAttack.getRoll(rActor, rAction));
		end
		if ((rAction.subtype == "") or (rAction.subtype == "save")) and ((rAction.save or "") ~= "") then
			table.insert(rRolls, ActionPower.getSaveVsRoll(rActor, rAction));
		end
	
	elseif rAction.type == "attack" then
		table.insert(rRolls, ActionAttack.getRoll(rActor, rAction));
		
	elseif rAction.type == "powersave" then
		table.insert(rRolls, ActionPower.getSaveVsRoll(rActor, rAction));

	elseif rAction.type == "damage" then
		table.insert(rRolls, ActionDamage.getRoll(rActor, rAction));
		
	elseif rAction.type == "heal" then
		table.insert(rRolls, ActionHeal.getRoll(rActor, rAction));
		
	elseif rAction.type == "effect" then
		local rRoll = ActionEffect.getRoll(draginfo, rActor, rAction);
		if rRoll then
			table.insert(rRolls, rRoll);
		end
	end
	
	if #rRolls > 0 then
		ActionsManager.performMultiAction(draginfo, rActor, rRolls[1].sType, rRolls);
	end
	return true;
end

-------------------------
-- POWER PARSING
-------------------------

function parseAttacks(sPowerName, aWords)
	local attacks = {};
	
	for i = 1, #aWords do
		if StringManager.isWord(aWords[i], "attack") then
			-- 2024
			if StringManager.isWord(aWords[i - 1], { "melee", "ranged", }) and ((i == 2) or StringManager.isWord(aWords[i + 1], "roll")) then
				local nIndex = i + 1;
				if StringManager.isWord(aWords[nIndex], "roll") then
					nIndex = nIndex + 1;
				end
				if StringManager.isWord(aWords[nIndex], ":") then
					nIndex = nIndex + 1;
				end
				if StringManager.isNumberString(aWords[nIndex]) then
					local rAttack = {
						startindex = i - 1,
						endindex = nIndex,
						label = sPowerName,
						modifier = tonumber(aWords[nIndex]) or 0,
					};
					if StringManager.isWord(aWords[i - 1], "melee") then
						rAttack.range = "M";
					elseif StringManager.isWord(aWords[i - 1], "ranged") then
						rAttack.range = "R";
					end
					if StringManager.isWord(aWords[nIndex + 1], "reach") then
						rAttack.rangedist = aWords[nIndex + 2];
					end

					table.insert(attacks, rAttack);
				end
			else
				-- 2014
				local nIndex = i;
				if StringManager.isWord(aWords[nIndex + 1], ":") then
					nIndex = nIndex + 1;
				end
				if StringManager.isNumberString(aWords[nIndex+1]) and 
						StringManager.isWord(aWords[nIndex+2], "to") and
						StringManager.isWord(aWords[nIndex+3], "hit") then
					local rAttack = {};
					rAttack.startindex = i;
					rAttack.endindex = nIndex + 3;
					
					rAttack.label = sPowerName;
					
					if StringManager.isWord(aWords[i-1], "weapon") then
						rAttack.weapon = true;
						rAttack.startindex = i - 1;
					elseif StringManager.isWord(aWords[i-1], "spell") then
						rAttack.spell = true;
						rAttack.startindex = i - 1;
					end
					
					if StringManager.isWord(aWords[i-2], "melee") then
						rAttack.range = "M";
						rAttack.startindex = i - 2;
					elseif StringManager.isWord(aWords[i-2], "ranged") then
						rAttack.range = "R";
						rAttack.startindex = i - 2;
					end
					
					if StringManager.isWord(aWords[nIndex+4], "reach") then
						rAttack.rangedist = aWords[nIndex+5];
					elseif StringManager.isWord(aWords[nIndex+4], "range") then
						if StringManager.isNumberString(aWords[nIndex+5]) and StringManager.isWord(aWords[nIndex+6], "ft") then
							rAttack.rangedist = aWords[nIndex+5];
							
							local nIndex2 = nIndex + 7;
							if StringManager.isWord(aWords[nIndex2], ".") then
								nIndex2 = nIndex2 + 1;
							end
							if StringManager.isNumberString(aWords[nIndex2]) and StringManager.isWord(aWords[nIndex2+1], "ft") then
								rAttack.rangedist = rAttack.rangedist .. "/" .. aWords[nIndex2];
							end
						end
					end

					rAttack.modifier = tonumber(aWords[nIndex+1]) or 0;

					table.insert(attacks, rAttack);
				else
					local bValid = false;
					if StringManager.isWord(aWords[i-1], {"weapon", "spell"}) and StringManager.isWord(aWords[i-2], {"melee", "ranged"}) and
							StringManager.isWord(aWords[i-3], {"a", "one", "single"}) and StringManager.isWord(aWords[i-4], "make") then
						bValid = true;
					elseif StringManager.isWord(aWords[i-2], {"melee", "ranged"}) and
							StringManager.isWord(aWords[i-3], {"a", "one", "single"}) and StringManager.isWord(aWords[i-4], "make") then
						bValid = true;
					end
					if bValid then
						if StringManager.isWord(aWords[i+1], "during") then
							bValid = false;
						elseif StringManager.isWord(aWords[i-5], "you") and StringManager.isWord(aWords[i-6], "when") then
							bValid = false;
						end
					end
					if bValid then
						local rAttack = {};
						rAttack.startindex = i - 2;
						rAttack.endindex = i;
						
						rAttack.label = sPowerName;
					
						if StringManager.isWord(aWords[i-1], "weapon") then
							rAttack.weapon = true;
						elseif StringManager.isWord(aWords[i-1], "spell") then
							rAttack.spell = true;
						end
						
						if StringManager.isWord(aWords[i-2], "melee") then
							rAttack.range = "M";
						elseif StringManager.isWord(aWords[i-2], "ranged") then
							rAttack.range = "R";
						end
						
						rAttack.modifier = 0;
						if rAttack.weapon then
							rAttack.nomod = true;
						else
							rAttack.base = "group";
						end

						table.insert(attacks, rAttack);
					end
				end
			end
		end
	end
	
	return attacks;
end

-- Assumes current index points to "damage"
function parseDamagePhrase(aWords, i)
	local rDamageFixed = nil;
	local rDamageVariable = nil;
	
	local bValid = false;
	local nDamageBegin = i;
	while StringManager.isWord(aWords[nDamageBegin - 1], DataCommon.dmgtypes) or
			(StringManager.isWord(aWords[nDamageBegin - 1], "iron") and StringManager.isWord(aWords[nDamageBegin - 2], "cold-forged")) or
			(StringManager.isWord(aWords[nDamageBegin - 1], "or") and StringManager.isWord(aWords[nDamageBegin - 2], DataCommon.dmgtypes)) or
			(StringManager.isWord(aWords[nDamageBegin - 1], "or") and StringManager.isWord(aWords[nDamageBegin - 2], "iron") and StringManager.isWord(aWords[nDamageBegin - 3], "cold-forged")) do
		if (StringManager.isWord(aWords[nDamageBegin - 1], "iron") and StringManager.isWord(aWords[nDamageBegin - 2], "cold-forged")) then
			nDamageBegin = nDamageBegin - 2;
		else
			nDamageBegin = nDamageBegin - 1;
		end
	end
	while StringManager.isDiceString(aWords[nDamageBegin - 1]) or (StringManager.isWord(aWords[nDamageBegin - 1], "plus") and StringManager.isDiceString(aWords[nDamageBegin - 2])) do
		bValid = true;
		nDamageBegin = nDamageBegin - 1;
	end
	if StringManager.isWord(aWords[nDamageBegin], "+") then
		nDamageBegin = nDamageBegin + 1;
	end
	
	if bValid then
		local nClauses = 0;
		local aFixedClauses = {};
		local aVariableClauses = {};
		local bHasVariableClause = false;
		local nDamageEnd = i;
		
		local j = nDamageBegin - 1;
		while bValid do
			local aDamage = {};

			while StringManager.isDiceString(aWords[j+1]) or (StringManager.isWord(aWords[j+1], "plus") and StringManager.isDiceString(aWords[j+2])) do
				if aWords[j+1] == "plus" then
					table.insert(aDamage, "+");
				else
					table.insert(aDamage, aWords[j+1]);
				end
				j = j + 1;
			end
			
			local aDmgType = {};
			while StringManager.isWord(aWords[j+1], DataCommon.dmgtypes) or
					(StringManager.isWord(aWords[j+1], "cold-forged") and StringManager.isWord(aWords[j+2], "iron")) or
					(StringManager.isWord(aWords[j+1], "or") and StringManager.isWord(aWords[j+2], DataCommon.dmgtypes)) or
					(StringManager.isWord(aWords[j+1], "or") and StringManager.isWord(aWords[j+2], "cold-forged") and StringManager.isWord(aWords[j+3], "iron")) do
				if StringManager.isWord(aWords[j+1], "cold-forged") and StringManager.isWord(aWords[j+2], "iron") then
					j = j + 1;
					table.insert(aDmgType, "cold-forged iron");
				elseif aWords[j+1] ~= "or" then
					table.insert(aDmgType, aWords[j+1]);
				end
				j = j + 1;
			end
			
			if #aDamage > 0 and StringManager.isWord(aWords[j+1], "damage") then
				j = j + 1;
				
				nClauses = nClauses + 1;
				
				local sDmgType = table.concat(aDmgType, ",");
				if #aDamage > 1 and StringManager.isNumberString(aDamage[1]) then
					bHasVariableClause = true;

					local rClauseFixed = {};
					rClauseFixed.dmgtype = sDmgType;
					rClauseFixed.dice, rClauseFixed.modifier = StringManager.convertStringToDice(aDamage[1]);
					aFixedClauses[nClauses] = rClauseFixed;

					local rClauseVariable = {};
					rClauseVariable.dmgtype = sDmgType;
					rClauseVariable.dice, rClauseVariable.modifier = StringManager.convertStringToDice(table.concat(aDamage, "", 2));
					aVariableClauses[nClauses] = rClauseVariable;
				else
					local rClauseFixed = {};
					rClauseFixed.dmgtype = sDmgType;
					rClauseFixed.dice, rClauseFixed.modifier = StringManager.convertStringToDice(table.concat(aDamage));
					aFixedClauses[nClauses] = rClauseFixed;
					
					local rClauseVariable = {};
					rClauseVariable.dmgtype = sDmgType;
					rClauseVariable.dice, rClauseVariable.modifier = StringManager.convertStringToDice(table.concat(aDamage));
					aVariableClauses[nClauses] = rClauseVariable;
				end
				
				nDamageEnd = j;

				if StringManager.isWord(aWords[j+1], {"and", "plus", "+"}) then
					j = j + 1;
					bValid = true;
				else
					bValid = false;
				end
			else
				bValid = false;
			end
		end

		if nClauses > 0 then
			rDamageFixed = {};
			rDamageFixed.startindex = nDamageBegin;
			rDamageFixed.endindex = nDamageEnd;

			rDamageFixed.clauses = aFixedClauses;
			
			if bHasVariableClause then
				rDamageVariable = {};
				rDamageVariable.startindex = nDamageBegin;
				rDamageVariable.endindex = nDamageEnd;

				rDamageVariable.clauses = aVariableClauses;
			end
		end
	elseif StringManager.isWord(aWords[i+1], "equal") and
			StringManager.isWord(aWords[i+2], "to") then
		local nStart = nDamageBegin;
		local aDamageDice = {};
		local aAbilities = {};
		local nMult = 1;
		
		j = i + 2;
		while aWords[j+1] do
			if StringManager.isDiceString(aWords[j+1]) then
				table.insert(aDamageDice, aWords[j+1]);
				nMult = 1;
			elseif StringManager.isWord(aWords[j+1], { "plus", "+" }) then
				-- Keep going
			elseif StringManager.isWord(aWords[j+1], "twice") then
				nMult = 2;
			elseif StringManager.isWord(aWords[j+1], "three") and
					StringManager.isWord(aWords[j+2], "times") then
				nMult = 3;
				j = j + 1;
			elseif StringManager.isWord(aWords[j+1], "four") and
					StringManager.isWord(aWords[j+2], "times") then
				nMult = 4;
				j = j + 1;
			elseif StringManager.isWord(aWords[j+1], "five") and
					StringManager.isWord(aWords[j+2], "times") then
				nMult = 5;
				j = j + 1;
			elseif StringManager.isWord(aWords[j+1], "your") and
					StringManager.isWord(aWords[j+2], "spellcasting") and
					StringManager.isWord(aWords[j+3], "ability") and
					StringManager.isWord(aWords[j+4], "modifier") then
				for n = 1, nMult do
					table.insert(aAbilities, "base");
				end
				nMult = 1;
				j = j + 3;
			elseif StringManager.isWord(aWords[j+1], "your") and
					StringManager.isWord(aWords[j+3], "modifier") and
					StringManager.isWord(aWords[j+2], DataCommon.abilities) then
				for n = 1, nMult do
					table.insert(aAbilities, aWords[j+2]);
				end
				nMult = 1;
				j = j + 2;
			elseif StringManager.isWord(aWords[j+1], "your") and
					StringManager.isWord(aWords[j+2], "level") then
				for n = 1, nMult do
					table.insert(aAbilities, "level");
				end
				nMult = 1;
				j = j + 1;
			elseif StringManager.isWord(aWords[j+1], "your") and
					StringManager.isWord(aWords[j+3], "level") and
					DataCommon.class_nametovalue[StringManager.capitalize(aWords[j+2])] then
				for n = 1, nMult do
					table.insert(aAbilities, DataCommon.class_nametovalue[StringManager.capitalize(aWords[j+2])]);
				end
				nMult = 1;
				j = j + 2;
			else
				break;
			end
			
			j = j + 1;
		end
		
		if (#aAbilities > 0) or (#aDamageDice > 0) then
			rDamageFixed = {};
			rDamageFixed.startindex = nStart;
			rDamageFixed.endindex = j;
			
			rDamageFixed.clauses = {};
			local rDmgClause = {};
			rDmgClause.dice, rDmgClause.modifier = StringManager.convertStringToDice(table.concat(aDamageDice, ""));
			if #aAbilities > 0 then
				rDmgClause.stat = aAbilities[1];
			end
			
			local aDmgType = {};
			if i ~= nStart then
				local k = nStart;
				while StringManager.isWord(aWords[k], DataCommon.dmgtypes) or
						(StringManager.isWord(aWords[k], "cold-forged") and StringManager.isWord(aWords[k+1], "iron")) do
					if StringManager.isWord(aWords[k], "cold-forged") and StringManager.isWord(aWords[k+1], "iron") then
						k = k + 1;
						table.insert(aDmgType, "cold-forged iron");
					else
						table.insert(aDmgType, aWords[k]);
					end
					k = k + 1;
				end
			end
			rDmgClause.dmgtype = table.concat(aDmgType, ",");
			
			table.insert(rDamageFixed.clauses, rDmgClause);
			
			for n = 2, #aAbilities do
				table.insert(rDamageFixed.clauses, { dice = {}, modifier = 0, stat = aAbilities[i], dmgtype = rDmgClause.dmgtype });
			end
		end
	end
	
	if rDamageFixed then
		if i < rDamageFixed.endindex then
			i = rDamageFixed.endindex;
		end
	end

	if rDamageVariable then 
		return i, rDamageVariable;
	end
	return i, rDamageFixed;
end

function parseDamages(sPowerName, aWords, bMagic)
	local damages = {};

	local bMagicAttack = false;
	
  	local i = 1;
  	while aWords[i] do
		-- MAIN TRIGGER ("damage")
		if StringManager.isWord(aWords[i], "damage") then
			local rDamage;
			i, rDamage = parseDamagePhrase(aWords, i);
			if rDamage then
				if StringManager.isWord(aWords[i+1], "at") and 
						StringManager.isWord(aWords[i+2], "the") and
						StringManager.isWord(aWords[i+3], { "start", "end" }) and
						StringManager.isWord(aWords[i+4], "of") then
					rDamage = nil;
				elseif StringManager.isWord(aWords[rDamage.startindex - 1], "extra") then
					rDamage = nil;
				end
			end
			if rDamage then
				rDamage.label = sPowerName;
				if StringManager.isWord(aWords[1], "ranged") then
					rDamage.range = "R";
				elseif StringManager.isWord(aWords[1], "melee") then
					rDamage.range = "M";
				end
				
				table.insert(damages, rDamage);
			end
  		-- CAPTURE MAGIC DAMAGE MODIFIER
		elseif StringManager.isWord(aWords[i], "attack") and StringManager.isWord(aWords[i-1], "weapon") and 
				StringManager.isWord(aWords[i-2], "magic") and StringManager.isWord(aWords[i-3], "a") and 
				StringManager.isWord(aWords[i-4], "is") and StringManager.isWord(aWords[i-5], "this") then
			bMagicAttack = true;
		end
		
		i = i + 1;
	end	

	-- SET MAGIC DAMAGE IF PHYSICAL DAMAGE SPECIFIED AND GENERATED BY SPELL
	if bMagic then
		for _,rDamage in ipairs(damages) do
			for _, rClause in ipairs(rDamage.clauses) do
				if (rClause.dmgtype or "") ~= "" then
					local aDmgType = StringManager.split(rClause.dmgtype, ",", true);
					if StringManager.contains(aDmgType, "bludgeoning") or StringManager.contains(aDmgType, "piercing") or StringManager.contains(aDmgType, "slashing") then
						bMagicAttack = true;
						break;
					end
				end
			end
		end
	end
	
	-- HANDLE MAGIC DAMAGE MODIFIER
	if bMagicAttack then
		for _,rDamage in ipairs(damages) do
			for _, rClause in ipairs(rDamage.clauses) do
				if not rClause.dmgtype or rClause.dmgtype == "" then
					rClause.dmgtype = "magic";
				else
					rClause.dmgtype = rClause.dmgtype .. ",magic";
				end
			end
		end
	end
	
	-- RESULTS
	return damages;
end

-- [-] regains additional hit points equal to 2 + spell's level.
-- [-] regains at least 1 hit point
-- [-] regains the maximum number of hit points possible from any healing.

-- regains <dice>+ hit points.
-- regains a number of hit points equal to <dice> + your spellcasting ability modifier.
-- regains hit points equal to <dice> + your spellcasting ability modifier.
-- regains hit points equal to <dice> + your spellcasting ability modifier.
-- regains 1 hit point at the start of each of its turns

function parseHeals(sPowerName, aWords)
	local heals = {};
	
  	-- Iterate through the words looking for clauses
  	local i = 1;
  	while aWords[i] do
  		-- Check for hit point gains (temporary or normal)
  		if StringManager.isWord(aWords[i], {"points", "point"}) and StringManager.isWord(aWords[i-1], "hit") then
  			-- Track the healing information
			local rHeal = nil;
  			local sTemp = nil;
   			local aHealDice = {};

  			-- Iterate backwards to determine values
  			local j = i - 2;
  			if StringManager.isWord(aWords[j], "temporary") then
				sTemp = "temp";
				j = j - 1;
   			end
			if StringManager.isWord(aWords[j], "of") and
					StringManager.isWord(aWords[j-1], "number") and
					StringManager.isWord(aWords[j-2], "a") then
				j = j - 3;
			end
 			if StringManager.isWord(aWords[j], "of") and
					StringManager.isWord(aWords[j-1], "number") and
					StringManager.isWord(aWords[j-2], "total") and
					StringManager.isWord(aWords[j-3], "a") then
				j = j - 4;
			end
 			while aWords[j] do
  				if StringManager.isDiceString(aWords[j]) and aWords[j] ~= "0" then
  					table.insert(aHealDice, 1, aWords[j]);
				else
  					break;
  				end
  				
  				j = j - 1;
  			end
			
			-- Make sure we started with "gain(s)" or "regain(s)" or "restore"
			if StringManager.isWord(aWords[j], { "gain", "gains", "regain", "regains", "restore", "restoring", }) and 
					not StringManager.isWord(aWords[j-1], { "cannot", "can't" }) then
				-- Determine self-targeting
				local bSelf = false;
				if aWords[j] ~= "restore" then
					local nSelfIndex = j;
					if StringManager.isWord(aWords[nSelfIndex-1], "to") and
							StringManager.isWord(aWords[nSelfIndex-2], "action") and
							StringManager.isWord(aWords[nSelfIndex-3], "bonus") and
							StringManager.isWord(aWords[nSelfIndex-4], "a") and
							StringManager.isWord(aWords[nSelfIndex-5], "use") then
						nSelfIndex = nSelfIndex - 5;
					end
 					if StringManager.isWord(aWords[nSelfIndex-1], "can") then
						nSelfIndex = nSelfIndex - 1;
					end
					if StringManager.isWord(aWords[nSelfIndex-1], "you") then
						bSelf = true;
					end
				end
				
				-- Figure out if the values in the text support a heal roll
				if (#aHealDice > 0) then
					local rHealFixedClause = {};
					local rHealVariableClause = {};
					
					local bHasVariableClause = false;
					if #aHealDice > 1 and StringManager.isNumberString(aHealDice[1]) then
						bHasVariableClause = true;

						rHealFixedClause.dice, rHealFixedClause.modifier = StringManager.convertStringToDice(aHealDice[1]);

						rHealVariableClause.dice, rHealVariableClause.modifier = StringManager.convertStringToDice(table.concat(aHealDice, "", 2));
					else
						rHealFixedClause.dice, rHealFixedClause.modifier = StringManager.convertStringToDice(table.concat(aHealDice));
						
						rHealVariableClause.dice, rHealVariableClause.modifier = StringManager.convertStringToDice(table.concat(aHealDice));
					end
					
					rHeal = {};
					rHeal.startindex = j;
					rHeal.endindex = i;
					
					rHeal.label = sPowerName;
					if sTemp then
						rHeal.subtype = "temp";
					end
					if bSelf then
						rHeal.sTargeting = "self";
					end
					
					rHeal.clauses = {};
					if bHasVariableClause then 
						table.insert(rHeal.clauses, rHealVariableClause);
					else
						table.insert(rHeal.clauses, rHealFixedClause);
					end
				
				elseif StringManager.isWord(aWords[i+1], "equal") and
						StringManager.isWord(aWords[i+2], "to") then
					local nStart = j;
					local aAbilities = {};
					local nMult = 1;
					
					j = i + 2;
					while aWords[j+1] do
						if StringManager.isDiceString(aWords[j+1]) then
							table.insert(aHealDice, aWords[j+1]);
							nMult = 1;
						elseif StringManager.isWord(aWords[j+1], { "plus", "+" }) then
							-- Keep going
						elseif StringManager.isWord(aWords[j+1], "twice") then
							nMult = 2;
						elseif StringManager.isWord(aWords[j+1], "three") and
								StringManager.isWord(aWords[j+2], "times") then
							nMult = 3;
							j = j + 1;
						elseif StringManager.isWord(aWords[j+1], "four") and
								StringManager.isWord(aWords[j+2], "times") then
							nMult = 4;
							j = j + 1;
						elseif StringManager.isWord(aWords[j+1], "five") and
								StringManager.isWord(aWords[j+2], "times") then
							nMult = 5;
							j = j + 1;
						elseif StringManager.isWord(aWords[j+1], "your") and
								StringManager.isWord(aWords[j+2], "spellcasting") and
								StringManager.isWord(aWords[j+3], "ability") and
								StringManager.isWord(aWords[j+4], "modifier") then
							for i = 1, nMult do
								table.insert(aAbilities, "base");
							end
							nMult = 1;
							j = j + 3;
							break;
						elseif StringManager.isWord(aWords[j+1], "your") and
								StringManager.isWord(aWords[j+3], "modifier") and
								StringManager.isWord(aWords[j+2], DataCommon.abilities) then
							for i = 1, nMult do
								table.insert(aAbilities, aWords[j+2]);
							end
							nMult = 1;
							j = j + 2;
						elseif StringManager.isWord(aWords[j+1], "your") and
								StringManager.isWord(aWords[j+2], "level") then
							for i = 1, nMult do
								table.insert(aAbilities, "level");
							end
							nMult = 1;
							j = j + 1;
						elseif StringManager.isWord(aWords[j+1], "your") and
								StringManager.isWord(aWords[j+3], "level") and
								DataCommon.class_nametovalue[StringManager.capitalize(aWords[j+2])] then
							-- One off - Lay on Hands
							local bAddOne = false;
							if StringManager.isWord(aWords[j+4], "x5") then
								bAddOne = true;
								nMult = 5;
							end
							for i = 1, nMult do
								table.insert(aAbilities, DataCommon.class_nametovalue[StringManager.capitalize(aWords[j+2])]);
							end
							nMult = 1;
							j = j + 2;
							if bAddOne then
								j = j + 1;
							end
						else
							break;
						end
						
						j = j + 1;
					end
					
					if (#aAbilities > 0) or (#aHealDice > 0) then
						rHeal = {};
						rHeal.startindex = nStart;
						rHeal.endindex = j;
						
						rHeal.label = sPowerName;
						if sTemp then
							rHeal.subtype = "temp";
						end
						if bSelf then
							rHeal.sTargeting = "self";
						end
						
						rHeal.clauses = {};
						local rHealClause = {};
						rHealClause.dice, rHealClause.modifier = StringManager.convertStringToDice(table.concat(aHealDice, ""));
						if #aAbilities > 0 then
							rHealClause.stat = aAbilities[1];
						end
						table.insert(rHeal.clauses, rHealClause);
						
						for i = 2, #aAbilities do
							table.insert(rHeal.clauses, { dice = {}, modifier = 0, stat = aAbilities[i] });
						end
					end
				end
			end
   		
			if rHeal then
				table.insert(heals, rHeal);
			end
		end
		
		-- Increment our counter
		i = i + 1;
	end	

	return heals;
end

function parseSaves(sPowerName, aWords, bPC, bMagic)
	local tSaves = {};
	
	for i = 1, #aWords do
		if StringManager.isWord(aWords[i], "magically") then
			bMagic = true;
		-- 2024 / 2014
		elseif StringManager.isWord(aWords[i], "throw") and
				StringManager.isWord(aWords[i - 1], "saving") and
				StringManager.isWord(aWords[i - 2], DataCommon.abilities) then
			if PowerManager.helperParseSaveStandard(sPowerName, aWords, bPC, bMagic, i - 2, i, tSaves) then
				-- Only pick up first save for PC powers
				if bPC then
					break;
				end
			end
		-- ToV
		elseif StringManager.isWord(aWords[i], "save") and
				(aWords[i - 1] and DataCommon.ability_stol[aWords[i - 1]:upper()]) then
			if PowerManager.helperParseSaveStandard(sPowerName, aWords, bPC, bMagic, i - 1, i, tSaves) then
				-- Only pick up first save for PC powers
				if bPC then
					break;
				end
			end
		-- 2014
		elseif StringManager.isWord(aWords[i], "throw") and
				StringManager.isWord(aWords[i-1], "saving") and
				StringManager.isWord(aWords[i-2], "this") and
				StringManager.isWord(aWords[i-3], "for") and
				StringManager.isWord(aWords[i-4], "dc") and
				StringManager.isWord(aWords[i+1], "equals") and
				StringManager.isWord(aWords[i+2], "8") and
				StringManager.isWord(aWords[i+3], "+") and
				StringManager.isWord(aWords[i+4], "your") and
				StringManager.isWord(aWords[i+5], DataCommon.abilities) and
				StringManager.isWord(aWords[i+6], "modifier") and
				StringManager.isWord(aWords[i+7], "+") and
				StringManager.isWord(aWords[i+8], "your") and
				StringManager.isWord(aWords[i+9], "proficiency") and
				StringManager.isWord(aWords[i+10], "bonus") then
			
			local rSave = {};
			rSave.startindex = i-4;
			rSave.endindex = i+10;
			rSave.label = sPowerName;
			rSave.save = "base";
			rSave.savestat = aWords[i+5];
			rSave.saveprof = 1;
		
			table.insert(tSaves, rSave);
			
			-- Only pick up first save for PC powers
			if bPC then
				break;
			end
		end
	end
	
	for i = 1,#tSaves do
		if bMagic then
			tSaves[i].magic = true;
		end
		local nHalfCheckStart = tSaves[i].startindex;
		local nHalfCheckEnd = #aWords;
		if i < #tSaves then
			nHalfCheckEnd = tSaves[i+1].startindex - 1;
		end
		for j = nHalfCheckStart,nHalfCheckEnd do
			if StringManager.isWord(aWords[j], "half") then
				-- 2024
				if StringManager.isWord(aWords[j+1], "damage") and 
						StringManager.isWord(aWords[j-1], ":") and
						StringManager.isWord(aWords[j-2], "success") then
					tSaves[i].onmissdamage = "half";
				-- 2014
				elseif StringManager.isWord(aWords[j+1], "as") and
						StringManager.isWord(aWords[j+2], "much") and
						StringManager.isWord(aWords[j+3], "damage") then
					tSaves[i].onmissdamage = "half";
				else
					local k = j;
					if StringManager.isWord(aWords[k-1], "only") then
						k = k - 1;
					end
					if StringManager.isWord(aWords[k-1], "takes") and
							StringManager.isWord(aWords[k-2], {"creature", "target"}) then
						-- Exception: Air Elemental - Whirlwind
						if sPowerName:match("^Whirlwind") then
							tSaves[1].onmissdamage = "half";
						else
							tSaves[i].onmissdamage = "half";
						end
					end
				end
			end
			
		end
	end
	
	return tSaves;
end
function helperParseSaveStandard(sPowerName, aWords, bPC, bMagic, nStart, nEnd, tSaves)
	local bValid = false;
	local nDC = nil;
	local nOriginalEnd = nEnd;

	local sAbility = aWords[nStart];
	if sAbility and DataCommon.ability_stol[sAbility:upper()] then
		sAbility = DataCommon.ability_stol[sAbility:upper()];
	end

	if StringManager.isWord(aWords[nEnd + 1], ":") then
		nEnd = nEnd + 1;
	end

	-- 2024
	if StringManager.isWord(aWords[nEnd + 1], "dc") and StringManager.isNumberString(aWords[nEnd + 2]) then
		bValid = true;
		nDC = tonumber(aWords[nEnd + 2]) or 0;
		nEnd = nEnd + 2;

	-- 2014
	elseif StringManager.isWord(aWords[nStart - 1], { "a", "an" }) then
		nStart = nStart - 1;
		if StringManager.isWord(aWords[nStart - 1], "fails") then
			bValid = true;
			nStart = nStart - 1;
		elseif StringManager.isWord(aWords[nStart - 1], "make") then
			if StringManager.isWord(aWords[nStart - 2], {"must", "to"}) then
				bValid = true;
				nStart = nStart - 1;
			elseif StringManager.isWord(aWords[nStart - 2], "it") and
					StringManager.isWord(aWords[nStart - 3], "of") and
					StringManager.isWord(aWords[nStart - 4], "feet") then
				bValid = true;
				nStart = nStart - 1;
			end
		elseif StringManager.isWord(aWords[nStart - 1], "on") and
				StringManager.isWord(aWords[nStart - 2], "succeed") and
				StringManager.isWord(aWords[nStart - 3], "must") then
			bValid = true;
			nStart = nStart - 3;
		elseif StringManager.isWord(aWords[nStart - 1], "makes") then
			if StringManager.isWord(aWords[nStart - 2], { "area", "cone", "cylinder", "emanation", "it", "line", "point", "points", "space", "range", "spell", "sphere", "then", "there", "touch", }) then
				bValid = true;
				nStart = nStart - 1;
			elseif StringManager.isWord(aWords[nStart - 2], "target") and
					StringManager.isWord(aWords[nStart - 3], { "the", "each", }) then
				bValid = true;
				nStart = nStart - 1;
			elseif StringManager.isWord(aWords[nStart - 2], "you") and
					StringManager.isWord(aWords[nStart - 3], "from") then
				bValid = true;
				nStart = nStart - 1;
			end
		end
		
	-- 2014
	elseif StringManager.isNumberString(aWords[nStart - 1]) and 
			StringManager.isWord(aWords[nStart - 2], "dc") then
		bValid = true;
		nDC = tonumber(aWords[nStart - 1]) or 0;
		nStart = nStart - 2;
	end
	
	if bValid then
		if StringManager.isWord(aWords[nEnd + 1], "against") and 
				StringManager.isWord(aWords[nEnd + 2], "this") and
				StringManager.isWord(aWords[nEnd + 3], "magic") then
			nEnd = nEnd + 3;
			bMagic = true;
		end
		
		local rSave = {
			startindex = nStart,
			endindex = nEnd,
			label = sPowerName,
			save = sAbility,
			savemod = nDC,
		};

		if not rSave.savemod then
			-- Handle special saving throws in traits (Antimagic Susceptibility)
			if StringManager.isWord(aWords[nOriginalEnd + 1], "against") and StringManager.isWord(aWords[nOriginalEnd + 2], "the") and
					StringManager.isWord(aWords[nOriginalEnd + 3], "caster's") and StringManager.isWord(aWords[nOriginalEnd + 4], "spell") and
					StringManager.isWord(aWords[nOriginalEnd + 5], "save") and StringManager.isWord(aWords[nOriginalEnd + 6], "DC") then
				rSave.savemod = 0;
			else
				rSave.savebase = "group";
			end
		end

		table.insert(tSaves, rSave);
		return true;
	end
	return false;
end

function parseEffectsAdd(aWords, i, rEffect, effects)
	local nDurIndex = rEffect.endindex + 1;
	if StringManager.isWord(aWords[nDurIndex], {"condition", "conditions"}) then
		nDurIndex = nDurIndex + 1;
	elseif StringManager.isWord(aWords[nDurIndex], "by") 
			and StringManager.isWord(aWords[nDurIndex + 1], "the") then
		nDurIndex = nDurIndex + 3;
	end
	
	-- Handle expiration phrases
	if StringManager.isWord(aWords[nDurIndex], "for") 
			and StringManager.isNumberString(aWords[nDurIndex + 1]) 
			and StringManager.isWord(aWords[nDurIndex + 2], {"round", "rounds", "minute", "minutes", "hour", "hours", "day", "days"}) then
		rEffect.nDuration = tonumber(aWords[nDurIndex + 1]) or 0;
		if StringManager.isWord(aWords[nDurIndex + 2], {"minute", "minutes"}) then
			rEffect.sUnits = "minute";
		elseif StringManager.isWord(aWords[nDurIndex + 2], {"hour", "hours"}) then
			rEffect.sUnits = "hour";
		elseif StringManager.isWord(aWords[nDurIndex + 2], {"day", "days"}) then
			rEffect.sUnits = "day";
		end
		rEffect.endindex = nDurIndex + 2;
		
	elseif StringManager.isWord(aWords[nDurIndex], { "until", "at" })
			and StringManager.isWord(aWords[nDurIndex + 1], "the")
			and StringManager.isWord(aWords[nDurIndex + 2], { "start", "end" })
			and StringManager.isWord(aWords[nDurIndex + 3], "of")
			and StringManager.isWord(aWords[nDurIndex + 4], { "its", "your" })
			and StringManager.isWord(aWords[nDurIndex + 5], "next")
			and StringManager.isWord(aWords[nDurIndex + 6], "turn") then
		rEffect.nDuration = 1;
		rEffect.endindex = nDurIndex + 6;

	elseif StringManager.isWord(aWords[nDurIndex], { "until", "at" })
			and StringManager.isWord(aWords[nDurIndex + 1], "the")
			and StringManager.isWord(aWords[nDurIndex + 2], { "start", "end" })
			and StringManager.isWord(aWords[nDurIndex + 3], "of")
			and StringManager.isWord(aWords[nDurIndex + 4], "the")
			and StringManager.isWord(aWords[nDurIndex + 6], "next")
			and StringManager.isWord(aWords[nDurIndex + 7], "turn") then
		rEffect.nDuration = 1;
		rEffect.endindex = nDurIndex + 7;

	elseif StringManager.isWord(aWords[nDurIndex], "until")
			and StringManager.isWord(aWords[nDurIndex + 1], "its")
			and StringManager.isWord(aWords[nDurIndex + 2], "next")
			and StringManager.isWord(aWords[nDurIndex + 3], "turn") then
		rEffect.nDuration = 1;
		rEffect.endindex = nDurIndex + 3;

	elseif StringManager.isWord(aWords[nDurIndex], "until")
			and StringManager.isWord(aWords[nDurIndex + 1], "the")
			and StringManager.isWord(aWords[nDurIndex + 3], "next")
			and StringManager.isWord(aWords[nDurIndex + 4], "turn") then
		rEffect.nDuration = 1;
		rEffect.endindex = nDurIndex + 4;

	elseif StringManager.isWord(aWords[nDurIndex], "while")
			and StringManager.isWord(aWords[nDurIndex + 1], "poisoned") then
		if #effects > 0 and rEffect.sName == "Unconscious" and effects[#effects].sName == "Poisoned" then
			local rComboEffect = effects[#effects];
			rComboEffect.sName = rComboEffect.sName .. "; " .. rEffect.sName;
			rComboEffect.endindex = rEffect.endindex;
			return;
		end
	end

	-- Add or combine effect
	if #effects > 0 and effects[#effects].endindex + 1 == rEffect.startindex and not effects[#effects].nDuration then
		local rComboEffect = effects[#effects];
		rComboEffect.sName = rComboEffect.sName .. "; " .. rEffect.sName;
		rComboEffect.endindex = rEffect.endindex;
		rComboEffect.nDuration = rEffect.nDuration;
		rComboEffect.sUnits = rEffect.sUnits;
	else
		table.insert(effects, rEffect);
	end
end

function parseEffects(sPowerName, aWords)
	local effects = {};
	
	local rCurrent = nil;
	local i = 1;
	while aWords[i] do
		if StringManager.isWord(aWords[i], "damage") then
			i, rCurrent = parseDamagePhrase(aWords, i);
			if rCurrent then
				if StringManager.isWord(aWords[i+1], "at") and 
						StringManager.isWord(aWords[i+2], "the") and
						StringManager.isWord(aWords[i+3], { "start", "end" }) and
						StringManager.isWord(aWords[i+4], "of") then
					
					local nTrigger = i + 4;
					if StringManager.isWord(aWords[nTrigger+1], "each") and
							StringManager.isWord(aWords[nTrigger+2], "of") then
						if StringManager.isWord(aWords[nTrigger+3], "its") then
							nTrigger = nTrigger + 3;
						else
							nTrigger = nTrigger + 4;
						end
					elseif StringManager.isWord(aWords[nTrigger+1], "its") then
						nTrigger = i;
					elseif StringManager.isWord(aWords[nTrigger+1], "your") then
						nTrigger = nTrigger + 1;
					end
					if StringManager.isWord(aWords[nTrigger+1], { "turn", "turns" }) then
						nTrigger = nTrigger + 1;
					end
					rCurrent.endindex = nTrigger;
					
					if StringManager.isWord(aWords[rCurrent.startindex - 1], "takes") and
							StringManager.isWord(aWords[rCurrent.startindex - 2], "and") and
							StringManager.isWord(aWords[rCurrent.startindex - 3], DataCommon.conditions) then
						rCurrent.startindex = rCurrent.startindex - 2;
					end
					
					local aName = {};
					for _,v in ipairs(rCurrent.clauses) do
						local sDmg = StringManager.convertDiceToString(v.dice, v.modifier);
						if v.dmgtype and v.dmgtype ~= "" then
							sDmg = sDmg .. " " .. v.dmgtype;
						end
						table.insert(aName, "DMGO: " .. sDmg);
					end
					rCurrent.clauses = nil;
					rCurrent.sName = table.concat(aName, "; ");
				elseif StringManager.isWord(aWords[rCurrent.startindex - 1], "extra") then
					rCurrent.startindex = rCurrent.startindex - 1;
					if StringManager.isWord(aWords[rCurrent.startindex - 1], "an") and 
							StringManager.isWord(aWords[rCurrent.startindex - 2], "deal") and
							StringManager.isWord(aWords[rCurrent.startindex - 3], "each") then
						-- No targeting
					else
						rCurrent.sTargeting = "self";
					end
					rCurrent.sApply = "roll";
					
					local aName = {};
					for _,v in ipairs(rCurrent.clauses) do
						local sDmg = StringManager.convertDiceToString(v.dice, v.modifier);
						if v.dmgtype and v.dmgtype ~= "" then
							sDmg = sDmg .. " " .. v.dmgtype;
						end
						table.insert(aName, "DMG: " .. sDmg);
					end
					rCurrent.clauses = nil;
					rCurrent.sName = table.concat(aName, "; ");
				else
					rCurrent = nil;
				end
			end

		elseif (i > 1) and StringManager.isWord(aWords[i], DataCommon.conditions) then
			local bValidCondition = false;
			local nConditionStart = i;

			local bNewConditionText = false;
			if StringManager.isWord(aWords[i+1], {"condition", "conditions"}) then
				bNewConditionText = true;
			elseif StringManager.isWord(aWords[i+1], "and") and 
					StringManager.isWord(aWords[i+2], DataCommon.conditions) and
					StringManager.isWord(aWords[i+3], "conditions") then
				bNewConditionText = true;
			end

			if bNewConditionText then
				local j = i - 1;
				if StringManager.isWord(aWords[i+1], "conditions") and StringManager.isWord(aWords[i-1], "and") and StringManager.isWord(aWords[i-2], DataCommon.conditions) then
					j = j - 2;
					nConditionStart = i - 1;
				end
				if StringManager.isWord(aWords[j], "the") and StringManager.isWord(aWords[j - 1], { "has", "have", "gain" }) then
					j = j - 2;
					while aWords[j] do
						if StringManager.isWord(aWords[j], "also") then
							-- Skip

						-- Standard positive leading words
						elseif StringManager.isWord(aWords[j], { "or", "and", "touch", }) then
							bValidCondition = true;

						-- Conditional positive leading words
						elseif StringManager.isWord(aWords[j], { "target", "creature" }) then
							if StringManager.isWord(aWords[j-1], "the") then
								j = j - 1;
							end
							if StringManager.isWord(aWords[j-1], { "if", "while" }) then
								break;
							end
							bValidCondition = true;
						
						elseif StringManager.isWord(aWords[j], { "it", "you" }) then
							if StringManager.isWord(aWords[j-1], { "if", "while" }) then
								break;
							end
							bValidCondition = true;

						-- Multi phrase
						elseif StringManager.isWord(aWords[j], "damage") then
							bValidCondition = true;

						-- Special positive cases
						elseif StringManager.isWord(aWords[j], { "breathe", "smaller", }) then
							bValidCondition = true;

						else
							break;
						end

						j = j - 1;
					end
				end
			else
				local j = i - 1;
				while aWords[j] do
					if StringManager.isWord(aWords[j], "be") then
						if StringManager.isWord(aWords[j-1], "or") then
							bValidCondition = true;
							nConditionStart = j;
							break;
						end
					
					elseif StringManager.isWord(aWords[j], "being") and
							StringManager.isWord(aWords[j-1], "against") then
						bValidCondition = true;
						nConditionStart = j;
						break;
					
					elseif StringManager.isWord(aWords[j], { "also", "magically" }) then
					
					-- Special handling: Blindness/Deafness
					elseif StringManager.isWord(aWords[j], "or") and StringManager.isWord(aWords[j-1], DataCommon.conditions) and 
							StringManager.isWord(aWords[j-2], "either") and StringManager.isWord(aWords[j-3], "is") then
						bValidCondition = true;
						break;
						
					elseif StringManager.isWord(aWords[j], { "while", "when", "cannot", "not", "if", "be", "or" }) then
						bValidCondition = false;
						break;
					
					elseif StringManager.isWord(aWords[j], { "target", "creature", "it" }) then
						if StringManager.isWord(aWords[j-1], "the") then
							j = j - 1;
						end
						nConditionStart = j;
						
					elseif StringManager.isWord(aWords[j], "and") then
						if #effects == 0 then
							break;
						elseif effects[#effects].endindex ~= j - 1 then
							if not StringManager.isWord(aWords[i], "unconscious") and not StringManager.isWord(aWords[j-1], "minutes") then
								break;
							end
						end
						bValidCondition = true;
						nConditionStart = j;
						
					elseif StringManager.isWord(aWords[j], "is") then
						if bValidCondition or StringManager.isWord(aWords[i], "prone") or
								(StringManager.isWord(aWords[i], "invisible") and StringManager.isWord(aWords[j-1], {"wearing", "wears", "carrying", "carries"})) then
							break;
						end
						bValidCondition = true;
						nConditionStart = j;
					
					elseif StringManager.isWord(aWords[j], DataCommon.conditions) then
						break;

					elseif StringManager.isWord(aWords[i], "poisoned") then
						if (StringManager.isWord(aWords[j], "instead") and StringManager.isWord(aWords[j-1], "is")) then
							bValidCondition = true;
							nConditionStart = j - 1;
							break;
						elseif StringManager.isWord(aWords[j], "become") then
							bValidCondition = true;
							nConditionStart = j;
							break;
						end
					
					elseif StringManager.isWord(aWords[j], {"knock", "knocks", "knocked", "fall", "falls"}) and StringManager.isWord(aWords[i], "prone")  then
						bValidCondition = true;
						nConditionStart = j;
						
					elseif StringManager.isWord(aWords[j], {"knock", "knocks", "fall", "falls", "falling", "remain", "is"}) and StringManager.isWord(aWords[i], "unconscious") then
						if StringManager.isWord(aWords[j], "falling") and StringManager.isWord(aWords[j-1], "of") and StringManager.isWord(aWords[j-2], "instead") then
							break;
						end
						if StringManager.isWord(aWords[j], "fall") and StringManager.isWord(aWords[j-1], "you") and StringManager.isWord(aWords[j-1], "if") then
							break;
						end
						if StringManager.isWord(aWords[j], "falls") and StringManager.isWord(aWords[j-1], "or") then
							break;
						end
						bValidCondition = true;
						nConditionStart = j;
						if StringManager.isWord(aWords[j], "fall") and StringManager.isWord(aWords[j-1], "or") then
							break;
						end
						
					elseif StringManager.isWord(aWords[j], {"become", "becomes"}) and StringManager.isWord(aWords[i], "frightened")  then
						bValidCondition = true;
						nConditionStart = j;
						break;
						
					elseif StringManager.isWord(aWords[j], {"turns", "become", "becomes"}) 
							and StringManager.isWord(aWords[i], {"invisible"}) then
						if StringManager.isWord(aWords[j-1], {"can't", "cannot"}) then
							break;
						end
						bValidCondition = true;
						nConditionStart = j;
					
					-- Special handling: Blindness/Deafness
					elseif StringManager.isWord(aWords[j], "either") and StringManager.isWord(aWords[j-1], "is") then
						bValidCondition = true;
						break;
					
					else
						break;
					end

					j = j - 1;
				end
			end
			
			if bValidCondition then
				rCurrent = {};
				rCurrent.sName = StringManager.capitalize(aWords[i]);
				rCurrent.startindex = nConditionStart;
				rCurrent.endindex = i;
			end
		
		elseif StringManager.isWord(aWords[i], "resistance") and 
				StringManager.isWord(aWords[i+1], "to") and
				StringManager.isWord(aWords[i+2], DataCommon.dmgtypes) and
				StringManager.isWord(aWords[i-1], "damage") and
				StringManager.isWord(aWords[i-1], "have") then
			local bValidResist = false;
			if StringManager.isWord(aWords[i-2], "allies") then
				bValidResist = true;
			elseif StringManager.isWord(aWords[i-2], "you") and
					not StringManager.isWord(aWords[i-3], "if") then
				bValidResist = true;
			end

			if bValidResist then
				rCurrent = {};
				rCurrent.sName = "RESIST: " .. aWords[i+2];
				rCurrent.startindex = i;
				rCurrent.endindex = i+2;
			end

		elseif StringManager.isWord(aWords[i], "cover") and 
				StringManager.isWord(aWords[i-1], { "half", "three-quarters", }) then
			local bValidCover = false;
			if StringManager.isWord(aWords[i-2], "provides") then
				bValidCover = true;
			elseif StringManager.isWord(aWords[i-2], "have") and
					StringManager.isWord(aWords[i-3], "allies") then
				bValidCover = true;
			elseif StringManager.isWord(aWords[i-2], "you") and
					StringManager.isWord(aWords[i-3], "grants") then
				bValidCover = true;
			end

			if bValidCover then
				rCurrent = {};
				if aWords[i+1] == "three-quarters" then
					rCurrent.sName = "SCOVER";
				else
					rCurrent.sName = "COVER";
				end
				rCurrent.startindex = i-1;
				rCurrent.endindex = i;
			end
		end
		
		if rCurrent then
			PowerManager.parseEffectsAdd(aWords, i, rCurrent, effects);
			rCurrent = nil;
		end
		
		i = i + 1;
	end

	if rCurrent then
		PowerManager.parseEffectsAdd(aWords, i - 1, rCurrent, effects);
	end
	
	-- Handle duration field in NPC spell translations
	i = 1;
	while aWords[i] do
		if StringManager.isWord(aWords[i], "duration") and StringManager.isWord(aWords[i+1], ":") then
			j = i + 2;
			local bConc = false;
			if StringManager.isWord(aWords[j], "concentration") and StringManager.isWord(aWords[j+1], "up") and StringManager.isWord(aWords[j+2], "to") then
				bConc = true;
				j = j + 3;
			end
			if StringManager.isNumberString(aWords[j]) and StringManager.isWord(aWords[j+1], {"round", "rounds", "minute", "minutes", "hour", "hours", "day", "days"}) then
				local nDuration = tonumber(aWords[j]) or 0;
				local sUnits = "";
				if StringManager.isWord(aWords[j+1], {"minute", "minutes"}) then
					sUnits = "minute";
				elseif StringManager.isWord(aWords[j+1], {"hour", "hours"}) then
					sUnits = "hour";
				elseif StringManager.isWord(aWords[j+1], {"day", "days"}) then
					sUnits = "day";
				end

				for _,vEffect in ipairs(effects) do
					if not vEffect.nDuration and (vEffect.sName ~= "Prone") then
						if bConc then
							vEffect.sName = vEffect.sName .. "; (C)";
						end
						vEffect.nDuration = nDuration;
						vEffect.sUnits = sUnits;
					end
				end

				-- Add direct effect right from concentration text
				if bConc then
					local rConcentrate = {};
					rConcentrate.sName = sPowerName .. "; (C)";
					rConcentrate.startindex = i;
					rConcentrate.endindex = j+1;

					PowerManager.parseEffectsAdd(aWords, i, rConcentrate, effects);
				end
			end
		end
		i = i + 1;
	end
	
	return effects;
end

function parsePower(tData)
	if not tData or not tData.sName or not tData.sDesc then
		return;
	end

	-- Get rid of some problem characters, and make lowercase
	local sCleanLower = tData.sDesc:gsub("’", "'"):gsub("–", "-"):lower();

	-- Parse the words
	local tWords, tWordStats = StringManager.parseWords(sCleanLower, "%[%].:;\n");
	
	-- Add/separate markers for end of sentence, end of clause and clause label separators
	tWords, tWordStats = PowerManager.helperParsePower(tData, tWords, tWordStats);

	-- Build master list of all power actions and sort
	local tActions = {};
	PowerManager.helperParsePowerConsolidation(tActions, tWordStats, "attack", PowerManager.parseAttacks(tData.sName, tWords));
	PowerManager.helperParsePowerConsolidation(tActions, tWordStats, "damage", PowerManager.parseDamages(tData.sName, tWords, tData.bMagic));
	PowerManager.helperParsePowerConsolidation(tActions, tWordStats, "heal", PowerManager.parseHeals(tData.sName, tWords));
	PowerManager.helperParsePowerConsolidation(tActions, tWordStats, "powersave", PowerManager.parseSaves(tData.sName, tWords, tData.bPC, tData.bMagic));
	PowerManager.helperParsePowerConsolidation(tActions, tWordStats, "effect", PowerManager.parseEffects(tData.sName, tWords));
	table.sort(tActions, function(a,b) return a.startpos < b.startpos end)

	return tActions;
end
function helperParsePower(tData, tWords, tWordStats)
	local tFinalWords = {};
	local tFinalWordStats = {};
	
	-- Separate words ending in periods, colons and semicolons
	for kWord,sWord in ipairs(tWords) do
		local nSpecialChar = sWord:find("[%.:;\n]");
		if nSpecialChar then
			local nStartPos = tWordStats[kWord].startpos;
			while nSpecialChar do
				if nSpecialChar > 1 then
					table.insert(tFinalWords, sWord:sub(1, nSpecialChar - 1));
					table.insert(tFinalWordStats, { startpos = nStartPos, endpos = nStartPos + nSpecialChar - 1 });
				end
				table.insert(tFinalWords, sWord:sub(nSpecialChar, nSpecialChar));
				table.insert(tFinalWordStats, { startpos = nStartPos + nSpecialChar - 1, endpos = nStartPos + nSpecialChar });
				
				nStartPos = nStartPos + nSpecialChar;
				sWord = sWord:sub(nSpecialChar + 1);
				nSpecialChar = sWord:find("[%.:;\n]");
			end
			if #sWord > 0 then
				table.insert(tFinalWords, sWord);
				table.insert(tFinalWordStats, { startpos = nStartPos, endpos = tWordStats[kWord].endpos });
			end
		else
			table.insert(tFinalWords, sWord);
			table.insert(tFinalWordStats, tWordStats[kWord]);
		end
	end

	-- Apply variables
	if tData and tData.tVariables then
		for sVar, vVar in pairs(tData.tVariables) do
			local sPattern = string.format("([+-]?)%%[%s%%]", sVar);
			for i = 1, #tFinalWords do
				local sSign = tFinalWords[i]:match(sPattern);
				if sSign then
					tFinalWords[i] = sSign .. (tostring(vVar) or "");
				end
			end
		end
	end
	
	return tFinalWords, tFinalWordStats;
end
function helperParsePowerConsolidation(tActions, tWordStats, sAbilityType, tNewActions)
	for _,v in ipairs(tNewActions) do
		-- Add type
		v.type = sAbilityType;

		-- Convert word indices to character positions
		v.startpos = tWordStats[v.startindex].startpos;
		v.endpos = tWordStats[v.endindex].endpos;
		v.startindex = nil;
		v.endindex = nil;

		-- Add to actions list
		table.insert(tActions, v);
	end
end

function cleanNPCPowerName(s)
	local sResult = StringManager.trim(s);
	sResult = sResult:gsub("%*$", "");
	sResult = sResult:gsub("%s?%([^)]+%)$", "");
	sResult = sResult:gsub(" %- .*$", "");
	return StringManager.trim(sResult);
end

function getPowerActions(nodePower, bNPC)
	if not nodePower then
		return nil;
	end

	local sPowerKey;
	if bNPC then
		sPowerKey = PowerManager.cleanNPCPowerName(DB.getValue(nodePower, "name", ""));
	else
		sPowerKey = DB.getValue(nodePower, "name", "");
	end

	if DB.getValue(nodePower, "version", "") == "2024" then
		sPowerKey = StringManager.simplify(sPowerKey);
		if DataSpell.tBuildDataSpell2024[sPowerKey] then
			return UtilityManager.copyDeep(DataSpell.tBuildDataSpell2024[sPowerKey]);
		end
	else
		sPowerKey = StringManager.simplify(sPowerKey);
		if DataSpell.parsedata[sPowerKey] then
			return UtilityManager.copyDeep(DataSpell.parsedata[sPowerKey]);
		end
	end

	return nil;
end

function parseNPCPower(nodePower, bAllowSpellDataOverride)
	if not nodePower then
		return {};
	end

	-- Allow override for NPC spells to be pre-parsed
	if bAllowSpellDataOverride then
		local tActions = PowerManager.getPowerActions(nodePower, true);
		if tActions then
			return tActions;
		end
	end
	
	-- Determine if NPC ability is in spell sections
	local bSpell = StringManager.contains({"spells", "innatespells"}, DB.getName(DB.getParent(nodePower)));

	-- Determine if NPC ability is magic
	-- NOTE: Add exception for beholder type creatures, since Eye Rays are broken out into individual powers and are all magical
	local bMagic = bSpell;
	if not bMagic then
		for _,v in ipairs(DB.getChildList(nodePower, "...")) do
			if StringManager.contains({ "eyeray", "eyerays" }, StringManager.simplify(DB.getValue(v, "name", ""))) then
				bMagic = true;
			end
		end
	end

	-- Get NPC power name and power description
	-- NOTE: Clean the power name of NPC decorators
	-- NOTE: Add in any value replacements for NPC summons
	local sPowerName = PowerManager.cleanNPCPowerName(DB.getValue(nodePower, "name", ""));
	local sPowerDesc = DB.getValue(nodePower, "desc", "");

	-- Parse NPC ability actions from text
	local tData = {
		sName = sPowerName,
		sDesc = sPowerDesc,
		bMagic = bMagic,
		tVariables = PowerManager.getNPCPowerVariables(nodePower),
		nodePower = nodePower,
	};
	for k,v in pairs(tData.tVariables or {}) do
		sPowerDesc = sPowerDesc:gsub("%[" .. k .. "%]", v);
	end
	local tActions = PowerManager.parsePower(tData);

	-- Make sure correct duration applied to NPC spell effects
	if bSpell then
		local sDuration, sUnits = sPowerDesc:lower():match("duration: concentration, up to (%d+) (%w+)");
		if sDuration and sUnits then
			local nDuration = tonumber(sDuration) or 0;
			if nDuration > 0 then
				local sDurationUnits = "";
				if StringManager.isWord(sUnits, {"minute", "minutes"}) then
					sDurationUnits = "minute";
				elseif StringManager.isWord(sUnits, {"hour", "hours"}) then
					sDurationUnits = "hour";
				elseif StringManager.isWord(sUnits, {"day", "days"}) then
					sDurationUnits = "day";
				end
				
				for _,v in ipairs(tActions) do
					if v.type == "effect" then
						if ((v.nDuration or 0) == 0) and (nDuration ~= 0) and (v.sName ~= "Prone") then
							v.nDuration = nDuration;
							v.sUnits = sDurationUnits;
						end
					end
				end
			end
		end
	end

	return tActions;
end
-- NOTE: Variable names must be lower case; and assumed to be encapsulated by brackets
function getNPCPowerVariables(nodePower)
	if not nodePower then
		return nil;
	end
	local nodeActor = DB.getChild(nodePower, "...");
	if not nodeActor then
		return nil;
	end
	if DB.getValue(nodeActor, "summon", 0) ~= 1 then
		return nil;
	end
	local tVars = {
		["slevel"] = DB.getValue(nodeActor, "summon_level", 0),
		["sattack"] = DB.getValue(nodeActor, "summon_attack", 0),
		["sdc"] = DB.getValue(nodeActor, "summon_dc", 0),
		["smod"] = DB.getValue(nodeActor, "summon_mod", 0),
	};
	return tVars;
end

function parsePCPower(nodePower)
	-- CLean out old actions
	local nodeActions = DB.createChild(nodePower, "actions");
	DB.deleteChildren(nodeActions);
	
	-- Track whether cast action already created
	local nodeCastAction = nil;
	
	-- Pull the actions from the spell data table (if available)
	local tActions = PowerManager.getPowerActions(nodePower);
	if tActions then
		for _,vAction in ipairs(tActions) do
			if vAction.type then
				if vAction.type == "attack" then
					if not nodeCastAction or (DB.getValue(nodeCastAction, "atktype", "") ~= "") then
						nodeCastAction = DB.createChild(nodeActions);
						DB.setValue(nodeCastAction, "type", "string", "cast");
					end
					if nodeCastAction then
						if vAction.range == "R" then
							DB.setValue(nodeCastAction, "atktype", "string", "ranged");
						else
							DB.setValue(nodeCastAction, "atktype", "string", "melee");
						end
						
						if vAction.modifier then
							DB.setValue(nodeCastAction, "atkbase", "string", "fixed");
							DB.setValue(nodeCastAction, "atkmod", "number", tonumber(vAction.modifier) or 0);
						end
					end
				
				elseif vAction.type == "damage" then
					local nodeAction = DB.createChild(nodeActions);
					DB.setValue(nodeAction, "type", "string", "damage");
					
					local nodeDmgList = DB.createChild(nodeAction, "damagelist");
					for _,vDamage in ipairs(vAction.clauses) do
						local nodeEntry = DB.createChild(nodeDmgList);
						
						DB.setValue(nodeEntry, "dice", "dice", vDamage.dice);
						DB.setValue(nodeEntry, "bonus", "number", vDamage.bonus);
						if vDamage.stat then
							DB.setValue(nodeEntry, "stat", "string", vDamage.stat);
						end
						if vDamage.statmult then
							DB.setValue(nodeEntry, "statmult", "number", vDamage.statmult);
						end
						DB.setValue(nodeEntry, "type", "string", vDamage.dmgtype);
					end
				
				elseif vAction.type == "heal" then
					local nodeAction = DB.createChild(nodeActions);
					DB.setValue(nodeAction, "type", "string", "heal");
						
					if vAction.subtype == "temp" then
						DB.setValue(nodeAction, "healtype", "string", "temp");
					end
					if vAction.sTargeting then
						DB.setValue(nodeAction, "healtargeting", "string", vAction.sTargeting);
					end
					
					local nodeHealList = DB.createChild(nodeAction, "heallist");
					for _,vHeal in ipairs(vAction.clauses) do
						local nodeEntry = DB.createChild(nodeHealList);
						
						DB.setValue(nodeEntry, "dice", "dice", vHeal.dice);
						DB.setValue(nodeEntry, "bonus", "number", vHeal.bonus);
						if vHeal.stat then
							DB.setValue(nodeEntry, "stat", "string", vHeal.stat);
						end
						if vHeal.statmult then
							DB.setValue(nodeEntry, "statmult", "number", vHeal.statmult);
						end
					end

				elseif vAction.type == "powersave" then
					if not nodeCastAction or (DB.getValue(nodeCastAction, "savetype", "") ~= "") then
						nodeCastAction = DB.createChild(nodeActions);
						DB.setValue(nodeCastAction, "type", "string", "cast");
					end
					if nodeCastAction then
						DB.setValue(nodeCastAction, "savetype", "string", vAction.save);
						DB.setValue(nodeCastAction, "savemagic", "number", 1);
						
						if vAction.savemod then
							DB.setValue(nodeCastAction, "savedcbase", "string", "fixed");
							DB.setValue(nodeCastAction, "savedcmod", "number", tonumber(vAction.savemod) or 8);
						elseif vAction.savestat then
							if vAction.savestat ~= "base" then
								DB.setValue(nodeCastAction, "savedcbase", "string", "ability");
								DB.setValue(nodeCastAction, "savedcstat", "string", vAction.savestat);
							end
						end
						if vAction.onmissdamage == "half" then
							DB.setValue(nodeCastAction, "onmissdamage", "string", "half");
						end
					end
				
				elseif vAction.type == "effect" then
					local nodeAction = DB.createChild(nodeActions);
					DB.setValue(nodeAction, "type", "string", "effect");
					
					DB.setValue(nodeAction, "label", "string", vAction.sName);

					if vAction.sTargeting then
						DB.setValue(nodeAction, "targeting", "string", vAction.sTargeting);
					end
					if vAction.sApply then
						DB.setValue(nodeAction, "apply", "string", vAction.sApply);
					end
					
					local nDuration = tonumber(vAction.nDuration) or 0;
					if nDuration ~= 0 then
						DB.setValue(nodeAction, "durmod", "number", nDuration);
						DB.setValue(nodeAction, "durunit", "string", vAction.sUnits);
					end

				end
			end
		end
	-- Otherwise, parse the power description for actions
	else
		local sPowerName = DB.getValue(nodePower, "name", "");
		local sPowerDesc = DB.getValue(nodePower, "description", "");

		-- Get the power duration
		local nDuration = 0;
		local sDurationUnits = "";
		local bConcentration = false;
		local sPowerDuration = DB.getValue(nodePower, "duration", "");
		local aDurationWords = StringManager.parseWords(sPowerDuration:lower());
		
		local j = 1;
		if StringManager.isWord(aDurationWords[j], "concentration") and StringManager.isWord(aDurationWords[j+1], "up") and StringManager.isWord(aDurationWords[j+2], "to") then
			bConcentration = true;
			j = j + 3;
		elseif StringManager.isWord(aDurationWords[j], "up") and StringManager.isWord(aDurationWords[j+1], "to") then
			j = j + 2;
		end
		if StringManager.isNumberString(aDurationWords[j]) and StringManager.isWord(aDurationWords[j+1], {"round", "rounds", "minute", "minutes", "hour", "hours", "day", "days"}) then
			nDuration = tonumber(aDurationWords[j]) or 0;
			if StringManager.isWord(aDurationWords[j+1], {"minute", "minutes"}) then
				sDurationUnits = "minute";
			elseif StringManager.isWord(aDurationWords[j+1], {"hour", "hours"}) then
				sDurationUnits = "hour";
			elseif StringManager.isWord(aDurationWords[j+1], {"day", "days"}) then
				sDurationUnits = "day";
			end
		end

		-- Determine whether this power is a spell
		local bMagic = false;
		local sGroup = DB.getValue(nodePower, "group", "");
		local bFoundGroup = false;
		local nodeActor = DB.getChild(nodePower, "...");
		for _,v in ipairs(DB.getChildList(nodeActor, "powergroup")) do
			if DB.getValue(v, "name", "") == sGroup then
				bFoundGroup = true;
				if DB.getValue(v, "castertype", "") == "memorization" then
					bMagic = true;
				end
				break;
			end
		end
		if not bFoundGroup then
			bMagic = (sGroup == Interface.getString("char_spell_powergroup_base"));
		end
		
		-- Parse the description
		local tData = {
			sName = sPowerName,
			sDesc = sPowerDesc,
			bMagic = bMagic,
			bPC = true,
			nodePower = nodePower,
		};
		local aActions = PowerManager.parsePower(tData);
		
		-- Handle effect duration based on spell
		local bEffectFound = false;
		local bConcEffectFound = false;
		for _,v in ipairs(aActions) do
			if v.type == "effect" then
				if ((v.nDuration or 0) == 0) and (nDuration ~= 0) and (v.sName ~= "Prone") then
					if bConcentration then
						bConcEffectFound = true;
						v.sName = v.sName .. "; (C)";
					end
					bEffectFound = true;
					v.nDuration = nDuration;
					v.sUnits = sDurationUnits;
				end
			end
		end
		if bConcentration then
			if not bConcEffectFound then
				bConcEffectFound = true;
				table.insert(aActions, 1, { type = "effect", sName = sPowerName .. "; (C)", sTargeting="self", nDuration = nDuration, sUnits = sDurationUnits });
			end
		else
			if not bEffectFound and (nDuration > 0) then
				table.insert(aActions, 1, { type = "effect", sName = sPowerName, sTargeting="self", nDuration = nDuration, sUnits = sDurationUnits });
			end
		end
		
		-- Translate parsed power records into entries in the PC Actions tab
		local bAttackFound = false;
		for _, v in ipairs(aActions) do
			if v.type == "attack" then
				if not bAttackFound then
					bAttackFound = true;
					if not nodeCastAction then
						nodeCastAction = DB.createChild(nodeActions);
						DB.setValue(nodeCastAction, "type", "string", "cast");
					end
					if nodeCastAction then
						if v.range == "R" then
							DB.setValue(nodeCastAction, "atktype", "string", "ranged");
						else
							DB.setValue(nodeCastAction, "atktype", "string", "melee");
						end
						
						if v.spell then
							-- Use group attack mod
						else
							DB.setValue(nodeCastAction, "atkbase", "string", "fixed");
							DB.setValue(nodeCastAction, "atkmod", "number", v.modifier);
						end
					end
				end
			
			elseif v.type == "damage" then
				local nodeAction = DB.createChild(nodeActions);
				DB.setValue(nodeAction, "type", "string", "damage");
				
				local nodeDmgList = DB.createChild(nodeAction, "damagelist");
				for _,vDamage in ipairs(v.clauses) do
					local nodeEntry = DB.createChild(nodeDmgList);
					
					DB.setValue(nodeEntry, "dice", "dice", vDamage.dice);
					DB.setValue(nodeEntry, "bonus", "number", vDamage.modifier);
					if vDamage.stat then
						DB.setValue(nodeEntry, "stat", "string", vDamage.stat);
					end
					if vDamage.statmult then
						DB.setValue(nodeEntry, "statmult", "number", vDamage.statmult);
					end
					DB.setValue(nodeEntry, "type", "string", vDamage.dmgtype);
				end

			elseif v.type == "heal" then
				local nodeAction = DB.createChild(nodeActions);
				DB.setValue(nodeAction, "type", "string", "heal");
					
				if v.subtype == "temp" then
					DB.setValue(nodeAction, "healtype", "string", "temp");
				end
				if v.sTargeting then
					DB.setValue(nodeAction, "healtargeting", "string", v.sTargeting);
				end
				
				local nodeHealList = DB.createChild(nodeAction, "heallist");
				for _,vHeal in ipairs(v.clauses) do
					local nodeEntry = DB.createChild(nodeHealList);
					
					DB.setValue(nodeEntry, "dice", "dice", vHeal.dice);
					DB.setValue(nodeEntry, "bonus", "number", vHeal.modifier);
					if vHeal.stat then
						DB.setValue(nodeEntry, "stat", "string", vHeal.stat);
					end
					if vHeal.statmult then
						DB.setValue(nodeEntry, "statmult", "number", vHeal.statmult);
					end
				end

			elseif v.type == "powersave" then
				if not nodeCastAction then
					nodeCastAction = DB.createChild(nodeActions);
					DB.setValue(nodeCastAction, "type", "string", "cast");
				end
				if nodeCastAction then
					DB.setValue(nodeCastAction, "savetype", "string", v.save);
					if v.magic then
						DB.setValue(nodeCastAction, "savemagic", "number", 1);
					end
					if v.savestat then
						if v.savestat ~= "base" then
							DB.setValue(nodeCastAction, "savedcbase", "string", "ability");
							DB.setValue(nodeCastAction, "savedcstat", "string", v.savestat);
						end
					elseif v.savemod then
						DB.setValue(nodeCastAction, "savedcbase", "string", "fixed");
						DB.setValue(nodeCastAction, "savedcmod", "number", v.savemod);
					end
					if v.onmissdamage == "half" then
						DB.setValue(nodeCastAction, "onmissdamage", "string", "half");
					end
				end
				
			elseif v.type == "effect" then
				local nodeAction = DB.createChild(nodeActions);
				if nodeAction then
					DB.setValue(nodeAction, "type", "string", "effect");
					
					DB.setValue(nodeAction, "label", "string", v.sName);
					if v.sTargeting then
						DB.setValue(nodeAction, "targeting", "string", v.sTargeting);
					end
					if v.sApply then
						DB.setValue(nodeAction, "apply", "string", v.sApply);
					end
					if (v.nDuration or 0) ~= 0 then
						DB.setValue(nodeAction, "durmod", "number", v.nDuration);
						DB.setValue(nodeAction, "durunit", "string", v.sUnits);
					end
				end
			end
		end
	end
end
