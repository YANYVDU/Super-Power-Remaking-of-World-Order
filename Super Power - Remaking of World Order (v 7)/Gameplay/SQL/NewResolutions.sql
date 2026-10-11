--Cold War
INSERT INTO Resolutions(Type, Description, Help, EmbargoIdeology, VoterDecision, ProposerDecision, TechPrereqAnyMember)
SELECT 'RESOLUTION_COLD_WAR', 'TXT_KEY_RESOLUTION_COLD_WAR', 'TXT_KEY_RESOLUTION_COLD_WAR_HELP', 1, 'RESOLUTION_DECISION_YES_OR_NO', 'RESOLUTION_DECISION_NONE', 'TECH_ATOMIC_THEORY';

--War Convention
INSERT INTO Resolutions(Type, Description, Help, VoterDecision, ProposerDecision, TechPrereqAnyMember, GlobalAttackModifier, GlobalWarCasualtiesChanges)
SELECT 'RESOLUTION_WAR_CONVENTION', 'TXT_KEY_RESOLUTION_WAR_CONVENTION', 'TXT_KEY_RESOLUTION_WAR_CONVENTION_HELP', 'RESOLUTION_DECISION_YES_OR_NO', 'RESOLUTION_DECISION_NONE', 'TECH_ATOMIC_THEORY', -10, -20;

-- International Law Protection
-- Register the "choose a city-state" decision type. SP is the primary provider; the Tiandao mod
-- must remove its own copy to avoid a UNIQUE(Type) conflict. Explicit ID=10 aligns with the
-- RESOLUTION_DECISION_CITY_CSD enum value; SP loads before Tiandao (which depends on SP).
INSERT OR IGNORE INTO ResolutionDecisions (ID, Type, Description)
VALUES (10, 'RESOLUTION_DECISION_CITY_CSD', 'TXT_KEY_RESOLUTION_DECISION_CITY_CSD');

-- International law protection proposal: target a met city-state. While enacted, units at war with
-- that city-state and standing inside its territory may be attacked by any civ without declaring war.
INSERT INTO Resolutions(Type, Description, Help, VoterDecision, ProposerDecision, InternationalLawProtection)
SELECT 'RESOLUTION_INTERNATIONAL_LAW_PROTECTION', 'TXT_KEY_RESOLUTION_INTERNATIONAL_LAW_PROTECTION', 'TXT_KEY_RESOLUTION_INTERNATIONAL_LAW_PROTECTION_HELP', 'RESOLUTION_DECISION_YES_OR_NO', 'RESOLUTION_DECISION_CITY_CSD', 1;