-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

--
--
function onInit()
	setHoverCursor("hand");
end

--
--
function action(draginfo)
	-- Initialize variables
	local sActorPath = self.actorpath
	local bSecret = not ActorManager.isPC(rActor)
	local sType = self.rolltype
	local sSkill = self.skill
	local nodeSkill = window.getDatabaseNode()
	local nodeActor = DB.getChild(nodeSkill, sActorPath)
	local rActor = ActorManager.resolveActor(nodeActor)

	-- Determine what roll to perform based on sType
	if sType == "skill" then
		-- Get skill
		for _,v in pairs(DB.getChildren(nodeActor, "skilllist")) do
			if DB.getValue(v, "name", ""):lower() == sSkill then
				nodeSkill = v
				break
			end
		end

		ActionSkill.performRoll(draginfo, rActor, nodeSkill, bSecret)
		return true
	end

	if sType == "init" then
		ActionInit.performRoll(draginfo, rActor, bSecret)
		return true
	end

	return true
end

--
--
function onDragStart(button, x, y, draginfo)
	return action(draginfo)
end

--
--
function onDoubleClick(x,y)
	return action()
end