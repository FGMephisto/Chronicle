-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

-- Adjusted
function collapse()
	-- proficienciestitle.collapse();
	-- featstitle.collapse();
	-- featurestitle.collapse();
	-- traitstitle.collapse();
	languagestitle.collapse();
	feats_benefits_title.collapse();
	feats_drawbacks_title.collapse();
end

-- Adjusted
function expand()
	-- proficienciestitle.expand();
	-- featstitle.expand();
	-- featurestitle.expand();
	-- traitstitle.expand();
	languagestitle.expand();
	feats_benefits_title.expand();
	feats_drawbacks_title.expand();
end

function onDrop(x, y, draginfo)
	if draginfo.isType("shortcut") then
		local sClass, sRecord = draginfo.getShortcutData();
		return CharBuildDropManager.addInfoDB(getDatabaseNode(), sClass, sRecord);
	end
end