--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	if super and super.onInit then
		super.onInit();
	end
	OptionsManager.registerCallback("HRIS", self.onHRISOptionChanged);
	self.onHRISOptionChanged();
end
function onClose()
	OptionsManager.unregisterCallback("HRIS", self.onHRISOptionChanged);
end

function onHRISOptionChanged()
	local sOptHRIS = OptionsManager.getOption("HRIS");
	local nOptHRIS = math.min(math.max(tonumber(sOptHRIS) or 1, 1), 5);

	if inspiration.getMaxValue() ~= nOptHRIS then
		inspiration.setMaxValue(nOptHRIS);
		inspiration.updateSlots();
	end
	inspiration.setAnchor("left", "inspirationtitle", "center", "absolute", -5 * nOptHRIS);
end
