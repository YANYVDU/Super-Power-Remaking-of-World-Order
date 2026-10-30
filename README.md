[简体中文](./README.cn.md) · **English**

---

# Super Power - Remaking of World Order (SP)

A comprehensive gameplay-overhaul mod for Sid Meier's Civilization V (Chinese name: 超级大国 / Superpower). Built on top of **MPDLL** as its primary consumer of the newly added API — MPDLL provides the mechanics, SP applies them via database and Lua. Current version: V11, full title **Super Power V11 - Pillars of Sovereignty**.

---

# Multiplayer (Online) Development Rules & Preventive Measures

> For ALL contributors — both manual developers and AI-assisted developers. Violating these rules can cause **state duplication (gold/faith doubling)** or **desync** in multiplayer.
> Applies to any newly added / modified Lua that **mutates game state**: gold, faith, religious beliefs, city-state relations, buildings, units, policies, great people, etc.

## 0. The Single Most Important Rule: How to Decide

Civilization V multiplayer uses a **lockstep deterministic simulation + host-authoritative** model: every client runs the same simulation with the same random seed, and the host's authoritative state eventually reconciles all clients.

So whether a piece of state-changing Lua works correctly in multiplayer is decided by **whether it runs synchronously on ALL clients, or only on a single client**:

| Trigger scenario | How to change state | Stacking risk |
|---|---|---|
| Engine GameEvent callback (all clients) | **Mutate locally directly** | None (deterministic once per client; host unifies) |
| UI single-client interaction (button/click) | Must broadcast via `SendAndExecuteLuaFunction` | None (single origin; `InvokeRecorder` dedupes) |
| Same function used by both paths | Isolate via `bBroadcast` param | None (explicit routing) |

## 1. Engine GameEvent Callbacks — Triggered On Every Client, Mutate Directly, Do NOT send

Examples: `PantheonFounded / ReligionFounded / ReligionEnhanced / ReligionReformed / PlayerDoTurn / PlayerCityFounded / CityConstructed / SetPopulation / PlayerCompletedQuest / BuildFinished`, etc.

- Every client executes the same callback in the same deterministic order. Calling `player:ChangeGold(...)`, `city:SetNumRealBuilding(...)`, or `unit:Kill()` directly keeps every client in sync; the host's authoritative state applies it exactly once.
- ☠️ **NEVER** call `obj:SendAndExecuteLuaFunction(...)` inside these callbacks: every client would broadcast it once, and `InvokeRecorder`'s "identical-signature dedupe" relies on the lockstep ordering of *run locally first → receive the broadcast*. Once a network message arrives before the local simulation (ordering broken), the effect runs repeatedly → **gold/faith × number of players (e.g. 2 human players get 1000 instead of 500)**.
- ✅ Correct approach: mutate the object directly (lockstep syncs it to every client).

## 2. UI Single-Client Interactions — Triggered Only On The Clicker's Client, MUST send

Examples: `LuaEvents.*.Add` (e.g. the `Action` in `UnitPanelActionAddin`), `Controls.*:RegisterCallback(Mouse.eLClick, ...)`, `InputHandler`, etc.

- These callbacks run only on the single client that triggered them. Without a `SendAndExecute` broadcast, other clients / the host won't see the change → desync.
- ✅ Use `obj:SendAndExecuteLuaFunction("CvLuaPlayer::lXxx", args...)` to broadcast; every client runs it once (deduped by `InvokeRecorder` → exactly once, no stacking).

## 3. One Function Used By Both Paths — Isolate With A `bBroadcast` Parameter (SP Pattern)

When an existing function may be called both by the engine simulation and by the UI, route both paths through `bBroadcast` (see `SatelliteLaunchEffects / SatelliteEffectsGlobal / ImproveTiles / CarrierRestore / RemoveConflictFeatures` in `Utility/UtilityFunctions.lua`):

```lua
local function Xxx_Base(...)   -- Direct call: engine simulation / single-player path
  ...
end
local function Xxx_MP(...)     -- SendAndExecute broadcast: multiplayer UI path
  ...
end
function Xxx(..., bBroadcast)
  if bBroadcast and Game.IsGameMultiPlayer() then
    return Xxx_MP(...)
  end
  return Xxx_Base(...)
end
-- Calling convention:
--   Engine simulation path   (NewUnitsRules.lua, NewHandicap.lua …)  pass false → direct
--   UI interaction path      (UnitSpecialButtons.lua Action …)      pass true  → broadcast
```

## 4. SendAndExecuteLuaFunction Usage Rules

1. **Pass explicit player / city-state IDs; never rely on `getActivePlayer()` inside the called function.** Prefer the C++ variant with `FromMajor` / an explicit player ID, and broadcast the `iActivePlayer` you read on the originating client. Example: CSUA custom-belief uses `lDoCityStateFaithBeliefPurchaseFromMajor(iActivePlayer, minorID, beliefID)` instead of the internal-`getActivePlayer()` version — **different clients have different `getActivePlayer()` during multiplayer**, so an implicit dependency corrupts state (explicit args make every client use the same value).
2. **Arguments must be deterministically identical.** `SendAndExecuteLuaFunction` serializes its arguments for the broadcast, and `InvokeRecorder` treats two invocations as the same (then dedupes) only when "function name + argument sequence" are exactly equal. If an argument is derived from the player state read at that instant (e.g. `GetNumFreeTechs() + N`, `total/2 - gold`), the moment before clients resync can produce different values → different signature → no dedupe → each executes independently → stacking. Prefer **constants** or **values that can be recomputed deterministically**.
3. **Leave client-only visuals / local checks local.** `bSuccess`, UI sound effects, and `AddNotification` (notifications to the local machine) are meaningful only on the originating client — write them directly; do NOT rely on the return value from the broadcast-executing sides.

## 5. Keep Direct Calls, Do NOT Add send

- Read-only calls (`GetXxx`, `GetProduction`, `IsGoldenAge`, `IsHuman` …)
- `Game.Rand` shuffling (deterministic random seed, identical on every client — **must stay a direct call**)
- Pure boolean checks (`CanConstruct`, `CanGrowNormally`, a button's `Condition` / `Disabled` callbacks …)

## 6. Mechanism Reference (for debugging)

- Originator `CvLuaScopedInstance.h::lSendAndExecuteLuaFunction`: runs locally immediately, then broadcasts via `gDLL->SendRenameCity(-len, str)`.
- Receiver `CvDllNetMessageHandler.cpp::ResponseRenameCity`: dedupes with `InvokeRecorder::getInvokeExist(str)` (implemented in `NetworkMessageUtil.cpp`), guaranteeing each client runs a given signature exactly once.
- Weak points of the dedupe: ① every client must produce an **exactly identical** signature; ② it depends on the lockstep ordering of "run locally first, then receive the broadcast".

## 7. Verification

After adding or changing multiplayer Lua, always **test with two human players in a real game**: gold, faith, religious beliefs, city-state relations, buildings, and units must each sync correctly exactly once — no stacking, no desync.

## 8. Loading Lua in a DLC (no `.modinfo`) environment

**Background**: Regular mods declare how their Lua is loaded via `.modinfo` — a Gameplay script is listed as `<File import="1">`, a UI entry as `<EntryPoint type="InGameUIAddin">` — and `Modding.GetActivatedModEntryPoints("InGameUIAddin")` auto-loads them. **Mods inside a DLC folder (e.g. `Assets/DLC/SPV11联机魔改DLC/Mods/*`) have no `.modinfo`**, so the Modding system cannot recognise them as activated mods and their Lua is **NOT loaded by default** — their callbacks (`GameEvents`/`LuaEvents`), panel buttons, etc. simply never run.

**SP fix pattern (commit `fadceb4 fix: mul InGame.lua`)**:
`UI/InGame/InGame.lua` (the vanilla core UI entry, overridden and loaded by the DLC) adds a fallback after its `InGameUIAddin` loop, using `bAddinsLoaded` to detect whether any `InGameUIAddin` was actually activated:
```lua
local bAddinsLoaded = false
for addin in Modding.GetActivatedModEntryPoints("InGameUIAddin") do
    bAddinsLoaded = true
    -- ... table.insert(g_uiAddins, ContextPtr:LoadNewContext(addin.path))
end
-- DLC has no .modinfo, so SPInit would never load → load it manually
if not bAddinsLoaded then
    table.insert(g_uiAddins, ContextPtr:LoadNewContext("SPInit"))
end
```
`bAddinsLoaded == false` means we are in a DLC / no-modinfo environment; the code then manually `LoadNewContext("SPInit")` to mount SP's main entry `Gameplay/Lua/SPInit.lua`, registering all of SP's Lua logic.

**Impact on standalone mods**:
- normally loaded as an `InGameUIAddin` entry (registers `UnitPanelActionAddin`, `CityCanConstruct`, …);
- — normally executed via modinfo `import="1"` (registers pantheon/founder belief `GameEvents`).

Neither is loaded by default in the DLC. Currently SP's `InGame.lua` fallback **only mounts `SPInit`, not these two mods' Lua** — to make them (and any other DLC-bundled mod) work in a DLC environment, you must **manually load their scripts** at the central entry (`InGame.lua` fallback block or `SPInit`): `LoadNewContext` into `g_uiAddins` if they have an associated Context/XML, otherwise `include`/execute the script as originally declared.

**Verification**: after loading a save in the DLC environment, confirm these Lua files were loaded (their `GameEvents`/`LuaEvents` fire, buttons/belief effects appear); otherwise check whether the entry was wired up.