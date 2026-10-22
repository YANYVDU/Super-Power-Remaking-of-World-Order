include( "IconSupport" );
----------------------------------------------------------------
-- Super Power V11: adds a per-row button that opens the complete
-- world ranking (all alive major civilizations) for that category.
----------------------------------------------------------------
----------------------------------------------------------------
local m_PopulationTable = {};
local m_FoodTable = {};
local m_ProductionTable = {};
local m_GoldTable = {};
local m_LandTable = {};
local m_ArmyTable = {};
local m_ApprovalTable = {};
local m_LiteracyTable = {};

local m_bIsEndGame = (ContextPtr:GetID() == "EndGameDemographics");

-- Full ranking overlay state
local m_FullRankTable = nil;
local m_FullRankFormat = "#,###,###,###";
local m_bFullRankVisible = false;


----------------------------------------------------------------
----------------------------------------------------------------
function BuildTables()
    for i = 0, GameDefines.MAX_MAJOR_CIVS do
        m_PopulationTable[ i ] = 0;
        m_FoodTable[ i ] = 0;
        m_ProductionTable[ i ] = 0;
        m_GoldTable[ i ] = 0;
        m_LandTable[ i ] = 0;
        m_ArmyTable[ i ] = 0;
        m_ApprovalTable[ i ] = 0;
        m_LiteracyTable[ i ] = 0;

        m_PopulationTable[ i ] = GetPopulationValue( i );
        m_FoodTable[ i ] = GetFoodValue( i );
        m_ProductionTable[ i ] = GetProductionValue( i );
        m_GoldTable[ i ] = GetGoldValue( i );
        m_LandTable[ i ] = GetLandValue( i );
        m_ArmyTable[ i ] = GetArmyValue( i );
        m_ApprovalTable[ i ] = GetApprovalValue( i );
        m_LiteracyTable[ i ] = GetLiteracyValue( i );
    end
end


----------------------------------------------------------------
----------------------------------------------------------------
function GetBest( table, iPlayer )
    local highest = nil;
    local highestID = iPlayer;
    for i = 0, GameDefines.MAX_MAJOR_CIVS do
		local pPlayer = Players[i];
        if(pPlayer:IsAlive() and not pPlayer:IsMinorCiv()) then
            if( highest == nil or table[i] > highest ) then
                highest = table[i];
                highestID = i;
            end
       end
    end

    return { highest, highestID };
end


----------------------------------------------------------------
----------------------------------------------------------------
function GetAverage( table, iPlayer )
    local accum = 0;
    local count = 0;

    for i = 0, GameDefines.MAX_MAJOR_CIVS do
       	local pPlayer = Players[i];
        if(pPlayer:IsAlive() and not pPlayer:IsMinorCiv()) then
            count = count + 1;
            accum = accum + table[i];
        end
    end

    return accum / count;
end


----------------------------------------------------------------
----------------------------------------------------------------
function GetWorst( table, iPlayer )
    local lowest = nil;
    local lowestID = iPlayer;
    for i = 0, GameDefines.MAX_MAJOR_CIVS do
        local pPlayer = Players[i];
		if(pPlayer:IsAlive() and not pPlayer:IsMinorCiv()) then
            if( lowest == nil or table[i] <= lowest ) then
                lowest = table[i];
                lowestID = i;
            end
       end
    end

    return { lowest, lowestID };
end


----------------------------------------------------------------
----------------------------------------------------------------
function GetRank( table, iPlayer )
    local playerVal = table[iPlayer];
    local rank = 1;

    for i = 0, GameDefines.MAX_MAJOR_CIVS do
        local pPlayer = Players[i];
		if(pPlayer:IsAlive() and not pPlayer:IsMinorCiv()) then
            if( table[i] > playerVal ) then
                rank = rank + 1;
            end
        end
    end

    return rank;
end


----------------------------------------------------------------
-- Full ranking overlay
----------------------------------------------------------------
function GetFullRankPlayerName( iPlayer )
    local pPlayer = Players[iPlayer];
    if (iPlayer == Game.GetActivePlayer()) then
        return Locale.ConvertTextKey(pPlayer:GetCivilizationShortDescriptionKey())
            .. Locale.ConvertTextKey("TXT_KEY_DEMOGRAPHICS_FULL_RANK_YOU");
    elseif (not Teams[pPlayer:GetTeam()]:IsHasMet(Game.GetActiveTeam())) then
        -- Same information policy as the Best/Worst columns: unmet civs stay unknown.
        return Locale.ConvertTextKey("TXT_KEY_MISC_UNKNOWN");
    end
    return Locale.ConvertTextKey(pPlayer:GetCivilizationShortDescriptionKey());
end


----------------------------------------------------------------
----------------------------------------------------------------
function BuildFullRankList()
    Controls.RankStack:DestroyAllChildren();

    local tSorted = {};
    for i = 0, GameDefines.MAX_MAJOR_CIVS do
        local pPlayer = Players[i];
        if (pPlayer ~= nil and pPlayer:IsAlive() and not pPlayer:IsMinorCiv()) then
            tSorted[ #tSorted + 1 ] = { ID = i, Value = m_FullRankTable[i] or 0 };
        end
    end

    table.sort( tSorted, function( a, b )
        if (a.Value ~= b.Value) then
            return a.Value > b.Value;
        end
        return a.ID < b.ID;
    end );

    for _, entry in ipairs( tSorted ) do
        local iPlayer = entry.ID;
        local instance = {};
        ContextPtr:BuildInstanceForControl( "RankEntry", instance, Controls.RankStack );

        instance.Rank:SetText( Locale.ToNumber( GetRank( m_FullRankTable, iPlayer ), "#" ) );
        SetIcon( iPlayer, instance.Icon, instance.IconBG, instance.IconShadow );
        instance.Name:SetText( GetFullRankPlayerName( iPlayer ) );
        instance.Value:SetText( Locale.ToNumber( entry.Value, m_FullRankFormat ) );
    end

    Controls.RankStack:CalculateSize();
    Controls.RankStack:ReprocessAnchoring();
    Controls.RankScrollPanel:CalculateInternalSize();
end


----------------------------------------------------------------
----------------------------------------------------------------
function ShowFullRank( tValues, sNameTag, sValueFormat )
    m_FullRankTable = tValues;
    m_FullRankFormat = sValueFormat;

    Controls.RankTitle:SetText( Locale.ConvertTextKey(sNameTag)
        .. " - " .. Locale.ConvertTextKey("TXT_KEY_DEMOGRAPHICS_FULL_RANK_TITLE") );

    BuildFullRankList();

    Controls.RankDimmer:SetHide( false );
    Controls.RankPanel:SetHide( false );
    m_bFullRankVisible = true;
end


----------------------------------------------------------------
----------------------------------------------------------------
function HideFullRank()
    if (not m_bFullRankVisible) then
        return;
    end
    m_bFullRankVisible = false;
    Controls.RankPanel:SetHide( true );
    Controls.RankDimmer:SetHide( true );
end


----------------------------------------------------------------
----------------------------------------------------------------
function SetupRankButton( instance, tValues, sNameTag, sValueFormat )
    instance.RankButton:SetToolTipString( Locale.ConvertTextKey("TXT_KEY_DEMOGRAPHICS_FULL_RANK_TT") );
    instance.RankButton:RegisterCallback( Mouse.eLClick, function()
        ShowFullRank( tValues, sNameTag, sValueFormat );
    end );
end


----------------------------------------------------------------
----------------------------------------------------------------
function GetPopulationValue( iPlayer )
    return Players[iPlayer]:GetRealPopulation();
end


----------------------------------------------------------------
----------------------------------------------------------------
function BuildPopulationEntry( iPlayer )
    local instance = {};
    ContextPtr:BuildInstanceForControl( "Entry", instance, Controls.MainStack );

    instance.Name:LocalizeAndSetText( "TXT_KEY_DEMOGRAPHICS_POPULATION" );

    instance.Value:SetText( Locale.ToNumber(m_PopulationTable[ iPlayer ], "#,###,###,###" ));
    instance.ValueTT:SetToolTipString( Locale.ConvertTextKey("TXT_KEY_DEMOGRAPHICS_POPULATION_MEASURE") );

    local best = GetBest( m_PopulationTable, iPlayer );
    SetIcon(best[2], instance.BestIcon, instance.BestIconBG, instance.BestIconShadow);
    instance.Best:SetText( Locale.ToNumber(best[1], "#,###,###,###") );
    instance.BestTT:SetToolTipString( Locale.ConvertTextKey("TXT_KEY_DEMOGRAPHICS_POPULATION_MEASURE") );

    instance.Average:SetText( Locale.ToNumber( GetAverage( m_PopulationTable, iPlayer ), "#,###,###,###" ) );
    instance.AverageTT:SetToolTipString( Locale.ConvertTextKey("TXT_KEY_DEMOGRAPHICS_POPULATION_MEASURE") );

    local worst = GetWorst( m_PopulationTable, iPlayer );
    SetIcon(worst[2], instance.WorstIcon, instance.WorstIconBG, instance.WorstIconShadow);
    instance.Worst:LocalizeAndSetText( Locale.ToNumber(worst[1], "#,###,###,###" ) );
    instance.WorstTT:SetToolTipString( Locale.ConvertTextKey("TXT_KEY_DEMOGRAPHICS_POPULATION_MEASURE") );

    instance.Rank:SetText( Locale.ToNumber(GetRank( m_PopulationTable, iPlayer ), "#") );

    SetupRankButton( instance, m_PopulationTable, "TXT_KEY_DEMOGRAPHICS_POPULATION", "#,###,###,###" );
end


----------------------------------------------------------------
----------------------------------------------------------------
function GetFoodValue( iPlayer )
    return Players[iPlayer]:CalculateTotalYield(YieldTypes.YIELD_FOOD);
end


----------------------------------------------------------------
----------------------------------------------------------------
function BuildFoodEntry( iPlayer )
    local instance = {};
    ContextPtr:BuildInstanceForControl( "Entry", instance, Controls.MainStack );

    instance.Name:LocalizeAndSetText( "TXT_KEY_DEMOGRAPHICS_FOOD" );

    instance.Value:SetText( Locale.ToNumber(m_FoodTable[ iPlayer ], "#,###,###,###" ));
    instance.ValueTT:SetToolTipString( Locale.ConvertTextKey("TXT_KEY_DEMOGRAPHICS_FOOD_MEASURE") );

    local best = GetBest( m_FoodTable, iPlayer );
    SetIcon(best[2], instance.BestIcon, instance.BestIconBG, instance.BestIconShadow);
    instance.Best:SetText( Locale.ToNumber(best[1], "#,###,###,###") );
    instance.BestTT:SetToolTipString( Locale.ConvertTextKey("TXT_KEY_DEMOGRAPHICS_FOOD_MEASURE") );

    instance.Average:SetText( Locale.ToNumber( GetAverage( m_FoodTable, iPlayer ), "#,###,###,###" ) );
    instance.AverageTT:SetToolTipString( Locale.ConvertTextKey("TXT_KEY_DEMOGRAPHICS_FOOD_MEASURE") );

    local worst = GetWorst( m_FoodTable, iPlayer );
    SetIcon(worst[2], instance.WorstIcon, instance.WorstIconBG, instance.WorstIconShadow);
    instance.Worst:LocalizeAndSetText( Locale.ToNumber(worst[1], "#,###,###,###" ) );
    instance.WorstTT:SetToolTipString( Locale.ConvertTextKey("TXT_KEY_DEMOGRAPHICS_FOOD_MEASURE") );

    instance.Rank:SetText( Locale.ToNumber(GetRank( m_FoodTable, iPlayer ), "#") );

    SetupRankButton( instance, m_FoodTable, "TXT_KEY_DEMOGRAPHICS_FOOD", "#,###,###,###" );
end


----------------------------------------------------------------
----------------------------------------------------------------
function GetProductionValue( iPlayer )
    return Players[iPlayer]:CalculateTotalYield(YieldTypes.YIELD_PRODUCTION);
end


----------------------------------------------------------------
----------------------------------------------------------------
function BuildProductionEntry( iPlayer )
    local instance = {};
    ContextPtr:BuildInstanceForControl( "Entry", instance, Controls.MainStack );

    instance.Name:LocalizeAndSetText( "TXT_KEY_DEMOGRAPHICS_PRODUCTION" );

    instance.Value:SetText( Locale.ToNumber(m_ProductionTable[ iPlayer ], "#,###,###,###" ));
    instance.ValueTT:SetToolTipString( Locale.ConvertTextKey("TXT_KEY_DEMOGRAPHICS_PRODUCTION_MEASURE") );

    local best = GetBest( m_ProductionTable, iPlayer );
    SetIcon(best[2], instance.BestIcon, instance.BestIconBG, instance.BestIconShadow);
    instance.Best:SetText( Locale.ToNumber(best[1], "#,###,###,###") );
    instance.BestTT:SetToolTipString( Locale.ConvertTextKey("TXT_KEY_DEMOGRAPHICS_PRODUCTION_MEASURE") );

    instance.Average:SetText( Locale.ToNumber( GetAverage( m_ProductionTable, iPlayer ), "#,###,###,###" ) );
    instance.AverageTT:SetToolTipString( Locale.ConvertTextKey("TXT_KEY_DEMOGRAPHICS_PRODUCTION_MEASURE") );

    local worst = GetWorst( m_ProductionTable, iPlayer );
    SetIcon(worst[2], instance.WorstIcon, instance.WorstIconBG, instance.WorstIconShadow);
    instance.Worst:LocalizeAndSetText( Locale.ToNumber(worst[1], "#,###,###,###" ) );
    instance.WorstTT:SetToolTipString( Locale.ConvertTextKey("TXT_KEY_DEMOGRAPHICS_PRODUCTION_MEASURE") );

    instance.Rank:SetText( Locale.ToNumber(GetRank( m_ProductionTable, iPlayer ), "#") );

    SetupRankButton( instance, m_ProductionTable, "TXT_KEY_DEMOGRAPHICS_PRODUCTION", "#,###,###,###" );
end


----------------------------------------------------------------
----------------------------------------------------------------
function GetGoldValue( iPlayer )
    return Players[iPlayer]:CalculateGrossGold();
end


----------------------------------------------------------------
----------------------------------------------------------------
function BuildGoldEntry( iPlayer )
    local instance = {};
    ContextPtr:BuildInstanceForControl( "Entry", instance, Controls.MainStack );

    instance.Name:LocalizeAndSetText( "TXT_KEY_DEMOGRAPHICS_GOLD" );

    instance.Value:SetText( Locale.ToNumber(m_GoldTable[ iPlayer ], "#,###,###,###" ));
    instance.ValueTT:SetToolTipString( Locale.ConvertTextKey("TXT_KEY_DEMOGRAPHICS_GOLD_MEASURE") );

    local best = GetBest( m_GoldTable, iPlayer );
    SetIcon(best[2], instance.BestIcon, instance.BestIconBG, instance.BestIconShadow);
    instance.Best:SetText( Locale.ToNumber(best[1], "#,###,###,###") );
    instance.BestTT:SetToolTipString( Locale.ConvertTextKey("TXT_KEY_DEMOGRAPHICS_GOLD_MEASURE") );

    instance.Average:SetText( Locale.ToNumber( GetAverage( m_GoldTable, iPlayer ), "#,###,###,###" ) );
    instance.AverageTT:SetToolTipString( Locale.ConvertTextKey("TXT_KEY_DEMOGRAPHICS_GOLD_MEASURE") );

    local worst = GetWorst( m_GoldTable, iPlayer );
    SetIcon(worst[2], instance.WorstIcon, instance.WorstIconBG, instance.WorstIconShadow);
    instance.Worst:LocalizeAndSetText( Locale.ToNumber(worst[1], "#,###,###,###" ) );
    instance.WorstTT:SetToolTipString( Locale.ConvertTextKey("TXT_KEY_DEMOGRAPHICS_GOLD_MEASURE") );

    instance.Rank:SetText( Locale.ToNumber(GetRank( m_GoldTable, iPlayer ), "#") );

    SetupRankButton( instance, m_GoldTable, "TXT_KEY_DEMOGRAPHICS_GOLD", "#,###,###,###" );
end


----------------------------------------------------------------
----------------------------------------------------------------
function GetLandValue( iPlayer )
    return Players[iPlayer]:GetNumPlots() * 10000;
end


----------------------------------------------------------------
----------------------------------------------------------------
function BuildLandEntry( iPlayer )
    local instance = {};
    ContextPtr:BuildInstanceForControl( "Entry", instance, Controls.MainStack );

    instance.Name:LocalizeAndSetText( "TXT_KEY_DEMOGRAPHICS_LAND" );

    instance.Value:SetText( Locale.ToNumber(m_LandTable[ iPlayer ], "#,###,###,###" ));
    instance.ValueTT:SetToolTipString( Locale.ConvertTextKey("TXT_KEY_DEMOGRAPHICS_LAND_MEASURE") );

    local best = GetBest( m_LandTable, iPlayer );
    SetIcon(best[2], instance.BestIcon, instance.BestIconBG, instance.BestIconShadow);
    instance.Best:SetText( Locale.ToNumber(best[1], "#,###,###,###") );
    instance.BestTT:SetToolTipString( Locale.ConvertTextKey("TXT_KEY_DEMOGRAPHICS_LAND_MEASURE") );

    instance.Average:SetText( Locale.ToNumber( GetAverage( m_LandTable, iPlayer ), "#,###,###,###" ) );
    instance.AverageTT:SetToolTipString( Locale.ConvertTextKey("TXT_KEY_DEMOGRAPHICS_LAND_MEASURE") );

    local worst = GetWorst( m_LandTable, iPlayer );
    SetIcon(worst[2], instance.WorstIcon, instance.WorstIconBG, instance.WorstIconShadow);
    instance.Worst:LocalizeAndSetText( Locale.ToNumber(worst[1], "#,###,###,###" ) );
    instance.WorstTT:SetToolTipString( Locale.ConvertTextKey("TXT_KEY_DEMOGRAPHICS_LAND_MEASURE") );

    instance.Rank:SetText( Locale.ToNumber(GetRank( m_LandTable, iPlayer ), "#") );

    SetupRankButton( instance, m_LandTable, "TXT_KEY_DEMOGRAPHICS_LAND", "#,###,###,###" );
end


----------------------------------------------------------------
----------------------------------------------------------------
function GetArmyValue( iPlayer )
    return math.sqrt( Players[iPlayer]:GetMilitaryMight() ) * 2000;
end


----------------------------------------------------------------
----------------------------------------------------------------
function BuildArmyEntry( iPlayer )
    local instance = {};
    ContextPtr:BuildInstanceForControl( "Entry", instance, Controls.MainStack );

    instance.Name:LocalizeAndSetText( "TXT_KEY_DEMOGRAPHICS_ARMY" );

    instance.Value:SetText( Locale.ToNumber(m_ArmyTable[ iPlayer ], "#,###,###,###" ));
    instance.ValueTT:SetToolTipString( Locale.ConvertTextKey("TXT_KEY_DEMOGRAPHICS_ARMY_MEASURE") );

    local best = GetBest( m_ArmyTable, iPlayer );
    SetIcon(best[2], instance.BestIcon, instance.BestIconBG, instance.BestIconShadow);
    instance.Best:SetText( Locale.ToNumber(best[1], "#,###,###,###") );
    instance.BestTT:SetToolTipString( Locale.ConvertTextKey("TXT_KEY_DEMOGRAPHICS_ARMY_MEASURE") );

    instance.Average:SetText( Locale.ToNumber( GetAverage( m_ArmyTable, iPlayer ), "#,###,###,###" ) );
    instance.AverageTT:SetToolTipString( Locale.ConvertTextKey("TXT_KEY_DEMOGRAPHICS_ARMY_MEASURE") );

    local worst = GetWorst( m_ArmyTable, iPlayer );
    SetIcon(worst[2], instance.WorstIcon, instance.WorstIconBG, instance.WorstIconShadow);
    instance.Worst:LocalizeAndSetText( Locale.ToNumber(worst[1], "#,###,###,###" ) );
    instance.WorstTT:SetToolTipString( Locale.ConvertTextKey("TXT_KEY_DEMOGRAPHICS_ARMY_MEASURE") );

    instance.Rank:SetText( Locale.ToNumber(GetRank( m_ArmyTable, iPlayer ), "#") );

    SetupRankButton( instance, m_ArmyTable, "TXT_KEY_DEMOGRAPHICS_ARMY", "#,###,###,###" );
end


function SetIcon(iPlayerID, control, controlBG, controlShadow)
	local pPlayer = Players[iPlayerID];
	local iTeam = pPlayer:GetTeam();
	local pTeam = Teams[iTeam];

    -- Active player
	if (pPlayer:GetID() == Game.GetActivePlayer()) then
		CivIconHookup( iPlayerID, 32, control, controlBG, controlShadow, false, true);
	-- Haven't yet met this player
	elseif (not pTeam:IsHasMet(Game.GetActiveTeam())) then
		CivIconHookup( -1, 32, control, controlBG, controlShadow, false, true);
	-- Met players
	else
		CivIconHookup( iPlayerID, 32, control, controlBG, controlShadow, false, true);
	end
end

----------------------------------------------------------------
----------------------------------------------------------------
function GetApprovalValue( iPlayer )
    local value = 60 + (Players[iPlayer]:GetExcessHappiness() * 3);
    if( value < 0 ) then
        return 0;
    elseif( value > 100 ) then
        return 100;
    end
    return value;
end


----------------------------------------------------------------
----------------------------------------------------------------
function BuildApprovalEntry( iPlayer )
    local instance = {};
    ContextPtr:BuildInstanceForControl( "Entry", instance, Controls.MainStack );

    instance.Name:LocalizeAndSetText( "TXT_KEY_DEMOGRAPHICS_APPROVAL" );

    instance.Value:SetText( Locale.ToNumber(m_ApprovalTable[ iPlayer ], "#'%'" ));

    local best = GetBest( m_ApprovalTable, iPlayer );
    SetIcon(best[2], instance.BestIcon, instance.BestIconBG, instance.BestIconShadow);
    instance.Best:SetText( Locale.ToNumber(best[1], "#'%'") );

    instance.Average:SetText( Locale.ToNumber( GetAverage( m_ApprovalTable, iPlayer ), "#'%'" ) );

    local worst = GetWorst( m_ApprovalTable, iPlayer );
    SetIcon(worst[2], instance.WorstIcon, instance.WorstIconBG, instance.WorstIconShadow);
    instance.Worst:LocalizeAndSetText( Locale.ToNumber(worst[1], "#'%'" ) );

    instance.Rank:SetText( Locale.ToNumber(GetRank( m_ApprovalTable, iPlayer ), "#") );

    SetupRankButton( instance, m_ApprovalTable, "TXT_KEY_DEMOGRAPHICS_APPROVAL", "#'%'" );
end


----------------------------------------------------------------
----------------------------------------------------------------
function GetLiteracyValue( iPlayer )

    local pTeamTechs = Teams[ Players[ iPlayer ]:GetTeam() ]:GetTeamTechs();

    local iWriting = GameInfoTypes[ "TECH_WRITING" ];
    if( iWriting ~= nil and
        not pTeamTechs:HasTech( iWriting ) ) then
        return 0;
    end

    local iCount = 0;
	for row in GameInfo.Technologies() do
	    if( pTeamTechs:HasTech( row.ID ) ) then
	        iCount = iCount + 1;
	    end
	end

	return 100 * iCount / #GameInfo.Technologies;
end


----------------------------------------------------------------
----------------------------------------------------------------
function BuildLiteracyEntry( iPlayer )
    local instance = {};
    ContextPtr:BuildInstanceForControl( "Entry", instance, Controls.MainStack );

    instance.Name:LocalizeAndSetText( "TXT_KEY_DEMOGRAPHICS_LITERACY" );

    instance.Value:SetText( Locale.ToNumber(m_LiteracyTable[ iPlayer ], "#'%'" ));

    local best = GetBest( m_LiteracyTable, iPlayer );
    SetIcon(best[2], instance.BestIcon, instance.BestIconBG, instance.BestIconShadow);
    instance.Best:SetText( Locale.ToNumber(best[1], "#'%'") );

    instance.Average:SetText( Locale.ToNumber( GetAverage( m_LiteracyTable, iPlayer ), "#'%'" ) );

    local worst = GetWorst( m_LiteracyTable, iPlayer );
    SetIcon(worst[2], instance.WorstIcon, instance.WorstIconBG, instance.WorstIconShadow);
    instance.Worst:LocalizeAndSetText( Locale.ToNumber(worst[1], "#'%'" ) );

    instance.Rank:SetText( Locale.ToNumber(GetRank( m_LiteracyTable, iPlayer ), "#") );

    SetupRankButton( instance, m_LiteracyTable, "TXT_KEY_DEMOGRAPHICS_LITERACY", "#'%'" );
end


----------------------------------------------------------------
----------------------------------------------------------------
function BuildList( iPlayer )
    Controls.MainStack:DestroyAllChildren();

    BuildPopulationEntry( iPlayer );
    BuildFoodEntry( iPlayer );
    BuildProductionEntry( iPlayer );
    BuildGoldEntry( iPlayer );
    BuildLandEntry( iPlayer );
    BuildArmyEntry( iPlayer );
    BuildApprovalEntry( iPlayer );
    BuildLiteracyEntry( iPlayer );

    Controls.MainStack:CalculateSize();
    Controls.MainStack:ReprocessAnchoring();
    Controls.BigStack:ReprocessAnchoring();

    CivIconHookup( iPlayer, 64, Controls.Icon, Controls.CivIconBG, Controls.CivIconShadow, false, true);
end


----------------------------------------------------------------
----------------------------------------------------------------
function OnPlayerPulldown( iPlayerID )
    BuildList( iPlayerID );
end
-- Controls.PlayerPulldown:RegisterSelectionCallback( OnPlayerPulldown );


----------------------------------------------------------------
----------------------------------------------------------------
function ShowHideHandler( bIsHide, bIsInit )

    if( not bIsInit ) then
        if( not bIsHide ) then
            HideFullRank();

            BuildTables();
            BuildList( Game.GetActivePlayer() );

            if( not m_bIsEndGame ) then
	            UI.incTurnTimerSemaphore();
	            Events.SerialEventGameMessagePopupShown(m_PopupInfo);
            end
        else
            HideFullRank();
			Events.SerialEventGameMessagePopupProcessed.CallImmediate(ButtonPopupTypes.BUTTONPOPUP_DEMOGRAPHICS, 0);
            if( not m_bIsEndGame ) then
	            UI.decTurnTimerSemaphore();
            end
        end
    end

end
ContextPtr:SetShowHideHandler( ShowHideHandler );

BuildTables();
BuildList( Game.GetActivePlayer() );

if( m_bIsEndGame ) then
    Controls.BGBlock:SetHide( true );
    Controls.InGameSet:SetHide( true );
end


-------------------------------------------------
-- On Popup
-------------------------------------------------
function OnPopup( popupInfo )

	-- End game is its own deal that shouldn't come up when we hit a hotkey or something
	if (m_bIsEndGame) then
		return
	end

	if( popupInfo.Type == ButtonPopupTypes.BUTTONPOPUP_DEMOGRAPHICS ) then
		m_PopupInfo = popupInfo;
		if( m_PopupInfo.Data1 == 1 ) then
        	if( ContextPtr:IsHidden() == false ) then
        	    OnBack();
            else
            	UIManager:QueuePopup( ContextPtr, PopupPriority.InGameUtmost );
        	end
    	else
        	UIManager:QueuePopup( ContextPtr, PopupPriority.Demographics );
    	end
	end
end
Events.SerialEventGameMessagePopup.Add( OnPopup );

----------------------------------------------------------------
----------------------------------------------------------------
function OnBack()
	print("Dequeuing demographics");
	UIManager:DequeuePopup( ContextPtr );
end
Controls.BackButton:RegisterCallback( Mouse.eLClick, OnBack );


----------------------------------------------------------------
-- Full ranking overlay close button
----------------------------------------------------------------
Controls.RankCloseButton:RegisterCallback( Mouse.eLClick, HideFullRank );


----------------------------------------------------------------
-- Key Down Processing
----------------------------------------------------------------
function InputHandler( uiMsg, wParam, lParam )
    if( uiMsg == KeyEvents.KeyDown ) then
        if( wParam == Keys.VK_RETURN or wParam == Keys.VK_ESCAPE ) then
            -- Close the full ranking first, then the demographics panel.
            if (Controls.RankPanel:IsHidden() == false) then
                HideFullRank();
                return true;
            end
			OnBack();
            return true;
        end
    end
end
if( not m_bIsEndGame ) then
	ContextPtr:SetInputHandler( InputHandler );
end

----------------------------------------------------------------
-- 'Active' (local human) player has changed
----------------------------------------------------------------
Events.GameplaySetActivePlayer.Add(OnBack);
