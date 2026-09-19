-------------------------------------------------------------------------------
-- Choose Belief Popup (Super Power V11)
--
-- 维滕贝格城邦UA：盟友可花费高额信仰，为盟友为领袖的宗教购买一个自选信条。
-- 本弹窗复用原版选神系UI的样式，信条按分类列出并突破限制（被他人占用的也可选），
-- 仅排除盟友宗教已含的同一信条。可通过 g_CSUABeliefPopupParams 全局参数复用
-- （例如拉本塔UA再次调用时只需填充不同参数）。
-------------------------------------------------------------------------------

include( "IconSupport" );
include( "InstanceManager" );

-- 城邦外交界面通过 LuaEvents 传入参数（Lua 全局变量不跨 context 共享）
-- Mode: "belief"（维滕贝格任意信条）或 "pantheon"（拉本塔空闲神系）
g_CSUABeliefPopupParams = nil;
LuaEvents.CSUABeliefPopupOpen.Add(function(MinorID, Cost, ReligionName, Mode)
	g_CSUABeliefPopupParams = { MinorID = MinorID, Cost = Cost, ReligionName = ReligionName, Mode = Mode or "belief" };
	print("[ChooseBeliefPopup] params received minor=" .. tostring(MinorID) .. " cost=" .. tostring(Cost) .. " religion=" .. tostring(ReligionName) .. " mode=" .. tostring(Mode));
end);

-- 交替底色（同原版选神系UI）
local ltBlue = {19/255,32/255,46/255,120/255};
local dkBlue = {12/255,22/255,30/255,120/255};

local g_SectionManager = InstanceManager:new( "SectionInstance", "SectionLabel", Controls.ItemStack );
local g_ItemManager = InstanceManager:new( "ItemInstance", "Button", Controls.ItemStack );
local bHidden = true;

local g_BeliefID = -1;

-- 各分类折叠状态：true = 收起（只显示分类标题，点击展开本类型全部信条）
local g_CollapsedSections = {
	PANTHEON = true,
	FOLLOWER = true,
	FOUNDER = true,
	ENHANCER = true,
	REFORMATION = true,
};

local screenSizeX, screenSizeY = UIManager:GetScreenSizeVal();
local spWidth, spHeight = Controls.ItemScrollPanel:GetSizeVal();

-- 原版UI按1050px高度设计，这里做同样的高度补偿
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
-- 列表刷新
-------------------------------------------------------------------------------
function RefreshList()
	g_SectionManager:ResetInstances();
	g_ItemManager:ResetInstances();

	local pPlayer = Players[Game.GetActivePlayer()];
	CivIconHookup( pPlayer:GetID(), 64, Controls.CivIcon, Controls.CivIconBG, Controls.CivIconShadow, false, true );

	-- 左上角显示玩家创立的宗教图标（无正式宗教则保持默认神系图标）
	local religionID = pPlayer:GetReligionCreatedByPlayer();
	if (religionID ~= -1 and GameInfo.Religions[religionID] ~= nil) then
		IconHookup( GameInfo.Religions[religionID].PortraitIndex, 80, GameInfo.Religions[religionID].IconAtlas, Controls.ReligionIcon );
	end

	-- 获取盟友宗教已含信条集合（含CSUA购买的信条）
	local knownBeliefs = {};
	local params = g_CSUABeliefPopupParams;
	local religionID = pPlayer:GetReligionCreatedByPlayer();
	if (religionID ~= -1) then
		for _, bid in ipairs(Game.GetBeliefsInReligion(religionID)) do
			knownBeliefs[bid] = true;
		end
	end

	local mode = params.Mode or "belief";

	-- 拉本塔 pantheon 模式：构建已占用神系集合（被任意宗教占用的神系不可再购买，仅保留空闲神系）
	local occupiedBeliefs = {};
	if (mode == "pantheon") then
		for religionRow in GameInfo.Religions() do
			local rid = religionRow.ID;
			for _, bid in ipairs(Game.GetBeliefsInReligion(rid)) do
				occupiedBeliefs[bid] = true;
			end
		end
	end

	-- 分类定义：神系 / 追随者 / 创立 / 强化 / 改革
	local sections = {
		{ key = "PANTHEON",     labelKey = "TXT_KEY_CHOOSE_BELIEF_SECTION_PANTHEON",     list = {} },
		{ key = "FOLLOWER",     labelKey = "TXT_KEY_CHOOSE_BELIEF_SECTION_FOLLOWER",     list = {} },
		{ key = "FOUNDER",      labelKey = "TXT_KEY_CHOOSE_BELIEF_SECTION_FOUNDER",      list = {} },
		{ key = "ENHANCER",     labelKey = "TXT_KEY_CHOOSE_BELIEF_SECTION_ENHANCER",     list = {} },
		{ key = "REFORMATION",  labelKey = "TXT_KEY_CHOOSE_BELIEF_SECTION_REFORMATION",  list = {} },
	};

	-- 收集全部信条，按类型归类；维滕贝格突破限制：被他人占用/未占用的均可选，仅排除盟友宗教已含的同一信条；
	-- 拉本塔仅允许购买未被任何宗教占用的空闲神系信条
	for row in GameInfo.Beliefs() do
		local beliefID = row.ID;
		if (not knownBeliefs[beliefID]) and (not occupiedBeliefs[beliefID]) then
			local section = nil;
			if (mode == "pantheon") then
				if (row.Pantheon) then
					section = sections[1];
				end
			elseif (row.Reformation) then
				section = sections[5];
			elseif (row.Enhancer) then
				section = sections[4];
			elseif (row.Founder) then
				section = sections[3];
			elseif (row.Follower) then
				section = sections[2];
			elseif (row.Pantheon) then
				section = sections[1];
			end
			if (section ~= nil) then
				table.insert(section.list, {
					ID = beliefID,
					Name = Locale.Lookup(row.ShortDescription),
					Description = Locale.Lookup(row.Description),
				});
			end
		end
	end

	local bTickTock = false;
	for _, section in ipairs(sections) do
		if (#section.list > 0) then
			-- 分类标题（可点击折叠）
			local secInstance = g_SectionManager:GetInstance();
			secInstance.SectionLabel:SetText(Locale.Lookup(section.labelKey));

			local bCollapsed = g_CollapsedSections[section.key];
			secInstance.CollapseLabel:SetText(bCollapsed and "+" or "-");
			secInstance.SectionButton:RegisterCallback(Mouse.eLClick, function()
				g_CollapsedSections[section.key] = not g_CollapsedSections[section.key];
				RefreshList();
			end);

			-- 类内按名称排序
			table.sort(section.list, function(a, b) return Locale.Compare(a.Name, b.Name) < 0; end);

			if (not bCollapsed) then
				for _, belief in ipairs(section.list) do
					local itemInstance = g_ItemManager:GetInstance();
					itemInstance.Name:SetText(belief.Name);
					itemInstance.Description:SetText(belief.Description);
					itemInstance.Button:RegisterCallback(Mouse.eLClick, function() SelectBelief(belief.ID); end);

					if (bTickTock == false) then
						itemInstance.Box:SetColorVal(unpack(ltBlue));
					else
						itemInstance.Box:SetColorVal(unpack(dkBlue));
					end

					-- 根据描述文本动态调整行高
					local buttonWidth, buttonHeight = itemInstance.Button:GetSizeVal();
					local descWidth, descHeight = itemInstance.Description:GetSizeVal();
					local newHeight = descHeight + 40;
					itemInstance.Button:SetSizeVal(buttonWidth, newHeight);
					itemInstance.Box:SetSizeVal(buttonWidth + 20, newHeight);
					itemInstance.BounceAnim:SetSizeVal(buttonWidth + 20, newHeight + 5);
					itemInstance.BounceGrid:SetSizeVal(buttonWidth + 20, newHeight + 5);

					bTickTock = not bTickTock;
				end
			end
		end
	end

	Controls.ItemStack:CalculateSize();
	Controls.ItemStack:ReprocessAnchoring();
	Controls.ItemScrollPanel:CalculateInternalSize();
end

-------------------------------------------------------------------------------
-- 选择信条 -> 确认弹窗
-------------------------------------------------------------------------------
function SelectBelief(beliefID)
	g_BeliefID = beliefID;
	local belief = GameInfo.Beliefs[beliefID];
	Controls.ConfirmText:LocalizeAndSetText("TXT_KEY_CONFIRM_BELIEF_PURCHASE", belief.ShortDescription);
	Controls.ChooseConfirm:SetHide(false);
end

function OnYes()
	Controls.ChooseConfirm:SetHide(true);
	local params = g_CSUABeliefPopupParams;
	print("[ChooseBeliefPopup] OnYes params=" .. tostring(params) .. " beliefID=" .. tostring(g_BeliefID));
	if (params ~= nil and params.MinorID ~= nil and g_BeliefID ~= -1) then
		local bSuccess = false;
		local iActivePlayer = Game.GetActivePlayer();
		if (params.Mode == "pantheon") then
			--bSuccess = Game.DoCityStateFaithPantheonPurchase(params.MinorID, g_BeliefID);
			bSuccess = Game.SendAndExecuteLuaFunction("CvLuaGame::lDoCityStateFaithPantheonPurchaseFromMajor", iActivePlayer, params.MinorID, g_BeliefID);
			print("[CSUA PantheonPurchase] minor=" .. params.MinorID .. " belief=" .. g_BeliefID .. " result=" .. tostring(bSuccess));
		else
			--bSuccess = Game.DoCityStateFaithBeliefPurchase(params.MinorID, g_BeliefID);
			bSuccess = Game.SendAndExecuteLuaFunction("CvLuaGame::lDoCityStateFaithBeliefPurchaseFromMajor", iActivePlayer, params.MinorID, g_BeliefID);
			print("[CSUA BeliefPurchase] minor=" .. params.MinorID .. " belief=" .. g_BeliefID .. " result=" .. tostring(bSuccess));
		end
		if (bSuccess) then
			Events.AudioPlay2DSound("AS2D_INTERFACE_POLICY");
		end
	else
		print("[ChooseBeliefPopup] OnYes SKIPPED: params nil or no belief selected");
	end
	OnClose();
end
Controls.Yes:RegisterCallback( Mouse.eLClick, OnYes );

function OnNo()
	Controls.ChooseConfirm:SetHide(true);
end
Controls.No:RegisterCallback( Mouse.eLClick, OnNo );

-------------------------------------------------------------------------------
-- 关闭
-------------------------------------------------------------------------------
function OnClose()
	UIManager:DequeuePopup(ContextPtr);
end
Controls.CloseButton:RegisterCallback( Mouse.eLClick, OnClose );

-------------------------------------------------------------------------------
-- 键盘处理
-------------------------------------------------------------------------------
function InputHandler( uiMsg, wParam, lParam )
	if uiMsg == KeyEvents.KeyDown then
		if (wParam == Keys.VK_RETURN or wParam == Keys.VK_ESCAPE) then
			if (Controls.ChooseConfirm:IsHidden()) then
				OnClose();
			else
				Controls.ChooseConfirm:SetHide(true);
			end
			return true;
		end
	end
end
ContextPtr:SetInputHandler( InputHandler );

-------------------------------------------------------------------------------
-- 显示/隐藏
-------------------------------------------------------------------------------
function ShowHideHandler( bIsHide, bInitState )
	bHidden = bIsHide;
	if (not bInitState) then
		if (not bIsHide) then
			UI.incTurnTimerSemaphore();

			-- 读取调用方参数（维滕贝格/拉本塔UA均可复用）
			local params = g_CSUABeliefPopupParams;
			if (params ~= nil) then
				if (params.Mode == "pantheon") then
					Controls.SubtitleLabel:LocalizeAndSetText("TXT_KEY_CHOOSE_PANTHEON_SUBTITLE", params.ReligionName, params.Cost);
				elseif (params.ReligionName ~= nil) then
					Controls.SubtitleLabel:LocalizeAndSetText("TXT_KEY_CHOOSE_BELIEF_SUBTITLE", params.ReligionName, params.Cost);
				else
					Controls.SubtitleLabel:LocalizeAndSetText("TXT_KEY_CHOOSE_BELIEF_SUBTITLE_NO_RELIGION", params.Cost);
				end
			end

			RefreshList();

			local unitPanel = ContextPtr:LookUpControl( "/InGame/WorldView/UnitPanel/Base" );
			if ( unitPanel ~= nil ) then
				unitPanel:SetHide( true );
			end

			local infoCorner = ContextPtr:LookUpControl( "/InGame/WorldView/InfoCorner" );
			if ( infoCorner ~= nil ) then
				infoCorner:SetHide( true );
			end
		else
			local unitPanel = ContextPtr:LookUpControl( "/InGame/WorldView/UnitPanel/Base" );
			if ( unitPanel ~= nil ) then
				unitPanel:SetHide(false);
			end

			local infoCorner = ContextPtr:LookUpControl( "/InGame/WorldView/InfoCorner" );
			if ( infoCorner ~= nil ) then
				infoCorner:SetHide(false);
			end

			UI.decTurnTimerSemaphore();
		end
	end
end
ContextPtr:SetShowHideHandler( ShowHideHandler );

----------------------------------------------------------------
-- 活动玩家变更：关闭确认框
----------------------------------------------------------------
function OnActivePlayerChanged()
	if (not Controls.ChooseConfirm:IsHidden()) then
		Controls.ChooseConfirm:SetHide(true);
	end
end
Events.GameplaySetActivePlayer.Add(OnActivePlayerChanged);

function OnDirty()
	if not bHidden then
		OnClose();
	end
end
Events.UnitSelectionChanged.Add( OnDirty );
