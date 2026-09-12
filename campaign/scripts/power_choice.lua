--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local _sActorPath;
local _tPowerData;
function setData(rActor, tPowerData)
	_sActorPath = ActorManager.getCreatureNodeName(rActor);
	_tPowerData = tPowerData;
	self.initDisplay();
	self.showContent();

	self.setupChoices();
	self.processNextChoice();
end

function initDisplay()
	if not _tPowerData then
		return;
	end

	link.setValue(RecordDataManager.getRecordTypeDisplayClass("spell"), DB.getPath(_tPowerData.nodePower));
	name.setValue(DB.getValue(_tPowerData.nodePower, "name", ""));
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
function updateChoiceDisplay()
	local tChoice = self.getCurrentChoice();
	accept.setVisible(tChoice and tChoice.bMultiple);
	list.closeAll();
	for _,s in ipairs(tChoice or {}) do
		local w = list.createWindow();
		w.setData(s);
	end
end
function updateAcceptDisplay()
	accept.setVisible((#(self.getCurrentChoiceSelection()) > 0));
end

local _nChoiceIndex = 0;
local _tChoiceList = {};
local _tChoiceSelectionList = {};
function setupChoices()
	_nChoiceIndex = 0;
	_tChoiceList = {};
	_tChoiceSelectionList = {};

	if _tPowerData then
		_tChoiceList = UtilityManager.copyDeep(_tPowerData.tChoices);
	end
end
function incrementChoiceIndex()
	_nChoiceIndex = _nChoiceIndex + 1;
end
function getCurrentChoice()
	return _tChoiceList[_nChoiceIndex];
end
function getCurrentChoiceSelection()
	_tChoiceSelectionList[_nChoiceIndex] = _tChoiceSelectionList[_nChoiceIndex] or {};
	return _tChoiceSelectionList[_nChoiceIndex];
end
function finalizeChoices()
	self.closeContent();

	if not _tPowerData then
		return;
	end

	_tPowerData.tChoiceSelections = {};
	for k,tChoices in ipairs(_tChoiceList) do
		local tSelections = UtilityManager.copyDeep(_tChoiceSelectionList[k]);
		tSelections.node = tChoices.node;
		tSelections.sTag = tChoices.sTag;
		table.insert(_tPowerData.tChoiceSelections, tSelections);
	end

	local rActor = ActorManager.resolveActor(_sActorPath);
	PowerManager5E.handlePowerChoiceSelectionsComplete(rActor, _tPowerData);
end

function processNextChoice()
	self.incrementChoiceIndex();

	local tChoice = self.getCurrentChoice();
	if tChoice then
		if #tChoice > 1 then
			self.updateChoiceDisplay();
		elseif #tChoice == 1 then
			self.addChoice(tChoice[1]);
			if tChoice.bMultiple then
				self.processNextChoice();
			end
		else
			self.processNextChoice();
		end
	else
		self.finalizeChoices();
	end
end
function addChoice(s)
	local tChoiceSelection = self.getCurrentChoiceSelection();
	if not StringManager.contains(tChoiceSelection, s) then
		table.insert(tChoiceSelection, s);
	end

	local tChoice = self.getCurrentChoice()
	if tChoice and tChoice.bMultiple then
		self.updateAcceptDisplay();
	else
		self.processNextChoice();
	end
end
function removeChoice(s)
	local tChoice = self.getCurrentChoice()
	if not tChoice or not tChoice.bMultiple then
		return;
	end
	local tChoiceSelection = self.getCurrentChoiceSelection();
	for k,sChoice in ipairs(tChoiceSelection) do
		if s == sChoice then
			table.remove(tChoiceSelection, k);
			break;
		end
	end
	self.updateAcceptDisplay();
end
function processAccept()
	local tChoice = self.getCurrentChoice();
	if not tChoice or not tChoice.bMultiple then
		return;
	end
	local tChoiceSelection = self.getCurrentChoiceSelection();
	if #tChoiceSelection > 0 then
		self.processNextChoice();
	end
end
function processCancel()
	self.closeContent();
end
