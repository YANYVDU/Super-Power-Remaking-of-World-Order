-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function BuildTradeRouteGoldToolTipString (pOriginCity, pTargetCity, eDomain)

	local iPlayer = pOriginCity:GetOwner();
	local pPlayer = Players[iPlayer];
	local iOtherPlayer = pTargetCity:GetOwner();
	local pOtherPlayer = Players[iOtherPlayer];
	local strOtherLeaderName;
	if(pOtherPlayer:GetNickName() ~= "" and Game:IsNetworkMultiPlayer()) then
		strOtherLeaderName = pOtherPlayer:GetNickName();
	else
		strOtherLeaderName = pOtherPlayer:GetName();
	end

	local strResult = "";
	-- Fixed-value components (x100) plus their sum, mirroring GetTradeConnectionValueTimes100 gold branch
	local iBaseTotal, iBase, iGPTOrigin, iGPTDest, iResource, iExclusive, iPolicy, iCityState, iYourBuilding, iTheirBuilding, iTrait, iOtherTrait
		= pPlayer:GetInternationalTradeRouteBaseValueDetail(pOriginCity, pTargetCity, eDomain, true);

	-- Percentage modifiers (percentage points)
	local iDomainMod = pPlayer:GetInternationalTradeRouteDomainModifier(eDomain);
	local iRiverMod = pPlayer:GetInternationalTradeRouteRiverModifier(pOriginCity, pTargetCity, eDomain, true);
	local iCSUAMod = pPlayer:GetCSUATradeRouteGoldModifier(pOriginCity, pTargetCity, eDomain) or 0;
	local iTotalX100 = pPlayer:GetInternationalTradeRouteTotal(pOriginCity, pTargetCity, eDomain, true);

	-- strDomainModifier kept for reuse in the tradee (their) revenue section
	local strDomainModifier = "";
	if (iDomainMod ~= 0) then
		if (eDomain == DomainTypes.DOMAIN_SEA) then
			strDomainModifier = Locale.ConvertTextKey("TXT_KEY_CHOOSE_INTERNATIONAL_TRADE_ROUTE_ITEM_DOMAIN_SEA_MODIFIER", (iDomainMod + 100) / 100);
		end
	end
	
	local strOtherTotal = "";
	local iTradeeAmount = pOtherPlayer:GetInternationalTradeRouteTotal(pOriginCity, pTargetCity, eDomain, false);
	if (iTradeeAmount ~= 0) then
		local strOtherRevenueHeader;
		if (iPlayer == Game.GetActivePlayer()) then
			strOtherRevenueHeader = Locale.ConvertTextKey("TXT_KEY_CHOOSE_INTERNATIONAL_TRADE_ROUTE_ITEM_TT_THEIR_REVENUE");
		else
			strOtherRevenueHeader = Locale.ConvertTextKey("TXT_KEY_CHOOSE_INTERNATIONAL_TRADE_ROUTE_ITEM_TT_YOUR_REVENUE");
		end
		 
		strOtherTotal = strOtherTotal .. strOtherRevenueHeader;
		strOtherTotal = strOtherTotal .. "[NEWLINE]";
		
		local iOtherBase = pOtherPlayer:GetInternationalTradeRouteBaseBonus(pOriginCity, pTargetCity, false);
		if (iOtherBase ~= 0) then
			strOtherTotal = strOtherTotal .. Locale.ConvertTextKey("TXT_KEY_CHOOSE_INTERNATIONAL_TRADE_ROUTE_ITEM_TT_BASE", iOtherBase / 100);
			strOtherTotal = strOtherTotal .. "[NEWLINE]";
		end
		
		local iRiverModifier = pPlayer:GetInternationalTradeRouteRiverModifier(pOriginCity, pTargetCity, eDomain, false);
		if (iRiverModifier ~= 0) then
			strOtherTotal = strOtherTotal .. Locale.ConvertTextKey("TXT_KEY_CHOOSE_INTERNATIONAL_TRADE_ROUTE_ITEM_TT_RIVER_MODIFIER", iRiverModifier);
			strOtherTotal = strOtherTotal .. "[NEWLINE]";
		end
		
		if (strDomainModifier ~= "") then
			strOtherTotal = strOtherTotal .. strDomainModifier;
			strOtherTotal = strOtherTotal .. "[NEWLINE]";
		end
		
		local iOtherBuildingBonus = pOtherPlayer:GetInternationalTradeRouteTheirBuildingBonus(pOriginCity, pTargetCity, eDomain, false);
		if (iOtherBuildingBonus ~= 0) then
			strOtherTotal = strOtherTotal .. Locale.ConvertTextKey("TXT_KEY_CHOOSE_INTERNATIONAL_TRADE_ROUTE_ITEM_TT_BUILDING", pTargetCity:GetNameKey(), iOtherBuildingBonus / 100);
			strOtherTotal = strOtherTotal .. "[NEWLINE]";
		end
		
		strOtherTotal = strOtherTotal .. Locale.ConvertTextKey("TXT_KEY_CHOOSE_INTERNATIONAL_TRADE_ROUTE_ITEM_TT_TRADEE_TOTAL", strOtherLeaderName, iTradeeAmount / 100);
	end
	
	if (iPlayer ~= Game.GetActivePlayer()) then
		strResult = Locale.ConvertTextKey("TXT_KEY_CHOOSE_INTERNATIONAL_TRADE_ROUTE_ITEM_TT_THEIR_REVENUE");
	else
		strResult = Locale.ConvertTextKey("TXT_KEY_CHOOSE_INTERNATIONAL_TRADE_ROUTE_ITEM_TT_YOUR_REVENUE");
	end
	strResult = strResult .. "[NEWLINE]";

	-- Total at the very top
	strResult = strResult .. Locale.ConvertTextKey("TXT_KEY_CHOOSE_INTERNATIONAL_TRADE_ROUTE_ITEM_TT_FINAL_TOTAL", iTotalX100 / 100);
	strResult = strResult .. "[NEWLINE]";
	strResult = strResult .. "[NEWLINE]";

	-- Base value block: sum on top, then each non-zero fixed component
	strResult = strResult .. Locale.ConvertTextKey("TXT_KEY_CHOOSE_INTERNATIONAL_TRADE_ROUTE_ITEM_TT_BASE_VALUE", iBaseTotal / 100);
	strResult = strResult .. "[NEWLINE]";
	local aBaseDetails = {
		{ value = iBase,          tag = "TXT_KEY_CHOOSE_INTERNATIONAL_TRADE_ROUTE_ITEM_TT_BASE_DETAIL_BASE" },
		{ value = iGPTOrigin,     tag = "TXT_KEY_CHOOSE_INTERNATIONAL_TRADE_ROUTE_ITEM_TT_BASE_DETAIL_GPT_ORIGIN" },
		{ value = iGPTDest,       tag = "TXT_KEY_CHOOSE_INTERNATIONAL_TRADE_ROUTE_ITEM_TT_BASE_DETAIL_GPT_DEST" },
		{ value = iResource,      tag = "TXT_KEY_CHOOSE_INTERNATIONAL_TRADE_ROUTE_ITEM_TT_BASE_DETAIL_RESOURCE" },
		{ value = iExclusive,     tag = "TXT_KEY_CHOOSE_INTERNATIONAL_TRADE_ROUTE_ITEM_TT_BASE_DETAIL_EXCLUSIVE" },
		{ value = iPolicy,        tag = "TXT_KEY_CHOOSE_INTERNATIONAL_TRADE_ROUTE_ITEM_TT_BASE_DETAIL_POLICY" },
		{ value = iCityState,     tag = "TXT_KEY_CHOOSE_INTERNATIONAL_TRADE_ROUTE_ITEM_TT_BASE_DETAIL_CITY_STATE" },
		{ value = iYourBuilding,  tag = "TXT_KEY_CHOOSE_INTERNATIONAL_TRADE_ROUTE_ITEM_TT_BASE_DETAIL_YOUR_BUILDING" },
		{ value = iTheirBuilding, tag = "TXT_KEY_CHOOSE_INTERNATIONAL_TRADE_ROUTE_ITEM_TT_BASE_DETAIL_THEIR_BUILDING" },
		{ value = iTrait,         tag = "TXT_KEY_CHOOSE_INTERNATIONAL_TRADE_ROUTE_ITEM_TT_BASE_DETAIL_TRAIT" },
		{ value = iOtherTrait,    tag = "TXT_KEY_CHOOSE_INTERNATIONAL_TRADE_ROUTE_ITEM_TT_BASE_DETAIL_OTHER_TRAIT" },
	};
	for _, kDetail in ipairs(aBaseDetails) do
		if (kDetail.value ~= 0) then
			strResult = strResult .. "  · " .. Locale.ConvertTextKey(kDetail.tag, kDetail.value / 100);
			strResult = strResult .. "[NEWLINE]";
		end
	end
	strResult = strResult .. "[NEWLINE]";

	-- Percentage block: sum on top, then each non-zero source
	local iPctSum = iDomainMod + iRiverMod + iCSUAMod;
	strResult = strResult .. Locale.ConvertTextKey("TXT_KEY_CHOOSE_INTERNATIONAL_TRADE_ROUTE_ITEM_TT_PERCENT_SUM", iPctSum);
	strResult = strResult .. "[NEWLINE]";
	if (iDomainMod ~= 0) then
		if (eDomain == DomainTypes.DOMAIN_SEA) then
			strResult = strResult .. "  · " .. Locale.ConvertTextKey("TXT_KEY_CHOOSE_INTERNATIONAL_TRADE_ROUTE_ITEM_TT_DOMAIN_SEA_MODIFIER", iDomainMod);
		else
			strResult = strResult .. "  · " .. Locale.ConvertTextKey("TXT_KEY_CHOOSE_INTERNATIONAL_TRADE_ROUTE_ITEM_TT_DOMAIN_LAND_MODIFIER", iDomainMod);
		end
		strResult = strResult .. "[NEWLINE]";
	end
	if (iRiverMod ~= 0) then
		strResult = strResult .. "  · " .. Locale.ConvertTextKey("TXT_KEY_CHOOSE_INTERNATIONAL_TRADE_ROUTE_ITEM_TT_RIVER_MODIFIER", iRiverMod);
		strResult = strResult .. "[NEWLINE]";
	end
	if (iCSUAMod ~= 0) then
		strResult = strResult .. "  · " .. Locale.ConvertTextKey("TXT_KEY_CHOOSE_INTERNATIONAL_TRADE_ROUTE_ITEM_TT_CS_UA", iCSUAMod);
		strResult = strResult .. "[NEWLINE]";
	end
	strResult = strResult .. "[NEWLINE]";

	-- Extra earnings closing the math: total = base x (100+pct)/100 (clamped to 100) + extra
	local iAfterModX100 = math.max(100, math.floor(iBaseTotal * (100 + iPctSum) / 100));
	local iExtraX100 = iTotalX100 - iAfterModX100;
	if (iExtraX100 ~= 0) then
		strResult = strResult .. Locale.ConvertTextKey("TXT_KEY_CHOOSE_INTERNATIONAL_TRADE_ROUTE_ITEM_TT_EXTRA", iExtraX100 / 100);
		strResult = strResult .. "[NEWLINE]";
	end

	-- Belief: Trade Route bonuses for all yields (concatenated per belief type)
	local beliefYields = {YieldTypes.YIELD_FOOD, YieldTypes.YIELD_PRODUCTION, YieldTypes.YIELD_GOLD, YieldTypes.YIELD_SCIENCE, YieldTypes.YIELD_CULTURE, YieldTypes.YIELD_FAITH, YieldTypes.YIELD_TOURISM, YieldTypes.YIELD_GOLDEN_AGE_POINTS};
	local iconMap = {[YieldTypes.YIELD_FOOD] = "[ICON_FOOD]", [YieldTypes.YIELD_PRODUCTION] = "[ICON_PRODUCTION]", [YieldTypes.YIELD_GOLD] = "[ICON_GOLD]", [YieldTypes.YIELD_SCIENCE] = "[ICON_RESEARCH]", [YieldTypes.YIELD_CULTURE] = "[ICON_CULTURE]", [YieldTypes.YIELD_FAITH] = "[ICON_PEACE]", [YieldTypes.YIELD_TOURISM] = "[ICON_TOURISM]", [YieldTypes.YIELD_GOLDEN_AGE_POINTS] = "[ICON_GOLDEN_AGE]"};

	-- Holy City origin bonus
	local holyCityStr = "";
	for _, y in ipairs(beliefYields) do
		local v = pOriginCity:GetReligionTradeRouteHolyCityYield(pTargetCity, y);
		if (v ~= 0) then
			holyCityStr = holyCityStr .. " +" .. v .. iconMap[y];
		end
	end
	if (holyCityStr ~= "") then
		strResult = strResult .. "[NEWLINE]";
		strResult = strResult .. Locale.ConvertTextKey("TXT_KEY_CHOOSE_INTERNATIONAL_TRADE_ROUTE_ITEM_TT_BELIEF_HOLY_CITY", holyCityStr);
	end

	-- Same Religion modifier
	local sameReligionStr = "";
	for _, y in ipairs(beliefYields) do
		local v = pOriginCity:GetReligionTradeRouteSameReligionModifier(pTargetCity, y);
		if (v ~= 0) then
			sameReligionStr = sameReligionStr .. " +" .. v .. "%" .. iconMap[y];
		end
	end
	if (sameReligionStr ~= "") then
		strResult = strResult .. "[NEWLINE]";
		strResult = strResult .. Locale.ConvertTextKey("TXT_KEY_CHOOSE_INTERNATIONAL_TRADE_ROUTE_ITEM_TT_BELIEF_SAME_RELIGION", sameReligionStr);
	end

	strResult = strResult .. "[NEWLINE]";

	if (strOtherTotal ~= "") then
		strResult = strResult .. "[NEWLINE]";
		strResult = strResult .. strOtherTotal;
	end

	-- Holy City dest bonus (shown in their revenue section)
	local holyCityDestStr = "";
	for _, y in ipairs(beliefYields) do
		local v = pOriginCity:GetReligionTradeRouteHolyCityDestYield(pTargetCity, y);
		if (v ~= 0) then
			holyCityDestStr = holyCityDestStr .. " +" .. v .. iconMap[y];
		end
	end
	if (holyCityDestStr ~= "") then
		strResult = strResult .. "[NEWLINE]";
		strResult = strResult .. Locale.ConvertTextKey("TXT_KEY_CHOOSE_INTERNATIONAL_TRADE_ROUTE_ITEM_TT_BELIEF_HOLY_CITY_DEST", holyCityDestStr);
	end
	return strResult;
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function BuildTradeRouteScienceToolTipString (pOriginCity, pTargetCity, eDomain)

	local strResult = "";
	local iPlayer = pOriginCity:GetOwner();
	local pOriginPlayer = Players[iPlayer];
	local iOtherPlayer = pTargetCity:GetOwner();
	local pOtherPlayer = Players[iOtherPlayer];
	
	local strOriginLeaderName;
	if(pOriginPlayer:GetNickName() ~= "" and Game:IsNetworkMultiPlayer()) then
		strOriginLeaderName = pOriginPlayer:GetNickName();
	else
		strOriginLeaderName = pOriginPlayer:GetName();
	end
	
	local strOtherLeaderName;
	if(pOtherPlayer:GetNickName() ~= "" and Game:IsNetworkMultiPlayer()) then
		strOtherLeaderName = pOtherPlayer:GetNickName();
	else
		strOtherLeaderName = pOtherPlayer:GetName();
	end

	local iOriginScience  = pOriginPlayer:GetInternationalTradeRouteScience(pOriginCity, pTargetCity, eDomain, true) / 100;
	local iDestScience = pOtherPlayer:GetInternationalTradeRouteScience(pOriginCity, pTargetCity, eDomain, false) / 100;

	if (iOriginScience > 0) then
		local iNumTechs = pOriginPlayer:GetNumTechDifference(iOtherPlayer);
		local iInfluenceScience = pOriginPlayer:GetInfluenceTradeRouteScienceBonus(iOtherPlayer);
		if (iPlayer == Game.GetActivePlayer()) then	
			strResult = strResult .. Locale.ConvertTextKey("TXT_KEY_CHOOSE_INTERNATIONAL_TRADE_ROUTE_ITEM_TT_YOUR_SCIENCE_GAIN");
			strResult = strResult .. "[NEWLINE]";
			strResult = strResult .. Locale.ConvertTextKey("TXT_KEY_CHOOSE_INTERNATIONAL_TRADE_ROUTE_ITEM_TT_YOUR_SCIENCE_EXPLAINED", strOtherLeaderName, iNumTechs, iInfluenceScience);
			strResult = strResult .. "[NEWLINE]";
			strResult = strResult .. Locale.ConvertTextKey("TXT_KEY_CHOOSE_INTERNATIONAL_TRADE_ROUTE_ITEM_TT_YOUR_SCIENCE_TOTAL", iOriginScience);
		else
			strResult = strResult .. Locale.ConvertTextKey("TXT_KEY_CHOOSE_INTERNATIONAL_TRADE_ROUTE_ITEM_TT_THEIR_SCIENCE_GAIN");
			strResult = strResult .. "[NEWLINE]";
			strResult = strResult .. Locale.ConvertTextKey("TXT_KEY_CHOOSE_INTERNATIONAL_TRADE_ROUTE_ITEM_TT_THEIR_SCIENCE_EXPLAINED", iNumTechs, strOriginLeaderName, iInfluenceScience);
			strResult = strResult .. "[NEWLINE]";
			strResult = strResult .. Locale.ConvertTextKey("TXT_KEY_CHOOSE_INTERNATIONAL_TRADE_ROUTE_ITEM_TT_THEIR_SCIENCE_TOTAL", strOriginLeaderName, iOriginScience);				
		end
	end
	
	if (iDestScience > 0) then
		if (strResult ~= "") then
			strResult = strResult .. "[NEWLINE][NEWLINE]";
		end
	
		local iNumTechs = pOtherPlayer:GetNumTechDifference(iPlayer);
		local iInfluenceScience = pOtherPlayer:GetInfluenceTradeRouteScienceBonus(iPlayer);
		if (iPlayer == Game.GetActivePlayer()) then
			strResult = strResult .. Locale.ConvertTextKey("TXT_KEY_CHOOSE_INTERNATIONAL_TRADE_ROUTE_ITEM_TT_THEIR_SCIENCE_GAIN");
			strResult = strResult .. "[NEWLINE]";
			strResult = strResult .. Locale.ConvertTextKey("TXT_KEY_CHOOSE_INTERNATIONAL_TRADE_ROUTE_ITEM_TT_THEIR_SCIENCE_EXPLAINED", iNumTechs, strOtherLeaderName, iInfluenceScience);
			strResult = strResult .. "[NEWLINE]";
			strResult = strResult .. Locale.ConvertTextKey("TXT_KEY_CHOOSE_INTERNATIONAL_TRADE_ROUTE_ITEM_TT_THEIR_SCIENCE_TOTAL", strOtherLeaderName, iDestScience);		
		else
			strResult = strResult .. Locale.ConvertTextKey("TXT_KEY_CHOOSE_INTERNATIONAL_TRADE_ROUTE_ITEM_TT_YOUR_SCIENCE_GAIN");
			strResult = strResult .. "[NEWLINE]";
			strResult = strResult .. Locale.ConvertTextKey("TXT_KEY_CHOOSE_INTERNATIONAL_TRADE_ROUTE_ITEM_TT_YOUR_SCIENCE_EXPLAINED", strOriginLeaderName, iNumTechs, iInfluenceScience);
			strResult = strResult .. "[NEWLINE]";
			strResult = strResult .. Locale.ConvertTextKey("TXT_KEY_CHOOSE_INTERNATIONAL_TRADE_ROUTE_ITEM_TT_YOUR_SCIENCE_TOTAL", iDestScience);		
		end

	end


	-- Belief: Trade Route to Holy City origin bonus (concatenated)
	local beliefYields = {YieldTypes.YIELD_FOOD, YieldTypes.YIELD_PRODUCTION, YieldTypes.YIELD_GOLD, YieldTypes.YIELD_SCIENCE, YieldTypes.YIELD_CULTURE, YieldTypes.YIELD_FAITH, YieldTypes.YIELD_TOURISM, YieldTypes.YIELD_GOLDEN_AGE_POINTS};
	local iconMap = {[YieldTypes.YIELD_FOOD] = "[ICON_FOOD]", [YieldTypes.YIELD_PRODUCTION] = "[ICON_PRODUCTION]", [YieldTypes.YIELD_GOLD] = "[ICON_GOLD]", [YieldTypes.YIELD_SCIENCE] = "[ICON_RESEARCH]", [YieldTypes.YIELD_CULTURE] = "[ICON_CULTURE]", [YieldTypes.YIELD_FAITH] = "[ICON_PEACE]", [YieldTypes.YIELD_TOURISM] = "[ICON_TOURISM]", [YieldTypes.YIELD_GOLDEN_AGE_POINTS] = "[ICON_GOLDEN_AGE]"};

	local holyCityStr = "";
	for _, y in ipairs(beliefYields) do
		local v = pOriginCity:GetReligionTradeRouteHolyCityYield(pTargetCity, y);
		if (v ~= 0) then
			holyCityStr = holyCityStr .. " +" .. v .. iconMap[y];
		end
	end
	if (holyCityStr ~= "") then
		strResult = strResult .. "[NEWLINE]";
		strResult = strResult .. Locale.ConvertTextKey("TXT_KEY_CHOOSE_INTERNATIONAL_TRADE_ROUTE_ITEM_TT_BELIEF_HOLY_CITY", holyCityStr);
	end
	return strResult;
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function BuildTradeRouteToolTipString (pPlayer, pOriginCity, pTargetCity, eDomain)
	local strResult;

	-- shortcut for using gold currently
	if (pPlayer:GetInternationalTradeRouteTotal(pOriginCity, pTargetCity, true, true) > 0) then
		local strGoldToolTip = BuildTradeRouteGoldToolTipString(pOriginCity, pTargetCity, eDomain);
		strResult = strGoldToolTip;
		-- Science tooltip only for international trade routes
		if (pOriginCity:GetOwner() ~= pTargetCity:GetOwner()) then
			local strScienceToolTip = BuildTradeRouteScienceToolTipString(pOriginCity, pTargetCity, eDomain);
			if (strScienceToolTip ~= "") then
				if (strResult ~= "") then
					strResult = strResult .. "[NEWLINE][NEWLINE]";
				end
				strResult = strResult .. strScienceToolTip;
			end
		end
	end
	
	return strResult;
end
