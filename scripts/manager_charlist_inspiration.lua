-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

CHARLIST_WIDGET_POSITION = "topright";
CHARLIST_WIDGET_X = -12;
CHARLIST_WIDGET_Y = 12;
CHARLIST_WIDGET_W = 24;
CHARLIST_WIDGET_H = 24;

function onInit()
	DB.addHandler("charsheet.*.inspiration", "onUpdate", self.onUpdate);
	CharacterListManager.setDecorator("inspiration", self.updateWidgets);
end

function onUpdate(node)
	self.updateWidgets(CharacterListManager.getDisplayControlByPath(DB.getPath(DB.getChild(node, ".."))));
end

function updateWidgets(c)
	if not c then
		return;
	end

	local nodeRecord = c.getRecordNode();
	if not nodeRecord then
		return;
	end

	local n = DB.getValue(nodeRecord, "inspiration", 0);
	self.updateBitmapWidget(c, n);
	self.updateTextWidget(c, n);
end
function updateBitmapWidget(c, n)
	local widget = c.findWidget("inspiration");
	if n <= 0 then
		if widget then 
			widget.destroy();
		end
	else
		if not widget then
			widget = c.addBitmapWidget({ 
				name = "inspiration", 
				icon = "charlist_inspiration", 
				position = CHARLIST_WIDGET_POSITION, x = CHARLIST_WIDGET_X, y = CHARLIST_WIDGET_Y, 
				w = CHARLIST_WIDGET_W, h = CHARLIST_WIDGET_H,
			});
		end
	end
end
function updateTextWidget(c, n)
	local widget = c.findWidget("inspirationtext");
	if n <= 1 then
		if widget then 
			widget.destroy();
		end
	else
		if not widget then
			widget = c.addTextWidget({
				name = "inspirationtext", 
				font = "sheetlabel", text = "", 
				position = CHARLIST_WIDGET_POSITION, x = CHARLIST_WIDGET_X, y = CHARLIST_WIDGET_Y,
			});
		end
		widget.setText(n);
	end
end
