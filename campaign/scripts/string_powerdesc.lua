--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local bParsed = false;
local aAbilities = {};

local bDragging = nil;
local hoverAbility = nil;
local clickAbility = nil;

function getActor()
	local wTop = WindowManager.getTopWindow(window);
	local nodeCreature = wTop.getDatabaseNode();
	return ActorManager.resolveActor(nodeCreature);
end

function onValueChanged()
	bParsed = false;
end

function parseComponents()
	aAbilities = PowerManager.parseNPCPower(window.getDatabaseNode());
	bParsed = true;
end

-- Reset selection when the cursor leaves the control
function onHover(bOnControl)
	if bDragging or bOnControl then
		return;
	end

	hoverAbility = nil;
	setSelectionPosition(0);
end

-- Hilight attack or damage hovered on
function onHoverUpdate(x, y)
	if bDragging then
		return;
	end

	if not bParsed then
		self.parseComponents();
	end
	local nMouseIndex = getIndexAt(x, y);
	hoverAbility = nil;

	for i = 1, #aAbilities do
		if aAbilities[i].startpos <= nMouseIndex and aAbilities[i].endpos > nMouseIndex then
			setCursorPosition(aAbilities[i].startpos);
			setSelectionPosition(aAbilities[i].endpos);

			hoverAbility = i;
		end
	end

	if hoverAbility then
		setHoverCursor("hand");
	else
		setHoverCursor("arrow");
	end
end

function action(draginfo, rAction)
	local rActionCopy = UtilityManager.copyDeep(rAction);
	return PowerManager.performAction(draginfo, self.getActor(), rActionCopy, window.getDatabaseNode());
end

-- Suppress default processing to support dragging
function onClickDown()
	clickAbility = hoverAbility;
	return true;
end
-- On mouse click, set focus, set cursor position and clear selection
function onClickRelease(_, x, y)
	setFocus();

	local n = getIndexAt(x, y);
	setSelectionPosition(n);
	setCursorPosition(n);

	return true;
end
function onDoubleClick()
	if hoverAbility then
		self.action(nil, aAbilities[hoverAbility]);
		return true;
	end
end
function onDragStart(button, x, y, draginfo)
	return self.onDrag(button, x, y, draginfo);
end
function onDrag(_, _, _, draginfo)
	if bDragging then
		return true;
	end

	if clickAbility then
		self.action(draginfo, aAbilities[clickAbility]);
		clickAbility = nil;
		bDragging = true;
		return true;
	end

	return true;
end
function onDragEnd()
	setCursorPosition(0);
	bDragging = false;
end
