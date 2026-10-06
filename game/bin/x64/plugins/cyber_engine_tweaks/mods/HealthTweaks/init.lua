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

registerForEvent("onInit", function()

  -- Disable Passive Health Regeneration
  setFlat("BaseStatPools.PlayerBaseInCombatHealthRegen_inline4.value", CONFIG.PassiveRegenInCombat)
  setFlat("BaseStatPools.PlayerBaseOutOfCombatHealthRegen_inline4.value", CONFIG.PassiveRegenOutOfCombat)

  -- Slow Inhaler Recharge (lower = slower)
  setFlat("BaseStatPools.PlayerHealingChargesRegen_inline4.value", CONFIG.HealingChargesRegen)

  -------------------------------------------------------------------------
  -- Bounce Back Gameplay Changes
  -------------------------------------------------------------------------

  -- Bounce Back V0 duration
  setFlat("Items.BonesMcCoy70Duration_inline0.value", BounceBackDuration)

  -- Bounce Back V0 heal-per-second
  setFlat("BaseStatusEffect.BonesMcCoy70V0_inline2.valuePerSec", BounceBack1HealOverTime)

  -- Bounce Back V0 instant heal
  setFlat("BaseStatusEffect.BonesMcCoy70V0_inline10.statPoolValue", BounceBack1InstantHeal)

  -- Bounce Back V0 effective item healing values
  setFlat(
  "Items.BonesMcCoy70V0_inline6.value", BounceBack1HealOverTime)

  setFlat("Items.BonesMcCoy70V0_inline7.value", BounceBack1InstantHeal)

  -- Bounce Back V1 effective item healing values
  setFlat("Items.BonesMcCoy70V1_inline6.value", BounceBack2HealOverTime)

  setFlat("Items.BonesMcCoy70V1_inline7.value", BounceBack2InstantHeal)

  -- Bounce Back V2 effective item healing values
  setFlat("Items.BonesMcCoy70V2_inline6.value", BounceBack3HealOverTime)

  setFlat("Items.BonesMcCoy70V2_inline7.value", BounceBack3InstantHeal)

  -------------------------------------------------------------------------
  -- MaxDoc Gameplay Changes
  -------------------------------------------------------------------------

  -- MaxDoc instant heal
  -- setFlat("BaseStatusEffect.FirstAidWhiffV0_inline3.statPoolValue", MaxDoc1Heal)
  -- setFlat("BaseStatusEffect.FirstAidWhiffV1_inline3.statPoolValue", MaxDoc2Heal)
  -- setFlat("BaseStatusEffect.FirstAidWhiffV2_inline3.statPoolValue", MaxDoc3Heal)

  -------------------------------------------------------------------------
  -- Bounce Back tooltip descriptions
  --
  -- Vanilla LocKey uses:
  --   intValues[0] = healing per second
  --   intValues[1] = instant healing
  --   intValues[2] = duration
  --
  -- HPS values are rounded to the nearest integer for the description.
  -- Actual gameplay values remain unchanged.
  -------------------------------------------------------------------------

  setFlat(
    "Items.BonesMcCoy70V0_inline8.intValues",
    {
      math.floor(CONFIG.BounceBack.V0.HPS + 0.5),
      CONFIG.BounceBack.V0.Instant,
      BounceBackDuration
    }
  )

  setFlat(
    "Items.BonesMcCoy70V1_inline8.intValues",
    {
      math.floor(CONFIG.BounceBack.V1.HPS + 0.5),
      CONFIG.BounceBack.V1.Instant,
      BounceBackDuration
    }
  )

  setFlat(
    "Items.BonesMcCoy70V2_inline8.intValues",
    {
      math.floor(CONFIG.BounceBack.V2.HPS + 0.5),
      CONFIG.BounceBack.V2.Instant,
      BounceBackDuration
    }
  )

  log("loaded")
end)

return HealthTweaks
