-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

-- Added
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

-- Added
function update(bReadOnly, bForceHide)
	local bLocalShow;
	if bForceHide then
		bLocalShow = false;
	else
		bLocalShow = true;
		if bReadOnly and not nohide and getValue() == 0 then
			bLocalShow = false;
		end
	end

	setReadOnly(bReadOnly);
	setVisible(bLocalShow);

	-- Adjust field if read only
	if bReadOnly then
		setFrame(nil)
	else
		setFrame("fielddark", 7,5,7,5)
	end

	-- Hide Label field if the number field is not shown
	local sLabel = getName() .. "_label";
	if window[sLabel] then
		window[sLabel].setVisible(bLocalShow);
	end
	
	if self.onUpdate then
		self.onUpdate(bLocalShow);
	end
	
	return bLocalShow;
end

-- Added
function onValueChanged()
	if isVisible() then
		if window.VisDataCleared then
			if getValue() == 0 then
				window.VisDataCleared();
			end
		end
	else
		if window.InvisDataAdded then
			if getValue() ~= 0 then
				window.InvisDataAdded();
			end
		end
	end
end