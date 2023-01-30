-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	DB.addHandler("charsheet.*.inspiration", "onUpdate", onUpdate);
	CharacterListManager.addDecorator("inspiration", addInspirationWidget);
end

function onUpdate(nodeInspiration)
	updateWidgets(DB.getName(DB.getChild(nodeInspiration, "..")));
end

function addInspirationWidget(control, sIdentity)
	local widget = control.addBitmapWidget({ icon = "charlist_inspiration", name = "inspiration", x = -25, y = 9 });
	widget.setVisible(false);

	local textwidget = control.addTextWidget({ font = "mini_name", text = "", name = "inspirationtext", x = -25, y = 9 });
	textwidget.setVisible(false);
	
	updateWidgets(sIdentity);
end

function updateWidgets(sIdentity)
	local ctrlChar = CharacterListManager.getEntry(sIdentity);
	if not ctrlChar then
		return;
	end
	local widget = ctrlChar.findWidget("inspiration");
	local textwidget = ctrlChar.findWidget("inspirationtext");
	if not widget or not textwidget then
		return;
	end	
	local nInspiration = DB.getValue("charsheet." .. sIdentity .. ".inspiration", 0);
	if nInspiration <= 0 then
		widget.setVisible(false);
		textwidget.setVisible(false);
	elseif nInspiration == 1 then
		widget.setVisible(true);
		textwidget.setVisible(false);
	else
		widget.setVisible(true);
		textwidget.setVisible(true);
		textwidget.setText(nInspiration);
	end
end
