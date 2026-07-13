local _, privateTable = ...
local ns = privateTable or ClassicProfessionCDs

ns.Tracker = {}

-- Ignore global cooldown and other short timers.
local MIN_PROFESSION_CD_SECONDS = 60

local function PlayerKnowsSpell(spellId)
  if IsPlayerSpell and IsPlayerSpell(spellId) then
    return true
  end
  if IsSpellKnown and IsSpellKnown(spellId) then
    return true
  end
  return false
end

local function ReadCooldownRemaining(spellId)
  local name = GetSpellInfo(spellId)
  local start, duration, enabled

  if name then
    start, duration, enabled = GetSpellCooldown(name)
  end

  if (not start or not duration) and GetSpellCooldown then
    start, duration, enabled = GetSpellCooldown(spellId)
  end

  if not start or not duration then
    return nil
  end

  if enabled == 0 then
    return nil
  end

  if start > 0 and duration >= MIN_PROFESSION_CD_SECONDS then
    local remaining = (start + duration) - GetTime()
    if remaining < 0 then
      remaining = 0
    end
    return remaining
  end

  return 0
end

-- When the trade skill UI is open, match recipe names to tracked spells.
local function ScanOpenTradeSkill()
  if not GetNumTradeSkills then
    return
  end

  local num = GetNumTradeSkills()
  if not num or num <= 0 then
    return
  end

  local skillLineName = GetTradeSkillLine and GetTradeSkillLine() or nil
  local seenByProfession = {}

  for i = 1, num do
    local skillName, skillType = GetTradeSkillInfo(i)
    if skillName and skillType ~= "header" then
      for _, spell in ipairs(ns.SPELLS) do
        local display = ns.GetSpellDisplayName(spell.id)
        if skillName == display or skillName == spell.name then
          seenByProfession[spell.profession] = seenByProfession[spell.profession] or {}
          seenByProfession[spell.profession][spell.id] = true

          local cooldown = GetTradeSkillCooldown and GetTradeSkillCooldown(i)
          if type(cooldown) == "number" and cooldown >= MIN_PROFESSION_CD_SECONDS then
            ns.Database:SetCooldown(spell.id, GetServerTime() + cooldown, true)
          elseif type(cooldown) == "number" then
            ns.Database:SetCooldown(spell.id, 0, true)
          else
            local remaining = ReadCooldownRemaining(spell.id)
            if remaining == nil or remaining == 0 then
              ns.Database:SetCooldown(spell.id, 0, true)
            else
              ns.Database:SetCooldown(spell.id, GetServerTime() + remaining, true)
            end
          end
        end
      end
    end
  end

  -- If we opened Alchemy or Tailoring, drop recipes for that profession that vanished.
  if skillLineName == "Alchemy" or skillLineName == "Tailoring" then
    ns.Database:ReconcileProfession(skillLineName, seenByProfession[skillLineName] or {})
  end
end

function ns.Tracker:IsTrackedSpell(spellId)
  return spellId and ns.SPELL_BY_ID[spellId] ~= nil
end

function ns.Tracker:Scan()
  if not ns.Database.ready then
    return
  end

  ns.Database:EnsureCharacter()

  for _, spell in ipairs(ns.SPELLS) do
    local spellId = spell.id
    if PlayerKnowsSpell(spellId) then
      local remaining = ReadCooldownRemaining(spellId)
      if remaining == nil then
        -- Keep previous saved row; still mark known.
        local _, char = ns.Database:EnsureCharacter()
        if char and not char.cooldowns[spellId] then
          ns.Database:SetCooldown(spellId, 0, true)
        elseif char and char.cooldowns[spellId] then
          char.cooldowns[spellId].known = true
          char.updatedAt = GetServerTime()
        end
      elseif remaining == 0 then
        ns.Database:SetCooldown(spellId, 0, true)
      else
        ns.Database:SetCooldown(spellId, GetServerTime() + remaining, true)
      end
    end
  end

  ScanOpenTradeSkill()
end

function ns.Tracker:FormatRemaining(readyAt)
  local now = GetServerTime()
  if not readyAt or readyAt <= 0 or readyAt <= now then
    return "Ready", true
  end

  local remaining = readyAt - now
  local days = math.floor(remaining / 86400)
  local hours = math.floor((remaining % 86400) / 3600)
  local minutes = math.floor((remaining % 3600) / 60)

  local parts = {}
  if days > 0 then
    table.insert(parts, days .. "d")
  end
  if hours > 0 or days > 0 then
    table.insert(parts, hours .. "h")
  end
  table.insert(parts, minutes .. "m")

  return table.concat(parts, " "), false
end
