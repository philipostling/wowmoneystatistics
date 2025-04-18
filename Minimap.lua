local addon_name, addon = ...
local minimap = addon.minimap

local core = addon.core
local ldb = addon.ldb
local tt = addon.tooltip
local menu = addon.menu
local util = addon.utility
local profile = addon.profile
local sd = addon.statDisplay
local global = addon.global
local _G = _G

local realm = GetRealmName()
local _, class = UnitClass("player")
local player = UnitName("player")
local faction = UnitFactionGroup("player")

local mmb

local function SetMinimapLock(lock)
   return mmb:SetMinimapLock(lock)
end

local function SetMinimapHidden(hide)
   return mmb:SetMinimapHidden(hide)
end

local function SetLock(lock)
   return mmb:SetLock(lock)
end

local function OnEnter(self)
   util.SetLDBInteraction(false)
   if (not menu.IsMenuOpen()) and not mmb:IsDragging() then
      tt.ShowTooltip(self)
   end
end

local function OnLeave(self)
   tt.HideTooltip()
end

local function OnClick(self, button, down)
   if not down and menu.IsMenuOpen() then
      -- if context menu is open allow both left and right clicks to close it
      menu.CloseMenu()
      OnEnter(self)
   elseif button == "RightButton" and not down then
      tt.HideTooltip()
      menu.ToggleMenu(mmb.button)
   elseif button == "LeftButton" and not menu.IsMenuOpen() and not mmb:IsDragging() and not down then
      sd.ToggleDialog()
   end
end

local frame = CreateFrame("Frame")
local function EventHandler(self, event, ...)
   local args = {...}
   if event == "ADDON_LOADED" and args[1] ~= addon_name then
      return
   end

   addon.debugPrint("Minimap Event", event, ...)
   if event == "ADDON_LOADED" and args[1] == addon_name then
      global.InitGlobals()

      self:SetScript("OnUpdate", 
         function(self, elapsed)
            if core.VersionChangesApplied then
               local IsAddOnLoaded = C_AddOns.IsAddOnLoaded or IsAddOnLoaded;
               if (IsAddOnLoaded("SexyMap") and profile.GetSexyCompatSetting())
                  or IsAddOnLoaded("MBB") then
                  mmb = LibStub("LibDBIcon-1.0")
                  mmb:Register(addon_name, ldb.GetLDB(), _G.WOWMSProfile[realm][player].Minimap)
               else
                  mmb = 
                  Prototype_MMB:new(
                     {
                        IconTexture = "Interface\\Icons\\INV_Misc_Coin_17",
                        IsMinimapLocked = profile.GetMinimapLockSetting(),
                        IsMinimapHidden = profile.GetMinimapHideSetting(),
                        IsLocked = profile.GetLockSetting(),
                        OnPositionChange = 
                           function(x, y)
                              menu.CloseMenu()
                              tt.HideTooltip()
                              profile.SetMinimapButtonPos(x, y)
                           end,
                        OnEnter = OnEnter,
                        OnLeave = OnLeave,
                        OnClick = OnClick,
                     }
                  )
                  mmb:Initialize(addon_name, profile.GetMinimapButtonXPos(), profile.GetMinimapButtonYPos())
               end
               self:SetScript("OnUpdate", nil)
            end
         end
      )
   end
end

util.RegisterEvents(frame, EventHandler, 'ADDON_LOADED')

minimap.GetMinimapLockSetting = GetMinimapLockSetting
minimap.SetMinimapLock = SetMinimapLock
minimap.GetMinimapHideSetting = GetMinimapHideSetting
minimap.SetMinimapHidden = SetMinimapHidden
minimap.GetLockSetting = GetLockSetting
minimap.SetLock = SetLock
