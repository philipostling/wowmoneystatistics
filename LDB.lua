local addon_name, addon = ...

local core = addon.core
local menu = addon.menu
local tt = addon.tooltip
local util = addon.utility
local sd = addon.statDisplay
local ldbt = addon.ldb

local ldb

-- TitanPanel calls some of the same methods I do to create the right-click context menus; Bypassing.
local TitanHack 
local function OnEnter(self)
   TitanHack = TitanPanelRightClickMenu_Toggle
   TitanPanelRightClickMenu_Toggle = function(...) end

   util.SetLDBInteraction(true)

   if (not menu.IsMenuOpen()) then
      tt.ShowTooltip(self)
   end
end

local function OnLeave(self)
   tt.HideTooltip()
   TitanPanelRightClickMenu_Toggle = TitanHack
end

local function OnClick(self, button)
   if menu.IsMenuOpen() then
      -- if context menu is open allow both left and right clicks to close it
      menu.CloseMenu()
   elseif button == "RightButton" then
      tt.HideTooltip()
      menu.ToggleMenu(self)
   elseif button == "LeftButton" then
      sd.ToggleDialog()
   end
end

local frame = CreateFrame("Frame")
local loaded = false


ldb = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject (addon_name,
   {
      type = "launcher",
      icon = "Interface\\Icons\\INV_Misc_Coin_17",
      OnEnter = OnEnter,
      OnLeave = OnLeave,
      OnClick = OnClick,
      text = "", -- Rational: Need to wait for version changes before I update the text
   }
)

local function EventHandler(self, event, ...)
   if event == "PLAYER_ENTERING_WORLD" and loaded then
      return
   elseif event == "PLAYER_ENTERING_WORLD" then
      addon.debugPrint("LDB Event", event, ...)
      self:SetScript("OnUpdate", 
         function(self, elapsed)
            if core.VersionChangesApplied then
               loaded = true
               self:SetScript("OnUpdate", nil)
               ldb.text = util.FormatMoney(GetMoney())
            end
         end
      )
   elseif event == "PLAYER_MONEY" then
      if ldb then
         ldb.text = util.FormatMoney(GetMoney())
      end
   end

end
util.RegisterEvents(frame, EventHandler,
                              'PLAYER_ENTERING_WORLD',
                              'PLAYER_MONEY')

function ldbt.GetLDB()
   return ldb
end
