-- HealthTweaks (Cyber Engine Tweaks mod)
-- Entry point: CET loads this file automatically.

local modName = "HealthTweaks"

local HealthTweaks = {
  description = "Editable Tweaks: Passive Health Regeneration both (In Combat and Out of Combat); Inhaler Recharge Cooldown, MaxDoc + BounceBack healing values",
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
local function setFlat(key, value, opts)
  -- Some flats vary by game version / can change types; avoid noisy logs for successes.
  -- opts.optional=true => suppress "not found" and "failed" logs (for non-critical UI tweaks)
  opts = opts or {}

  local existing = TweakDB:GetFlat(key)
  if existing == nil then
    if not opts.optional then
      log("Flat not found: " .. key)
    end
    return false
  end

  local ok = TweakDB:SetFlat(key, value)
  if ok then return true end

  -- Retry numeric values as float/int to work around occasional type mismatch issues.
  if type(value) == "number" then
    ok = TweakDB:SetFlat(key, value * 1.0)
    if ok then return true end
    ok = TweakDB:SetFlat(key, math.floor(value))
    if ok then return true end
  end

  if not opts.optional then
    log("FAILED to set " .. key)
  end
  return false
end

local function trySet(keys, value, opts)
  for _, k in ipairs(keys) do
    local existing = TweakDB:GetFlat(k)
    if existing ~= nil then
      if setFlat(k, value, opts) then
        return k
      end
    end
  end
  return nil
end

local function cloneRecord(newId, fromId, opts)
  -- CloneRecord can fail if the source record isn't present in this build.
  -- opts.optional=true => suppress failure logs (for non-critical UI tweaks)
  opts = opts or {}
  local ok = pcall(function()
    TweakDB:CloneRecord(newId, fromId)
  end)
  if (not ok) and (not opts.optional) then
    log("FAILED to clone record " .. tostring(fromId) .. " -> " .. tostring(newId))
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

  -- Bounce Back duration
  setFlat("Items.BonesMcCoy70Duration_inline0.value", CONFIG.BounceBackDuration)

  -- Bounce Back heal-per-second — candidates vary across game versions
  local BB_HPS_CANDIDATES = {
    V0 = {
      "BaseStatusEffect.BonesMcCoy70V0_inline2.valuePerSec",
      "BaseStatusEffect.BonesMcCoy70V0_inline1.valuePerSec",
      "BaseStatusEffect.BonesMcCoy70V0_inline3.valuePerSec",
      "BaseStatusEffect.BonesMcCoy70V0_inline0.valuePerSec",
      "BaseStatusEffect.BonesMcCoy70V0_inline4.valuePerSec",
    },
    V1 = {
      "BaseStatusEffect.BonesMcCoy70V1_inline2.valuePerSec",
      "BaseStatusEffect.BonesMcCoy70V1_inline1.valuePerSec",
      "BaseStatusEffect.BonesMcCoy70V1_inline3.valuePerSec",
      "BaseStatusEffect.BonesMcCoy70V1_inline0.valuePerSec",
      "BaseStatusEffect.BonesMcCoy70V1_inline4.valuePerSec",
    },
    V2 = {
      "BaseStatusEffect.BonesMcCoy70V2_inline2.valuePerSec",
      "BaseStatusEffect.BonesMcCoy70V2_inline1.valuePerSec",
      "BaseStatusEffect.BonesMcCoy70V2_inline3.valuePerSec",
      "BaseStatusEffect.BonesMcCoy70V2_inline0.valuePerSec",
      "BaseStatusEffect.BonesMcCoy70V2_inline4.valuePerSec",
    },
  }

  local usedHpsV0 = trySet(BB_HPS_CANDIDATES.V0, CONFIG.BounceBack.V0.HPS)
  local usedHpsV1 = trySet(BB_HPS_CANDIDATES.V1, CONFIG.BounceBack.V1.HPS)
  local usedHpsV2 = trySet(BB_HPS_CANDIDATES.V2, CONFIG.BounceBack.V2.HPS)

  if not usedHpsV0 then log("BounceBack V0 healing-over-time (HPS/regen) NOT patched (no candidate flat found).") end
  if not usedHpsV1 then log("BounceBack V1 healing-over-time (HPS/regen) NOT patched (no candidate flat found).") end
  if not usedHpsV2 then log("BounceBack V2 healing-over-time (HPS/regen) NOT patched (no candidate flat found).") end

  -- MaxDoc instant heal
  setFlat("BaseStatusEffect.FirstAidWhiffV0_inline3.statPoolValue", CONFIG.MaxDoc.V0)
  setFlat("BaseStatusEffect.FirstAidWhiffV1_inline3.statPoolValue", CONFIG.MaxDoc.V1)
  setFlat("BaseStatusEffect.FirstAidWhiffV2_inline3.statPoolValue", CONFIG.MaxDoc.V2)

  -------------------------------------------------------------------------
  -- Bounce Back instant heal — tries several likely flats
  -------------------------------------------------------------------------
  local BB_INSTANT_CANDIDATES = {
    V0 = {
      "BaseStatusEffect.BonesMcCoy70V0_inline3.value",
      "BaseStatusEffect.BonesMcCoy70V0_inline3.statPoolValue",
      "Items.BonesMcCoy70V0_inline6.value",
    },
    V1 = {
      "Items.BonesMcCoy70V1_inline6.value",
      "BaseStatusEffect.BonesMcCoy70V1_inline3.statPoolValue",
      "BaseStatusEffect.BonesMcCoy70V1_inline3.value",
    },
    V2 = {
      "Items.BonesMcCoy70V2_inline6.value",
      "BaseStatusEffect.BonesMcCoy70V2_inline3.statPoolValue",
      "BaseStatusEffect.BonesMcCoy70V2_inline3.value",
    },
  }

  local usedV0 = trySet(BB_INSTANT_CANDIDATES.V0, CONFIG.BounceBack.V0.Instant)
  local usedV1 = trySet(BB_INSTANT_CANDIDATES.V1, CONFIG.BounceBack.V1.Instant)
  local usedV2 = trySet(BB_INSTANT_CANDIDATES.V2, CONFIG.BounceBack.V2.Instant)

  if usedV0 then
    log("BounceBack V0 instant (one-time) heal patched via: " .. usedV0)
  else
    log("BounceBack V0 instant (one-time) heal NOT patched (no candidate flat worked).")
  end
  if usedV1 then
    log("BounceBack V1 instant (one-time) heal patched via: " .. usedV1)
  else
    log("BounceBack V1 instant (one-time) heal NOT patched (no candidate flat worked).")
  end
  if usedV2 then
    log("BounceBack V2 instant (one-time) heal patched via: " .. usedV2)
  else
    log("BounceBack V2 instant (one-time) heal NOT patched (no candidate flat worked).")
  end

  -------------------------------------------------------------------------
  -- UI updates (tooltips match what you set)
  -------------------------------------------------------------------------

  setFlat(
    "Items.BonesMcCoy70V0_inline7.localizedDescription",
    bbDesc(CONFIG.BounceBack.V0.Instant, CONFIG.BounceBack.V0.HPS, CONFIG.BounceBackDuration),
    { optional = true }
  )
  setFlat(
    "Items.BonesMcCoy70V1_inline7.localizedDescription",
    bbDesc(CONFIG.BounceBack.V1.Instant, CONFIG.BounceBack.V1.HPS, CONFIG.BounceBackDuration),
    { optional = true }
  )

  setFlat("Items.BonesMcCoy70V0_inline7.intValues", {}, { optional = true })
  setFlat("Items.BonesMcCoy70V1_inline7.intValues", {}, { optional = true })

  cloneRecord("BounceBackV2UI_zz", "Items.BonesMcCoy70V1_inline7", { optional = true })
  setFlat(
    "BounceBackV2UI_zz.localizedDescription",
    bbDesc(CONFIG.BounceBack.V2.Instant, CONFIG.BounceBack.V2.HPS, CONFIG.BounceBackDuration),
    { optional = true }
  )
  setFlat("Items.BonesMcCoy70V2_inline7.UIData", "BounceBackV2UI_zz", { optional = true })

  setFlat("Items.FirstAidWhiffV0_inline7.localizedDescription", mdDesc(CONFIG.MaxDoc.V0), { optional = true })
  setFlat("Items.FirstAidWhiffV0_inline7.intValues", {}, { optional = true })

  cloneRecord("MaxDocV1UI_zz", "Items.FirstAidWhiffV0_inline7", { optional = true })
  setFlat("MaxDocV1UI_zz.localizedDescription", mdDesc(CONFIG.MaxDoc.V1), { optional = true })
  setFlat("Items.FirstAidWhiffV1_inline7.UIData", "MaxDocV1UI_zz", { optional = true })

  cloneRecord("MaxDocV2UI_zz", "Items.FirstAidWhiffV0_inline7", { optional = true })
  setFlat("MaxDocV2UI_zz.localizedDescription", mdDesc(CONFIG.MaxDoc.V2), { optional = true })
  setFlat("Items.FirstAidWhiffV2_inline7.UIData", "MaxDocV2UI_zz", { optional = true })

  log("Loaded.")
end)

return HealthTweaks
