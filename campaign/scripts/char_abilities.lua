--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function collapse()
	proficienciestitle.collapse();
	featstitle.collapse();
	featurestitle.collapse();
	traitstitle.collapse();
	languagestitle.collapse();
end

function expand()
	proficienciestitle.expand();
	featstitle.expand();
	featurestitle.expand();
	traitstitle.expand();
	languagestitle.expand();
end

function onDrop(_, _, draginfo)
	if draginfo.isType("shortcut") then
		local sClass, sRecord = draginfo.getShortcutData();
		return CharBuildDropManager.addInfoDB(getDatabaseNode(), sClass, sRecord);
	end
end
