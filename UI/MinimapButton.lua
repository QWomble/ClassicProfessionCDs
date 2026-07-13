local _, privateTable = ...
local ns = privateTable or ClassicProfessionCDs

ns.MinimapButton = {}

local BUTTON_SIZE = 32
local dragging = false

-- Keep the icon outside the circular minimap mask by parenting to the cluster.
local function GetButtonParent()
  if MinimapCluster and MinimapCluster.GetObjectType then
    return MinimapCluster
  end
  return Minimap
end

local function GetRadius()
  if not Minimap then
    return 80
  end
  return (Minimap:GetWidth() / 2) + 10
end

local function UpdatePosition(button)
  if not Minimap or not button then
    return
  end
  local angle = math.rad(ns.Database:GetMinimapAngle() or 220)
  local radius = GetRadius()
  button:ClearAllPoints()
  button:SetPoint(
    "CENTER",
    Minimap,
    "CENTER",
    math.cos(angle) * radius,
    math.sin(angle) * radius
  )
end

local function OnUpdateDrag(button)
  if not Minimap then
    return
  end
  local mx, my = Minimap:GetCenter()
  if not mx or not my then
    return
  end
  local px, py = GetCursorPosition()
  local scale = Minimap:GetEffectiveScale()
  if not scale or scale == 0 then
    return
  end
  px, py = px / scale, py / scale
  local angle = math.deg(math.atan2(py - my, px - mx))
  ns.Database:SetMinimapAngle(angle)
  UpdatePosition(button)
end

function ns.MinimapButton:Init()
  if self.button or not Minimap then
    return
  end

  local button = CreateFrame("Button", "ClassicProfessionCDsMinimapButton", GetButtonParent())
  button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
  button:SetFrameStrata("MEDIUM")
  button:SetFrameLevel((Minimap:GetFrameLevel() or 0) + 16)
  button:SetMovable(true)
  button:EnableMouse(true)
  button:RegisterForClicks("AnyUp")
  button:RegisterForDrag("LeftButton")
  button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

  local overlay = button:CreateTexture(nil, "OVERLAY")
  overlay:SetSize(54, 54)
  overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  overlay:SetPoint("TOPLEFT", 0, 0)

  local background = button:CreateTexture(nil, "BACKGROUND")
  background:SetSize(20, 20)
  background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
  background:SetPoint("CENTER")

  local icon = button:CreateTexture(nil, "ARTWORK")
  icon:SetSize(18, 18)
  icon:SetTexture("Interface\\Icons\\INV_Misc_PocketWatch_01")
  icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  icon:SetPoint("CENTER")
  button.icon = icon

  button:SetScript("OnClick", function(_, mouseButton)
    if dragging then
      dragging = false
      return
    end
    if mouseButton ~= "LeftButton" then
      return
    end
    if ns.UI and ns.UI.Toggle then
      ns.UI:Toggle()
    end
  end)

  button:SetScript("OnDragStart", function(self)
    dragging = true
    self:LockHighlight()
    self:SetScript("OnUpdate", OnUpdateDrag)
  end)

  button:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
    self:UnlockHighlight()
    -- Swallow the click that follows a drag.
    dragging = true
    if C_Timer and C_Timer.After then
      C_Timer.After(0, function()
        dragging = false
      end)
    else
      dragging = false
    end
  end)

  button:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("Classic Profession CDs")
    GameTooltip:AddLine("Left-click to toggle", 1, 1, 1)
    GameTooltip:AddLine("Drag to move", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("/cd or /cpcd", 0.5, 0.8, 0.5)
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
