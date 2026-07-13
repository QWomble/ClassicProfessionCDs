local _, privateTable = ...
local ns = privateTable or ClassicProfessionCDs

ns.UI = {}

local ROW_HEIGHT = 18
local FRAME_WIDTH = 440
local FRAME_HEIGHT = 420

local function CharacterLabel(char, key)
  if not char then
    return key or "Unknown"
  end
  local name = char.name or key
  if char.realm then
    return name .. " - " .. char.realm
  end
  return name
end

local function GetSortedCharacterKeys()
  local characters = ns.Database:GetAllCharacters()
  local keys = {}
  for key in pairs(characters) do
    table.insert(keys, key)
  end
  table.sort(keys)
  return keys, characters
end

local function ResolveSelectedKey()
  local keys, characters = GetSortedCharacterKeys()
  if #keys == 0 then
    return nil
  end

  local selected = ns.Database:GetSelectedCharacter()
  if selected and characters[selected] then
    return selected
  end

  local current = ns.Database:CharacterKey()
  if current and characters[current] then
    ns.Database:SetSelectedCharacter(current)
    return current
  end

  ns.Database:SetSelectedCharacter(keys[1])
  return keys[1]
end

local function SpellDisplayOrder()
  local spellOrder = {}
  for _, spell in ipairs(ns.SPELLS) do
    table.insert(spellOrder, spell)
  end
  table.sort(spellOrder, function(a, b)
    if a.profession ~= b.profession then
      return a.profession < b.profession
    end
    return a.name < b.name
  end)
  return spellOrder
end

local function BuildRows(selectedKey)
  local rows = {}
  if not selectedKey then
    return rows
  end

  local characters = ns.Database:GetAllCharacters()
  local char = characters[selectedKey]
  if not char then
    return rows
  end

  local cds = char.cooldowns or {}
  for _, spell in ipairs(SpellDisplayOrder()) do
    local data = cds[spell.id]
    local known = data and data.known
    if known then
      local text, ready = ns.Tracker:FormatRemaining(data.readyAt)
      table.insert(rows, {
        kind = "cooldown",
        spellId = spell.id,
        readyText = text,
        ready = ready,
        learned = true,
        profession = spell.profession,
      })
    else
      table.insert(rows, {
        kind = "cooldown",
        spellId = spell.id,
        readyText = "Not learned",
        ready = false,
        learned = false,
        profession = spell.profession,
      })
    end
  end

  return rows
end

function ns.UI:UpdateCharDropdown()
  local dropdown = self.charDropdown
  if not dropdown then
    return
  end

  local selectedKey = ResolveSelectedKey()
  local characters = ns.Database:GetAllCharacters()
  if selectedKey and characters[selectedKey] then
    UIDropDownMenu_SetText(dropdown, CharacterLabel(characters[selectedKey], selectedKey))
    UIDropDownMenu_SetSelectedValue(dropdown, selectedKey)
  else
    UIDropDownMenu_SetText(dropdown, "No characters")
  end
end

function ns.UI:Init()
  local template = BackdropTemplateMixin and "BackdropTemplate" or nil
  local frame = CreateFrame("Frame", "ClassicProfessionCDsFrame", UIParent, template)
  frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relativePoint, x, y = self:GetPoint(1)
    ns.Database:SetUIPosition(point, relativePoint, x, y)
  end)
  frame:SetFrameStrata("DIALOG")
  frame:Hide()

  if frame.SetBackdrop then
    frame:SetBackdrop({
      bgFile = "Interface\\Buttons\\WHITE8X8",
      edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
      tile = true,
      tileSize = 8,
      edgeSize = 32,
      insets = { left = 8, right = 8, top = 8, bottom = 8 },
    })
    frame:SetBackdropColor(0, 0, 0, 1)
  end

  local pos = ns.Database:GetUIPosition()
  frame:ClearAllPoints()
  frame:SetPoint(pos.point or "CENTER", UIParent, pos.relativePoint or "CENTER", pos.x or 0, pos.y or 0)

  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOP", 0, -16)
  title:SetText("Classic Profession CDs")

  local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  subtitle:SetPoint("TOP", title, "BOTTOM", 0, -4)
  subtitle:SetText("Transmutes, Mooncloth & Salt Shaker — /cd")

  local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -4, -4)

  local charLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  charLabel:SetPoint("TOPLEFT", 24, -56)
  charLabel:SetText("Character:")

  local dropdown = CreateFrame("Frame", "ClassicProfessionCDsCharDropDown", frame, "UIDropDownMenuTemplate")
  dropdown:SetPoint("LEFT", charLabel, "RIGHT", -8, -2)
  UIDropDownMenu_SetWidth(dropdown, 220)
  UIDropDownMenu_JustifyText(dropdown, "LEFT")
  UIDropDownMenu_Initialize(dropdown, function(_, level)
    local keys, characters = GetSortedCharacterKeys()
    local selected = ns.Database:GetSelectedCharacter()
    for _, key in ipairs(keys) do
      local char = characters[key]
      local info = UIDropDownMenu_CreateInfo()
      info.text = CharacterLabel(char, key)
      info.value = key
      info.checked = (key == selected)
      info.arg1 = key
      info.func = function(_, characterKey)
        ns.Database:SetSelectedCharacter(characterKey)
        UIDropDownMenu_SetSelectedValue(dropdown, characterKey)
        UIDropDownMenu_SetText(dropdown, CharacterLabel(characters[characterKey], characterKey))
        ns.UI:Refresh()
      end
      if char and char.class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[char.class] then
        local c = RAID_CLASS_COLORS[char.class]
        info.colorCode = string.format("|cff%02x%02x%02x", c.r * 255, c.g * 255, c.b * 255)
      end
      UIDropDownMenu_AddButton(info, level)
    end
  end)

  local refresh = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  refresh:SetSize(80, 22)
  refresh:SetPoint("BOTTOMLEFT", 16, 16)
  refresh:SetText("Refresh")
  refresh:SetScript("OnClick", function()
    ns.Tracker:Scan()
    ns.UI:Refresh()
  end)

  local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  hint:SetPoint("LEFT", refresh, "RIGHT", 10, 0)
  hint:SetPoint("RIGHT", frame, "RIGHT", -16, 0)
  hint:SetJustifyH("LEFT")
  hint:SetText("Log into each alt once (addon enabled) to list them. No recipes still show as Not learned.")

  local scroll = CreateFrame("ScrollFrame", "ClassicProfessionCDsScroll", frame, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 20, -86)
  scroll:SetPoint("BOTTOMRIGHT", -36, 48)

  local content = CreateFrame("Frame", nil, scroll)
  content:SetSize(FRAME_WIDTH - 60, 1)
  scroll:SetScrollChild(content)

  self.frame = frame
  self.content = content
  self.rowFrames = {}
  self.subtitle = subtitle
  self.charDropdown = dropdown

  -- Lightweight ticker while visible so "Ready" flips without a reload.
  frame:SetScript("OnShow", function()
    ns.Tracker:Scan()
    ns.UI:Refresh()
    if self.ticker then
      self.ticker:Cancel()
    end
    if C_Timer and C_Timer.NewTicker then
      self.ticker = C_Timer.NewTicker(30, function()
        if frame:IsShown() then
          ns.UI:Refresh()
        end
      end)
    end
  end)
  frame:SetScript("OnHide", function()
    if self.ticker then
      self.ticker:Cancel()
      self.ticker = nil
    end
  end)
end

function ns.UI:ClearRows()
  for _, row in ipairs(self.rowFrames) do
    row:Hide()
  end
end

function ns.UI:AcquireRow(index)
  local row = self.rowFrames[index]
  if row then
    row:Show()
    return row
  end

  row = CreateFrame("Frame", nil, self.content)
  row:SetSize(FRAME_WIDTH - 60, ROW_HEIGHT)
  row.left = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  row.left:SetPoint("LEFT", 0, 0)
  row.left:SetJustifyH("LEFT")
  row.right = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  row.right:SetPoint("RIGHT", 0, 0)
  row.right:SetJustifyH("RIGHT")
  self.rowFrames[index] = row
  return row
end

function ns.UI:Refresh()
  if not self.frame then
    return
  end

  self:UpdateCharDropdown()
  self:ClearRows()

  local selectedKey = ResolveSelectedKey()
  local rows = BuildRows(selectedKey)
  local y = 0

  if #rows == 0 then
    local row = self:AcquireRow(1)
    row:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, 0)
    row.left:SetText("No characters yet. Log into each alt with the addon enabled, then /reload.")
    row.left:SetTextColor(0.7, 0.7, 0.7)
    row.right:SetText("")
    self.content:SetHeight(ROW_HEIGHT)
    return
  end

  for i, data in ipairs(rows) do
    local row = self:AcquireRow(i)
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, -y)

    local name = ns.GetSpellDisplayName(data.spellId)
    row.left:SetText(name)
    row.right:SetText(data.readyText)
    if not data.learned then
      row.left:SetTextColor(0.55, 0.55, 0.55)
      row.right:SetTextColor(0.55, 0.55, 0.55)
    elseif data.ready then
      row.left:SetTextColor(0.9, 0.9, 0.9)
      row.right:SetTextColor(0.2, 0.9, 0.3)
    else
      row.left:SetTextColor(0.9, 0.9, 0.9)
      row.right:SetTextColor(1, 0.82, 0)
    end

    y = y + ROW_HEIGHT
  end

  self.content:SetHeight(math.max(y, 1))
end

function ns.UI:RefreshIfVisible()
  if self.frame and self.frame:IsShown() then
    self:Refresh()
  end
end

function ns.UI:Toggle()
  if not self.frame then
    print("|cff33ff99Classic Profession CDs|r: UI not ready. Try /reload.")
    return
  end
  if self.frame:IsShown() then
    self.frame:Hide()
  else
    self.frame:Show()
  end
end

function ns.UI:ResetPosition()
  if not self.frame then
    return
  end
  ns.Database:SetUIPosition("CENTER", "CENTER", 0, 0)
  self.frame:ClearAllPoints()
  self.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
end
