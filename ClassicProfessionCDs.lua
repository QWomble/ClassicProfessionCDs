--[[
  Classic Profession CDs
  Free, open-source Classic Era add-on.
  Complies with Blizzard UI Add-On Development Policy:
  https://us.forums.blizzard.com/en/wow/t/ui-add-on-development-policy/24534
]]

local ADDON_NAME, privateTable = ...

local ns = privateTable or {}
ns.ADDON_NAME = ADDON_NAME
ns.VERSION = "1.2.0"

-- Shared namespace used by all files loaded after this one.
ClassicProfessionCDs = ns

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_LOGOUT")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
eventFrame:RegisterEvent("BAG_UPDATE_COOLDOWN")
eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
eventFrame:RegisterEvent("TRADE_SKILL_SHOW")
eventFrame:RegisterEvent("TRADE_SKILL_CLOSE")

eventFrame:SetScript("OnEvent", function(_, event, arg1, ...)
  if event == "ADDON_LOADED" then
    if arg1 ~= ADDON_NAME then
      return
    end
    ns.Database:Init()
    if UnitName("player") then
      ns.Database:EnsureCharacter()
    end
    ns.UI:Init()
    return
  end

  if not ns.Database or not ns.Database.ready then
    return
  end

  if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
    ns.Database:EnsureCharacter()
    ns.Tracker:Scan()
    if ns.UI and ns.UI.RefreshIfVisible then
      ns.UI:RefreshIfVisible()
    end
  elseif event == "PLAYER_LOGOUT" then
    ns.Tracker:Scan()
  elseif event == "SPELL_UPDATE_COOLDOWN"
    or event == "BAG_UPDATE_COOLDOWN"
    or event == "TRADE_SKILL_SHOW"
    or event == "TRADE_SKILL_CLOSE" then
    ns.Tracker:Scan()
    if ns.UI and ns.UI.RefreshIfVisible then
      ns.UI:RefreshIfVisible()
    end
  elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
    -- Modern Classic Era: unit, castGUID, spellID
    -- Older signature: unit, spellName, rank, lineID, spellID
    if arg1 ~= "player" then
      return
    end
    local a, b, c, d = ...
    local id
    if type(b) == "number" then
      id = b
    elseif type(d) == "number" then
      id = d
    elseif type(c) == "number" then
      id = c
    end
    if ns.Tracker:IsTrackedSpell(id) then
      local function rescan()
        ns.Tracker:Scan()
        if ns.UI and ns.UI.RefreshIfVisible then
          ns.UI:RefreshIfVisible()
        end
      end
      if C_Timer and C_Timer.After then
        C_Timer.After(0.5, rescan)
      else
        rescan()
      end
    end
  end
end)

SLASH_CLASSICPROFESSIONCDS1 = "/cpcd"
SLASH_CLASSICPROFESSIONCDS2 = "/professioncds"
SlashCmdList.CLASSICPROFESSIONCDS = function(msg)
  msg = (msg or ""):match("^%s*(.-)%s*$") or ""
  msg = msg:lower()

  if msg == "" or msg == "toggle" then
    ns.UI:Toggle()
  elseif msg == "reset" then
    ns.UI:ResetPosition()
    print("|cff33ff99Classic Profession CDs|r: window position reset.")
  elseif msg == "wipe" then
    ns.Database:Wipe()
    ns.Tracker:Scan()
    ns.UI:RefreshIfVisible()
    print("|cff33ff99Classic Profession CDs|r: all saved data cleared.")
  elseif msg == "scan" then
    ns.Tracker:Scan()
    ns.UI:RefreshIfVisible()
    print("|cff33ff99Classic Profession CDs|r: scanned current character.")
  elseif msg == "help" then
    print("|cff33ff99Classic Profession CDs|r commands:")
    print("  /cpcd — toggle window")
    print("  /cpcd scan — refresh current character")
    print("  /cpcd reset — reset window position")
    print("  /cpcd wipe — clear all saved data")
    print("  /cpcd help — this list")
  else
    print("|cff33ff99Classic Profession CDs|r: unknown command. Try |cffffffff/cpcd help|r")
  end
end
