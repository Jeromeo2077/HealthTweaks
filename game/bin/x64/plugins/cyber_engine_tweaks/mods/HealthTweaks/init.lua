-- HealthTweaks (Cyber Engine Tweaks mod)
-- Entry point: CET loads this file automatically.

local modName = "HealthTweaks"

local HealthTweaks = {
  description = "Editable MaxDoc + BounceBack healing tweaks",
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

local function trySet(keys, value)
  for _, k in ipairs(keys) do
    local existing = TweakDB:GetFlat(k)
    if existing ~= nil then
      if setFlat(k, value) then
        return k
      end
    end
  end
  return nil
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

  -- Bounce Back duration
  setFlat("Items.BonesMcCoy70Duration_inline0.value", CONFIG.BounceBackDuration)

  -- Bounce Back heal-per-second
  setFlat("BaseStatusEffect.BonesMcCoy70V0_inline2.valuePerSec", CONFIG.BounceBack.V0.HPS)
  setFlat("BaseStatusEffect.BonesMcCoy70V1_inline2.valuePerSec", CONFIG.BounceBack.V1.HPS)
  setFlat("BaseStatusEffect.BonesMcCoy70V2_inline2.valuePerSec", CONFIG.BounceBack.V2.HPS)

  -- MaxDoc instant heal
  setFlat("BaseStatusEffect.FirstAidWhiffV0_inline3.statPoolValue", CONFIG.MaxDoc.V0)
  setFlat("BaseStatusEffect.FirstAidWhiffV1_inline3.statPoolValue", CONFIG.MaxDoc.V1)
  setFlat("BaseStatusEffect.FirstAidWhiffV2_inline3.statPoolValue", CONFIG.MaxDoc.V2)

  -------------------------------------------------------------------------
  -- Bounce Back instant heal — tries several likely flats
  -------------------------------------------------------------------------
  local BB_INSTANT_CANDIDATES = {
    V0 = {
      "BaseStatusEffect.BonesMcCoy70V0_inline3.statPoolValue",
      "BaseStatusEffect.BonesMcCoy70V0_inline3.value",
      "Items.BonesMcCoy70V0_inline6.value",
    },
    V1 = {
      "BaseStatusEffect.BonesMcCoy70V1_inline3.statPoolValue",
      "BaseStatusEffect.BonesMcCoy70V1_inline3.value",
      "Items.BonesMcCoy70V1_inline6.value",
    },
    V2 = {
      "BaseStatusEffect.BonesMcCoy70V2_inline3.statPoolValue",
      "BaseStatusEffect.BonesMcCoy70V2_inline3.value",
      "Items.BonesMcCoy70V2_inline6.value",
    },
  }

  local usedV0 = trySet(BB_INSTANT_CANDIDATES.V0, CONFIG.BounceBack.V0.Instant)
  local usedV1 = trySet(BB_INSTANT_CANDIDATES.V1, CONFIG.BounceBack.V1.Instant)
  local usedV2 = trySet(BB_INSTANT_CANDIDATES.V2, CONFIG.BounceBack.V2.Instant)

  if usedV0 then
    log("BounceBack V0 instant heal patched via: " .. usedV0)
  else
    log("BounceBack V0 instant heal NOT patched (no candidate flat worked).")
  end
  if usedV1 then
    log("BounceBack V1 instant heal patched via: " .. usedV1)
  else
    log("BounceBack V1 instant heal NOT patched (no candidate flat worked).")
  end
  if usedV2 then
    log("BounceBack V2 instant heal patched via: " .. usedV2)
  else
    log("BounceBack V2 instant heal NOT patched (no candidate flat worked).")
  end

  -------------------------------------------------------------------------
  -- UI updates (tooltips match what you set)
  -------------------------------------------------------------------------

  setFlat(
    "Items.BonesMcCoy70V0_inline7.localizedDescription",
    bbDesc(CONFIG.BounceBack.V0.Instant, CONFIG.BounceBack.V0.HPS, CONFIG.BounceBackDuration)
  )
  setFlat(
    "Items.BonesMcCoy70V1_inline7.localizedDescription",
    bbDesc(CONFIG.BounceBack.V1.Instant, CONFIG.BounceBack.V1.HPS, CONFIG.BounceBackDuration)
  )

  setFlat("Items.BonesMcCoy70V0_inline7.intValues", {})
  setFlat("Items.BonesMcCoy70V1_inline7.intValues", {})

  TweakDB:CloneRecord("BounceBackV2UI_zz", "Items.BonesMcCoy70V1_inline7")
  setFlat(
    "BounceBackV2UI_zz.localizedDescription",
    bbDesc(CONFIG.BounceBack.V2.Instant, CONFIG.BounceBack.V2.HPS, CONFIG.BounceBackDuration)
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
