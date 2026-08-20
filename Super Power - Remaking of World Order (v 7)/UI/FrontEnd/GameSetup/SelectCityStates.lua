-------------------------------------------------
-- Select City-States
-- Popup for picking which city-states are force-loaded at game start.
-- The selection is stored in PreGame GameOptions (GAMEOPTION_SP_CS_*) so it
-- survives to the DLL, which reads them during CvGame::init2.
-------------------------------------------------
include( "IconSupport" );
include( "SP_PreGameManager" );   -- persist the selection via the pregame-save feature
EUI = EUI or {};   -- fallback in case EUI is not loaded

local MAX_MAJOR = GameDefines.MAX_MAJOR_CIVS;
local MAX_CIV   = GameDefines.MAX_CIV_PLAYERS;

local OPT_ENABLED = "GAMEOPTION_SP_CS_ENABLED";
local function SlotOption( slot )
	return "GAMEOPTION_SP_CS_" .. tostring( slot );
end

-- civType (MinorCivilizations.ID) -> bool
g_Selection = g_Selection or {};
-- civType list in click order (used to fill slots in a stable order)
g_Order     = g_Order     or {};

-------------------------------------------------
-- Read the current selection back from PreGame GameOptions.
-------------------------------------------------
local function ReadSelection()
	g_Selection = {};
	g_Order     = {};

	if (PreGame.GetGameOption( OPT_ENABLED ) or 0) ~= 1 then
		return; -- feature not enabled, empty selection
	end

	for slot = MAX_MAJOR, MAX_CIV - 1 do
		local t = PreGame.GetGameOption( SlotOption( slot ) ) or -1;
		if t >= 0 then
			g_Selection[t] = true;
			g_Order[#g_Order + 1] = t;
		end
	end
end

-------------------------------------------------
-- Refresh the count label and confirm availability
-------------------------------------------------
local function UpdateCount()
	local n = 0;
	for _, v in pairs(g_Selection) do
		if v then n = n + 1; end
	end

	Controls.DescLabel:LocalizeAndSetText( "TXT_KEY_SP_SELECT_CITY_STATES_DESC", n );

	local maxMinor = PreGame.GetNumMinorCivs();
	if maxMinor < 0 then
		local world = GameInfo.Worlds[PreGame.GetWorldSize()];
		if world then maxMinor = world.DefaultMinorCivs; end
	end
	Controls.ConfirmButton:SetDisabled( n > maxMinor );
end

-------------------------------------------------
-- Set a selection state and keep the click-order list in sync.
-- WriteSelection() walks g_Order to fill the PreGame slots, so every
-- check change (row click or checkbox click) must update it too.
-------------------------------------------------
local function SetSelection( civType, bChecked )
	g_Selection[civType] = bChecked;
	if bChecked then
		local found = false;
		for _, v in ipairs( g_Order ) do
			if v == civType then found = true; break; end
		end
		if not found then g_Order[#g_Order + 1] = civType; end
	else
		for i = #g_Order, 1, -1 do
			if g_Order[i] == civType then
				table.remove( g_Order, i );
			end
		end
	end
	UpdateCount();
end

-------------------------------------------------
-- Toggle a city-state selection
-------------------------------------------------
local function Toggle( civType, checkControl )
	local bChecked = not (g_Selection[civType] or false);
	SetSelection( civType, bChecked );
	if checkControl then checkControl:SetCheck( bChecked ); end
end

-------------------------------------------------
-- Rebuild the full city-state list (two columns)
-------------------------------------------------
local function RebuildList()
	Controls.CityStateStack:DestroyAllChildren();

	ReadSelection();

	-- Load every city-state, sorted by name for stable display.
	local civList = {};
	for row in GameInfo.MinorCivilizations() do
		table.insert( civList, row );
	end
	table.sort( civList, function( a, b )
		return Locale.Compare( Locale.ConvertTextKey( a.ShortDescription ), Locale.ConvertTextKey( b.ShortDescription ) ) < 0;
	end );

	-- Build two per row (two columns).
	for i = 1, #civList, 2 do
		local rowControls = {};
		ContextPtr:BuildInstanceForControl( "RowInstance", rowControls, Controls.CityStateStack );
		for col = 1, 2 do
			local row = civList[i + col - 1];
			if row then
				local civControls = {};
				ContextPtr:BuildInstanceForControl( "CityStateInstance", civControls, rowControls["Col" .. col] );

				local civType = row.ID;
				civControls.Name:SetText( Locale.ConvertTextKey( row.ShortDescription ) );

				-- UA help text as the checkbox tooltip.
				local helpText = "";
				if row.UAType and row.UAType ~= "" then
					local uaInfo = GameInfo.CityStateUAs[row.UAType];
					if uaInfo and uaInfo.Help then
						helpText = Locale.Lookup( uaInfo.Help );
					end
				end
				civControls.Check:SetToolTipString( helpText );
				civControls.Row:SetToolTipString( helpText );

				civControls.Check:SetCheck( not not g_Selection[civType] );

				local civTypeLocal = civType;
				local checkControl = civControls.Check;
				civControls.Row:RegisterCallback( Mouse.eLClick, function()
					Toggle( civTypeLocal, checkControl );
				end );
				civControls.Check:RegisterCheckHandler( function( bChecked )
					SetSelection( civTypeLocal, bChecked );
				end );
			end
		end
	end

	Controls.CityStateStack:CalculateSize();
	Controls.CityStateStack:ReprocessAnchoring();
	Controls.ListPanel:CalculateInternalSize();
	UpdateCount();
end

-------------------------------------------------
-- Write the selection into PreGame GameOptions.
-------------------------------------------------
local function WriteSelection()
	local slot = MAX_MAJOR;
	local n = 0;
	for _, civType in ipairs( g_Order ) do
		if g_Selection[civType] and slot < MAX_CIV then
			PreGame.SetGameOption( SlotOption( slot ), civType );
			slot = slot + 1;
			n = n + 1;
		end
	end
	-- Clear the remaining slots so no stale selection survives.
	for s = slot, MAX_CIV - 1 do
		PreGame.SetGameOption( SlotOption( s ), -1 );
	end
	PreGame.SetGameOption( OPT_ENABLED, (n > 0) and 1 or 0 );
end

-------------------------------------------------
-- Close handler
-------------------------------------------------
local function ClosePopup()
	-- Opened via UIManager:PushModal (see AdvancedSetup.lua), so it must be
	-- closed with PopModal -- DequeuePopup only works for QueuePopup popups.
	UIManager:PopModal( ContextPtr );
	ContextPtr:CallParentShowHideHandler( false );
	ContextPtr:SetHide( true );
end

Controls.ConfirmButton:RegisterCallback( Mouse.eLClick, function()
	WriteSelection();
	-- Persist the full pregame setup (incl. city-state selection) to
	-- ModUserData so it survives restarting the game.
	if SPData and SPData.SaveData then SPData:SaveData(); end
	ClosePopup();
end );

Controls.CancelButton:RegisterCallback( Mouse.eLClick, function()
	ClosePopup();
end );

ContextPtr:SetInputHandler( function( uiMsg, wParam )
	if uiMsg == KeyEvents.KeyDown and wParam == Keys.VK_ESCAPE then
		ClosePopup();
		return true;
	end
	return false;
end );

ContextPtr:SetShowHideHandler( function( bIsHide )
	if not bIsHide then
		RebuildList();
	end
end );
