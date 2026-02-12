-- HealthTweaks (Cyber Engine Tweaks mod)
-- Entry point: CET loads this file automatically.

local modName = "HealthTweaks"

local HealthTweaks = {
  description = "Editable Tweaks: Passive Health Regeneration both (In Combat and Out of Combat); Inhaler Recharge Cooldown,itable Tweaks: Passive Health Regeneration both (In Combat and Out of Combat); Inhaler Recharge Cooldown, MaxDoc + BounceBack values",
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

  -- Bounce Back values (V0/V1/V2 are Mk1/Mk2/Mk3-ish tiers)
  BounceBack = {
    V0 = { Instant = 5, HPS = 3 },
    V1 = { Instant = 7, HPS = 4 },
    V2 = { Instant = 10, HPS = 5 },
  },

  -- MaxDoc values (instant heal)
  MaxDoc = {
    V0 = 40,
    V1 = 55,
    V2 = 70,
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
  if ok then
    log("Set " .. key .. " = " .. tostring(value))
  else
    log("FAILED to set " .. key)
  end
  return ok
end

local function bbDesc(instant, hps, dur)
  return "Instantly restores "
    .. instant
    .. " health and regenerates "
    .. hps
    .. " health per second for "
    .. dur
    .. " seconds."
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
  -- Gameplay changes
  -------------------------------------------------------------------------

  -- Bounce Back duration (updated per your request)
  TweakDB:SetFlat("Items.BonesMcCoy70Duration_inline0.value", BounceBackDuration)

  -- Bounce Back heal-per-second
  TweakDB:SetFlat("BaseStatusEffect.BonesMcCoy70V0_inline2.valuePerSec", BounceBack1HealOverTime)
  TweakDB:SetFlat("BaseStatusEffect.BonesMcCoy70V1_inline2.valuePerSec", BounceBack2HealOverTime)
  TweakDB:SetFlat("BaseStatusEffect.BonesMcCoy70V2_inline2.valuePerSec", BounceBack3HealOverTime)

  -- Bounce Back instant heal
  TweakDB:SetFlat("BaseStatusEffect.BonesMcCoy70V0_inline6.statPoolValue", BounceBack1InstantHeal)
  TweakDB:SetFlat("BaseStatusEffect.BonesMcCoy70V1_inline6.statPoolValue", BounceBack2InstantHeal)
  TweakDB:SetFlat("BaseStatusEffect.BonesMcCoy70V2_inline6.statPoolValue", BounceBack3InstantHeal)

  -- MaxDoc instant heal
  TweakDB:SetFlat("BaseStatusEffect.FirstAidWhiffV0_inline3.statPoolValue", MaxDoc1Heal)
  TweakDB:SetFlat("BaseStatusEffect.FirstAidWhiffV1_inline3.statPoolValue", MaxDoc2Heal)
  TweakDB:SetFlat("BaseStatusEffect.FirstAidWhiffV2_inline3.statPoolValue", MaxDoc3Heal)

  -------------------------------------------------------------------------
  -- UI updates (tooltips match what you set)
  -------------------------------------------------------------------------

  setFlat(
    "Items.BonesMcCoy70V0_inline7.localizedDescription",
    bbDesc(CONFIG.BounceBack.V0.Instant, CONFIG.BounceBack.V0.HPS, BounceBackDuration)
  )
  setFlat(
    "Items.BonesMcCoy70V1_inline7.localizedDescription",
    bbDesc(CONFIG.BounceBack.V1.Instant, CONFIG.BounceBack.V1.HPS, BounceBackDuration)
  )

  setFlat("Items.BonesMcCoy70V0_inline7.intValues", {})
  setFlat("Items.BonesMcCoy70V1_inline7.intValues", {})

  TweakDB:CloneRecord("BounceBackV2UI_zz", "Items.BonesMcCoy70V1_inline7")
  setFlat(
    "BounceBackV2UI_zz.localizedDescription",
    bbDesc(CONFIG.BounceBack.V2.Instant, CONFIG.BounceBack.V2.HPS, BounceBackDuration)
  )
  setFlat("Items.BonesMcCoy70V2_inline7.UIData", "BounceBackV2UI_zz")

  setFlat("Items.FirstAidWhiffV0_inline7.localizedDescription", mdDesc(CONFIG.MaxDoc.V0))
  setFlat("Items.FirstAidWhiffV0_inline7.intValues", {})

  TweakDB:CloneRecord("MaxDocV1UI_zz", "Items.FirstAidWhiffV0_inline7")
  setFlat("MaxDocV1UI_zz.localizedDescription", mdDesc(CONFIG.MaxDoc.V1))
  setFlat("Items.FirstAidWhiffV1_inline7.UIData", "MaxDocV1UI_zz")

  TweakDB:CloneRecord("MaxDocV2UI_zz", "Items.FirstAidWhiffV0_inline7")
  setFlat("MaxDocV2UI_zz.localizedDescription", mdDesc(CONFIG.MaxDoc.V2))
  setFlat("Items.FirstAidWhiffV2_inline7.UIData", "MaxDocV2UI_zz")

  log("Loaded.")
end)

return HealthTweaks
