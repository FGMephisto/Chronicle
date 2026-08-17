--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

-- Adjusted - ToDo: Change to show injuries and wounds on Token
function onInit()
	TokenManager.addDefaultHealthFeatures(nil, { "hptotal", "injuires", "wounds", "trauma" });
	TokenManager.addDefaultEffectFeatures();
end