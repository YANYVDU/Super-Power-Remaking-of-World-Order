-------------------------------------------------
-- MiniMapPanel.lua
-- Minimap panel with map options, adapted from EUI
-- Extended with ShowPlotNames toggle for plot name labels
-- Strategic-view overlay/icon controls restored from vanilla (Brave New World)
-------------------------------------------------

include("InstanceManager")

local pairs = pairs

local ContextPtr = ContextPtr
local Controls = Controls
local Events = Events
local GetActivePlayer = Game.GetActivePlayer
local GameViewTypes = GameViewTypes
local GetGameViewRenderType = GetGameViewRenderType
local InStrategicView = InStrategicView
local Mouse = Mouse
local OptionsManager = OptionsManager
local PreGame = PreGame
local SetGameViewRenderType = SetGameViewRenderType
local SS_OBSERVER = SlotStatus.SS_OBSERVER
local ToggleStrategicView = ToggleStrategicView
local UI = UI
local YieldDisplayTypes = YieldDisplayTypes

local g_LegendIM = InstanceManager:new("LegendKey", "Item", Controls.LegendStack)
local g_Overlays = GetStrategicViewOverlays()
local g_IconModes = GetStrategicViewIconSettings()

local g_width, g_height

local g_OptionActions = {
	ShowGrid = UI.SetGridVisibleMode,
	ShowYield = UI.SetYieldVisibleMode,
	ShowResources = UI.SetResourceVisibleMode,
	ShowTrade = Events.Event_ToggleTradeRouteDisplay,
	HideRecommendation = LuaEvents.OnRecommendationCheckChanged.Call,
	ShowPlotNames = function(isChecked)
		LuaEvents.PlotNameToggleLabels(isChecked)
	end,
	ShowFeatures = StrategicViewShowFeatures,
	ShowFogOfWar = StrategicViewShowFogOfWar,
	SVOverlayMode = SetStrategicViewOverlay,
	SVIconMode = SetStrategicViewIconSetting,
}

local g_SaveOptions = {
	HideRecommendation = OptionsManager.SetNoTileRecommendations_Cached,
	ShowResources = OptionsManager.SetResourceOn_Cached,
	ShowYield = OptionsManager.SetYieldOn_Cached,
	ShowTrade = OptionsManager.SetShowTradeOn_Cached,
	ShowGrid = OptionsManager.SetGridOn_Cached,
}

local g_GetOptions = {
	HideRecommendation = OptionsManager.IsNoTileRecommendations_Cached,
	ShowResources = OptionsManager.GetResourceOn_Cached,
	ShowYield = OptionsManager.GetYieldOn_Cached,
	ShowTrade = OptionsManager.GetShowTradeOn_Cached,
	ShowGrid = OptionsManager.GetGridOn_Cached,
}

local g_YieldDisplayActions = {
	[YieldDisplayTypes.USER_ALL_ON or -1] = { "ShowYield", true },
	[YieldDisplayTypes.USER_ALL_OFF or -1] = { "ShowYield", false },
	[YieldDisplayTypes.USER_ALL_RESOURCE_ON or -1] = { "ShowResources", true },
	[YieldDisplayTypes.USER_ALL_RESOURCE_OFF or -1] = { "ShowResources", false },
	[-1] = nil
}

local g_PerPlayerMapOptions = {}
local g_MapOptions
local g_MapOptionDefaults = {
	ShowPlotNames = true,
	ShowFeatures = true,
	ShowFogOfWar = true,
	SVOverlayMode = 1,
	SVIconMode = 1,
}

for k, isOption in pairs(g_GetOptions) do
	g_MapOptionDefaults[k] = isOption()
end

--==========================================================
-- Minimap texture broadcast
--==========================================================
Events.MinimapTextureBroadcastEvent.Add(function(uiHandle, width, height)
	Controls.Minimap:SetTextureHandle(uiHandle)
	if width ~= g_width or height ~= g_height then
		g_width, g_height = width, height
		Controls.Minimap:SetSizeVal(width, height)
		Controls.MinimapPanel:SetSizeVal(width + 35, height + 87)
		local EndTurnButton = ContextPtr:LookUpControl("../ActionInfoPanel/EndTurnButton")
		if EndTurnButton then
			EndTurnButton:SetOffsetY(height + 10)
		end
		local OuterStack = ContextPtr:LookUpControl("../ActionInfoPanel/NotificationPanel/OuterStack")
		if OuterStack then
			OuterStack:SetOffsetY(height + 50)
		end
		Controls.OuterStack:CalculateSize()
		Controls.OuterStack:ReprocessAnchoring()
	end
end)
UI.RequestMinimapBroadcast()

--==========================================================
-- Minimap click
--==========================================================
Controls.Minimap:RegisterCallback(Mouse.eLClick, function(_, _, _, x, y)
	Events.MinimapClickedEvent(x, y)
end)

--==========================================================
-- Strategic view overlay legend
--==========================================================
local function SetLegend(index)
	g_LegendIM:ResetInstances()

	local info = GetOverlayLegend()
	if index ~= nil then
		Controls.OverlayTitle:SetText(Locale.ConvertTextKey(g_Overlays[index]))
	end

	if info ~= nil and InStrategicView() then
		for i, v in pairs(info) do
			local controlTable = g_LegendIM:GetInstance()

			local keyColor = { x = v.Color.R, y = v.Color.G, z = v.Color.B, w = 1 }
			controlTable.KeyColor:SetColor(keyColor)
			controlTable.KeyName:LocalizeAndSetText(v.Name)
		end

		Controls.LegendStack:CalculateSize()
		Controls.LegendStack:ReprocessAnchoring()
		Controls.LegendFrame:SetHide(false)
		Controls.LegendFrame:DoAutoSize()
		Controls.SideStack:CalculateSize()
		Controls.SideStack:ReprocessAnchoring()
	else
		Controls.LegendFrame:SetHide(true)
		Controls.SideStack:CalculateSize()
		Controls.SideStack:ReprocessAnchoring()
	end
end

--==========================================================
-- Strategic view overlay / icon pulldowns
--==========================================================
local function OnOverlaySelected(index)
	SetStrategicViewOverlay(index)
	g_MapOptions.SVOverlayMode = index

	Controls.OverlayDropDown:GetButton():SetText(Locale.ConvertTextKey(g_Overlays[index]))
	SetLegend(index)
end

local function PopulateOverlayPulldown(pullDown)
	for i, text in pairs(g_Overlays) do
		local controlTable = {}
		pullDown:BuildEntry("InstanceOne", controlTable)

		controlTable.Button:SetVoid1(i)
		controlTable.Button:SetText(Locale.ConvertTextKey(text))
	end

	Controls.OverlayDropDown:GetButton():SetText(Locale.ConvertTextKey(g_Overlays[1]))

	pullDown:CalculateInternals()
	pullDown:RegisterSelectionCallback(OnOverlaySelected)
end

local function OnIconModeSelected(index)
	SetStrategicViewIconSetting(index)
	g_MapOptions.SVIconMode = index

	Controls.IconDropDown:GetButton():SetText(Locale.ConvertTextKey(g_IconModes[index]))
end

local function PopulateIconPulldown(pullDown)
	for i, text in pairs(g_IconModes) do
		local controlTable = {}
		pullDown:BuildEntry("InstanceOne", controlTable)

		controlTable.Button:SetVoid1(i)
		controlTable.Button:SetText(Locale.ConvertTextKey(text))
	end

	Controls.IconDropDown:GetButton():SetText(Locale.ConvertTextKey(g_IconModes[1]))

	pullDown:CalculateInternals()
	pullDown:RegisterSelectionCallback(OnIconModeSelected)
end

--==========================================================
-- Update options panel UI
--==========================================================
local function UpdateOptionsPanel()
	for key, isChecked in pairs(g_MapOptions) do
		local control = Controls[key]
		if control then
			control:SetCheck(isChecked)
		end
	end
	Controls.StrategicStack:SetHide(not InStrategicView())
	Controls.OverlayDropDown:GetButton():SetText(Locale.ConvertTextKey(g_Overlays[g_MapOptions.SVOverlayMode]))
	Controls.IconDropDown:GetButton():SetText(Locale.ConvertTextKey(g_IconModes[g_MapOptions.SVIconMode]))
	SetLegend(g_MapOptions.SVOverlayMode)
	Controls.StrategicStack:CalculateSize()
	Controls.MainStack:CalculateSize()
	Controls.OptionsPanel:DoAutoSize()
	Controls.SideStack:CalculateSize()
	Controls.SideStack:ReprocessAnchoring()
end

--==========================================================
-- Strategic View Button
--==========================================================
Controls.StrategicViewButton:RegisterCallback(Mouse.eLClick, function()
	if PreGame.GetSlotStatus(GetActivePlayer()) == SS_OBSERVER then
		local eViewType = GetGameViewRenderType()
		if eViewType == GameViewTypes.GAMEVIEW_NONE then
			SetGameViewRenderType(GameViewTypes.GAMEVIEW_STANDARD)
		elseif eViewType == GameViewTypes.GAMEVIEW_STANDARD then
			SetGameViewRenderType(GameViewTypes.GAMEVIEW_STRATEGIC)
		else
			SetGameViewRenderType(GameViewTypes.GAMEVIEW_NONE)
		end
	else
		ToggleStrategicView()
	end
end)

--==========================================================
-- Map Options open / close
--==========================================================
local function OpenMapOptions()
	Controls.OptionsPanel:SetHide(false)
	UpdateOptionsPanel()
	Controls.SideStack:CalculateSize()
	Controls.SideStack:ReprocessAnchoring()
end

local function CloseMapOptions()
	Controls.OptionsPanel:SetHide(true)
	Controls.SideStack:CalculateSize()
	Controls.SideStack:ReprocessAnchoring()
end

Controls.MapOptionsButton:RegisterCallback(Mouse.eLClick, function()
	if Controls.OptionsPanel:IsHidden() then
		OpenMapOptions()
	else
		CloseMapOptions()
	end
end)

--==========================================================
-- Checkbox handlers
--==========================================================
local function SetMapOptionCheck(key, isChecked)
	Controls[key]:SetCheck(isChecked)
	g_MapOptions[key] = isChecked
end

local function SetMapOptionAction(key, isChecked)
	g_MapOptions[key] = isChecked
	if g_SaveOptions[key] then
		g_SaveOptions[key](isChecked)
		OptionsManager.CommitGameOptions(PreGame.IsHotSeatGame())
	end
	if g_OptionActions[key] then
		g_OptionActions[key](isChecked)
	end
end

for k in pairs(g_MapOptionDefaults) do
	local control = Controls[k]
	if control then
		control:RegisterCheckHandler(function(isChecked)
			SetMapOptionAction(k, isChecked)
		end)
	end
end

--==========================================================
-- 'Active' (local human) player has changed
--==========================================================
local function OnActivePlayerChanged(ActivePlayerID, PrevActivePlayerID)
	g_PerPlayerMapOptions[PrevActivePlayerID] = g_MapOptions
	g_MapOptions = g_PerPlayerMapOptions[ActivePlayerID]
	if not g_MapOptions then
		g_MapOptions = {}
		for k, v in pairs(g_MapOptionDefaults) do
			g_MapOptions[k] = v
		end
		g_PerPlayerMapOptions[ActivePlayerID] = g_MapOptions
	end
	for k, action in pairs(g_OptionActions) do
		action(g_MapOptions[k])
	end
	if PreGame.IsHotSeatGame() then
		local isChanged = false
		for k, isOption in pairs(g_GetOptions) do
			if isOption() ~= g_MapOptions[k] and g_SaveOptions[k] then
				g_SaveOptions[k](g_MapOptions[k])
				isChanged = true
			end
		end
		if isChanged then
			OptionsManager.CommitGameOptions(true)
		end
	end
	UpdateOptionsPanel()
	CloseMapOptions()
end

--==========================================================
-- Strategic view tooltip
--==========================================================
local controlInfo = GameInfo.Controls.CONTROL_TOGGLE_STRATEGIC_VIEW
if type(controlInfo) == "table" then
	local hotKey = controlInfo.HotKey
	if type(hotKey) == "string" then
		local keyDesc = Locale.GetHotKeyDescription(hotKey, controlInfo.CtrlDown, controlInfo.AltDown, controlInfo.ShiftDown)
		if type(keyDesc) == "string" then
			Controls.StrategicViewButton:SetToolTipString(
				Locale.ConvertTextKey("TXT_KEY_POP_STRATEGIC_VIEW_TT") .. " (" .. keyDesc .. ")"
			)
		end
	end
end

--==========================================================
-- Initialize
--==========================================================
PopulateOverlayPulldown(Controls.OverlayDropDown)
PopulateIconPulldown(Controls.IconDropDown)

Events.SequenceGameInitComplete.Add(function()
	OnActivePlayerChanged(GetActivePlayer(), -1)
	Events.GameplaySetActivePlayer.Add(OnActivePlayerChanged)
	Events.GameOptionsChanged.Add(UpdateOptionsPanel)
	Events.StrategicViewStateChanged.Add(function(isStrategicView)
		Controls.ShowResources:SetDisabled(isStrategicView)
		Controls.ShowResources:SetAlpha(isStrategicView and 0.5 or 1.0)
		if isStrategicView then
			Controls.StrategicViewButton:SetTexture("MainWorldButton.dds")
			Controls.StrategicMO:SetTexture("MainWorldButton.dds")
			Controls.StrategicHL:SetTexture("MainWorldButtonHL.dds")
		else
			Controls.ShowGrid:SetCheck(OptionsManager.GetGridOn_Cached())
			Controls.StrategicViewButton:SetTexture("MainStrategicButton.dds")
			Controls.StrategicMO:SetTexture("MainStrategicButton.dds")
			Controls.StrategicHL:SetTexture("MainStrategicButtonHL.dds")
		end
		UpdateOptionsPanel()
	end)
	Events.SerialEventHexGridOn.Add(function()
		SetMapOptionCheck("ShowGrid", true)
	end)
	Events.SerialEventHexGridOff.Add(function()
		SetMapOptionCheck("ShowGrid", false)
	end)
	if Events.Event_ToggleTradeRouteDisplay then
		Events.Event_ToggleTradeRouteDisplay.Add(function(isChecked)
			SetMapOptionCheck("ShowTrade", isChecked)
		end)
	elseif Controls.ShowTrade then
		Controls.ShowTrade:SetHide(true)
	end
	Events.RequestYieldDisplay.Add(function(t)
		t = g_YieldDisplayActions[t]
		if t then
			return SetMapOptionCheck(t[1], t[2])
		end
	end)
end)
