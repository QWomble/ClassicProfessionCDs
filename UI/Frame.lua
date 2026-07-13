local _, privateTable = ...
local ns = privateTable or ClassicProfessionCDs

ns.UI = {}

local ROW_HEIGHT = 18
local FRAME_WIDTH = 420
local FRAME_HEIGHT = 360

local function ClassColor(classToken)
  if not classToken or not RAID_CLASS_COLORS or not RAID_CLASS_COLORS[classToken] then
    return 1, 1, 1
  end
  local c = RAID_CLASS_COLORS[classToken]
  return c.r, c.g, c.b
end

local function BuildRows()
  local rows = {}
  local characters = ns.Database:GetAllCharacters()

  local keys = {}
  for key in pairs(characters) do
    table.insert(keys, key)
  end
  table.sort(keys)

  for _, key in ipairs(keys) do
    local char = characters[key]
    local cds = char.cooldowns or {}
    local spellIds = {}
    for spellId, data in pairs(cds) do
      if data and data.known then
        table.insert(spellIds, spellId)
      end
    end
    table.sort(spellIds, function(a, b)
      local na = ns.GetSpellDisplayName(a)
      local nb = ns.GetSpellDisplayName(b)
      return na < nb
    end)

    if #spellIds == 0 then
      table.insert(rows, {
        kind = "character",
        key = key,
        char = char,
        empty = true,
      })
    else
      table.insert(rows, {
        kind = "character",
        key = key,
        char = char,
        empty = false,
      })
      for _, spellId in ipairs(spellIds) do
        local data = cds[spellId]
        local text, ready = ns.Tracker:FormatRemaining(data.readyAt)
        table.insert(rows, {
          kind = "cooldown",
          spellId = spellId,
          readyText = text,
          ready = ready,
          profession = ns.SPELL_BY_ID[spellId] and ns.SPELL_BY_ID[spellId].profession or "",
        })
      end
    end
  end

  return rows
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
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
      tile = true,
      tileSize = 32,
      edgeSize = 32,
      insets = { left = 8, right = 8, top = 8, bottom = 8 },
    })
  end

  local pos = ns.Database:GetUIPosition()
  frame:ClearAllPoints()
  frame:SetPoint(pos.point or "CENTER", UIParent, pos.relativePoint or "CENTER", pos.x or 0, pos.y or 0)

  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOP", 0, -16)
  title:SetText("Classic Profession CDs")

  local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  subtitle:SetPoint("TOP", title, "BOTTOM", 0, -4)
  subtitle:SetText("Alchemy transmutes & Mooncloth — /cpcd")

  local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -4, -4)

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
  hint:SetText("Log each crafting alt once to record recipes.")

  local scroll = CreateFrame("ScrollFrame", "ClassicProfessionCDsScroll", frame, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 20, -48)
  scroll:SetPoint("BOTTOMRIGHT", -36, 48)

  local content = CreateFrame("Frame", nil, scroll)
  content:SetSize(FRAME_WIDTH - 60, 1)
  scroll:SetScrollChild(content)

  self.frame = frame
  self.content = content
  self.rowFrames = {}
  self.subtitle = subtitle

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

  self:ClearRows()
  local rows = BuildRows()
  local y = 0

  if #rows == 0 then
    local row = self:AcquireRow(1)
    row:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, 0)
    row.left:SetText("No data yet. Open Alchemy/Tailoring or craft on each alt.")
    row.left:SetTextColor(0.7, 0.7, 0.7)
    row.right:SetText("")
    self.content:SetHeight(ROW_HEIGHT)
    return
  end

  for i, data in ipairs(rows) do
    local row = self:AcquireRow(i)
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, -y)

    if data.kind == "character" then
      local label = data.char.name or data.key
      if data.char.realm then
        label = label .. "  |cffaaaaaa" .. data.char.realm .. "|r"
      end
      row.left:SetText(label)
      row.left:SetTextColor(ClassColor(data.char.class))
      if data.empty then
        row.right:SetText("no tracked recipes")
        row.right:SetTextColor(0.5, 0.5, 0.5)
      else
        row.right:SetText("")
      end
    else
      local name = ns.GetSpellDisplayName(data.spellId)
      row.left:SetText("  " .. name)
      row.left:SetTextColor(0.9, 0.9, 0.9)
      row.right:SetText(data.readyText)
      if data.ready then
        row.right:SetTextColor(0.2, 0.9, 0.3)
      else
        row.right:SetTextColor(1, 0.82, 0)
      end
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
