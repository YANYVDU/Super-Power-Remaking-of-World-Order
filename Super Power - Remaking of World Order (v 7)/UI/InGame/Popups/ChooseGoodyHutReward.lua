-------------------------------------------------
-- Choose Faith Great Person Popup
-------------------------------------------------
include("IconSupport");
include("InfoTooltipInclude");

-- This global table handles how items are populated based on an identifier.
g_NumberOfFreeItems = 0;
local m_PopupInfo = nil;
local pPlayer = nil;
local pUnit = nil;
local pPlot = nil;
PopulateItems = {};
CommitItems = {};
SelectedItems = {};

-- Multiplayer fallback for the goody hut reward picker.
-- In network MP only the owner's client shows this popup while every other client waits for
-- Network.SendGoodyChoice. The DLL pre-rolls a reward on every client and hands it over as popup
-- Data3 (-1 when there is no fallback: single player, hotseat, PBEM or an older DLL). If the owner
-- never confirms we broadcast that pre-rolled reward instead, so the goody is never silently lost
-- and the turn cannot stay blocked waiting for a choice that will never come.
local m_iFallbackGoody = -1;
local m_bResolved = false;
local m_iOpenedAt = 0;
local GOODY_CHOICE_TIMEOUT_SECONDS = 30;

-- Broadcasts the pre-rolled fallback reward. Safe to call repeatedly: only the first call goes out.
-- Deliberately does not hide the popup here; the caller decides whether the popup is already closing.
local function PickFallback()
	if(m_bResolved) then
		return;
	end
	if(m_iFallbackGoody < 0 or pUnit == nil or pPlot == nil) then
		return;
	end

	m_bResolved = true;
	Network.SendGoodyChoice(m_PopupInfo.Data1, pPlot:GetX(), pPlot:GetY(), m_iFallbackGoody, pUnit:GetID());
end

-- Timeout ticker. Only does work while the popup is actually up.
local function OnGoodyChoiceUpdate()
	if(ContextPtr:IsHidden()) then
		return;
	end
	if(m_bResolved or m_iFallbackGoody < 0) then
		return;
	end

	if(os.time() - m_iOpenedAt >= GOODY_CHOICE_TIMEOUT_SECONDS) then
		PickFallback();
		ContextPtr:SetHide(true);
	end
end
ContextPtr:SetUpdate(OnGoodyChoiceUpdate);

PopulateItems["GoodyHutBonuses"] = function(stackControl, playerID)

	local count = 0;
	Controls.TitleLabel:LocalizeAndSetText("TXT_KEY_CHOOSE_GOODY_HUT_BONUS_TITLE");
	Controls.DescriptionLabel:LocalizeAndSetText("TXT_KEY_CHOOSE_GOODY_HUT_BONUS_DESCRIPTION");
	SelectedItems = {};
	stackControl:DestroyAllChildren();

	local iIndex = 0;

	for info in GameInfo.GoodyHuts() do
		local iGoodyType = iIndex;
		if (pPlayer:CanGetGoody(pPlot, iGoodyType, pUnit)) then
			local controlTable = {};
			ContextPtr:BuildInstanceForControl( "ItemInstance", controlTable, stackControl );
			controlTable.Name:LocalizeAndSetText(info.ChooseDescription);

			local selectionAnim = controlTable.SelectionAnim;

			controlTable.Button:RegisterCallback(Mouse.eLClick, function()

				local foundIndex = nil;
				for i,v in ipairs(SelectedItems) do
					if(v[1] == iGoodyType) then
						foundIndex = i;
						break;
					end
				end

				if(foundIndex ~= nil) then
					if(g_NumberOfFreeItems > 1) then
						selectionAnim:SetHide(true);
						table.remove(SelectedItems, foundIndex);
					end
				else
					if(g_NumberOfFreeItems > 1) then
						if(#SelectedItems < g_NumberOfFreeItems) then
							selectionAnim:SetHide(false);
							table.insert(SelectedItems, {iGoodyType, controlTable});
						end
					else
						if(#SelectedItems > 0) then
							for i,v in ipairs(SelectedItems) do
								v[2].SelectionAnim:SetHide(true);
							end
							SelectedItems = {};
						end

						selectionAnim:SetHide(false);
						table.insert(SelectedItems, {iGoodyType, controlTable});
					end
				end

				Controls.ConfirmButton:SetDisabled(g_NumberOfFreeItems ~= #SelectedItems);

			end);

			count = count + 1;
		end
		iIndex = iIndex + 1;
	end

	return count;
end

CommitItems["GoodyHutBonuses"] = function(selection, playerID)

	local activePlayer = Players[playerID];
	if(activePlayer ~= nil) then
		for i,v in ipairs(selection) do
			local iGoodyType = v[1];
			print("Unit: " .. pUnit:GetID());
			Network.SendGoodyChoice(playerID, pPlot:GetX(), pPlot:GetY(), iGoodyType, pUnit:GetID());
		end
	end
end

function DisplayPopup(playerID, classType, numberOfFreeItems)

	if(numberOfFreeItems ~= 1) then
		error("This UI currently only supports 1 free item for the time being.");
	end

	local count = PopulateItems[classType](Controls.ItemStack, playerID);

	Controls.ItemStack:CalculateSize();
	Controls.ItemStack:ReprocessAnchoring();
	Controls.ItemScrollPanel:CalculateInternalSize();

	if(count > 0 and numberOfFreeItems > 0) then
		g_NumberOfFreeItems = math.min(numberOfFreeItems, count);
		Controls.ConfirmButton:SetDisabled(true);
		ContextPtr:SetHide(false);
	else
		ContextPtr:SetHide(true);
	end

	Controls.ConfirmButton:RegisterCallback(Mouse.eLClick, function()
		if(m_bResolved) then
			return;
		end
		-- Mark resolved before committing so the timeout ticker and the hide handler cannot also
		-- fire the fallback pick for this same goody.
		m_bResolved = true;
		CommitItems[classType](SelectedItems, playerID);
		ContextPtr:SetHide(true);
	end);
end


function OnPopup( popupInfo )
    if( popupInfo.Type == ButtonPopupTypes.BUTTONPOPUP_CHOOSE_GOODY_HUT_REWARD and ContextPtr:IsHidden() == true ) then
        m_PopupInfo = popupInfo;
        pPlayer = Players[popupInfo.Data1];
		pUnit = pPlayer:GetUnitByID(m_PopupInfo.Data2);
		pPlot = pUnit:GetPlot();

		m_iFallbackGoody = popupInfo.Data3 or -1;
		m_bResolved = false;
		m_iOpenedAt = os.time();

        DisplayPopup(m_PopupInfo.Data1, "GoodyHutBonuses", 1);
    end
end
Events.SerialEventGameMessagePopup.Add( OnPopup );

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function ShowHideHandler( bIsHide, bInitState )

    if( not bInitState ) then
        if( not bIsHide ) then
        	UI.incTurnTimerSemaphore();
        	Events.SerialEventGameMessagePopupShown(m_PopupInfo);
        else
			-- Dismissed without a pick (e.g. the active player changed) - fall back to the pre-rolled
			-- reward so the goody is not lost and no client is left waiting on a choice.
			PickFallback();
            UI.decTurnTimerSemaphore();
            Events.SerialEventGameMessagePopupProcessed.CallImmediate(ButtonPopupTypes.BUTTONPOPUP_CHOOSE_GOODY_HUT_REWARD, 0);
        end
    end
end
ContextPtr:SetShowHideHandler( ShowHideHandler );

----------------------------------------------------------------
-- 'Active' (local human) player has changed
----------------------------------------------------------------
function OnActivePlayerChanged( iActivePlayer, iPrevActivePlayer )
	if (not ContextPtr:IsHidden()) then
		ContextPtr:SetHide(true);
	end
end
Events.GameplaySetActivePlayer.Add(OnActivePlayerChanged);
