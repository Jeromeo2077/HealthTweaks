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

local function scanInlineFlats(prefix, property, maxIndex)
  log("Scanning " .. prefix .. " for " .. property)

  for i = 0, maxIndex do
    local key = prefix .. "_inline" .. i .. "." .. property

    local ok, value = pcall(function()
      return TweakDB:GetFlat(key)
    end)

    if ok and value ~= nil then
      log("FOUND: " .. key .. " = " .. tostring(value))
    end
  end
end

local function readableTDB(value)
  local ok, result = pcall(function()
    return TDBID.ToStringDEBUG(value)
  end)

  if ok and result ~= nil and result ~= "" then
    return result
  end

  local okRecord, recordID = pcall(function()
    return value:GetID()
  end)

  if okRecord and recordID ~= nil then
    local okName, name = pcall(function()
      return TDBID.ToStringDEBUG(recordID)
    end)

    if okName and name ~= nil then
      return name
    end
  end

  return tostring(value)
end

local function dumpItemFlat(item, property)
  local key = item .. "." .. property

  local ok, value = pcall(function()
    return TweakDB:GetFlat(key)
  end)

  if not ok or value == nil then
    log("  " .. property .. " = <none>")
    return
  end

  if type(value) == "table" then
    log("  " .. property .. ":")

    if #value == 0 then
      log("    <empty>")
    else
      for i, entry in ipairs(value) do
        log("    [" .. i .. "] " .. readableTDB(entry))
      end
    end
  else
    log("  " .. property .. " = " .. readableTDB(value))
  end
end

local function dumpHealingItem(item)
  log("===== " .. item .. " =====")

  dumpItemFlat(item, "OnAttach")
  dumpItemFlat(item, "OnEquip")
  dumpItemFlat(item, "effectors")
  dumpItemFlat(item, "statModifiers")
  dumpItemFlat(item, "statModifierGroups")
  dumpItemFlat(item, "statPools")
  dumpItemFlat(item, "objectActions")
  dumpItemFlat(item, "UIData")
end

local function dumpHealingChildren(item)
  local equip = item .. "_inline4"
  local action = item .. "_inline0"

  log("===== ON EQUIP: " .. equip .. " =====")

  dumpItemFlat(equip, "effectors")
  dumpItemFlat(equip, "items")
  dumpItemFlat(equip, "statPools")
  dumpItemFlat(equip, "stats")
  dumpItemFlat(equip, "UIData")
  dumpItemFlat(equip, "stackable")

  log("===== ACTION: " .. action .. " =====")

  dumpItemFlat(action, "completionEffects")
  dumpItemFlat(action, "startEffects")
  dumpItemFlat(action, "activationTime")
  dumpItemFlat(action, "durationTime")
  dumpItemFlat(action, "costs")
  dumpItemFlat(action, "rewards")
  dumpItemFlat(action, "removeAfterUse")
  dumpItemFlat(action, "actionName")
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

local function dumpCompletionStatus(item)
  local completion = item .. "_inline3"

  log("===== COMPLETION: " .. completion .. " =====")

  local ok, statusEffect = pcall(function()
    return TweakDB:GetFlat(completion .. ".statusEffect")
  end)

  if not ok or statusEffect == nil then
    log("  statusEffect = <none>")
    return
  end

  local statusName = readableTDB(statusEffect)

  log("  statusEffect = " .. statusName)

  if statusName == nil or statusName == "" then
    return
  end

  scanInlineFlats(statusName, "valuePerSec", 30)
  scanInlineFlats(statusName, "statPoolValue", 30)
end

local function mdDesc(instant)
  return "Instantly restores " .. instant .. " health."
end

local function cloneRecordIfMissing(newId, baseId)
  local newTDBID = TweakDBID(newId)
  local baseTDBID = TweakDBID(baseId)

  local okGet, existing = pcall(function()
    return TweakDB:GetRecord(newTDBID)
  end)

  if okGet and existing ~= nil then
    log("record already exists: " .. newId)
    return true
  end

  local okClone, cloneResult = pcall(function()
    return TweakDB:CloneRecord(newTDBID, baseTDBID)
  end)

  if not okClone then
    log(
      "FAILED to clone record "
        .. newId
        .. " | ERROR: "
        .. tostring(cloneResult)
    )
    return false
  end

  if cloneResult ~= true then
    log(
      "FAILED to clone record "
        .. newId
        .. " | CloneRecord returned false"
    )
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

  -- MaxDoc instant heal
  -- setFlat("BaseStatusEffect.FirstAidWhiffV0_inline3.statPoolValue", MaxDoc1Heal)
  -- setFlat("BaseStatusEffect.FirstAidWhiffV1_inline3.statPoolValue", MaxDoc2Heal)
  -- setFlat("BaseStatusEffect.FirstAidWhiffV2_inline3.statPoolValue", MaxDoc3Heal)

  -------------------------------------------------------------------------
  -- UI updates
  -------------------------------------------------------------------------

  -- Bounce Back UIData is inline8
  setFlat(
    "Items.BonesMcCoy70V0_inline8.localizedDescription",
    bbDesc(CONFIG.BounceBack.V0.Instant, CONFIG.BounceBack.V0.HPS, BounceBackDuration)
  )

  setFlat(
    "Items.BonesMcCoy70V1_inline8.localizedDescription",
    bbDesc(CONFIG.BounceBack.V1.Instant, CONFIG.BounceBack.V1.HPS, BounceBackDuration)
  )

  setFlat(
    "Items.BonesMcCoy70V2_inline8.localizedDescription",
    bbDesc(CONFIG.BounceBack.V2.Instant, CONFIG.BounceBack.V2.HPS, BounceBackDuration)
  )

  setFlat("Items.BonesMcCoy70V0_inline8.intValues", {})
  setFlat("Items.BonesMcCoy70V1_inline8.intValues", {})
  setFlat("Items.BonesMcCoy70V2_inline8.intValues", {})

  -- MaxDoc UIData is inline7
  setFlat(
    "Items.FirstAidWhiffV0_inline7.localizedDescription",
    mdDesc(CONFIG.MaxDoc.V0)
  )

  setFlat(
    "Items.FirstAidWhiffV1_inline7.localizedDescription",
    mdDesc(CONFIG.MaxDoc.V1)
  )

  setFlat(
    "Items.FirstAidWhiffV2_inline7.localizedDescription",
    mdDesc(CONFIG.MaxDoc.V2)
  )

  setFlat("Items.FirstAidWhiffV0_inline7.intValues", {})
  setFlat("Items.FirstAidWhiffV1_inline7.intValues", {})
  setFlat("Items.FirstAidWhiffV2_inline7.intValues", {})

  log("loaded")
end)

return HealthTweaks
