-- Spy points system: per-turn spy point sources on buildings / policies / beliefs / traits
-- Aggregated every turn by MPDLL CvPlayer::GetSpyPointsPerTurn() -> ChangeSpyPoints()
-- Threshold progression (base 100, +50 per spy) from Gameplay defines SPY_POINTS_THRESHOLD_BASE / _INCREASE

ALTER TABLE Buildings ADD COLUMN SpyPoints integer default 0;
ALTER TABLE Policies ADD COLUMN SpyPoints integer default 0;
ALTER TABLE Beliefs ADD COLUMN SpyPoints integer default 0;
ALTER TABLE Traits ADD COLUMN SpyPoints integer default 0;

INSERT INTO Defines(Name, Value) VALUES('SPY_POINTS_THRESHOLD_BASE', 100);
INSERT INTO Defines(Name, Value) VALUES('SPY_POINTS_THRESHOLD_INCREASE', 50);
