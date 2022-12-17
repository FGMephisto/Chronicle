local widget = nil;

function onInit()
	if icons and icons[1] then
		setIcon(icons[1]);
	end
end

function setIcon(sIcon)
	if widget then
		widget.destroy();
	end
	
	if sIcon then
		widget = addBitmapWidget({ icon = sIcon, position="topleft", x = 2, y = 8 });
	end
end
