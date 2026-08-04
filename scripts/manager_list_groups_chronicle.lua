--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

-- ListManagerGroups
-- Centralizes the group-to-groupid resolution and sort-key generation
-- that is shared by skill, injury, stat, and other grouped lists.

--- Resolve a window's "group" control value to the matching "groupid"
--- using the supplied lookup table.  The group value is always simplified
--- before lookup, and falls back to the "generic" key when empty or not found.
--- @param w          Window  – the list-item or header window (self)
--- @param tLookup    table   – e.g. DataCommon.skillgroups  (must contain a "generic" entry)
function updateGroupID(w, tLookup, sDefaultGroup) -- adjusted
	local sGroup = w.group.getValue();
	local sFallback = sDefaultGroup or "generic";

	if (sGroup or "") == "" then
		sGroup = sFallback;
	else
		sGroup = StringManager.simplify(sGroup);
	end

	local aGroup = tLookup[sGroup] or tLookup[sFallback];
	if aGroup then
		w.groupid.setValue(aGroup.groupid);
		if w.icon and aGroup.icon then
			w.icon.setIcon(aGroup.icon);
			w.icon.setVisible(true);
		end
	end
end

--- Build and set the sort key on a window.
--- Format: "<groupid>_<prefix>_<simplified-field1><simplified-field2>"
--- where prefix is "1" for headers (sort first) and "2" for items.
--- @param w          Window  – the list-item or header window (self)
--- @param bIsHeader  boolean – true → prefix "1", false → prefix "2"
--- @param sField1    string  – control name for the primary sort field (e.g. "name")
--- @param sField2    string|nil – optional control name for a secondary sort field (e.g. "name_focus")
function updateSortKey(w, bIsHeader, sField1, sField2) -- added
	local sGroupID = w.groupid.getValue();
	local sPrefix  = bIsHeader and "1" or "2";

	local sSortKey = sGroupID .. "_" .. sPrefix .. "_";

	local ctrl1 = w[sField1] or (w.header and w.header.subwindow and w.header.subwindow[sField1]);
	if sField1 and ctrl1 then
		sSortKey = sSortKey .. StringManager.simplify(ctrl1.getValue());
	end
	local ctrl2 = sField2 and (w[sField2] or (w.header and w.header.subwindow and w.header.subwindow[sField2]));
	if sField2 and ctrl2 then
		sSortKey = sSortKey .. StringManager.simplify(ctrl2.getValue());
	end

	if w.sortkey then
		w.sortkey.setValue(sSortKey);
	end
end

--- Convenience wrapper: resolves the group id and then rebuilds the sort key.
--- @param w          Window  – the list-item or header window (self)
--- @param tLookup    table   – group lookup table (must contain a "generic" entry)
--- @param bIsHeader  boolean – true → prefix "1", false → prefix "2"
--- @param sField1    string  – control name for the primary sort field
--- @param sField2    string|nil – optional control name for a secondary sort field
function onDataChanged(w, tLookup, bIsHeader, sField1, sField2, sDefaultGroup) -- adjusted
	updateGroupID(w, tLookup, sDefaultGroup);
	updateSortKey(w, bIsHeader, sField1, sField2);
end
