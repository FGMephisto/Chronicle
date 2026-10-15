--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

-- TODO: Temporary polyfill for CoreRPG manager_vision.lua (2026-10-09) calling Token.setDefaultVision / Token.setDefaultVisionRange
-- which are missing from the global Token package in FGU engine v5.1.14. Remove once CoreRPG / FGU engine is fixed upstream.
local function _polyfillTokenVisionAPI()
	if Token then
		if not Token.setDefaultVision then
			Token.setDefaultVision = function(token, bVision)
				if token and token.setDefaultVision then
					token.setDefaultVision(bVision);
				end
			end;
		end
		if not Token.setDefaultVisionRange then
			Token.setDefaultVisionRange = function(token, nRange)
				if token and token.setDefaultVisionRange then
					token.setDefaultVisionRange(nRange);
				end
			end;
		end
	end
end

_polyfillTokenVisionAPI();

-- Adjusted - ToDo: Change to show injuries and wounds on Token
function onInit()
	_polyfillTokenVisionAPI();

	TokenManager.addDefaultHealthFeatures(nil, { "hptotal", "injuires", "wounds", "trauma" });
	TokenManager.addDefaultEffectFeatures();
end
