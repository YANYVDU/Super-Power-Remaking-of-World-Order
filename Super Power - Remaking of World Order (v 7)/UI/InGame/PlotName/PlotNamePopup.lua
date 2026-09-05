-------------------------------------------------
-- PlotNamePopup.lua
-- Ctrl+N to name plots, floating labels on world map
-------------------------------------------------
include("InstanceManager")

local g_bVisible = false
local g_iTargetX = -1
local g_iTargetY = -1
local g_bLabelsVisible = true  -- global toggle for plot name label visibility

-- One InstanceManager per color (13 color codes)
local g_LabelIMs = {
	[""] = InstanceManager:new("PlotNameLabelR", "Anchor", Controls.WorldLabelStack),
	R  = InstanceManager:new("PlotNameLabelR",   "Anchor", Controls.WorldLabelStack),
	G  = InstanceManager:new("PlotNameLabelG",   "Anchor", Controls.WorldLabelStack),
	BL = InstanceManager:new("PlotNameLabelBL",  "Anchor", Controls.WorldLabelStack),
	Y  = InstanceManager:new("PlotNameLabelY",   "Anchor", Controls.WorldLabelStack),
	C  = InstanceManager:new("PlotNameLabelC",   "Anchor", Controls.WorldLabelStack),
	M  = InstanceManager:new("PlotNameLabelM",   "Anchor", Controls.WorldLabelStack),
	W  = InstanceManager:new("PlotNameLabelW",   "Anchor", Controls.WorldLabelStack),
	P  = InstanceManager:new("PlotNameLabelP",   "Anchor", Controls.WorldLabelStack),
	N  = InstanceManager:new("PlotNameLabelN",   "Anchor", Controls.WorldLabelStack),
	S  = InstanceManager:new("PlotNameLabelS",   "Anchor", Controls.WorldLabelStack),
	U  = InstanceManager:new("PlotNameLabelU",   "Anchor", Controls.WorldLabelStack),
	F  = InstanceManager:new("PlotNameLabelF",   "Anchor", Controls.WorldLabelStack),
	BR = InstanceManager:new("PlotNameLabelBR",  "Anchor", Controls.WorldLabelStack),
}

local function SyncLabels()
	for _, im in pairs(g_LabelIMs) do im:ResetInstances() end
	if not g_bLabelsVisible then return end
	if not Game.GetAllPlotNames then return end
	for _, entry in ipairs(Game.GetAllPlotNames()) do
		local displayName = entry.name
		local code = ""
		if #displayName >= 2 and string.sub(displayName, 1, 1) == "." then
			-- Try 2-letter code first (.BR .BL)
			if #displayName >= 3 then
				local code2 = string.upper(string.sub(displayName, 2, 3))
				if g_LabelIMs[code2] then
					code = code2
					displayName = string.sub(displayName, 4)
				end
			end
			-- Try 1-letter code
			if code == "" then
				local code1 = string.upper(string.sub(displayName, 2, 2))
				if g_LabelIMs[code1] then
					code = code1
					displayName = string.sub(displayName, 3)
				end
			end
		end
		local im = g_LabelIMs[code] or g_LabelIMs[""]
		local inst = im:GetInstance()
		if inst then
			inst.Label:SetText(displayName)
			local wx, wy, wz = GridToWorld(entry.x, entry.y)
			if wx then inst.Anchor:SetWorldPositionVal(wx, wy, wz + 30) end
		end
	end
end

-------------------------------------------------
-- Plot Name Label Visibility Toggle (called from MiniMapPanel)
-------------------------------------------------
function SetLabelsVisible(bVisible)
	g_bLabelsVisible = bVisible
	if bVisible then
		SyncLabels()
	else
		for _, im in pairs(g_LabelIMs) do im:ResetInstances() end
	end
	-- Persist setting across game sessions
	local userData = Modding.OpenUserData("SP_UserInterfaceOptions", 2)
	if userData then
		userData.SetValue("ShowPlotNames", bVisible and 1 or 0)
	end
end

function LoadPlotNameSettings()
	local userData = Modding.OpenUserData("SP_UserInterfaceOptions", 2)
	if userData then
		local saved = userData.GetValue("ShowPlotNames")
		-- Only disable if explicitly set to 0; missing key defaults to ON
		if saved == 0 then
			g_bLabelsVisible = false
		end
	end
end

LuaEvents.PlotNameToggleLabels.Add(SetLabelsVisible)

local function Show(iX, iY)
	if g_bVisible then return end
	g_iTargetX = iX; g_iTargetY = iY; g_bVisible = true
	local existingName = ""
	if Game.GetPlotName then
		local name = Game.GetPlotName(iX, iY)
		if name then existingName = name end
	end
	Controls.NameInput:SetText(existingName)
	Controls.MainGrid:SetHide(false)
	Controls.NameInput:TakeFocus()
end

local function Hide()
	g_bVisible = false
	Controls.MainGrid:SetHide(true)
end

local function OnConfirm()
	local text = Controls.NameInput:GetText()
	if Game.SetPlotName then Game.SendAndExecuteLuaFunction("CvLuaGame::lSetPlotName", g_iTargetX, g_iTargetY, text); SyncLabels() end
	Hide()
end

local function OnClear()
	if Game.RemovePlotName then Game.SendAndExecuteLuaFunction("CvLuaGame::lRemovePlotName", g_iTargetX, g_iTargetY); SyncLabels() end
	Hide()
end

function OnPopupInput(uiMsg, wParam, lParam)
	if not g_bVisible then return false end
	if uiMsg == KeyEvents.KeyDown then
		if wParam == Keys.VK_ESCAPE then Hide(); return true end
		if wParam == Keys.VK_RETURN then OnConfirm(); return true end
	end
	return false
end

LuaEvents.PlotNameShow.Add(Show)
ContextPtr:SetHide(false)
Controls.MainGrid:SetHide(true)
Controls.ConfirmBtn:RegisterCallback(Mouse.eLClick, OnConfirm)
Controls.ClearBtn:RegisterCallback(Mouse.eLClick, OnClear)
Controls.CancelBtn:RegisterCallback(Mouse.eLClick, Hide)
ContextPtr:SetInputHandler(OnPopupInput)
Events.SerialEventEnterCityScreen.Add(function() Controls.WorldLabelStack:SetHide(true); SyncLabels() end)
Events.SerialEventExitCityScreen.Add(function() Controls.WorldLabelStack:SetHide(false); SyncLabels() end)
LoadPlotNameSettings()
SyncLabels()
