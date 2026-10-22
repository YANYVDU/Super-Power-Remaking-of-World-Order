-------------------------------------------------
-- Bombardment
--
-- Based on the base game Assets/UI/InGame/Bombardment.lua.
-- Local changes:
--   * SP_CanUseBoxWalk / SP_ForEachPlotInRange: shared range iteration that
--     falls back to a full-map scan when plotXY wrapping would feed duplicate
--     highlights to the engine. Also used by InGame.lua.
--   * RangedStrikeHighlight: the city range comes from GetBombardRange() so
--     the preview matches the actual shot.
-------------------------------------------------

local redColor = Vector4( 0.7, 0, 0, 1 );
local highlightColor = Vector4( 0.7, 0.7, 0, 1 ); -- depending on the theme these may not actually be used (for example SplineBorder do not)
local ms_CityBombardPlayer = -1;
local ms_CityBombardID = -1;

-------------------------------------------------
-- Shared range iteration, also used by InGame.lua (which includes this file).
-- A (2*range+1)^2 box walk is far cheaper than scanning every plot, but
-- Map.GetPlotXY treats dx as a hexspace offset and wraps out-of-bounds
-- coordinates: a range close to the map size revisits the same plots over and
-- over and floods the engine hex-highlight system, which crashes the game.
-- Fall back to a single full-map scan whenever the box is unsafe or would
-- visit more plots than the map has.
function SP_CanUseBoxWalk(iRange)
	local iPlotCount = (iRange * 2 + 1) * (iRange * 2 + 1);
	if iPlotCount >= Map.GetNumPlots() then
		return false;
	end
	local iWidth, iHeight = Map.GetGridSize();
	-- Within one row the box spans 2*range+1 columns. On a wrapping axis that
	-- span repeats plots as soon as it exceeds the axis length (2*range >=
	-- width); rows never collide with each other because plotY stays unique
	-- until the Y axis itself wraps.
	if Map.IsWrapX() and iRange * 2 >= iWidth then
		return false;
	end
	if Map.IsWrapY() and iRange * 2 >= iHeight then
		return false;
	end
	return true;
end

function SP_ForEachPlotInRange(iX, iY, iRange, fn)
	-- GetPlotXY reads dx through lua_tointeger, which truncates; a float range
	-- would repeat and skip columns, so normalise once at the shared entry.
	iRange = math.floor(iRange);

	if SP_CanUseBoxWalk(iRange) then
		for iDX = -iRange, iRange, 1 do
			for iDY = -iRange, iRange, 1 do
				local pPlot = Map.GetPlotXY(iX, iY, iDX, iDY);
				if pPlot ~= nil then
					fn(pPlot);
				end
			end
		end
	else
		for iPlotLoop = 0, Map.GetNumPlots() - 1, 1 do
			local pPlot = Map.GetPlotByIndex(iPlotLoop);
			if pPlot ~= nil then
				fn(pPlot);
			end
		end
	end
end

local function HighlightPlotsInRange( pAttacker, pSourcePlot, iSourceX, iSourceY, eTeam, iRange, bIndirectFireAllowed, bDomainOnly, sMode )
	local NO_DIRECTION = -1;

	local function ProcessPlot(pTargetPlot)
		if pTargetPlot == nil then
			return;
		end
		local plotX = pTargetPlot:GetX();
		local plotY = pTargetPlot:GetY();
		if Map.PlotDistance(iSourceX, iSourceY, plotX, plotY) > iRange then
			return;
		end
		local hexID = ToHexFromGrid( Vector2( plotX, plotY) );
		if sMode == "NUKE" then
			if pAttacker:CanNukeAt(plotX, plotY) then
				Events.SerialEventHexHighlight( hexID, true, highlightColor, "FireRangeBorder" );
			end
		else
			local bCanRangeStrike = true;
			if sMode == "RANGED" then
				if not bIndirectFireAllowed then
					if not pSourcePlot:CanSeePlot(pTargetPlot, eTeam, iRange - 1, NO_DIRECTION) then
						bCanRangeStrike = false;
					end
				end
				if bDomainOnly then
					if pAttacker:GetDomainType() == DomainTypes.DOMAIN_LAND and pTargetPlot:IsWater() then
						bCanRangeStrike = false;
					elseif pAttacker:GetDomainType() == DomainTypes.DOMAIN_SEA and not pTargetPlot:IsWater() then
						bCanRangeStrike = false;
					end
				end
				if bCanRangeStrike and not pTargetPlot:IsVisible(eTeam, false) then
					bCanRangeStrike = false;
				end
			end
			if bCanRangeStrike then
				if pAttacker:CanRangeStrikeAt(plotX, plotY) then
					Events.SerialEventHexHighlight( hexID, true, highlightColor, "FireRangeBorder" );
					Events.SerialEventHexHighlight( hexID, true, redColor, "ValidFireTargetBorder");
				else
					Events.SerialEventHexHighlight( hexID, true, highlightColor, "FireRangeBorder" );
				end
			end
		end
	end

	SP_ForEachPlotInRange(iSourceX, iSourceY, iRange, ProcessPlot);
end

function RangedStrikeHighlight()
	local pHeadSelectedCity = UI.GetHeadSelectedCity();
	local pHeadSelectedUnit = UI.GetHeadSelectedUnit();
	local thingThatCanActuallyFire = nil;

	local iRange;
	local bIndirectFireAllowed;
	local bDomainOnly;
	local thisPlot = nil;
	local thisX;
	local thisY;
	local thisTeam;

	if pHeadSelectedCity and pHeadSelectedCity:CanRangeStrike() then
		-- Use the city's effective bombard range so previews match the real shot.
		local iCityRange, iCityIndirectFire = pHeadSelectedCity:GetBombardRange();
		iRange = iCityRange;
		bIndirectFireAllowed = (iCityIndirectFire == 1);
		thisPlot = pHeadSelectedCity:Plot();
		thisX = pHeadSelectedCity:GetX();
		thisY = pHeadSelectedCity:GetY();
		thisTeam = pHeadSelectedCity:GetTeam();
		thingThatCanActuallyFire = pHeadSelectedCity;
		bDomainOnly = false;
	elseif pHeadSelectedUnit and pHeadSelectedUnit:CanRangeStrike() then
		iRange = pHeadSelectedUnit:Range();
		bIndirectFireAllowed = pHeadSelectedUnit:IsRangeAttackIgnoreLOS();
		thisPlot = pHeadSelectedUnit:GetPlot();
		thisX = pHeadSelectedUnit:GetX();
		thisY = pHeadSelectedUnit:GetY();
		thisTeam = pHeadSelectedUnit:GetTeam();
		thingThatCanActuallyFire = pHeadSelectedUnit;
		bDomainOnly = pHeadSelectedUnit:IsRangeAttackOnlyInDomain();
	end
	if thingThatCanActuallyFire ~= nil and thisPlot then
		-- highlight the bombardable plots
		HighlightPlotsInRange( thingThatCanActuallyFire, thisPlot, thisX, thisY, thisTeam, iRange, bIndirectFireAllowed, bDomainOnly, "RANGED" );
	end
end

-------------------------------------------------
function AirStrikeHighlight()
	local pHeadSelectedUnit = UI.GetHeadSelectedUnit();
	local thingThatCanActuallyFire = nil;

	local iRange;
	local thisPlot;
	local thisX;
	local thisY;
	local thisTeam;

	if pHeadSelectedUnit and pHeadSelectedUnit:CanRangeStrike() then
		iRange = pHeadSelectedUnit:Range();
		thisPlot = pHeadSelectedUnit:GetPlot();
		thisX = pHeadSelectedUnit:GetX();
		thisY = pHeadSelectedUnit:GetY();
		thisTeam = pHeadSelectedUnit:GetTeam();
		thingThatCanActuallyFire = pHeadSelectedUnit;
	end
	if thingThatCanActuallyFire ~= nil then
		-- highlight the bombardable plots
		HighlightPlotsInRange( thingThatCanActuallyFire, thisPlot, thisX, thisY, thisTeam, iRange, false, false, "AIR" );
	end
end



-------------------------------------------------
function NukeStrikeHighlight()
	local pHeadSelectedUnit = UI.GetHeadSelectedUnit();
	local thingThatCanActuallyFire = nil;

	local iRange;
	local thisPlot;
	local thisX;
	local thisY;
	local thisTeam;

	if pHeadSelectedUnit and pHeadSelectedUnit:CanNuke() then
		iRange = pHeadSelectedUnit:Range();
		thisPlot = pHeadSelectedUnit:GetPlot();
		thisX = pHeadSelectedUnit:GetX();
		thisY = pHeadSelectedUnit:GetY();
		thisTeam = pHeadSelectedUnit:GetTeam();
		thingThatCanActuallyFire = pHeadSelectedUnit;
	end
	if thingThatCanActuallyFire ~= nil then
		-- highlight the nukable plots
		HighlightPlotsInRange( thingThatCanActuallyFire, thisPlot, thisX, thisY, thisTeam, iRange, false, false, "NUKE" );
	end
end


-------------------------------------------------
function DisplayBombardArrow( hexX, hexY )
	--find the selected attacker
	local unit = UI.GetHeadSelectedUnit();
	local city = UI.GetHeadSelectedCity();
	local attacker;
	if city and city:CanRangeStrike() then
		attacker = city;
	elseif unit and unit:CanRangeStrike() then
		attacker = unit
	end
	
	if attacker == nil then
		return
	end
	
	--get bombard end hex
	if attacker:CanRangeStrikeAt( hexX, hexY ) then
		Events.SpawnArrowEvent( attacker:GetX(), attacker:GetY(), hexX, hexY );
	else
		Events.RemoveAllArrowsEvent();
	end
	
end


-------------------------------------------------
function DisplayNukeArrow( hexX, hexY )
	--find the selected attacker
	local unit = UI.GetHeadSelectedUnit();
	local attacker;
	if unit and unit:CanNuke() then
		attacker = unit
	end
	
	if attacker == nil then
		return
	end
	
	--get bombard end hex
	if attacker:CanNukeAt( hexX, hexY ) then
		Events.SpawnArrowEvent( attacker:GetX(), attacker:GetY(), hexX, hexY );
	else
		Events.RemoveAllArrowsEvent();
	end
	
end


-------------------------------------------------
function BeginRangedAttack()
	local pHeadSelectedCity = UI.GetHeadSelectedCity();
	local pHeadSelectedUnit = UI.GetHeadSelectedUnit();
	
	-- Validate the Interface Mode
	local interfaceMode = UI.GetInterfaceMode();
	if (interfaceMode == InterfaceModeTypes.INTERFACEMODE_CITY_RANGE_ATTACK) then
		if (pHeadSelectedCity == nil) then
			UI.SetInterfaceMode(InterfaceModeTypes.INTERFACEMODE_SELECTION);
			return;
		else
			-- Keep track of the city, in case the selection changes
			ms_CityBombardPlayer = pHeadSelectedCity:GetOwner();
			ms_CityBombardID = pHeadSelectedCity:GetID();
		end
	end

	if (interfaceMode == InterfaceModeTypes.INTERFACEMODE_RANGE_ATTACK) then
		if (pHeadSelectedUnit == nil) then
			UI.SetInterfaceMode(InterfaceModeTypes.INTERFACEMODE_SELECTION);
			return;
		end
	end
	
	if (pHeadSelectedCity and pHeadSelectedCity:CanRangeStrike()) or (pHeadSelectedUnit and pHeadSelectedUnit:CanRangeStrike()) then
		Events.SerialEventMouseOverHex.Add( DisplayBombardArrow );
		RangedStrikeHighlight();
	end

end

-------------------------------------------------
function OnCityInfoDirty()
	local interfaceMode = UI.GetInterfaceMode();
	if (interfaceMode == InterfaceModeTypes.INTERFACEMODE_CITY_RANGE_ATTACK) then
		local pHeadSelectedCity = UI.GetHeadSelectedCity();
		-- Still selected?
		if (pHeadSelectedCity == nil) then
			UI.SetInterfaceMode(InterfaceModeTypes.INTERFACEMODE_SELECTION);
			return;
		end
		-- Same city?
		if (pHeadSelectedCity:GetOwner() ~= ms_CityBombardPlayer or pHeadSelectedCity:GetID() ~= ms_CityBombardID) then
			UI.SetInterfaceMode(InterfaceModeTypes.INTERFACEMODE_SELECTION);
		end
	end
end
Events.SerialEventCityInfoDirty.Add(OnCityInfoDirty);

-------------------------------------------------
function EndRangedAttack()
	Events.RemoveAllArrowsEvent();
	Events.SerialEventMouseOverHex.Remove( DisplayBombardArrow );
	ClearUnitHexHighlights();
end

-------------------------------------------------
function BeginAirAttack()
	local pHeadSelectedUnit = UI.GetHeadSelectedUnit();
	
	if (pHeadSelectedUnit and pHeadSelectedUnit:CanRangeStrike()) then
		Events.SerialEventMouseOverHex.Add( DisplayBombardArrow );
		AirStrikeHighlight();
	end

end

-------------------------------------------------
function EndAirAttack()
	Events.RemoveAllArrowsEvent();
	Events.SerialEventMouseOverHex.Remove( DisplayBombardArrow );
	ClearUnitHexHighlights();
end

-------------------------------------------------
function BeginNukeAttack()
	local pHeadSelectedUnit = UI.GetHeadSelectedUnit();
	if (pHeadSelectedUnit and pHeadSelectedUnit:CanNuke()) then
		Events.SerialEventMouseOverHex.Add( DisplayNukeArrow );
		NukeStrikeHighlight();
	end

end

-------------------------------------------------
function EndNukeAttack()
	Events.RemoveAllArrowsEvent();
	Events.SerialEventMouseOverHex.Remove( DisplayNukeArrow );
	ClearUnitHexHighlights();
end