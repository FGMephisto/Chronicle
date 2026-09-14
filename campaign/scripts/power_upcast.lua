--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local _sActorPath;
local _tData;
function setData(rActor, tData)
	_sActorPath = ActorManager.getCreatureNodeName(rActor);
	_tData = tData;
	self.initDisplay();
	self.showContent();
end

function initDisplay()
	if not _tData then
		return;
	end

	link.setValue(RecordDataManager.getRecordTypeDisplayClass("spell"), DB.getPath(_tData.nodePower));
	name.setValue(DB.getValue(_tData.nodePower, "name", ""));

	for i = 1, PowerManager.SPELL_LEVELS do
		local bShowLevel = (i >= _tData.nPowerLevel) and (_tData.tSlotData.tCharLevels[i]);
		self["slot" .. i].setVisible(bShowLevel);
		self["slot" .. i].setEnabled(_tData.tSlotData.tActiveLevels[i]);
		self["slot" .. i].setText(StringManager.convertNumberToOrdinal(i));
	end
	self["ritual"].setVisible(_tData.bRitual);
end
function showContent()
	local wTop = WindowManager.getTopWindow(self);
	if wTop.getClass() == "charsheet" then
		parentcontrol.setVisible(true);
	end
end
function closeContent()
	local wTop = WindowManager.getTopWindow(self);
	if wTop.getClass() == "charsheet" then
		parentcontrol.setVisible(false);
	else
		wTop.close();
	end
end

function processSlot(nSlot)
	self.closeContent();

	local rActor = ActorManager.resolveActor(_sActorPath);
	PowerManager5E.handleSpellSlotManualSelection(rActor, _tData, nSlot);
end
function processCancel()
	self.closeContent();
end
