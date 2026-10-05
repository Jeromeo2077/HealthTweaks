-- HealthTweaks (Cyber Engine Tweaks mod)
-- Entry point: CET loads this file automatically.

local modName = "Health Tweaks"

local HealthTweaks = {
  description = "Editable Tweaks: Passive Health Regeneration both (In Combat and Out of Combat); Inhaler Recharge Cooldown, MaxDoc + BounceBack values",
}

local function log(msg)
  print(string.format("[%s] %s", modName, tostring(msg)))
end

-------------------------------------------------------------------------
-- CONFIG: edit these numbers
-------------------------------------------------------------------------
local CONFIG = {
  -- Bounce Back duration (seconds)
  BounceBackDuration = 10,

  -- Bounce Back values (V0/V1/V2 are Consumer/Professional/Military tiers)
  BounceBack = {
    V0 = { Instant = 5, HPS = 1.25 },
    V1 = { Instant = 8, HPS = 1.6 },
    V2 = { Instant = 10, HPS = 2.00 },
  },

  -- MaxDoc values (instant heal)
  MaxDoc = {
    V0 = 25,
    V1 = 35,
    V2 = 45,
  },

  -- Passive regen / inhaler recharge
  PassiveRegenInCombat = 0.0,
  PassiveRegenOutOfCombat = 0.0,
  HealingChargesRegen = 0.01,
}

-- Alias used by your requested SetFlat call
local BounceBackDuration = CONFIG.BounceBackDuration

-- Bounce Back heal-over-time aliases (HPS)
local BounceBack1HealOverTime = CONFIG.BounceBack.V0.HPS
local BounceBack2HealOverTime = CONFIG.BounceBack.V1.HPS
local BounceBack3HealOverTime = CONFIG.BounceBack.V2.HPS

-- Bounce Back instant heal aliases
local BounceBack1InstantHeal = CONFIG.BounceBack.V0.Instant
local BounceBack2InstantHeal = CONFIG.BounceBack.V1.Instant
local BounceBack3InstantHeal = CONFIG.BounceBack.V2.Instant

-- MaxDoc instant heal aliases
local MaxDoc1Heal = CONFIG.MaxDoc.V0
local MaxDoc2Heal = CONFIG.MaxDoc.V1
local MaxDoc3Heal = CONFIG.MaxDoc.V2

-------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------
local function setFlat(key, value)
  local ok = TweakDB:SetFlat(key, value)
  if not ok then
    log("FAILED to set " .. key)
  end
  return ok
end

local function mdDesc(instant)
  return "Instantly restores " .. instant .. " health."
end

local function cloneRecordIfMissing(newId, baseId)
  -- Already created?
  local okGet, existing = pcall(function()
    return TweakDB:GetRecord(newId)
  end)

  if okGet and existing ~= nil then
    log("record already exists: " .. newId)
    return true
  end

  -- Resolve the real source record first.
  local okBase, baseRecord = pcall(function()
    return TweakDB:GetRecord(baseId)
  end)

  if not okBase or baseRecord == nil then
    log("FAILED: source record does not exist: " .. baseId)
    return false
  end

  local okID, baseTDBID = pcall(function()
    return baseRecord:GetID()
  end)

  if not okID or baseTDBID == nil then
    log("FAILED: could not get source TweakDBID: " .. baseId)
    return false
  end

  log("cloning " .. baseId .. " -> " .. newId)

  local cloneResult = TweakDB:CloneRecord(newId, baseTDBID)

  if not cloneResult then
    log("FAILED to clone record " .. newId .. " | CloneRecord returned false")
    return false
  end

  log("cloned record: " .. newId)
  return true
end

registerForEvent("onInit", function()

  dumpCompletionStatus("Items.BonesMcCoy70V0")
  dumpCompletionStatus("Items.BonesMcCoy70V1")
  dumpCompletionStatus("Items.BonesMcCoy70V2")

  dumpCompletionStatus("Items.FirstAidWhiffV0")
  dumpCompletionStatus("Items.FirstAidWhiffV1")
  dumpCompletionStatus("Items.FirstAidWhiffV2")

  -- Disable Passive Health Regeneration
  setFlat("BaseStatPools.PlayerBaseInCombatHealthRegen_inline4.value", CONFIG.PassiveRegenInCombat)
  setFlat("BaseStatPools.PlayerBaseOutOfCombatHealthRegen_inline4.value", CONFIG.PassiveRegenOutOfCombat)

  -- Slow Inhaler Recharge (lower = slower)
  setFlat("BaseStatPools.PlayerHealingChargesRegen_inline4.value", CONFIG.HealingChargesRegen)

  -------------------------------------------------------------------------
  -- Gameplay changes
  -------------------------------------------------------------------------

  -- Bounce Back V0 duration (updated per your request)
  setFlat("Items.BonesMcCoy70Duration_inline0.value", BounceBackDuration)

  -- Bounce Back V0 heal-per-second
  setFlat("BaseStatusEffect.BonesMcCoy70V0_inline2.valuePerSec", BounceBack1HealOverTime)

  -- Bounce Back V0 instant heal
  setFlat("BaseStatusEffect.BonesMcCoy70V0_inline10.statPoolValue", BounceBack1InstantHeal)

    -------------------------------------------------------------------------
  -- Bounce Back V1: independent healing package
  -------------------------------------------------------------------------

  cloneRecordIfMissing(
    "HealthTweaks.BounceBackV1Package",
    "BaseStatusEffect.BonesMcCoy70V0_inline0"
  )

  cloneRecordIfMissing(
    "HealthTweaks.BounceBackV1HoTEffector",
    "BaseStatusEffect.BonesMcCoy70V0_inline1"
  )

  cloneRecordIfMissing(
    "HealthTweaks.BounceBackV1HoTModifier",
    "BaseStatusEffect.BonesMcCoy70V0_inline2"
  )

  cloneRecordIfMissing(
    "HealthTweaks.BounceBackV1InstantEffector",
    "BaseStatusEffect.BonesMcCoy70V0_inline9"
  )

  cloneRecordIfMissing(
    "HealthTweaks.BounceBackV1InstantUpdate",
    "BaseStatusEffect.BonesMcCoy70V0_inline10"
  )

  setFlat(
    "HealthTweaks.BounceBackV1HoTModifier.valuePerSec",
    BounceBack2HealOverTime
  )

  setFlat(
    "HealthTweaks.BounceBackV1InstantUpdate.statPoolValue",
    BounceBack2InstantHeal
  )

  setFlat(
    "HealthTweaks.BounceBackV1HoTEffector.poolModifier",
    TweakDBID("HealthTweaks.BounceBackV1HoTModifier")
  )

  setFlat(
    "HealthTweaks.BounceBackV1InstantEffector.statPoolUpdates",
    {
      TweakDBID("HealthTweaks.BounceBackV1InstantUpdate")
    }
  )

  setFlat(
    "HealthTweaks.BounceBackV1Package.effectors",
    {
      TweakDBID("HealthTweaks.BounceBackV1HoTEffector"),
      TweakDBID("HealthTweaks.BounceBackV1InstantEffector"),
      TweakDBID("Effectors.UsedHealingItemOrCyberwareEffector")
    }
  )

  setFlat(
    "BaseStatusEffect.BonesMcCoy70V1.packages",
    {
      TweakDBID("HealthTweaks.BounceBackV1Package")
    }
  )

  -------------------------------------------------------------------------
  -- Bounce Back V2: independent healing package
  -------------------------------------------------------------------------

  cloneRecordIfMissing(
    "HealthTweaks.BounceBackV2Package",
    "BaseStatusEffect.BonesMcCoy70V0_inline0"
  )

  cloneRecordIfMissing(
    "HealthTweaks.BounceBackV2HoTEffector",
    "BaseStatusEffect.BonesMcCoy70V0_inline1"
  )

  cloneRecordIfMissing(
    "HealthTweaks.BounceBackV2HoTModifier",
    "BaseStatusEffect.BonesMcCoy70V0_inline2"
  )

  cloneRecordIfMissing(
    "HealthTweaks.BounceBackV2InstantEffector",
    "BaseStatusEffect.BonesMcCoy70V0_inline9"
  )

  cloneRecordIfMissing(
    "HealthTweaks.BounceBackV2InstantUpdate",
    "BaseStatusEffect.BonesMcCoy70V0_inline10"
  )

  setFlat(
    "HealthTweaks.BounceBackV2HoTModifier.valuePerSec",
    BounceBack3HealOverTime
  )

  setFlat(
    "HealthTweaks.BounceBackV2InstantUpdate.statPoolValue",
    BounceBack3InstantHeal
  )

  setFlat(
    "HealthTweaks.BounceBackV2HoTEffector.poolModifier",
    TweakDBID("HealthTweaks.BounceBackV2HoTModifier")
  )

  setFlat(
    "HealthTweaks.BounceBackV2InstantEffector.statPoolUpdates",
    {
      TweakDBID("HealthTweaks.BounceBackV2InstantUpdate")
    }
  )

  setFlat(
    "HealthTweaks.BounceBackV2Package.effectors",
    {
      TweakDBID("HealthTweaks.BounceBackV2HoTEffector"),
      TweakDBID("HealthTweaks.BounceBackV2InstantEffector"),
      TweakDBID("Effectors.UsedHealingItemOrCyberwareEffector")
    }
  )

  setFlat(
    "BaseStatusEffect.BonesMcCoy70V2.packages",
    {
      TweakDBID("HealthTweaks.BounceBackV2Package")
    }
  )

    -------------------------------------------------------------------------
  -- TEMP: verify cloned Bounce Back records directly
  -------------------------------------------------------------------------

  local function verifyFlat(key)
    local ok, value = pcall(function()
      return TweakDB:GetFlat(key)
    end)

    if ok and value ~= nil then
      log("VERIFY: " .. key .. " = " .. tostring(value))
    else
      log("VERIFY FAILED: " .. key)
    end
  end

  local function verifyRecord(key)
    local ok, record = pcall(function()
      return TweakDB:GetRecord(key)
    end)

    if ok and record ~= nil then
      log("VERIFY RECORD EXISTS: " .. key)
    else
      log("VERIFY RECORD MISSING: " .. key)
    end
  end

  verifyRecord("HealthTweaks.BounceBackV1Package")
  verifyRecord("HealthTweaks.BounceBackV1HoTModifier")
  verifyRecord("HealthTweaks.BounceBackV1InstantUpdate")

  verifyRecord("HealthTweaks.BounceBackV2Package")
  verifyRecord("HealthTweaks.BounceBackV2HoTModifier")
  verifyRecord("HealthTweaks.BounceBackV2InstantUpdate")

  verifyFlat("HealthTweaks.BounceBackV1HoTModifier.valuePerSec")
  verifyFlat("HealthTweaks.BounceBackV1InstantUpdate.statPoolValue")

  verifyFlat("HealthTweaks.BounceBackV2HoTModifier.valuePerSec")
  verifyFlat("HealthTweaks.BounceBackV2InstantUpdate.statPoolValue")

  -- MaxDoc instant heal
  -- setFlat("BaseStatusEffect.FirstAidWhiffV0_inline3.statPoolValue", MaxDoc1Heal)
  -- setFlat("BaseStatusEffect.FirstAidWhiffV1_inline3.statPoolValue", MaxDoc2Heal)
  -- setFlat("BaseStatusEffect.FirstAidWhiffV2_inline3.statPoolValue", MaxDoc3Heal)

  -------------------------------------------------------------------------
  -- UI updates
  -------------------------------------------------------------------------

  -------------------------------------------------------------------------
  -- Bounce Back tooltips
  -------------------------------------------------------------------------

  setFlat(
    "Items.BonesMcCoy70V0_inline8.localizedDescription",
    bbDesc(
      CONFIG.BounceBack.V0.Instant,
      CONFIG.BounceBack.V0.HPS,
      BounceBackDuration
    )
  )

  setFlat(
    "Items.BonesMcCoy70V1_inline8.localizedDescription",
    bbDesc(
      CONFIG.BounceBack.V1.Instant,
      CONFIG.BounceBack.V1.HPS,
      BounceBackDuration
    )
  )

  setFlat(
    "Items.BonesMcCoy70V2_inline8.localizedDescription",
    bbDesc(
      CONFIG.BounceBack.V2.Instant,
      CONFIG.BounceBack.V2.HPS,
      BounceBackDuration
    )
  )

  log("loaded")
end)

return HealthTweaks
