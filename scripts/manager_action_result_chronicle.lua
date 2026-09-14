-- 
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function capDice(rRoll)
	rRoll.nTest = tonumber(rRoll.nTest) or 0;
	rRoll.nBonus = tonumber(rRoll.nBonus) or 0;
	rRoll.nPenalty = tonumber(rRoll.nPenalty) or 0;

	-- Set minimum number of Test Die
	if rRoll.nTest < 0 then
		rRoll.nTest = 0;
	end

	-- Determine # of dice added by user with drag-and-right-click
	local nTotalDice = #(rRoll.aDice or {});

	-- Add # of dice added by user with drag-and-right-click to bonus die
	if nTotalDice > (rRoll.nTest + rRoll.nBonus) then
		rRoll.nBonus = nTotalDice - rRoll.nTest;
	end

	-- Cap maximum number of Bonus Die
	if rRoll.nBonus > rRoll.nTest then
		rRoll.nBonus = rRoll.nTest;
	end

	-- Cap maximum number of Penalty Die
	if rRoll.nPenalty > rRoll.nTest then
		rRoll.nPenalty = rRoll.nTest;
	end

	-- Reset nMod if no Test dice are left for roll
	if rRoll.nPenalty >= rRoll.nTest then
		rRoll.nMod = 0;
	end

	-- Rebuild aDice with Test and Bonus dice
	rRoll.aDice = {};
	for i = 1, rRoll.nTest + rRoll.nBonus do
		table.insert(rRoll.aDice, { type = "d6" });
	end

	return rRoll;
end

function DropDice(rRoll)
	rRoll.nBonus = tonumber(rRoll.nBonus) or 0;
	rRoll.nPenalty = tonumber(rRoll.nPenalty) or 0;
	local nDiceDrop = rRoll.nBonus + rRoll.nPenalty;
	local nDiceProcessed = 0;

	-- Drop dice and process rRoll if Bonus or Penalty Dice have been part of the roll
	if nDiceDrop > 0 then
		for i = 1, 6, 1 do
			for _, v in ipairs(rRoll.aDice or {}) do
				if v.result == i and nDiceProcessed < nDiceDrop then
					v.backcolor = "80808080";
					v.iconcolor = "80FFFFFF";
					v.icon = "d6gicon";
					v.dropped = true;
					nDiceProcessed = nDiceProcessed + 1;

					-- Mark dice dropped in excess of all Bonus die as Penalty die
					if nDiceProcessed > rRoll.nBonus then
						v.icon = "d6ricon";
					end
				end
				if nDiceProcessed == nDiceDrop then
					break;
				end
			end
			if nDiceProcessed == nDiceDrop then
				break;
			end
		end
	end

	-- Determine and set roll total
	rRoll.nTotal = ActionsManager.total(rRoll);
	rRoll.aDice.Total = tostring(rRoll.nTotal);

	return rRoll;
end

function DetermineSuccessTest(rMessage, rRoll)
	local nTarget = tonumber(rRoll.nTarget) or 0;
	local nTotal = ActionsManager.total(rRoll);

	rMessage.text = rMessage.text .. " (vs. " .. Interface.getString("dc_long") .. " " .. nTarget .. ")";

	if nTotal >= nTarget then
		if nTotal >= nTarget + 15 then
			rMessage.text = rMessage.text .. " [" .. Interface.getString("success_test_degree_4") .. "]";
			rRoll.nDoS = 4;
			rRoll.nDoF = 0;
		elseif nTotal >= nTarget + 10 then
			rMessage.text = rMessage.text .. " [" .. Interface.getString("success_test_degree_3") .. "]";
			rRoll.nDoS = 3;
			rRoll.nDoF = 0;
		elseif nTotal >= nTarget + 5 then
			rMessage.text = rMessage.text .. " [" .. Interface.getString("success_test_degree_2") .. "]";
			rRoll.nDoS = 2;
			rRoll.nDoF = 0;
		else
			rMessage.text = rMessage.text .. " [" .. Interface.getString("success_test_degree_1") .. "]";
			rRoll.nDoS = 1;
			rRoll.nDoF = 0;
		end
	else
		if nTotal < nTarget - 4 then
			rMessage.text = rMessage.text .. " [" .. Interface.getString("failure_test_2") .. "]";
			rRoll.nDoS = 0;
			rRoll.nDoF = 2;
		else
			rMessage.text = rMessage.text .. " [" .. Interface.getString("failure_test_1") .. "]";
			rRoll.nDoS = 0;
			rRoll.nDoF = 1;
		end
	end

	return rMessage, rRoll;
end

function DetermineSuccessAttack(rMessage, rRoll)
	local nTarget = tonumber(rRoll.nDefenseVal) or 0;
	local nTotal = ActionsManager.total(rRoll);

	rMessage.text = rMessage.text .. " (vs. " .. Interface.getString("dc_long") .. " " .. nTarget .. ")";
	if not rRoll.aMessages then
		rRoll.aMessages = {};
	end

	if nTotal >= nTarget then
		if nTotal >= nTarget + 15 then
			table.insert(rRoll.aMessages, "[" .. Interface.getString("success_attack_degree_4") .. "]");
			rRoll.sResult = "hit";
			rRoll.nDoS = 4;
			rRoll.nDoF = 0;
		elseif nTotal >= nTarget + 10 then
			table.insert(rRoll.aMessages, "[" .. Interface.getString("success_attack_degree_3") .. "]");
			rRoll.sResult = "hit";
			rRoll.nDoS = 3;
			rRoll.nDoF = 0;
		elseif nTotal >= nTarget + 5 then
			table.insert(rRoll.aMessages, "[" .. Interface.getString("success_attack_degree_2") .. "]");
			rRoll.sResult = "hit";
			rRoll.nDoS = 2;
			rRoll.nDoF = 0;
		else
			table.insert(rRoll.aMessages, "[" .. Interface.getString("success_attack_degree_1") .. "]");
			rRoll.sResult = "hit";
			rRoll.nDoS = 1;
			rRoll.nDoF = 0;
		end
	else
		if nTotal < nTarget - 4 then
			table.insert(rRoll.aMessages, "[" .. Interface.getString("failure_attack_degree_2") .. "]");
			rRoll.sResult = "miss";
			rRoll.nDoS = 0;
			rRoll.nDoF = 2;
		else
			table.insert(rRoll.aMessages, "[" .. Interface.getString("failure_attack_degree_1") .. "]");
			rRoll.sResult = "miss";
			rRoll.nDoS = 0;
			rRoll.nDoF = 1;
		end
	end

	return rMessage, rRoll;
end