local _, privateTable = ...
local ns = privateTable or ClassicProfessionCDs

ns.MinimapButton = {}

local BUTTON_SIZE = 31
local ICON_SIZE = 20
local RADIUS = 80
local dragging = false

local function UpdatePosition(button)
  local angle = math.rad(ns.Database:GetMinimapAngle() or 220)
  button:ClearAllPoints()
  button:SetPoint(
    "CENTER",
    Minimap,
    "CENTER",
    math.cos(angle) * RADIUS,
    math.sin(angle) * RADIUS
  )
end

local function OnUpdateDrag(button)
  local mx, my = Minimap:GetCenter()
  local px, py = GetCursorPosition()
  local scale = Minimap:GetEffectiveScale()
  px, py = px / scale, py / scale
  local angle = math.deg(math.atan2(py - my, px - mx))
  ns.Database:SetMinimapAngle(angle)
  UpdatePosition(button)
end

function ns.MinimapButton:Init()
  if self.button then
    return
  end

  local button = CreateFrame("Button", "ClassicProfessionCDsMinimapButton", Minimap)
  button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
  button:SetFrameStrata("MEDIUM")
  button:SetFrameLevel(8)
  button:SetMovable(true)
  button:RegisterForClicks("LeftButtonUp")
  button:RegisterForDrag("LeftButton")
  button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

  local overlay = button:CreateTexture(nil, "OVERLAY")
  overlay:SetSize(53, 53)
  overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  overlay:SetPoint("TOPLEFT")

  local background = button:CreateTexture(nil, "BACKGROUND")
  background:SetSize(ICON_SIZE, ICON_SIZE)
  background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
  background:SetPoint("CENTER")

  local icon = button:CreateTexture(nil, "ARTWORK")
  icon:SetSize(ICON_SIZE, ICON_SIZE)
  icon:SetTexture("Interface\\Icons\\INV_Misc_PocketWatch_01")
  icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
  icon:SetPoint("CENTER")
  button.icon = icon

  button:SetScript("OnClick", function()
    if dragging then
      dragging = false
      return
    end
    if ns.UI and ns.UI.Toggle then
      ns.UI:Toggle()
    end
  end)

  button:SetScript("OnDragStart", function(self)
    dragging = true
    self:SetScript("OnUpdate", OnUpdateDrag)
  end)

  button:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
  end)

  button:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("Classic Profession CDs")
    GameTooltip:AddLine("Click to toggle", 1, 1, 1)
    GameTooltip:AddLine("Drag to move", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("/cd", 0.5, 0.8, 0.5)
    GameTooltip:Show()
  end)

  button:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  self.button = button
  UpdatePosition(button)
  self:ApplyVisibility()
end

function ns.MinimapButton:ApplyVisibility()
  if not self.button then
    return
  end
  if ns.Database:GetMinimapHide() then
    self.button:Hide()
  else
    self.button:Show()
  end
end

function ns.MinimapButton:ToggleHide()
  local hide = not ns.Database:GetMinimapHide()
  ns.Database:SetMinimapHide(hide)
  self:ApplyVisibility()
  if hide then
    print("|cff33ff99Classic Profession CDs|r: minimap button hidden. Type |cffffffff/cd minimap|r to show it again.")
  else
    print("|cff33ff99Classic Profession CDs|r: minimap button shown.")
  end
end
