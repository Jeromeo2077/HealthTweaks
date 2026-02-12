-- Unit tests for game/bin/x64/plugins/cyber_engine_tweaks/mods/HealthTweaks/init.lua
-- Runs outside CET by mocking globals.

local INIT_PATH = "game/bin/x64/plugins/cyber_engine_tweaks/mods/HealthTweaks/init.lua"

local function fail(msg)
  error(msg, 2)
end

local function assert_true(v, msg)
  if not v then fail(msg or "expected true") end
end

local function assert_false(v, msg)
  if v then fail(msg or "expected false") end
end

local function assert_eq(a, b, msg)
  if a ~= b then
    fail((msg or "expected equality") .. ": got=" .. tostring(a) .. " expected=" .. tostring(b))
  end
end

local function assert_contains(haystack, needle, msg)
  if not string.find(haystack, needle, 1, true) then
    fail((msg or "expected substring") .. ": missing=" .. needle .. " in=" .. haystack)
  end
end

local function assert_not_contains(haystack, needle, msg)
  if string.find(haystack, needle, 1, true) then
    fail((msg or "unexpected substring") .. ": found=" .. needle .. " in=" .. haystack)
  end
end

local function join_lines(lines)
  return table.concat(lines, "\n")
end

local function makeMockTweakDB(opts)
  opts = opts or {}

  local existing = opts.existing or {}
  local setBehavior = opts.setBehavior or {}
  local cloneBehavior = opts.cloneBehavior or {}

  local calls = {
    setFlat = {},
    getFlat = {},
    cloneRecord = {},
  }

  local attemptCount = {}

  local TweakDB = {}

  function TweakDB:GetFlat(key)
    table.insert(calls.getFlat, { key = key })
    if existing[key] == nil then return nil end
    return existing[key]
  end

  function TweakDB:SetFlat(key, value)
    table.insert(calls.setFlat, { key = key, value = value })
    attemptCount[key] = (attemptCount[key] or 0) + 1

    local behavior = setBehavior[key]
    if behavior == nil then
      return true
    end

    if type(behavior) == "boolean" then
      return behavior
    end

    -- behavior can be { failTimes = 1 } etc.
    if type(behavior) == "table" then
      local failTimes = behavior.failTimes or 0
      if attemptCount[key] <= failTimes then
        return false
      end
      return true
    end

    return true
  end

  function TweakDB:CloneRecord(newId, fromId)
    table.insert(calls.cloneRecord, { newId = newId, fromId = fromId })
    local behavior = cloneBehavior[fromId]
    if behavior == "error" then
      error("CloneRecord failed")
    end
    return true
  end

  return TweakDB, calls, attemptCount
end

local function withMocks(mock)
  local old = {
    TweakDB = _G.TweakDB,
    registerForEvent = _G.registerForEvent,
    print = _G.print,
  }

  _G.TweakDB = mock.TweakDB

  local onInitCb
  _G.registerForEvent = function(evt, cb)
    if evt == "onInit" then
      onInitCb = cb
    end
  end

  local printed = {}
  _G.print = function(...)
    local parts = {}
    for i = 1, select("#", ...) do
      parts[i] = tostring(select(i, ...))
    end
    table.insert(printed, table.concat(parts, "\t"))
  end

  local ok, retOrErr = pcall(dofile, INIT_PATH)

  -- Restore globals
  _G.TweakDB = old.TweakDB
  _G.registerForEvent = old.registerForEvent
  _G.print = old.print

  if not ok then
    return false, retOrErr, nil, nil
  end

  if type(onInitCb) ~= "function" then
    return false, "onInit callback not registered", nil, nil
  end

  -- Reinstall print for init execution output capture.
  _G.print = function(...)
    local parts = {}
    for i = 1, select("#", ...) do
      parts[i] = tostring(select(i, ...))
    end
    table.insert(printed, table.concat(parts, "\t"))
  end

  -- Execute onInit; if it errors, capture and restore print.
  local ok2, err2 = pcall(onInitCb)
  _G.print = old.print

  if not ok2 then
    return false, err2, printed, retOrErr
  end

  return true, nil, printed, retOrErr
end

-- Common flat keys used by init.lua (so tests can mark them as existing)
local function baseExistingFlats()
  local e = {}

  -- Base stat pools
  e["BaseStatPools.PlayerBaseInCombatHealthRegen_inline4.value"] = 0
  e["BaseStatPools.PlayerBaseOutOfCombatHealthRegen_inline4.value"] = 0
  e["BaseStatPools.PlayerHealingChargesRegen_inline4.value"] = 0

  -- Duration
  e["Items.BonesMcCoy70Duration_inline0.value"] = 0

  -- MaxDoc
  e["BaseStatusEffect.FirstAidWhiffV0_inline3.statPoolValue"] = 0
  e["BaseStatusEffect.FirstAidWhiffV1_inline3.statPoolValue"] = 0
  e["BaseStatusEffect.FirstAidWhiffV2_inline3.statPoolValue"] = 0

  return e
end

-- TEST: Clean run should only print summary lines (no flat-not-found spam for UI)
do
  local existing = baseExistingFlats()

  -- Make instant-heal candidates exist such that V0 uses BaseStatusEffect..., V1/V2 use Items...
  existing["BaseStatusEffect.BonesMcCoy70V0_inline3.value"] = 0
  existing["Items.BonesMcCoy70V1_inline6.value"] = 0
  existing["Items.BonesMcCoy70V2_inline6.value"] = 0

  -- HPS candidates: only V0 has one candidate; V1/V2 missing.
  existing["BaseStatusEffect.BonesMcCoy70V0_inline2.valuePerSec"] = 0

  local TweakDB, calls = makeMockTweakDB({ existing = existing })

  local ok, err, printed = withMocks({ TweakDB = TweakDB })
  assert_true(ok, tostring(err))

  local out = join_lines(printed)

  assert_contains(out, "[HealthTweaks] BounceBack V0 instant (one-time) heal patched via: BaseStatusEffect.BonesMcCoy70V0_inline3.value")
  assert_contains(out, "[HealthTweaks] BounceBack V1 instant (one-time) heal patched via: Items.BonesMcCoy70V1_inline6.value")
  assert_contains(out, "[HealthTweaks] BounceBack V2 instant (one-time) heal patched via: Items.BonesMcCoy70V2_inline6.value")

  assert_contains(out, "[HealthTweaks] BounceBack V1 healing-over-time (HPS/regen) NOT patched")
  assert_contains(out, "[HealthTweaks] BounceBack V2 healing-over-time (HPS/regen) NOT patched")

  -- V0 HoT should be patched (so no NOT patched line for V0)
  assert_not_contains(out, "BounceBack V0 healing-over-time (HPS/regen) NOT patched")

  -- UI flats are optional in init.lua; missing them should not log Flat not found
  assert_not_contains(out, "Flat not found: Items.BonesMcCoy70V0_inline7.localizedDescription")
  assert_not_contains(out, "Flat not found: Items.BonesMcCoy70V1_inline7.localizedDescription")

  assert_contains(out, "[HealthTweaks] Loaded.")

  -- Sanity: SetFlat should have been called on V0 HPS key
  local foundV0Hps = false
  for _, c in ipairs(calls.setFlat) do
    if c.key == "BaseStatusEffect.BonesMcCoy70V0_inline2.valuePerSec" then
      foundV0Hps = true
      break
    end
  end
  assert_true(foundV0Hps, "expected SetFlat for V0 HPS")
end

-- TEST: Missing non-optional flat should log "Flat not found"
do
  local existing = baseExistingFlats()

  -- Remove one required flat
  existing["BaseStatPools.PlayerHealingChargesRegen_inline4.value"] = nil

  -- Ensure instant-heal candidates exist so init proceeds
  existing["BaseStatusEffect.BonesMcCoy70V0_inline3.value"] = 0
  existing["Items.BonesMcCoy70V1_inline6.value"] = 0
  existing["Items.BonesMcCoy70V2_inline6.value"] = 0

  local TweakDB = makeMockTweakDB({ existing = existing })

  local ok, err, printed = withMocks({ TweakDB = TweakDB })
  assert_true(ok, tostring(err))

  local out = join_lines(printed)
  assert_contains(out, "[HealthTweaks] Flat not found: BaseStatPools.PlayerHealingChargesRegen_inline4.value")
end

-- TEST: Numeric retry (fail once then succeed) should not print FAILED, and should attempt multiple SetFlat calls
-- Note: Lua has one number type, so we test retry by failing first call and succeeding on second.
do
  local existing = baseExistingFlats()
  existing["BaseStatusEffect.BonesMcCoy70V0_inline3.value"] = 0
  existing["Items.BonesMcCoy70V1_inline6.value"] = 0
  existing["Items.BonesMcCoy70V2_inline6.value"] = 0

  local TweakDB, _, attemptCount = makeMockTweakDB({
    existing = existing,
    setBehavior = {
      ["Items.BonesMcCoy70Duration_inline0.value"] = { failTimes = 1 },
    },
  })

  local ok, err, printed = withMocks({ TweakDB = TweakDB })
  assert_true(ok, tostring(err))

  local out = join_lines(printed)
  assert_not_contains(out, "FAILED to set Items.BonesMcCoy70Duration_inline0.value")
  assert_true((attemptCount["Items.BonesMcCoy70Duration_inline0.value"] or 0) >= 2, "expected retry attempts")
end

-- TEST: Optional CloneRecord failures should not throw and should not log
-- We simulate CloneRecord throwing by making the fromId behavior "error".
do
  local existing = baseExistingFlats()
  existing["BaseStatusEffect.BonesMcCoy70V0_inline3.value"] = 0
  existing["Items.BonesMcCoy70V1_inline6.value"] = 0
  existing["Items.BonesMcCoy70V2_inline6.value"] = 0

  -- Make the UI source record look missing; CloneRecord error should be swallowed.
  local TweakDB = makeMockTweakDB({
    existing = existing,
    cloneBehavior = {
      ["Items.BonesMcCoy70V1_inline7"] = "error",
      ["Items.FirstAidWhiffV0_inline7"] = "error",
    },
  })

  local ok, err, printed = withMocks({ TweakDB = TweakDB })
  assert_true(ok, tostring(err))

  local out = join_lines(printed)
  assert_not_contains(out, "FAILED to clone record")
end

return true
