-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

-- NOTE: Non-land vehicles are also immune to "prone" by default
VEHICLE_TYPE_LAND = "land"
tStandardVehicleConditionImmunities = { "blinded", "charmed", "deafened", "frightened", "intoxicated", "paralyzed", "petrified", "poisoned", "stunned", "unconscious" }
tStandardVehicleDamageImmunities = { "poison", "psychic" }

-- ===================================================================================================================
-- ===================================================================================================================
function onInit()
	initActorHealth()
end

-- ===================================================================================================================
--	HEALTH
-- ===================================================================================================================
function initActorHealth()
	ActorHealthManager.registerStatusHealthColor(ActorHealthManager.STATUS_UNCONSCIOUS, ColorManager.COLOR_HEALTH_DYING_OR_DEAD)

	-- Replacing CoreRPG function with new function
	ActorHealthManager.getWoundPercent = getWoundPercent
end

-- ===================================================================================================================
-- NOTE: Always default to using CT node as primary to make sure 
--		that all bars and statuses are synchronized in combat tracker
--		(Cross-link network updates between PC and CT fields can occur in either order, 
--		depending on where the scripts or end user updates.)
-- NOTE 2: We can not use default effect checking in this function 
-- 		as it will cause endless loop with conditionals that check health
-- ===================================================================================================================
function getWoundPercent(v)
	local rActor = ActorManager.resolveActor(v)

	local nHP = 0
	local nWounds = 0

	local nodeCT = ActorManager.getCTNode(rActor)

	if nodeCT then
		nHP = math.max(DB.getValue(nodeCT, "hp.total", 0), 0)
		nWounds = math.max(DB.getValue(nodeCT, "hp.wounds", 0), 0)
	elseif ActorManager.isPC(rActor) then
		local nodePC = ActorManager.getCreatureNode(rActor)
		if nodePC then
			nHP = math.max(DB.getValue(nodePC, "hp.total", 0), 0)
			nWounds = math.max(DB.getValue(nodePC, "hp.wounds", 0), 0)
		end
	end

	local nPercentWounded = 0

	if nHP > 0 then
		nPercentWounded = nWounds / nHP
	end

	-- ToDo: Wounds and Injuries and status "Defeated"
	local sStatus
	if nPercentWounded >= 1 then
		-- ToDo: Use proper string management
		sStatus = "Defeated"
	else
		sStatus = ActorHealthManager.getDefaultStatusFromWoundPercent(nPercentWounded)
	end
	
	return nPercentWounded, sStatus
end

-- ===================================================================================================================
-- Set color for damage
-- ===================================================================================================================
function getPCSheetWoundColor(nodePC)
	local nHP = 0
	local nWounds = 0

	if nodePC then
		nHP = math.max(DB.getValue(nodePC, "hp.total", 0), 0)
		nWounds = math.max(DB.getValue(nodePC, "hp.wounds", 0), 0)
	end

	local nPercentWounded = 0
	if nHP > 0 then
		nPercentWounded = nWounds / nHP
	end
	
	local sColor = ColorManager.getHealthColor(nPercentWounded, false)
	return sColor
end

-- ===================================================================================================================
--	ABILITY SCORES
-- ===================================================================================================================
-- ToDo: Adjust
function getAbilityEffectsBonus(rActor, sAbility)
	if not rActor or ((sAbility or "") == "") then
		return 0, 0
	end
	
	local bNegativeOnly = (sAbility:sub(1,1) == "-")
	if bNegativeOnly then
		sAbility = sAbility:sub(2)
	end

	local sAbilityEffect = DataCommon.ability_ltos[sAbility]
	if not sAbilityEffect then
		return 0, 0
	end
	
	local nAbilityMod, nAbilityEffects = EffectManager5E.getEffectsBonus(rActor, sAbilityEffect, true)
	
	local nAbilityScore = ActorManager5E.getAbilityScore(rActor, sAbility)
	if nAbilityScore > 0 then
		local nAffectedScore = math.max(nAbilityScore + nAbilityMod, 0)
		
		local nCurrentBonus = math.floor((nAbilityScore - 10) / 2)
		local nAffectedBonus = math.floor((nAffectedScore - 10) / 2)
		
		nAbilityMod = nAffectedBonus - nCurrentBonus
	else
		if nAbilityMod > 0 then
			nAbilityMod = math.floor(nAbilityMod / 2)
		else
			nAbilityMod = math.ceil(nAbilityMod / 2)
		end
	end

	if bNegativeOnly and (nAbilityMod > 0) then
		nAbilityMod = 0
	end

	return nAbilityMod, nAbilityEffects
end

-- ===================================================================================================================
-- ===================================================================================================================
function getArmorPenalty(rActor)
	local nAP = 0

	-- Determine DB nodes
	local sNodeType, nodeActor = ActorManager.getTypeAndNode(rActor)

	-- Return 0 if Actor was not defined
	if not nodeActor then
		return 0
	end

	-- Get Armor Penalty
	nAP = DB.getValue(nodeActor, "defenses.armor.penalty", 0)

	return nAP
end

-- ===================================================================================================================
-- ===================================================================================================================
function getAbilityScore(rActor, sAbility)
	-- Return -1 if no Ability was handed over
	if not sAbility then
		return -1
	end

	-- Return -1 if Actor was not defined
	local nodeActor = ActorManager.getCreatureNode(rActor)

	-- Return -1 if Actor was not defined
	if not nodeActor then
		return -1
	end

	local nStatScore = -1

	-- Convert input to lower case and removing all spaces from the string
	sAbility = ActionsManager2.ConvertToTechnical(sAbility)

	-- Get Ability score
	nStatScore = DB.getValue(nodeActor, "abilities." .. sAbility .. ".score", 0)

	return nStatScore
end

-- ===================================================================================================================
-- ===================================================================================================================
function getSkillRank(rActor, sSkill)
	-- Return -1 if no Skill or "Dash" as Skill was handed over
	if not sSkill or sSkill == "-" or sSkill == "None" then
		return -1
	end

	-- Return -1 if Actor was not defined
	local nodeActor = ActorManager.getCreatureNode(rActor)

	if not nodeActor then
		return -1
	end

	local nSkillRank = -1
	local nodeSkill = nil

	-- Convert input to lower case and removing all spaces from the string
	sSkill = ActionsManager2.ConvertToTechnical(sSkill)

	-- Get Skill node
	for _, vSkill in pairs(DB.getChildren(nodeActor, "skilllist")) do
		if ActionsManager2.ConvertToTechnical(DB.getValue(vSkill, "name", "")) == sSkill then
			nodeSkill = vSkill
			break
		end
	end

	-- Avoid a timing issue where on the CT the name of a Skill is not yet set in the DB and we end up in nodeSkill == nil
	if nodeSkill == nil then
		for _, vSkill in pairs(DB.getChildren(nodeActor, "skilllist")) do
			nodeSkill = vSkill
			break
		end
	end

	-- Get Skill rank saved as "misc"
	nSkillRank = DB.getValue(nodeSkill, "misc", 0)

	return nSkillRank
end

-- ===================================================================================================================
-- ===================================================================================================================
function getHealthFatigue(rActor)
	-- Return -1 if Actor was not defined
	local nodeActor = ActorManager.getCreatureNode(rActor)

	if not nodeActor then
		return -1
	end

	-- Get number of Fatigue
	local nInjuries = DB.getValue(nodeActor, "hp.fatigue", 0)

	return nInjuries
end

-- ===================================================================================================================
-- ===================================================================================================================
function getHealthInjuries(rActor)
	-- Return -1 if Actor was not defined
	local nodeActor = ActorManager.getCreatureNode(rActor)

	if not nodeActor then
		return -1
	end

	-- Get number of Injuries
	local nInjuries = DB.getValue(nodeActor, "hp.injuries", 0)

	return nInjuries
end

-- ===================================================================================================================
-- ===================================================================================================================
function getHealthTrauma(rActor)
	-- Return -1 if Actor was not defined
	local nodeActor = ActorManager.getCreatureNode(rActor)

	if not nodeActor then
		return -1
	end

	-- Get number of Trauma
	local nTrauma = DB.getValue(nodeActor, "hp.trauma", 0)

	return nTrauma
end

-- ===================================================================================================================
--	DEFENSES
-- ===================================================================================================================
function getSave(rActor, sSave)
	local bADV = false
	local bDIS = false
	local nValue = ActorManager5E.getAbilityBonus(rActor, sSave)
	local aAddText = {}
	
	local nodeActor = ActorManager.getCreatureNode(rActor)
	if not nodeActor then
		return 0, false, false, ""
	end

	if ActorManager.isPC(rActor) then
		nValue = nValue + DB.getValue(nodeActor, "abilities." .. sSave .. ".savemodifier", 0)

		-- Check for saving throw proficiency
		if DB.getValue(nodeActor, "abilities." .. sSave .. ".saveprof", 0) == 1 then
			nValue = nValue + DB.getValue(nodeActor, "profbonus", 0)
		end

		-- Check for armor non-proficiency
		if StringManager.contains({"strength", "dexterity"}, sSave) then
			if DB.getValue(nodeActor, "defenses.ac.prof", 1) == 0 then
				table.insert(aAddText, Interface.getString("roll_msg_armor_nonprof"))
				bDIS = true
			end
		end
	elseif ActorManager.isRecordType(rActor, "npc") then
		local sSaves = DB.getValue(nodeActor, "savingthrows", "")
		for _,v in ipairs(StringManager.split(sSaves, ",\r\n", true)) do
			local sAbility, sSign, sMod = v:match("(%w+)%s*([%+%-–]?)(%d+)")
			if sAbility then
				if DataCommon.ability_stol[sAbility:upper()] then
					sAbility = DataCommon.ability_stol[sAbility:upper()]
				elseif DataCommon.ability_ltos[sAbility:lower()] then
					sAbility = sAbility:lower()
				else
					sAbility = nil
				end
				
				if sAbility == sSave then
					nValue = tonumber(sMod) or 0
					if sSign == "-" or sSign == "–" then
						nValue = 0 - nValue
					end
					break
				end
			end
		end
	end
	
	return nValue, bADV, bDIS, table.concat(aAddText, " ")
end

-- ===================================================================================================================
--ToDo: Do we actually have that value?
-- ===================================================================================================================
function getCheck(rActor, sStat, sSkill)
	local nValue = 0
	local aAddText = {}
	local sStat = sStat:lower()

	local nodeActor = ActorManager.getCreatureNode(rActor)

	if not nodeActor then
		return 0, false, false, ""
	end

	if ActorManager.isPC(rActor) then
		nValue = nValue + DB.getValue(nodeActor, "abilities." .. sStat .. ".checkmodifier", 0)
	end
	
	return nValue, table.concat(aAddText, " ")
end

-- ===================================================================================================================
-- ===================================================================================================================
function getDefenseAdvantage(rAttacker, rDefender, aAttackFilter)
-- ToDo: Adjust for Chronicle
	if not rDefender then
		return false, false
	end
	
	-- Check effects
	local bProne = false
	
	if ActorManager.hasCT(rDefender) then
	-- ToDo: List all
		if EffectManager5E.hasEffect(rAttacker, "Invisible", rDefender, true) then
			bADV = true
		end
		if EffectManager5E.hasEffect(rDefender, "Blinded", rAttacker) then
			bADV = true
		end
		if EffectManager5E.hasEffect(rDefender, "Invisible", rAttacker) then
			bDIS = true
		end
		if EffectManager5E.hasEffect(rDefender, "Paralyzed", rAttacker) then
			bADV = true
		end
		if EffectManager.hasCondition(rDefender, "Prone") then
			bProne = true
		end
		if EffectManager5E.hasEffect(rDefender, "Restrained", rAttacker) then
			bADV = true
		end
		if EffectManager5E.hasEffect(rDefender, "Stunned", rAttacker) then
			bADV = true
		end
		if EffectManager.hasCondition(rDefender, "Unconscious") then
			bADV = true
		end
		if EffectManager5E.hasEffect(rDefender, "Dodge", rAttacker) and 
				not (EffectManager5E.hasEffect(rDefender, "Paralyzed", rAttacker) or
				EffectManager5E.hasEffect(rDefender, "Stunned", rAttacker) or
				EffectManager5E.hasEffect(rDefender, "Incapacitated", rAttacker) or
				EffectManager5E.hasEffect(rDefender, "Unconscious", rAttacker) or
				EffectManager5E.hasEffect(rDefender, "Grappled", rAttacker) or
				EffectManager5E.hasEffect(rDefender, "Restrained", rAttacker)) then
			bDIS = true
		end
		
		if bProne then
			if StringManager.contains(aAttackFilter, "melee") then
				bADV = true
			elseif StringManager.contains(aAttackFilter, "ranged") then
				bDIS = true
			end
		end
	end
	-- if bProne then
		-- local nodeAttacker = ActorManager.getCTNode(rAttacker)
		-- local nodeDefender = ActorManager.getCTNode(rDefender)
		-- if nodeAttacker and nodeDefender then
			-- local tokenAttacker = CombatManager.getTokenFromCT(nodeAttacker)
			-- local tokenDefender = CombatManager.getTokenFromCT(nodeDefender)
			-- if tokenAttacker and tokenDefender then
				-- local nodeAttackerContainer = tokenAttacker.getContainerNode()
				-- local nodeDefenderContainer = tokenDefender.getContainerNode()
				-- if nodeAttackerContainer.getPath() == nodeDefenderContainer.getPath() then
					-- local nDU = GameSystem.getDistanceUnitsPerGrid()
					-- local nAttackerSpace = math.ceil(DB.getValue(nodeAttacker, "space", nDU) / nDU)
					-- local nDefenderSpace = math.ceil(DB.getValue(nodeDefender, "space", nDU) / nDU)
					-- local xAttacker, yAttacker = tokenAttacker.getPosition()
					-- local xDefender, yDefender = tokenDefender.getPosition()
					-- local nGrid = nodeAttackerContainer.getGridSize()
					
					-- local xDiff = math.abs(xAttacker - xDefender)
					-- local yDiff = math.abs(yAttacker - yDefender)
					-- local gx = math.floor(xDiff / nGrid)
					-- local gy = math.floor(yDiff / nGrid)
					
					-- local nSquares = 0
					-- local nStraights = 0
					-- if gx > gy then
						-- nSquares = nSquares + gy
						-- nSquares = nSquares + gx - gy
					-- else
						-- nSquares = nSquares + gx
						-- nSquares = nSquares + gy - gx
					-- end
					-- nSquares = nSquares - (nAttackerSpace / 2)
					-- nSquares = nSquares - (nDefenderSpace / 2)
					-- -- DEBUG - FINISH - Need to be able to get grid type and grid size from token container node
				-- end
			-- end
		-- end
	-- end

	return bADV, bDIS
end

-- ===================================================================================================================
-- ===================================================================================================================
function getDefenseValue(rAttacker, rDefender, rRoll)
	if not rDefender or not rRoll then
		return nil, 0, 0, false, false
	end
	
	-- Base calculations
	-- ToDo: ???
	local sAttack = rRoll.sDesc
	
	local sAttackType = string.match(sAttack, "%[ATTACK.*%((%w+)%)%]")
	local bOpportunity = string.match(sAttack, "%[OPPORTUNITY%]")
	local nCover = tonumber(string.match(sAttack, "%[COVER %-(%d)%]")) or 0

	local nDefense = 0

	local nodeDefender = ActorManager.getCreatureNode(rDefender)

	-- Exits if no defender was provided
	if not nodeDefender then
		return nil, 0, 0, false, false
	end

	-- Get Combat Defense
	local sDefenderActorType = ActorManager.getRecordType(rDefender)

	if sDefenderActorType == "charsheet" then
		nDefense = DB.getValue(nodeDefender, "defenses.ac.total", 0)
	elseif sDefenderActorType == "npc" then
		nDefense = DB.getValue(nodeDefender, "defenses.ac.total", 0)
	-- elseif sDefenderActorType == "vehicle" then
		-- nDefense = DB.getValue(nodeDefender, "defenses.ac.total", 0)
	else
		return 0, 0, 0
	end
	
	-- Effects
	local nDefenseEffectMod = 0

	if ActorManager.hasCT(rDefender) then
		local nBonusAC = 0
		local nBonusStat = 0
		local nBonusSituational = 0
		
		local aAttackFilter = {}
		if sAttackType == "M" then
			table.insert(aAttackFilter, "melee")
		elseif sAttackType == "R" then
			table.insert(aAttackFilter, "ranged")
		end
		if bOpportunity then
			table.insert(aAttackFilter, "opportunity")
		end

		local aACEffects, nACEffectCount = EffectManager5E.getEffectsBonusByType(rDefender, {"AC"}, true, aAttackFilter, rAttacker)
		for _,v in pairs(aACEffects) do
			nBonusAC = nBonusAC + v.mod
		end
		
		nBonusStat = ActorManager5E.getAbilityEffectsBonus(rDefender, sDefenseStat)
		
		local bProne = false
		if EffectManager.hasCondition(rDefender, "Prone") then
			bProne = true
		end
		if EffectManager5E.hasEffect(rDefender, "Unconscious", rAttacker) then
			-- Placeholder
		end

		-- ToDo: Check this
		if nCover < 5 then
			local aCover = EffectManager5E.getEffectsByType(rDefender, "SCOVER", aAttackFilter, rAttacker)
			if #aCover > 0 or EffectManager5E.hasEffect(rDefender, "SCOVER", rAttacker) then
				nBonusSituational = nBonusSituational + 5 - nCover
			elseif nCover < 2 then
				aCover = EffectManager5E.getEffectsByType(rDefender, "COVER", aAttackFilter, rAttacker)
				if #aCover > 0 or EffectManager5E.hasEffect(rDefender, "COVER", rAttacker) then
					nBonusSituational = nBonusSituational + 2 - nCover
				end
			end
		end
		
		nDefenseEffectMod = nBonusAC + nBonusStat + nBonusSituational
	end
	
	-- Results
	return nDefense, 0, nDefenseEffectMod
end