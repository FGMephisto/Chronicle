--
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

local _ctrlDiceTestIcon = nil
local _ctrlDiceTestControl = nil
local _ctrlDiceBonusIcon = nil
local _ctrlDiceBonusControl = nil
local _ctrlDiceInterface = nil

function onInit()
	-- Catch data of governing control
	local sName = getName() or ""
	local sRollType = (self.rolltype and self.rolltype[1]) or ""
	local sStat = (self.stat and self.stat[1] and self.stat[1]:lower()) or ""
	local sSkill = (self.skill and self.skill[1] and self.skill[1]:lower()) or ""
	local sActorPath = (self.actorpath and self.actorpath[1]) or ""
	local nWidth, nHeight = self.getSize()

	-- Get correct nodeChar
	local node = window.getDatabaseNode()
	local nodeChar = node
	if sActorPath ~= "" and node then
		nodeChar = DB.getChild(node, sActorPath)
	end

	-- Initialize sub-controls variables with 2px inner padding/spacing
	local nIconOffset = 2
	local nIconHeight = math.max(0, nHeight - (nIconOffset * 2))
	local nIconWidth = math.max(0, math.floor((nWidth - (nIconOffset * 3)) / 2))
	
	if (sName or "") ~= "" then
		-- Build Test Dice Icon
		local sTestIconName = sName .. "_dicetesticon"
		_ctrlDiceTestIcon = window.createControl("genericcontrol", sTestIconName)
		_ctrlDiceTestIcon.setAnchor("top", sName, "top", "absolute", nIconOffset)
		_ctrlDiceTestIcon.setAnchor("left", sName, "left", "absolute", nIconOffset)
		_ctrlDiceTestIcon.setAnchoredWidth(nIconWidth)
		_ctrlDiceTestIcon.setAnchoredHeight(nIconHeight)
		_ctrlDiceTestIcon.setIcon("d6icon")
		_ctrlDiceTestIcon.setVisible(isVisible())

		-- Build Test Dice Field
		local sTestControlName = sName .. "_diceTestControl"
		_ctrlDiceTestControl = window.createControl("dicecontrol_ability", sTestControlName)
		_ctrlDiceTestControl.setAnchor("top", sName, "top", "absolute", nIconOffset)
		_ctrlDiceTestControl.setAnchor("left", sName, "left", "absolute", nIconOffset)
		_ctrlDiceTestControl.setAnchoredWidth(nIconWidth)
		_ctrlDiceTestControl.setAnchoredHeight(nIconHeight)
		_ctrlDiceTestControl.setVisible(isVisible())

		-- Build Bonus Dice Icon
		local sBonusIconName = sName .. "_dicebonusicon"
		_ctrlDiceBonusIcon = window.createControl("genericcontrol", sBonusIconName)
		_ctrlDiceBonusIcon.setAnchor("top", sTestIconName, "top", "absolute", 0)
		_ctrlDiceBonusIcon.setAnchor("left", sTestIconName, "right", "absolute", nIconOffset)
		_ctrlDiceBonusIcon.setAnchoredWidth(nIconWidth)
		_ctrlDiceBonusIcon.setAnchoredHeight(nIconHeight)
		_ctrlDiceBonusIcon.setIcon("d6gicon")
		_ctrlDiceBonusIcon.setVisible(isVisible())

		-- Build Bonus Dice Field
		local sBonusControlName = sName .. "_diceBonusControl"
		_ctrlDiceBonusControl = window.createControl("dicecontrol_skill", sBonusControlName)
		_ctrlDiceBonusControl.setAnchor("top", sTestIconName, "top", "absolute", 0)
		_ctrlDiceBonusControl.setAnchor("left", sTestIconName, "right", "absolute", nIconOffset)
		_ctrlDiceBonusControl.setAnchoredWidth(nIconWidth)
		_ctrlDiceBonusControl.setAnchoredHeight(nIconHeight)
		_ctrlDiceBonusControl.setVisible(isVisible())

		-- Build User Interface Control
		local sInterfaceName = sName .. "_diceinterface"
		_ctrlDiceInterface = window.createControl("dicecontrol_interface", sInterfaceName)
		_ctrlDiceInterface.setAnchor("top", sName, "top", "absolute", 0)
		_ctrlDiceInterface.setAnchor("left", sName, "left", "absolute", 0)
		_ctrlDiceInterface.setAnchoredWidth(nWidth)
		_ctrlDiceInterface.setAnchoredHeight(nHeight)
		_ctrlDiceInterface.rolltype = sRollType
		_ctrlDiceInterface.actorpath = sActorPath
		_ctrlDiceInterface.stat = sStat
		_ctrlDiceInterface.skill = sSkill
		_ctrlDiceInterface.setVisible(isVisible())
	end

	-- Add handlers to Ability score and Skill ranks
	if nodeChar and sStat ~= "" then
		DB.addHandler(DB.getPath(nodeChar, "abilities." .. sStat .. ".score"), "onUpdate", onSourceUpdate)
	end
	if node then
		DB.addHandler(DB.getPath(node, "misc"), "onUpdate", onSourceUpdate)
	end

	-- Run initial update
	onSourceUpdate()
end

function onDestroy()
	if _ctrlDiceTestIcon then
		_ctrlDiceTestIcon.destroy()
		_ctrlDiceTestIcon = nil
	end
	if _ctrlDiceTestControl then
		_ctrlDiceTestControl.destroy()
		_ctrlDiceTestControl = nil
	end
	if _ctrlDiceBonusIcon then
		_ctrlDiceBonusIcon.destroy()
		_ctrlDiceBonusIcon = nil
	end
	if _ctrlDiceBonusControl then
		_ctrlDiceBonusControl.destroy()
		_ctrlDiceBonusControl = nil
	end
	if _ctrlDiceInterface then
		_ctrlDiceInterface.destroy()
		_ctrlDiceInterface = nil
	end
end

function onClose()
	local sStat = (self.stat and self.stat[1] and self.stat[1]:lower()) or ""
	local sActorPath = (self.actorpath and self.actorpath[1]) or ""
	local node = window.getDatabaseNode()
	local nodeChar = node
	if sActorPath ~= "" and node then
		nodeChar = DB.getChild(node, sActorPath)
	end

	-- Remove Ability and Skill handlers
	if nodeChar and sStat ~= "" then
		DB.removeHandler(DB.getPath(nodeChar, "abilities." .. sStat .. ".score"), "onUpdate", onSourceUpdate)
	end
	if node then
		DB.removeHandler(DB.getPath(node, "misc"), "onUpdate", onSourceUpdate)
	end
end

function onSourceUpdate()
	local sStat = (self.stat and self.stat[1] and self.stat[1]:lower()) or ""
	local sSkill = (self.skill and self.skill[1] and self.skill[1]:lower()) or ""
	local sActorPath = (self.actorpath and self.actorpath[1]) or ""
	local node = window.getDatabaseNode()
	local nodeChar = node
	if sActorPath ~= "" and node then
		nodeChar = DB.getChild(node, sActorPath)
	end
	local rActor = ActorManager.resolveActor(nodeChar)

	-- Update Attribute & Skill value
	if _ctrlDiceTestControl then
		_ctrlDiceTestControl.setValue(ActorManager5E.getAbilityScore(rActor, sStat))
	end
	if _ctrlDiceBonusControl then
		_ctrlDiceBonusControl.setValue(ActorManager5E.getSkillRank(rActor, sSkill))
	end
end

-- If the DiceControl visibility changes, push that change to all associated controls
function onVisibilityChanged()
	local bVisible = self.isVisible()

	if _ctrlDiceTestIcon ~= nil then
		_ctrlDiceTestIcon.setVisible(bVisible)
	end

	if _ctrlDiceTestControl ~= nil then
		_ctrlDiceTestControl.setVisible(bVisible)
	end

	if _ctrlDiceBonusIcon ~= nil then
		_ctrlDiceBonusIcon.setVisible(bVisible)
	end

	if _ctrlDiceBonusControl ~= nil then
		_ctrlDiceBonusControl.setVisible(bVisible)
	end

	if _ctrlDiceInterface ~= nil then
		_ctrlDiceInterface.setVisible(bVisible)
	end
end