--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	TokenManager.addDefaultHealthFeatures(nil, { "hptotal", "hptemp", "wounds", "deathsavefail" });
	TokenManager.addDefaultEffectFeatures();
end
