local _, privateTable = ...
local ns = privateTable or ClassicProfessionCDs

ns.Database = {
  ready = false,
}

local DEFAULTS = {
  version = 1,
  characters = {},
  ui = {
    point = "CENTER",
    relativePoint = "CENTER",
    x = 0,
    y = 0,
    selectedCharacter = nil,
  },
}

local function CopyDefaults(src, dst)
  if type(src) ~= "table" then
    return src
  end
  if type(dst) ~= "table" then
    dst = {}
  end
  for k, v in pairs(src) do
    if type(v) == "table" then
      dst[k] = CopyDefaults(v, dst[k])
    elseif dst[k] == nil then
      dst[k] = v
    end
  end
  return dst
end

function ns.Database:Init()
  ClassicProfessionCDsDB = CopyDefaults(DEFAULTS, ClassicProfessionCDsDB or {})
  self.db = ClassicProfessionCDsDB
  self.ready = true
end

function ns.Database:GetDB()
  return self.db
end

local function SeedCooldowns()
  local cooldowns = {}
  if ns.SPELLS then
    for _, spell in ipairs(ns.SPELLS) do
      cooldowns[spell.id] = { readyAt = 0, known = false }
    end
  end
  return cooldowns
end

function ns.Database:MakeCharacterKey(name, realm)
  if not name or name == "" or not realm or realm == "" then
    return nil
  end
  return name .. "-" .. realm
end

function ns.Database:CharacterKey()
  local name = UnitName("player")
  local realm = GetRealmName()
  if not name or not realm then
    return nil
  end
  return self:MakeCharacterKey(name, realm)
end

function ns.Database:EnsureCharacter()
  local key = self:CharacterKey()
  if not key then
    return nil
  end

  local chars = self.db.characters
  if not chars[key] then
    chars[key] = {
      name = UnitName("player"),
      realm = GetRealmName(),
      class = select(2, UnitClass("player")),
      faction = UnitFactionGroup("player"),
      cooldowns = SeedCooldowns(),
      updatedAt = GetServerTime(),
    }
  else
    chars[key].name = UnitName("player")
    chars[key].realm = GetRealmName()
    chars[key].class = select(2, UnitClass("player"))
    chars[key].faction = UnitFactionGroup("player")
  end

  return key, chars[key]
end

-- Manually add a roster entry (cooldowns stay Not learned until that alt is logged in).
function ns.Database:AddCharacter(name, realm)
  name = strtrim(name or "")
  realm = strtrim(realm or "")
  if name == "" then
    return nil, "Enter a character name."
  end
  if realm == "" then
    realm = GetRealmName() or ""
  end
  if realm == "" then
    return nil, "Enter a realm name."
  end

  local key = self:MakeCharacterKey(name, realm)
  local chars = self.db.characters
  if chars[key] then
    return key, chars[key], "Character already in the list."
  end

  chars[key] = {
    name = name,
    realm = realm,
    class = nil,
    faction = nil,
    cooldowns = SeedCooldowns(),
    updatedAt = GetServerTime(),
    manual = true,
  }
  return key, chars[key]
end

function ns.Database:RemoveCharacter(key)
  if not key or not self.db.characters[key] then
    return false
  end
  self.db.characters[key] = nil
  if self.db.ui.selectedCharacter == key then
    self.db.ui.selectedCharacter = nil
  end
  return true
end

function ns.Database:SetCooldown(spellId, readyAt, known)
  local _, char = self:EnsureCharacter()
  if not char then
    return
  end

  char.cooldowns[spellId] = {
    readyAt = readyAt or 0,
    known = known and true or false,
  }
  char.updatedAt = GetServerTime()
end

-- Only used when a profession window is open and we can see the full recipe list.
function ns.Database:ReconcileProfession(profession, seenIds)
  local _, char = self:EnsureCharacter()
  if not char then
    return
  end

  for spellId, data in pairs(char.cooldowns) do
    local info = ns.SPELL_BY_ID[spellId]
    -- Item-use CDs (Salt Shaker) are not always trade-skill rows; do not clear them here.
    if info and not info.itemId and info.profession == profession and data.known and not seenIds[spellId] then
      data.known = false
    end
  end
  char.updatedAt = GetServerTime()
end

function ns.Database:GetAllCharacters()
  return self.db.characters
end

function ns.Database:Wipe()
  self.db.characters = {}
  self:EnsureCharacter()
end

function ns.Database:GetUIPosition()
  return self.db.ui
end

function ns.Database:SetUIPosition(point, relativePoint, x, y)
  self.db.ui.point = point
  self.db.ui.relativePoint = relativePoint
  self.db.ui.x = x
  self.db.ui.y = y
end

function ns.Database:GetSelectedCharacter()
  return self.db.ui.selectedCharacter
end

function ns.Database:SetSelectedCharacter(key)
  self.db.ui.selectedCharacter = key
end
