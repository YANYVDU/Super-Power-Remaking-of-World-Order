-- NewBuildingEffects
-----------New building effects when it is built
local AIBonusQuery = DB.CreateQuery("SELECT ID FROM Buildings WHERE BuildingClass = 'BUILDINGCLASS_ARMORY' OR BuildingClass = 'BUILDINGCLASS_ARSENAL';");
local AIBonusQueryTable = {}
for row in AIBonusQuery() do AIBonusQueryTable[row.ID] = true end
function NewBuildingEffects(iPlayer, iCity, iBuilding, bGold, bFaith)
	local player = Players[iPlayer];
	if player == nil or player:IsBarbarian() or player:IsMinorCiv() or player:GetNumCities() <= 0 then
		return;
	end
	local pCity = player:GetCityByID(iCity);
	if pCity == nil then
		return;
	end

	-- AI Bonus
	if AIBonusQueryTable[iBuilding] then
		if not player:IsHuman() then
			local MAID = GameInfoTypes.BUILDING_MILITARY_ACADEMY
			pCity:SetNumRealBuilding(MAID, 1)
			print("AI Free Military Academy!")
			if player:HasTrait(GameInfoTypes["TRAIT_FIGHT_WELL_DAMAGED"])
			then
				local DJID = GameInfoTypes.BUILDING_JAPANESE_DOJO
				pCity:SetNumRealBuilding(DJID, 1)
				print("Japan AI free Dojo!")
			end
		end

		-- Move Captial
	elseif iBuilding == GameInfoTypes.BUILDING_NEW_PALACE then
		print("New Captial Built!")
		local oCity = player:GetCapitalCity();
		pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_NEW_PALACE"], 0);

		if oCity ~= nil then
			-- CityName Change
			if oCity:GetName() == Locale.ConvertTextKey("TXT_KEY_CITY_NAME_SHENDU") then
				oCity:SetName("TXT_KEY_CITY_NAME_LOYANG");
			end
			if pCity:GetName() == Locale.ConvertTextKey("TXT_KEY_CITY_NAME_LOYANG") then
				pCity:SetName("TXT_KEY_CITY_NAME_SHENDU");
			end

			-- MoveMark
			oCity:SetNumRealBuilding(GameInfoTypes["BUILDING_CAPITAL_MOVEMARK"], 0)
			pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_CAPITAL_MOVEMARK"], 1)

			for building in GameInfo.Buildings() do
				-- Palace
				if oCity:IsHasBuilding(building.ID) and building.Capital then
					local i = oCity:GetNumBuilding(building.ID);
					oCity:SetNumRealBuilding(building.ID, 0);
					pCity:SetNumRealBuilding(building.ID, i);
				end

				-- Remove "Corrupt" from New
				if pCity:IsHasBuilding(building.ID)
					and (building.BuildingClass == "BUILDINGCLASS_CITY_HALL_LV1"
						or building.BuildingClass == "BUILDINGCLASS_CITY_HALL_LV2"
						or building.BuildingClass == "BUILDINGCLASS_CITY_HALL_LV3"
						or building.BuildingClass == "BUILDINGCLASS_CITY_HALL_LV4"
						or building.BuildingClass == "BUILDINGCLASS_CITY_HALL_LV5"
						or building.BuildingClass == "BUILDINGCLASS_PUPPET_GOVERNEMENT"
						or building.BuildingClass == "BUILDINGCLASS_CONSTABLE"
						or building.BuildingClass == "BUILDINGCLASS_SHERIFF_OFFICE"
						or building.BuildingClass == "BUILDINGCLASS_POLICE_STATION"
						or building.BuildingClass == "BUILDINGCLASS_PROCURATORATE"
					) then
					pCity:SetNumRealBuilding(building.ID, 0);
				end

				-- Move Policy Buildings & Count Buildings
				local policFreeBCCapital = GameInfo.Policy_FreeBuildingClassCapital { BuildingClassType = building.BuildingClass } ()
				if oCity:IsHasBuilding(building.ID) and (policFreeBCCapital ~= nil) then
					local i = oCity:GetNumBuilding(building.ID);
					oCity:SetNumRealBuilding(building.ID, 0);
					pCity:SetNumRealBuilding(building.ID, i);
				end
			end
			print("Captial Moved!")
		end
	end
end ------Function End

GameEvents.CityConstructed.Add(NewBuildingEffects)

local ibRes_Man = GameInfoTypes["BUILDING_CIV_S_P_MAN_RESOURCES"]
local ibRes_Con = GameInfoTypes["BUILDING_CIV_S_P_CON_RESOURCES"]
local ibRes_Ele = GameInfoTypes["BUILDING_CIV_S_P_ELE_RESOURCES"]

function MinorProvideRes(iPlayerID)
	local pMinor  = Players[iPlayerID]
	if pMinor == nil or not pMinor:IsMinorCiv() or pMinor:GetCapitalCity() == nil or pMinor:GetAlly() < 0 then return end
	local pPlayer = Players[pMinor:GetAlly()]
	if pPlayer == nil then return end

	local iAllyEra = pPlayer:GetCurrentEra()
	local pCapital = pMinor:GetCapitalCity()
	
	-------------Minor Has Res-ManPower----------------------
	if iAllyEra >= 3 and pCapital:GetNumBuilding(ibRes_Man) < 10 then
		pCapital:SetNumRealBuilding(ibRes_Man, 10)
	elseif iAllyEra == 2 and pCapital:GetNumBuilding(ibRes_Man) < 6 then
		pCapital:SetNumRealBuilding(ibRes_Man, 6)
	elseif iAllyEra == 1 and pCapital:GetNumBuilding(ibRes_Man) < 3 then
		pCapital:SetNumRealBuilding(ibRes_Man, 3)
	elseif iAllyEra == 0 and pCapital:GetNumBuilding(ibRes_Man) < 2 then
		pCapital:SetNumRealBuilding(ibRes_Man, 2)
	end
	----------------Minor Has Res-Consumer----------------------
	if iAllyEra >= 4 and pCapital:GetNumBuilding(ibRes_Con) < 12 then
		pCapital:SetNumRealBuilding(ibRes_Con, 12)
	elseif iAllyEra == 3 and pCapital:GetNumBuilding(ibRes_Con) < 9 then
		pCapital:SetNumRealBuilding(ibRes_Con, 9)
	elseif iAllyEra == 2 and pCapital:GetNumBuilding(ibRes_Con) < 6 then
		pCapital:SetNumRealBuilding(ibRes_Con, 6)
	elseif iAllyEra == 1 and pCapital:GetNumBuilding(ibRes_Con) < 4 then
		pCapital:SetNumRealBuilding(ibRes_Con, 4)
	end
	----------------Minor Has Res-Electricity----------------------
	if not pPlayer:HasPolicy(GameInfoTypes["POLICY_MILITARY_AID"]) then
		return;
	elseif iAllyEra > 6 and pCapital:GetNumBuilding(ibRes_Ele) < 8 then
		pCapital:SetNumRealBuilding(ibRes_Ele, 6)
	elseif iAllyEra > 4 and pCapital:GetNumBuilding(ibRes_Ele) < 4 then
		pCapital:SetNumRealBuilding(ibRes_Ele, 3)
	end
end
GameEvents.PlayerDoTurn.Add(MinorProvideRes)

print("New Building Effects Check Pass!")