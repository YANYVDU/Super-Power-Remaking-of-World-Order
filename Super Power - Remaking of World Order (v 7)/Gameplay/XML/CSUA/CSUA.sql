-- City-State Unique Ability Effects (Super Power V11)
UPDATE MinorCivilizations SET UAType = 'CSUA_ZURICH' WHERE Type = 'MINOR_CIV_ZURICH';
UPDATE MinorCivilizations SET UAType = 'CSUA_ANTWERP' WHERE Type = 'MINOR_CIV_ANTWERP';

-- MinorCivAlliesThresholdExtra: per-era ally threshold increase (Rule 8)
-- Formula: threshold = FRIENDSHIP_THRESHOLD_ALLIES(60) + MinorCivAlliesThresholdExtra
-- 远古60, 古典90, 中古150, 启蒙240, 工业300, 电气400, 全战500, 原子600, 信息750, 未来900
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