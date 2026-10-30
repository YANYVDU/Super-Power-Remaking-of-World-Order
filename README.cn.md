[English](./README.md) · **简体中文**

---

# Super Power - Remaking of World Order（超级大国，SP）

文明V（Sid Meier's Civilization 5）大型玩法修正模组，中文名「超级大国」。基于 MPDLL 开发，是 MPDLL 新增 API 的主要运用端（MPDLL 提供功能，SP 写入数据库完成功能应用）。

---

# 联机（多人生效）开发规则与预防措施

> 面向**手动开发与 AI 辅助开发的所有贡献者**。违反下列规则可能导致多人游戏下状态叠加（金币/信仰翻倍）或状态不同步（desync）。
> 适用判定对象：任何新增/修改**会改动游戏状态**（金币、信仰、宗教信条、城邦关系、建筑、单位、政策、伟人等）的 Lua 代码。

## 0. 判别依据（最重要的一条）

文明5 联机采用「**锁步确定性模拟 + 主机权威**」架构：所有客户端跑相同模拟、相同随机种子，最终以主机权威状态统一。

因此一段修改状态的 Lua 能否在多人正确生效，**决定性因素是它「在所有客户端同步触发」还是「仅单个客户端触发」**：

| 触发场景 | 改状态方式 | 是否叠加风险 |
|---|---|---|
| 引擎 GameEvent 回调（各端同步） | **直接本地修改** | 无（各端确定性一次，主机统一）|
| UI 单客户端交互（按钮/点击） | 必须 `SendAndExecuteLuaFunction` 广播 | 无（单端发起，InvokeRecorder 去重）|
| 同一函数两类路径共用 | `bBroadcast` 参数隔离 | 无（显式分流）|

## 1. 引擎 GameEvent 回调 —— 各端同步触发，直接改状态，不要 send

对应的回调（示例）：`PantheonFounded / ReligionFounded / ReligionEnhanced / ReligionReformed / PlayerDoTurn / PlayerCityFounded / CityConstructed / SetPopulation / PlayerCompletedQuest / BuildFinished` 等。

- 各端以相同顺序确定性执行同一回调。直接 `player:ChangeGold(...)`、`city:SetNumRealBuilding(...)`、`unit:Kill()` 即让各端一致，主机权威统一生效一次。
- ☠️ **绝对禁止**在这些回调里写 `obj:SendAndExecuteLuaFunction(...)`：每个客户端都会各发起一次广播，`InvokeRecorder` 的「相同签名去重」依赖「先本地执行、再收广播」的锁步时序；一旦网络消息抢先于本地模拟（时序被打破），就会重复执行，导致**金币/信仰 ×玩家数（如 2 真人拿 1000 而非 500）**。
- ✅ 正确做法：直接持对象改状态（锁步会把它同步到各端）。

## 2. UI 单客户端交互 —— 只在点击者客户端触发，必须 send 广播

对应的回调：`LuaEvents.*.Add`（如 `UnitPanelActionAddin` 的 `Action`）、`Controls.*:RegisterCallback(Mouse.eLClick, ...)`、`InputHandler` 等。

- 这类回调只在**触发它的那个客户端**执行。若不 `SendAndExecute` 广播，其它端/主机看不到该改动，产生 desync。
- ✅ 用 `obj:SendAndExecuteLuaFunction("CvLuaPlayer::lXxx", 参数...)` 广播，各端同步各执行一次（`InvokeRecorder` 去重 → 恰一次，不叠加）。

## 3. 同一函数被两类路径共用 —— 用 `bBroadcast` 参数隔离（SP 落地范式）

当一个既有函数既可能被引擎模拟调用、也可能被 UI 调用时，用 `bBroadcast` 双路径分流（见 `Utility/UtilityFunctions.lua` 的 `SatelliteLaunchEffects / SatelliteEffectsGlobal / ImproveTiles / CarrierRestore / RemoveConflictFeatures`）：

```lua
local function Xxx_Base(...)   -- 直调：引擎模拟 / 单机路径
  ...
end
local function Xxx_MP(...)     -- SendAndExecute 广播：联机 UI 路径
  ...
end
function Xxx(..., bBroadcast)
  if bBroadcast and Game.IsGameMultiPlayer() then
    return Xxx_MP(...)
  end
  return Xxx_Base(...)
end
-- 调用约定：
--   引擎模拟路径（NewUnitsRules.lua、NewHandicap.lua …）  传 false → 直调
--   UI 交互路径（UnitSpecialButtons.lua 的 Action …）    传 true  → 广播
```

## 4. SendAndExecuteLuaFunction 使用规范

1. **用显式玩家/城邦 ID 参数，不依赖函数内部的 `getActivePlayer()`**。
   优先选带 `FromMajor` / 显式玩家 ID 的 C++ 变体，把发起端读到的 `iActivePlayer` 一并广播。
   例如 CSUA 自选信条用 `lDoCityStateFaithBeliefPurchaseFromMajor(iActivePlayer, minorID, beliefID)`，而非内部取 `getActivePlayer()` 的版本——**联机各端 `getActivePlayer()` 不同**，隐式依赖必错乱（参数显式传递则各端用同一值，一致）。
2. **参数必须确定性一致**。
   `SendAndExecuteLuaFunction` 的参数会序列化广播，`InvokeRecorder` 按「函数名 + 参数序列」完全一致才视为同一次调用并去重。若参数来自当时读取的玩家状态（如 `GetNumFreeTechs() + N`、`total/2 - gold`），端间状态尚未同步的一瞬会算出不同值 → 签名不同 → 不去重 → 各自执行产生叠加。尽量传**常量**或**可确定性复算**的值。
3. **单端视觉/本地判定留在本地**。
   `bSuccess`、UI 音效、`AddNotification`（发给本机的通知）只对发起端有意义，直接写；不要依赖广播执行端的返回值。

## 5. 保持直调、不要加 send 的

- 只读调用（`GetXxx`、`GetProduction`、`IsGoldenAge`、`IsHuman` …）
- `Game.Rand` 洗牌（确定性随机种子，各端一致，**必须保留直调**）
- 纯布尔判定（`CanConstruct`、`CanGrowNormally`、按钮的 `Condition`/`Disabled` 回调 …）

## 6. 机制备忘（排查用）

- 发起端 `CvLuaScopedInstance.h::lSendAndExecuteLuaFunction`：本地立即执行 + `gDLL->SendRenameCity(-len, str)` 广播。
- 接收端 `CvDllNetMessageHandler.cpp::ResponseRenameCity`：用 `InvokeRecorder::getInvokeExist(str)` 去重（实现于 `NetworkMessageUtil.cpp`），保证每端对同一签名恰执行一次。
- 去重成立的软肋：① 各端必须生成**完全相同**的签名；② 依赖「先本地执行再收广播」的锁步时序。

## 7. 验证

新增/改动联机相关 Lua 后，务必**双人实机开局验证**：金币、信仰、宗教信条、城邦关系、建筑、单位均**单次正确同步**，无叠加、无 desync。

## 8. DLC（无 .modinfo）环境下 Lua 的加载与手动接入

**背景**：标准 MOD 通过 `.modinfo` 声明 Lua 的加载方式——Gameplay 脚本写 `<File import="1">`、UI 入口写 `<EntryPoint type="InGameUIAddin">`，由 `Modding.GetActivatedModEntryPoints("InGameUIAddin")` 自动加载。**DLC 目录（如 `Assets/DLC/SPV11联机魔改DLC/Mods/*`）内的模组没有 `.modinfo`**，Modding 系统无法把它们识别为激活模组，其中的 Lua **默认不会被加载**，对应能力（`GameEvents`/`LuaEvents` 回调、面板按钮等）不生效。

**SP 的修复范式（提交 `fadceb4 fix: mul InGame.lua`）**：
`UI/InGame/InGame.lua`（被 DLC 覆盖加载的原版核心 UI 入口）在 InGameUIAddin 循环后增加兜底，用 `bAddinsLoaded` 探测是否存在任何激活的 InGameUIAddin：
```lua
local bAddinsLoaded = false
for addin in Modding.GetActivatedModEntryPoints("InGameUIAddin") do
    bAddinsLoaded = true
    -- ... table.insert(g_uiAddins, ContextPtr:LoadNewContext(addin.path))
end
-- DLC 无 .modinfo，SPInit 不会被自动加载 → 手动加载
if not bAddinsLoaded then
    table.insert(g_uiAddins, ContextPtr:LoadNewContext("SPInit"))
end
```
`bAddinsLoaded == false` 即 DLC/无 modinfo 环境，此时手动 `LoadNewContext("SPInit")` 强制挂载 SP 主入口 `Gameplay/Lua/SPInit.lua`，SP 的 Lua 能力随之注册。

**对独立模组的影响**：
-原通过 modinfo 以 `InGameUIAddin` 入口加载（注册 `UnitPanelActionAddin`、`CityCanConstruct` 等）；
-原通过 modinfo `import="1"` 执行（注册 `PantheonFounded` 等信条 GameEvents）。

它们在 DLC 中无 `.modinfo`，**默认不会被加载**。目前 SP 的 `InGame.lua` 兜底**只加载了 `SPInit`，尚未接入这两个模组的 Lua**——要使它们（及任何其它 DLC 整合模板组）在 DLC 环境生效，需在统一入口（`InGame.lua` 兜底块或 `SPInit`）**手动加载**其脚本：有配套 Context/XML 的用 `LoadNewContext` 挂入 `g_uiAddins`，纯 Gameplay 脚本按其原加载方式 `include`/执行。

**验证**：在 DLC 环境读档后，确认这些 Lua 已被加载（对应 `GameEvents`/`LuaEvents` 是否触发、按钮是否出现）；否则检查入口是否接入。