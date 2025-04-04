-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

-- Adjusted
function onInit()
	super.onInit();
	-- onValueChanged();
end

-- Adjusted
-- function update(bReadOnly)
	-- setReadOnly(bReadOnly);
-- end

-- Adjusted
-- function onValueChanged()
	-- local nMod = math.floor((getValue() - 10) / 2);
	
	-- local bonusctrl = window[self.target[1] .. "_bonus"];
	-- if bonusctrl then
		-- bonusctrl.setValue(nMod);
	-- end
	
	-- local modctrl = window[self.target[1] .. "_modtext"];
	-- if modctrl then
		-- modctrl.setValue(string.format("%+d", nMod));
	-- end
-- end

function action(draginfo)
	local rActor = ActorManager.resolveActor(window.getDatabaseNode());
	ActionCheck.performRoll(draginfo, rActor, self.target[1]);
	return true;
end

function onDragStart(button, x, y, draginfo)
	if rollable then
		return action(draginfo);
	end
end
	
function onDoubleClick(x, y)
	if rollable then
		return action();
	end
end
