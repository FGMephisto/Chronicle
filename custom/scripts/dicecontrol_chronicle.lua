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
	local sRollType = self.rolltype[1]
	local sStat = self.stat[1]:lower()
	local sSkill = self.skill[1]:lower()
	local ActorPath = self.actorpath[1]
	local nWidth, nHeight= self.getSize()

	-- Get correct nodeChar
	local node = window.getDatabaseNode()
	local nodeChar = DB.getChild(node, actorpath[1])

	-- Initialize sub-controls variables
	local sControlName = ""
	local nIconOffset = 0
	local nIconHeight = nHeight
	local nIconWidth = nIconHeight
	
	if (sName or "") ~= "" then
		-- Build Test Dice Icon
		local sControlName = sName .. "_dicetesticon"
		_ctrlDiceTestIcon = window.createControl("genericcontrol", sControlName)
		_ctrlDiceTestIcon.setAnchor("top", sName, "top", "absolute", nIconOffset)
		_ctrlDiceTestIcon.setAnchor("left", sName, "left", "absolute", nIconOffset)
		_ctrlDiceTestIcon.setAnchoredWidth(nIconWidth)
		_ctrlDiceTestIcon.setAnchoredHeight(nIconHeight)
		_ctrlDiceTestIcon.setIcon("d6icon")
		_ctrlDiceTestIcon.setVisible(isVisible())

		-- Build Test Dice Field - Hand over skill in field name to be used as ability
		local sControlName = sName .. "_diceTestControl"
		_ctrlDiceTestControl = window.createControl("dicecontrol_ability", sControlName)
		_ctrlDiceTestControl.setAnchor("top", sName, "top", "absolute", nIconOffset+1)
		_ctrlDiceTestControl.setAnchor("left", sName, "left", "absolute", nIconOffset)
		_ctrlDiceTestControl.setAnchoredWidth(nIconWidth)
		_ctrlDiceTestControl.setAnchoredHeight(nIconHeight)
		_ctrlDiceTestControl.setVisible(isVisible())

		-- Build Bonus Dice Icon
		local sControlName = sName .. "_dicebonusicon"
		_ctrlDiceBonusIcon = window.createControl("genericcontrol", sControlName)
		_ctrlDiceBonusIcon.setAnchor("top", sName .. "_dicetesticon", "top", "absolute", 0)
		_ctrlDiceBonusIcon.setAnchor("left", sName .. "_dicetesticon", "right", "absolute", 0)
		_ctrlDiceBonusIcon.setAnchoredWidth(nIconWidth)
		_ctrlDiceBonusIcon.setAnchoredHeight(nIconHeight)
		_ctrlDiceBonusIcon.setIcon("d6gicon")
		_ctrlDiceBonusIcon.setVisible(isVisible())

		-- Build Bonus Dice Field - Hand over skill in field name to be used as <target>
		local sControlName = sName .. "_diceBonusControl"
		_ctrlDiceBonusControl = window.createControl("dicecontrol_skill", sControlName)
		_ctrlDiceBonusControl.setAnchor("top", sName .. "_dicetesticon", "top", "absolute", 1)
		_ctrlDiceBonusControl.setAnchor("left", sName .. "_dicetesticon", "right", "absolute", 0)
		_ctrlDiceBonusControl.setAnchoredWidth(nIconWidth)
		_ctrlDiceBonusControl.setAnchoredHeight(nIconHeight)
		_ctrlDiceBonusControl.setVisible(isVisible())

		-- Build User Interface Control
		local sControlName = sName .. "_diceinterface"
		_ctrlDiceInterface = window.createControl("dicecontrol_interface", sControlName)
		_ctrlDiceInterface.setAnchor("top", sName, "top", "absolute", 0)
		_ctrlDiceInterface.setAnchor("left", sName, "left", "absolute", 0)
		_ctrlDiceInterface.setAnchoredWidth(nWidth)
		_ctrlDiceInterface.setAnchoredHeight(nHeight)
		_ctrlDiceInterface.rolltype = sRollType
		_ctrlDiceInterface.actorpath = ActorPath
		_ctrlDiceInterface.stat = sStat
		_ctrlDiceInterface.skill = sSkill
		_ctrlDiceInterface.setVisible(isVisible())
	end

	-- Add handlers to Ability score and Skill ranks
	DB.addHandler(DB.getPath(nodeChar, "abilities." .. sStat .. ".score"), "onUpdate", onSourceUpdate)
	DB.addHandler(DB.getPath(node, "misc"), "onUpdate", onSourceUpdate)

	-- Run inital update
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
	-- Get correct nodeChar
	local node = window.getDatabaseNode()
	local nodeChar = DB.getChild(node, actorpath[1])
	local rActor = ActorManager.resolveActor(nodeChar)

	-- Remove Ability and Skill handlers
	DB.removeHandler(DB.getPath(nodeChar, "abilities." .. self.stat[1] .. ".score"), "onUpdate", onSourceUpdate)
	DB.removeHandler(DB.getPath(node, "misc"), "onUpdate", onSourceUpdate)
end

function onSourceUpdate()
	-- Get correct nodeChar
	local node = window.getDatabaseNode()
	local nodeChar = DB.getChild(node, actorpath[1])
	local rActor = ActorManager.resolveActor(nodeChar)

	-- Update Attribute & Skill value
	_ctrlDiceTestControl.setValue(ActorManager5E.getAbilityScore(rActor, self.stat[1]))
	_ctrlDiceBonusControl.setValue(ActorManager5E.getSkillRank(rActor, self.skill[1]))
end

function onVisibilityChanged() -- If the DiceControl visibility changes, push that change to all associated controls
	local bVisibile = self.isVisible()

	if _ctrlDiceTestIcon ~= nil then
		_ctrlDiceTestIcon.setVisible(bVisibile)
	end

	if _ctrlDiceTestControl ~= nil then
		_ctrlDiceTestControl.setVisible(bVisibile)
	end

	if _ctrlDiceBonusIcon ~= nil then
		_ctrlDiceBonusIcon.setVisible(bVisibile)
	end

	if _ctrlDiceBonusIcon ~= nil then
		_ctrlDiceBonusControl.setVisible(bVisibile)
	end

	if _ctrlDiceInterface ~= nil then
		_ctrlDiceInterface.setVisible(bVisibile)
	end
end