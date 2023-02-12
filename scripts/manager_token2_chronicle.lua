-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
-- File adjusted for Chronicle System
--

-- ===================================================================================================================
-- ToDo: Change to show injuries and wounds on Token
-- Adjusted
-- ===================================================================================================================
function onInit()
	TokenManager.addDefaultHealthFeatures(getHealthInfo, {"hptotal", "injuires", "trauma", "wounds"});
	
	TokenManager.addEffectTagIconConditional("IF", handleIFEffectTag);
	TokenManager.addEffectTagIconSimple("IFT", "");
	TokenManager.addEffectTagIconBonus(DataCommon.bonuscomps);
	TokenManager.addEffectTagIconSimple(DataCommon.othercomps);
	TokenManager.addEffectConditionIcon(DataCommon.condcomps);
	TokenManager.addDefaultEffectFeatures(nil, EffectManager5E.parseEffectComp);
end

-- ===================================================================================================================
-- ===================================================================================================================
function getHealthInfo(nodeCT)
	local rActor = ActorManager.resolveActor(nodeCT);
	return ActorHealthManager.getTokenHealthInfo(rActor);
end

-- ===================================================================================================================
-- ===================================================================================================================
function handleIFEffectTag(rActor, nodeEffect, vComp)
	return EffectManager5E.checkConditional(rActor, nodeEffect, vComp.remainder);
end
