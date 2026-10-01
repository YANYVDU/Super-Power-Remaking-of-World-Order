INSERT INTO BuildingClasses (Type, Description, DefaultBuilding)
VALUES ('BUILDINGCLASS_CSUA', 'TXT_KEY_CITYSTATE_ALMATY', 'BUILDING_CSUA_ALMATY');

INSERT INTO Buildings (Type,BuildingClass,Help, Description, Cost,ConquestProb,HurryCostModifier,IconAtlas,PortraitIndex,NukeImmune)
VALUES  ('BUILDING_CSUA_ALMATY', 'BUILDINGCLASS_CSUA', 'TXT_KEY_BUILDING_CSUA_ALMATY_HELP', 'TXT_KEY_CITYSTATE_ALMATY', -1, 100, -1, 'BW_ATLAS_1', 19, 1);

-- Hormuz: fake building granting +20 oil to the city-state (shared with its ally via resource sharing)
INSERT INTO BuildingClasses (Type, Description, DefaultBuilding)
VALUES ('BUILDINGCLASS_CSUA_HORMUZ', 'TXT_KEY_CITYSTATE_ORMUS', 'BUILDING_CSUA_HORMUZ');

INSERT INTO Buildings (Type,BuildingClass,Help, Description, Cost,ConquestProb,HurryCostModifier,IconAtlas,PortraitIndex,NukeImmune)
VALUES  ('BUILDING_CSUA_HORMUZ', 'BUILDINGCLASS_CSUA_HORMUZ', 'TXT_KEY_BUILDING_CSUA_HORMUZ_HELP', 'TXT_KEY_CITYSTATE_ORMUS', -1, 100, -1, 'BW_ATLAS_1', 19, 1);

-- City-State Unique Ability Effects (Super Power V11)
UPDATE MinorCivilizations SET UAType = 'CSUA_ZURICH' WHERE Type = 'MINOR_CIV_ZURICH';
UPDATE MinorCivilizations SET UAType = 'CSUA_ANTWERP' WHERE Type = 'MINOR_CIV_ANTWERP';
UPDATE MinorCivilizations SET UAType = 'CSUA_FLORENCE' WHERE Type = 'MINOR_CIV_FLORENCE';
UPDATE MinorCivilizations SET UAType = 'CSUA_MALACCA' WHERE Type = 'MINOR_CIV_MALACCA';
UPDATE MinorCivilizations SET UAType = 'CSUA_PANAMA' WHERE Type = 'MINOR_CIV_PANAMA_CITY';
UPDATE MinorCivilizations SET UAType = 'CSUA_BRUSSELS' WHERE Type = 'MINOR_CIV_BRUSSELS';
UPDATE MinorCivilizations SET UAType = 'CSUA_COLOMBO' WHERE Type = 'MINOR_CIV_COLOMBO';
UPDATE MinorCivilizations SET UAType = 'CSUA_DUBAI' WHERE Type = 'MINOR_CIV_HONG_KONG';
UPDATE MinorCivilizations SET UAType = 'CSUA_VALLETTA' WHERE Type = 'MINOR_CIV_VALLETTA';
UPDATE MinorCivilizations SET UAType = 'CSUA_MELBOURNE' WHERE Type = 'MINOR_CIV_MELBOURNE';
UPDATE MinorCivilizations SET UAType = 'CSUA_ANTANANARIVO' WHERE Type = 'MINOR_CIV_ANTANANARIVO';
UPDATE MinorCivilizations SET UAType = 'CSUA_PRAGUE' WHERE Type = 'MINOR_CIV_PRAGUE';
UPDATE MinorCivilizations SET UAType = 'CSUA_CAHOKIA' WHERE Type = 'MINOR_CIV_CAHOKIA';
UPDATE MinorCivilizations SET UAType = 'CSUA_SAMARKAND' WHERE Type = 'MINOR_CIV_SAMARKAND';
UPDATE MinorCivilizations SET UAType = 'CSUA_ZANZIBAR' WHERE Type = 'MINOR_CIV_ZANZIBAR';
UPDATE MinorCivilizations SET UAType = 'CSUA_BYBLOS' WHERE Type = 'MINOR_CIV_BYBLOS';
UPDATE MinorCivilizations SET UAType = 'CSUA_WELLINGTON' WHERE Type = 'MINOR_CIV_WELLINGTON';
UPDATE MinorCivilizations SET UAType = 'CSUA_CAPE_TOWN' WHERE Type = 'MINOR_CIV_CAPE_TOWN';
UPDATE MinorCivilizations SET UAType = 'CSUA_GENOA' WHERE Type = 'MINOR_CIV_GENOA';
UPDATE MinorCivilizations SET UAType = 'CSUA_JERUSALEM' WHERE Type = 'MINOR_CIV_JERUSALEM';
UPDATE MinorCivilizations SET UAType = 'CSUA_VATICAN' WHERE Type = 'MINOR_CIV_VATICAN_CITY';
UPDATE MinorCivilizations SET UAType = 'CSUA_VILNIUS' WHERE Type = 'MINOR_CIV_VILNIUS';
UPDATE MinorCivilizations SET UAType = 'CSUA_SOFIA' WHERE Type = 'MINOR_CIV_SOFIA';
UPDATE MinorCivilizations SET UAType = 'CSUA_SIDON' WHERE Type = 'MINOR_CIV_SIDON';
UPDATE MinorCivilizations SET UAType = 'CSUA_GANGTOK' WHERE Type = 'MINOR_CIV_LHASA';
UPDATE MinorCivilizations SET UAType = 'CSUA_WITTENBERG' WHERE Type = 'MINOR_CIV_WITTENBERG';
UPDATE MinorCivilizations SET UAType = 'CSUA_LAVENTA' WHERE Type = 'MINOR_CIV_LA_VENTA';
UPDATE MinorCivilizations SET UAType = 'CSUA_KATHMANDU' WHERE Type = 'MINOR_CIV_KATHMANDU';
UPDATE MinorCivilizations SET UAType = 'CSUA_GENEVA' WHERE Type = 'MINOR_CIV_GENEVA';
UPDATE MinorCivilizations SET UAType = 'CSUA_SYDNEY' WHERE Type = 'MINOR_CIV_SYDNEY';
UPDATE MinorCivilizations SET UAType = 'CSUA_HORMUZ' WHERE Type = 'MINOR_CIV_ORMUS';
UPDATE MinorCivilizations SET UAType = 'CSUA_VANCOUVER' WHERE Type = 'MINOR_CIV_VANCOUVER';
UPDATE MinorCivilizations SET UAType = 'CSUA_IFE' WHERE Type = 'MINOR_CIV_IFE';
UPDATE MinorCivilizations SET UAType = 'CSUA_YEREVAN' WHERE Type = 'MINOR_CIV_YEREVAN';
UPDATE MinorCivilizations SET UAType = 'CSUA_BOGOTA' WHERE Type = 'MINOR_CIV_BOGOTA';
UPDATE MinorCivilizations SET UAType = 'CSUA_BRATISLAVA' WHERE Type = 'MINOR_CIV_BRATISLAVA';
UPDATE MinorCivilizations SET UAType = 'CSUA_RIGA' WHERE Type = 'MINOR_CIV_RIGA';
UPDATE MinorCivilizations SET UAType = 'CSUA_MANILA' WHERE Type = 'MINOR_CIV_MANILA';
UPDATE MinorCivilizations SET UAType = 'CSUA_BUCHAREST' WHERE Type = 'MINOR_CIV_BUCHAREST';
UPDATE MinorCivilizations SET UAType = 'CSUA_KIEV' WHERE Type = 'MINOR_CIV_KIEV';
UPDATE MinorCivilizations SET UAType = 'CSUA_KUALA_LUMPUR' WHERE Type = 'MINOR_CIV_KUALA_LUMPUR';
UPDATE MinorCivilizations SET UAType = 'CSUA_SINGAPORE' WHERE Type = 'MINOR_CIV_SINGAPORE';
UPDATE MinorCivilizations SET UAType = 'CSUA_TYRE' WHERE Type = 'MINOR_CIV_TYRE';
UPDATE MinorCivilizations SET UAType = 'CSUA_UR' WHERE Type = 'MINOR_CIV_UR';
UPDATE MinorCivilizations SET UAType = 'CSUA_MOMBASA' WHERE Type = 'MINOR_CIV_MOMBASA';
UPDATE MinorCivilizations SET UAType = 'CSUA_MOGADISHU' WHERE Type = 'MINOR_CIV_MOGADISHU';
UPDATE MinorCivilizations SET UAType = 'CSUA_QUEBEC' WHERE Type = 'MINOR_CIV_QUEBEC_CITY';
UPDATE MinorCivilizations SET UAType = 'CSUA_BELGRADE' WHERE Type = 'MINOR_CIV_BELGRADE';
UPDATE MinorCivilizations SET UAType = 'CSUA_BUDAPEST' WHERE Type = 'MINOR_CIV_BUDAPEST';
UPDATE MinorCivilizations SET UAType = 'CSUA_HANOI' WHERE Type = 'MINOR_CIV_HANOI';
UPDATE MinorCivilizations SET UAType = 'CSUA_MBANZA_KONGO' WHERE Type = 'MINOR_CIV_MBANZA_KONGO';
UPDATE MinorCivilizations SET UAType = 'CSUA_RAGUSA' WHERE Type = 'MINOR_CIV_RAGUSA';
UPDATE MinorCivilizations SET UAType = 'CSUA_KABUL' WHERE Type = 'MINOR_CIV_KABUL';
UPDATE MinorCivilizations SET UAType = 'CSUA_MILAN' WHERE Type = 'MINOR_CIV_MILAN';
UPDATE MinorCivilizations SET UAType = 'CSUA_MONACO' WHERE Type = 'MINOR_CIV_MONACO';
UPDATE MinorCivilizations SET UAType = 'CSUA_KYZYL' WHERE Type = 'MINOR_CIV_KYZYL';
UPDATE MinorCivilizations SET UAType = 'CSUA_BUENOS_AIRES' WHERE Type = 'MINOR_CIV_BUENOS_AIRES';

-- Yerevan CS UA: +1 culture to ANY improved plot that borders a holy site (per-ImprovementType rows).
-- Mirror of SP_AdjacentImprovementYieldChangesForNewImproments (NewSpecialistRule.sql): fully enumerate
-- every Improvement here and auto-add rows for any future Improvement INSERT via an AFTER INSERT trigger,
-- so ImprovementType is always a concrete type (strict match, no wildcard).
-- Runs after CSUA.xml in load order, so EFFECT_CSUA_YEREVAN_ALLY already exists (FK-safe).
INSERT INTO CityStateUAEffect_AdjacentImprovementYieldChanges(EffectType,ImprovementType,AdjacentImprovementType,YieldType,Yield)
SELECT 'EFFECT_CSUA_YEREVAN_ALLY', Type, 'IMPROVEMENT_HOLY_SITE', 'YIELD_CULTURE', 1
FROM Improvements
WHERE Type != 'IMPROVEMENT_INCA_CITY' AND Type NOT LIKE 'IMPROVEMENT_POLYNESIA_CITY_%';

CREATE TRIGGER IF NOT EXISTS SP_CSUA_YerevanAdjacentForNewImprovements
AFTER INSERT ON Improvements
WHEN New.Type != 'IMPROVEMENT_INCA_CITY' AND New.Type NOT LIKE 'IMPROVEMENT_POLYNESIA_CITY_%'
BEGIN
	INSERT INTO CityStateUAEffect_AdjacentImprovementYieldChanges(EffectType,ImprovementType,AdjacentImprovementType,YieldType,Yield)
	VALUES ('EFFECT_CSUA_YEREVAN_ALLY', New.Type, 'IMPROVEMENT_HOLY_SITE', 'YIELD_CULTURE', 1);
END;

-- Ur CS UA: each national wonder owned grants the city that holds it +5% science and +5% production
-- (city-level; consumed in CvCity::GetBaseYieldRateModifier via CityStateUAEffect_BuildingClassYieldModifiers).
-- "National wonder" is a per-player limited building class: MaxPlayerInstances > 0 (NULL compares false in
-- SQLite, so dummy classes with no limit set are excluded). This is the same set as isNationalWonderClass,
-- so it matches the Kiev national-wonder count (the palace and the SP specialist dummy classes are included
-- by design).
-- Runs after CSUA.xml in load order, so EFFECT_CSUA_UR_ALLY already exists (FK-safe).
INSERT INTO CityStateUAEffect_BuildingClassYieldModifiers(EffectType,BuildingClassType,YieldType,YieldMod)
SELECT 'EFFECT_CSUA_UR_ALLY', Type, 'YIELD_SCIENCE', 5
FROM BuildingClasses
WHERE MaxPlayerInstances > 0;

INSERT INTO CityStateUAEffect_BuildingClassYieldModifiers(EffectType,BuildingClassType,YieldType,YieldMod)
SELECT 'EFFECT_CSUA_UR_ALLY', Type, 'YIELD_PRODUCTION', 5
FROM BuildingClasses
WHERE MaxPlayerInstances > 0;

-- Ur CS UA: the enumeration above only covers building classes that already exist when this file runs,
-- so add rows for any national-wonder class inserted afterwards (a new national wonder added by another
-- mod/file would otherwise silently miss the +5%). Mirrors the Yerevan trigger above.
CREATE TRIGGER IF NOT EXISTS SP_CSUA_UrNationalWonderForNewBuildingClasses
AFTER INSERT ON BuildingClasses
WHEN New.MaxPlayerInstances > 0
BEGIN
	INSERT INTO CityStateUAEffect_BuildingClassYieldModifiers(EffectType,BuildingClassType,YieldType,YieldMod)
	VALUES ('EFFECT_CSUA_UR_ALLY', New.Type, 'YIELD_SCIENCE', 5);
	INSERT INTO CityStateUAEffect_BuildingClassYieldModifiers(EffectType,BuildingClassType,YieldType,YieldMod)
	VALUES ('EFFECT_CSUA_UR_ALLY', New.Type, 'YIELD_PRODUCTION', 5);
END;

-- MinorCivAlliesThresholdExtra: per-era ally threshold increase (Rule 8)
-- Formula: threshold = FRIENDSHIP_THRESHOLD_ALLIES(60) + MinorCivAlliesThresholdExtra
UPDATE Eras SET MinorCivAlliesThresholdExtra = 0   WHERE Type = 'ERA_ANCIENT';     --  60 - 60 = 0
UPDATE Eras SET MinorCivAlliesThresholdExtra = 30  WHERE Type = 'ERA_CLASSICAL';    --  90 - 60 = 30
UPDATE Eras SET MinorCivAlliesThresholdExtra = 90  WHERE Type = 'ERA_MEDIEVAL';     -- 150 - 60 = 90
UPDATE Eras SET MinorCivAlliesThresholdExtra = 180 WHERE Type = 'ERA_RENAISSANCE';  -- 240 - 60 = 180
UPDATE Eras SET MinorCivAlliesThresholdExtra = 240 WHERE Type = 'ERA_INDUSTRIAL';   -- 300 - 60 = 240
UPDATE Eras SET MinorCivAlliesThresholdExtra = 340 WHERE Type = 'ERA_MODERN';       -- 400 - 60 = 340
UPDATE Eras SET MinorCivAlliesThresholdExtra = 440 WHERE Type = 'ERA_WORLDWAR';     -- 500 - 60 = 440
UPDATE Eras SET MinorCivAlliesThresholdExtra = 540 WHERE Type = 'ERA_POSTMODERN';   -- 600 - 60 = 540
UPDATE Eras SET MinorCivAlliesThresholdExtra = 690 WHERE Type = 'ERA_INFORMATION';  -- 750 - 60 = 690
UPDATE Eras SET MinorCivAlliesThresholdExtra = 840 WHERE Type = 'ERA_FUTURE';       -- 900 - 60 = 840