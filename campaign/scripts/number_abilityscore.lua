--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	super.onInit();
	self.onValueChanged();
end

function update(bReadOnly)
	setReadOnly(bReadOnly);
end

function onValueChanged()
	local nMod = math.floor((getValue() - 10) / 2);

	local bonusctrl = window[self.target[1] .. "_bonus"];
	if bonusctrl then
		bonusctrl.setValue(nMod);
	end

	local modctrl = window[self.target[1] .. "_modtext"];
	if modctrl then
		modctrl.setValue(string.format("%+d", nMod));
	end
end

function onDragStart(_, _, _, draginfo)
	if window.onCheckAction then
		return WindowManager.callOuterWindowFunction(window, "onCheckAction", draginfo, self.target[1]);
	end
end
