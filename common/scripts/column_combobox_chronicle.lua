-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
-- File adjusted for Chronicle System.
--

-- ===================================================================================================================
-- ===================================================================================================================
function onInit()
	if super and super.onInit then
		super.onInit();
	end

	if isReadOnly() then
		self.update(true);
	else
		local node = getDatabaseNode();
		if not node or node.isReadOnly() then
			self.update(true);
		end
	end
end

-- ===================================================================================================================
-- ===================================================================================================================
function update(bReadOnly, bForceHide)
	local bLocalShow;

	if bForceHide then
		bLocalShow = false;
	else
		bLocalShow = true;
		if bReadOnly and not nohide and isEmpty() then
			bLocalShow = false;
		end
	end

	-- Calling functions from CoreRPG combobox.lua to adjust the combobox
	setComboBoxReadOnly(bReadOnly)
	setComboBoxVisible(bLocalShow)

	-- Hide label controls sharing the same name as the combobox
	local sLabel = getName() .. "_label";
	if window[sLabel] then
		window[sLabel].setVisible(bLocalShow);
	end

	if separator then
		if window[separator[1]] then
			window[separator[1]].setVisible(bLocalShow);
		end
	end

	-- Update associated components
	if self.onVisUpdate then
		self.onVisUpdate(bLocalShow, bReadOnly);
	end

	return bLocalShow;
end

-- ===================================================================================================================
-- ===================================================================================================================
function onVisUpdate(bLocalShow, bReadOnly)
	local sButtonName = getName() .. "_cbbutton";

	-- Hide frame and drop-down button if parent is "invisible" or "read only"
	if bLocalShow == false or bReadOnly then
		setFrame(nil);
		-- Hide combobox dropdown button
		if window[sButtonName] then
			window[sButtonName].setVisible(false);
		end
	else
		setFrame("fielddark", 7,5,7,5);
		-- Show combobox dropdown button
		if window[sButtonName] then
			window[sButtonName].setVisible(true);
		end
	end
end

-- ===================================================================================================================
-- ===================================================================================================================
function onValueChanged()
	update()
	if isVisible() then
		if window.VisDataCleared then
			if isEmpty() then
				window.VisDataCleared();
			end
		end
	else
		if window.InvisDataAdded then
			if not isEmpty() then
				window.InvisDataAdded();
			end
		end
	end
end