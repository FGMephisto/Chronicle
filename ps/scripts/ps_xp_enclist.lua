-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function deleteAll()
	DB.deleteChildren(getDatabaseNode());
end
