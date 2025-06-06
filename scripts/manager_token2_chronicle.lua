--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

-- Adjusted - ToDo: Change to show injuries and wounds on Token
function onInit()
	-- TokenManager.addDefaultHealthFeatures(nil, {"hptotal", "hptemp", "wounds", "deathsavefail"});
	TokenManager.addDefaultHealthFeatures(nil, {"hptotal", "injuires", "trauma", "wounds"});
	TokenManager.addEffectTagIconConditional("IF", TokenManager2.handleIFEffectTag);
	TokenManager.addEffectTagIconSimple("IFT", "");
	TokenManager.addEffectTagIconBonus(DataCommon.bonuscomps);
	TokenManager.addEffectTagIconSimple(DataCommon.othercomps);
	TokenManager.addEffectConditionIcon(DataCommon.condcomps);
	TokenManager.addDefaultEffectFeatures(nil, EffectManager5E.parseEffectComp);
end

function handleIFEffectTag(rActor, nodeEffect, vComp)
	return EffectManager5E.checkConditional(rActor, nodeEffect, vComp.remainder);
end
