-------------------------------------------------------------------------------
-- Aid Point Choice Popup (Super Power V11)
--
-- Generic picker used by the city-state aid-point submenu:
--   mode "unit"        -> preselect the military unit a city-state will gift
--   mode "greatperson" -> preselect the next Great Person from the patronage finisher
-------------------------------------------------------------------------------

include( "IconSupport" );
include( "InstanceManager" );

g_AidChoiceParams = nil;
LuaEvents.AidPointChoicePopupOpen.Add(function(mode, minorID, cost)
	g_AidChoiceParams = { Mode = mode, MinorID = minorID, Cost = cost };
end);

local g_ItemManager = InstanceManager:new( "ItemInstance", "Button", Controls.ItemStack );
local g_SelectedUnit = -1;
local bHidden = true;

local screenSizeX, screenSizeY = UIManager:GetScreenSizeVal();
local spWidth, spHeight = Controls.ItemScrollPanel:GetSizeVal();
local heightOffset = screenSizeY - 1020;
spHeight = spHeight + heightOffset;
Controls.ItemScrollPanel:SetSizeVal(spWidth, spHeight);
Controls.ItemScrollPanel:CalculateInternalSize();
Controls.ItemScrollPanel:ReprocessAnchoring();

local bpWidth, bpHeight = Controls.BottomPanel:GetSizeVal();
bpHeight = bpHeight + heightOffset;
Controls.BottomPanel:SetSizeVal(bpWidth, bpHeight);
Controls.BottomPanel:ReprocessAnchoring();

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function RefreshList()
	g_ItemManager:ResetInstances();
	g_SelectedUnit = -1;
	Controls.SelectedLabel:SetText("");
	Controls.ConfirmButton:SetHide(true);
	-- Hiding a stack child does not reflow the stack, so recalculate it by hand.
	Controls.ButtonStack:CalculateSize();
	Controls.ButtonStack:ReprocessAnchoring();

	local params = g_AidChoiceParams;
	if (params == nil) then return; end

	local iActivePlayer = Game.GetActivePlayer();
	CivIconHookup( iActivePlayer, 64, Controls.CivIcon, Controls.CivIconBG, Controls.CivIconShadow, false, true );

	local tUnits = {};
	if (params.Mode == "unit") then
		Controls.TitleLabel:SetText(Locale.Lookup("TXT_KEY_AID_CHOICE_UNIT_TITLE"));
		tUnits = Game.GetMinorGiftUnitChoices(iActivePlayer);
	else
		Controls.TitleLabel:SetText(Locale.Lookup("TXT_KEY_AID_CHOICE_GP_TITLE"));
		for row in GameInfo.Units() do
			if (row.Special == "SPECIALUNIT_PEOPLE" and not row.FoundReligion) then
				table.insert(tUnits, row.ID);
			end
		end
	end
	Controls.CostLabel:SetText(Locale.Lookup("TXT_KEY_AID_CHOICE_COST", params.Cost));

	-- Strongest first so the better picks are visible without scrolling
	table.sort(tUnits, function(a, b)
		local pa = GameInfo.Units[a];
		local pb = GameInfo.Units[b];
		if (pa.Power ~= pb.Power) then
			return pa.Power > pb.Power;
		end
		return a < b;
	end);

	for _, unitType in ipairs(tUnits) do
		local pInfo = GameInfo.Units[unitType];
		local sName = Locale.Lookup(pInfo.Description);
		local item = g_ItemManager:GetInstance();
		item.Name:SetText(sName);
		item.Button:RegisterCallback( Mouse.eLClick, function() OnItemClicked(unitType, sName); end );
	end

	Controls.ItemStack:CalculateSize();
	Controls.ItemStack:ReprocessAnchoring();
	Controls.ItemScrollPanel:CalculateInternalSize();
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function OnItemClicked(unitType, sName)
	g_SelectedUnit = unitType;
	Controls.SelectedLabel:SetText(Locale.Lookup("TXT_KEY_AID_CHOICE_SELECTED", sName));
	Controls.ConfirmButton:SetHide(false);
	-- Reflow the stack so confirm and cancel sit side by side instead of overlapping.
	Controls.ButtonStack:CalculateSize();
	Controls.ButtonStack:ReprocessAnchoring();
end

function OnConfirm()
	local params = g_AidChoiceParams;
	if (params == nil or g_SelectedUnit == -1) then return; end
	LuaEvents.AidPointChoiceSelected(params.Mode, params.MinorID, g_SelectedUnit);
	Events.AudioPlay2DSound("AS2D_INTERFACE_POLICY");
	OnClose();
end
Controls.ConfirmButton:RegisterCallback( Mouse.eLClick, OnConfirm );

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function OnClose()
	UIManager:DequeuePopup(ContextPtr);
end
Controls.CancelButton:RegisterCallback( Mouse.eLClick, OnClose );

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function InputHandler( uiMsg, wParam, lParam )
	if uiMsg == KeyEvents.KeyDown then
		if (wParam == Keys.VK_RETURN or wParam == Keys.VK_ESCAPE) then
			OnClose();
			return true;
		end
	end
end
ContextPtr:SetInputHandler( InputHandler );

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function ShowHideHandler( bIsHide, bInitState )
	bHidden = bIsHide;
	if (not bInitState) then
		if (not bIsHide) then
			UI.incTurnTimerSemaphore();
			RefreshList();
		else
			UI.decTurnTimerSemaphore();
		end
	end
end
ContextPtr:SetShowHideHandler( ShowHideHandler );

----------------------------------------------------------------
----------------------------------------------------------------
Events.GameplaySetActivePlayer.Add(OnClose);
