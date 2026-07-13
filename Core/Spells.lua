local _, privateTable = ...
local ns = privateTable or ClassicProfessionCDs

-- Classic Era spell IDs (Alchemy transmutes + Mooncloth).
-- Source: wowclassicdb / Wowhead Classic spell pages.
ns.SPELLS = {
  -- Alchemy: metals / arcanite
  {
    id = 17187,
    name = "Transmute: Arcanite",
    profession = "Alchemy",
    category = "transmute",
  },
  {
    id = 11479,
    name = "Transmute: Iron to Gold",
    profession = "Alchemy",
    category = "transmute",
  },
  {
    id = 11480,
    name = "Transmute: Mithril to Truesilver",
    profession = "Alchemy",
    category = "transmute",
  },
  -- Alchemy: elemental essences (often share a cooldown)
  {
    id = 17559,
    name = "Transmute: Air to Fire",
    profession = "Alchemy",
    category = "transmute",
  },
  {
    id = 17560,
    name = "Transmute: Fire to Earth",
    profession = "Alchemy",
    category = "transmute",
  },
  {
    id = 17561,
    name = "Transmute: Earth to Water",
    profession = "Alchemy",
    category = "transmute",
  },
  {
    id = 17562,
    name = "Transmute: Water to Air",
    profession = "Alchemy",
    category = "transmute",
  },
  {
    id = 17563,
    name = "Transmute: Undeath to Water",
    profession = "Alchemy",
    category = "transmute",
  },
  {
    id = 17564,
    name = "Transmute: Water to Undeath",
    profession = "Alchemy",
    category = "transmute",
  },
  {
    id = 17565,
    name = "Transmute: Earth to Life",
    profession = "Alchemy",
    category = "transmute",
  },
  {
    id = 17566,
    name = "Transmute: Life to Earth",
    profession = "Alchemy",
    category = "transmute",
  },
  -- Tailoring
  {
    id = 18560,
    name = "Mooncloth",
    profession = "Tailoring",
    category = "cloth",
  },
}

ns.SPELL_BY_ID = {}
for _, spell in ipairs(ns.SPELLS) do
  ns.SPELL_BY_ID[spell.id] = spell
end

function ns.GetSpellDisplayName(spellId)
  local info = ns.SPELL_BY_ID[spellId]
  local liveName = GetSpellInfo(spellId)
  if liveName and liveName ~= "" then
    return liveName
  end
  if info then
    return info.name
  end
  return ("Spell %d"):format(spellId)
end
