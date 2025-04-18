local addon_name, addon = ...
local menu = addon.menu

local util = addon.utility
local profile = addon.profile
local time = addon.time
local tt = addon.tooltip
local sd = addon.statDisplay
local minimap = addon.minimap
local debug = addon.debug
local fonts = addon.fonts
local mt = addon.mt
--local goals = addon.goals
local _G = _G

local cm

local realm = GetRealmName()
local player = UnitName("player")

-- Right-Click context cm initialization
local function ContextMenu_OnLoad(self, level, menuList)
   if cm then
      if level == 1 then
         -- If SexyMap is loaded this addon will allow SexyMap to control minimap icon movements and visibility
         -- Don't allow any context cm options to be visible that will not function
         local sexyMapLoaded = C_AddOns.IsAddOnLoaded("SexyMap")
         local mbbLoaded = C_AddOns.IsAddOnLoaded("MBB")
         local elvUILoaded = C_AddOns.IsAddOnLoaded("ElvUI")

         cm:AddDescriptor    (  "WoW Money Statistics", 1, true )
            cm:AddDescriptor    (  "-------------------", level )
         --[===[@debug
         -- TODO: Add Goals
         cm:AddOption        (  "Manage Goals",
                                    1,
                                    function(self)
                                       goals.ToggleDialog()
                                    end)
         cm:AddDescriptor    (  "-------------------", 1 )
         --@end-debug]===]
         cm:AddCheckOption   (  "Faction Only View",
                                    function(self)
                                       return profile.GetFactionDisplaySetting()
                                    end,
                                    1,
                                    function(self, _, _, checked) 
                                       profile.SetFactionDisplaySetting(checked)
                                       sd.UpdateStatDialog()
                                    end
                                 )
         cm:AddDescriptor    (  "-------------------", 1 )
         cm:AddMenu          (  "Tooltip", 1, "Tooltips" )
         if not util.IsLDBInteraction() and (not sexyMapLoaded or not profile.GetSexyCompatSetting()) and not mbbLoaded then
            cm:AddMenu          (  "Minimap Button", 1, "Minimaps" )
         elseif util.IsLDBInteraction() and (not sexyMapLoaded or not profile.GetSexyCompatSetting()) and not mbbLoaded then
            cm:AddCheckOption   (  "Hide Minimap Icon",
                                       function(self)
                                          return profile.GetMinimapHideSetting()
                                       end,
                                       1,
                                       function(self, _, _, checked) 
                                          profile.SetMinimapHideSetting(minimap.SetMinimapHidden(checked))
                                       end
                                    )
         end
         cm:AddDescriptor    (  "-------------------", 1 )
         cm:AddMenu          (  "Character", 1, "CharacterSettings" )
         cm:AddMenu          (  "Profile", 1, "ProfileSettings" )
         cm:AddDescriptor    (  "-------------------", 1 )
         cm:AddMenu          (  "Money Format", 1, "GoldFormats" )
         cm:AddDescriptor    (  "-------------------", 1 )
         if elvUILoaded then
            cm:AddCheckOption   (  "Use ElvUI Font",
                                       function(self)
                                          return profile.GetElvUIFontSetting()
                                       end,
                                       1,
                                       function(self, _, _, checked)
                                          profile.SetElvUIFontSetting(checked)
                                          menu:CloseMenu()
                                       end
                                )
         end
         if not profile.GetElvUIFontSetting() or not elvUILoaded then
            cm:AddMenu          (  "Font", 1, "Fonts" )
            cm:AddMenu          (  "Font Size", 1, "FontSize" )
         end
         cm:AddDescriptor    (  "-------------------", 1 )
         cm:AddMenu          (  "|cFFFF3333Remove Character|r", 1, "Removes" )
         cm:AddMenu          (  "|cFFFF3333Reset|r", 1, "Resets" )
         --[===[@debug
         cm:AddDescriptor    (  "-------------------", 1 )
         cm:AddMenu          (  "Debug", 1, "Debug" )
         --@end-debug]===]
      elseif level == 2 then
         if menuList == "Tooltips" then
            cm:AddDescriptor    (  "Tooltip", level, true )
            cm:AddDescriptor    (  "-------------------", level )
            tt.OptionalSettingMenu(cm, level, menuList)
         elseif menuList == "Debug" then
            cm:AddDescriptor    (  "Debug", level, true )
            cm:AddDescriptor    (  "-------------------", level )
            debug.debugContextMenu(cm, level)
         elseif menuList == "Minimaps" then
            cm:AddDescriptor    (  "Minimap Button", level, true )
            cm:AddDescriptor    (  "-------------------", level )
            cm:AddCheckOption   (  "Lock to Minimap",
                                       function(self)
                                          return profile.GetMinimapLockSetting()
                                       end,
                                       level,
                                       function(self, _, _, checked) 
                                          profile.SetMinimapLockSetting(minimap.SetMinimapLock(checked))
                                       end
                                    )
            cm:AddCheckOption   (  "Lock",
                                       function(self)
                                          return profile.GetLockSetting()
                                       end,
                                       level,
                                       function(self, _, _, checked) 
                                          profile.SetLockSetting(minimap.SetLock(checked))
                                       end
                                    )
         elseif menuList == "CharacterSettings" then
            cm:AddDescriptor    (  "Character", level, true )
            cm:AddDescriptor    (  "-------------------", level )
            cm:AddCheckOption   (  "Bank Character",
                                       function(self)
                                          return profile.GetBankCharacterSetting()
                                       end,
                                       level,
                                       function(self, _, _, checked) 
                                          profile.SetBankCharacterSetting(checked)
                                          util.UpdatePlayerCash()
                                       end
                                    )
         elseif menuList == "ProfileSettings" then
            cm:AddDescriptor    (  "Profile", level, true )
            cm:AddDescriptor    (  "-------------------", level )
            local cnt = 0
            for _, _ in pairs(_G.WOWMSProfile.Saved) do
               cnt = cnt + 1
            end
            if cnt ~= 0 then
               if _G.WOWMSProfile[realm][player].SavedProfile ~= nil then
                  cm:AddDescriptor    (  "Current Profile: ".._G.WOWMSProfile[realm][player].SavedProfile, level )
                  cm:AddDescriptor    (  "-------------------", level )
               else
                  cm:AddDescriptor    (  "Current Profile: None", level )
                  cm:AddDescriptor    (  "-------------------", level )
               end
            end
            cm:AddOption        (  "New",
                                    level,
                                    function(self)
                                       profile.CreateNew()
                                       cm:CloseMenu()
                                    end
                                )
            if cnt ~= 0 then
               if _G.WOWMSProfile[realm][player].SavedProfile ~= nil then
                  cm:AddOption        (  "Dissociate",
                                          level,
                                          function(self)
                                             profile.DissociateProfile()
                                          end
                                      )
               end
               cm:AddDescriptor    (  "-------------------", level )
               cm:AddMenu          (  "Associate", level, "AssociateProfile" )
               cm:AddMenu          (  "|cFFFF3333Delete|r", level, "DeleteProfile" )
            end
         elseif menuList == "Fonts" then
            cm:AddDescriptor    (  "Font", level, true )
            cm:AddDescriptor    (  "-------------------", level )
            local fnts = {}
            for n, v in pairs(fonts) do
               if type(v) ~= "table" then 
                  table.insert(fnts, n)
               end
            end
            table.sort(fnts)
            for _, v in pairs(fnts) do
               cm:AddRadioOption   (  v,
                                          function(self)
                                             return profile.GetFontSetting() == v
                                          end,
                                          level,
                                          function(self, _, _, _)
                                             profile.SetFontSetting(v)
                                             tt.UpdateFontInfo()
                                             sd.UpdateFontInfo()
                                             cm:Refresh()
                                          end
                                       )
            end      
         elseif menuList == "FontSize" then
            cm:AddDescriptor    (  "Font Size", level, true )
            cm:AddDescriptor    (  "-------------------", level )
            local fontSizes = fonts.Sizes
            for _, v in pairs(fontSizes) do
               cm:AddRadioOption   (  tostring(v),
                                          function(self)
                                             return profile.GetFontSizeSetting() == v
                                          end,
                                          level,
                                          function(self, _, _, _)
                                             profile.SetFontSizeSetting(v)
                                             tt.UpdateFontInfo()
                                             sd.UpdateFontInfo()
                                             cm:Refresh()
                                          end
                                       )
            end
         elseif menuList == "Removes" then
            cm:AddDescriptor    (  "Remove Character", level, true )
            cm:AddDescriptor    (  "-------------------", level )
            for n, v in pairs(_G.WOWMMGlobal) do
               if type(v) == "table" then
                  cm:AddMenu       (  n, level, "RemoveChar_"..n )
               end
            end
         elseif menuList == "Resets" then
            cm:AddDescriptor    (  "Reset", level, true )
            cm:AddDescriptor    (  "-------------------", level )
            cm:AddMenu( "Time", level, "ResetTimes")
            cm:AddMenu( "Averages", level, "ResetAvgs")
            cm:AddMenu( "Catagories", level, "ResetCatagories")
            local cnt = 0
            for _, _ in pairs(_G.WOWMSZone[realm].AllChars) do
               cnt = cnt + 1
               break
            end
            if cnt ~= 0 then
               cm:AddMenu( "Zones", level, "ResetZones")
            end
            cm:AddDescriptor    (  "-------------------", level )
            cm:AddOption        (  "Reset All",
                                    level,
                                    function(self)
                                       util.ResetAll()
                                       cm:CloseMenu()
                                    end
                                )
         elseif menuList == "GoldFormats" then
            cm:AddDescriptor    (  "Money Format", level, true )
            cm:AddDescriptor    (  "-------------------", level )
            cm:AddRadioOption( "Comma",
                                 function(self)
                                    local setting = profile.GetGoldFormatSetting()
                                    return setting == "COMMA"
                                 end,
                                 level,
                                 function(self, _, _, _)
                                    profile.SetGoldFormatSetting("COMMA")
                                    cm:Refresh()
                                 end
                               )

            cm:AddRadioOption( "Period",
                                 function(self)
                                    local setting = profile.GetGoldFormatSetting()
                                    return setting == "PERIOD"
                                 end,
                                 level,
                                 function(self, _, _, _)
                                    profile.SetGoldFormatSetting("PERIOD")
                                    cm:Refresh()
                                 end
                               )

            cm:AddRadioOption( "None",
                                 function(self)
                                    local setting = profile.GetGoldFormatSetting()
                                    return setting == "NONE"
                                 end,
                                 level,
                                 function(self, _, _, _)
                                    profile.SetGoldFormatSetting("NONE")
                                    cm:Refresh()
                                 end
                               )
         end
      elseif level == 3 then
         local s = util.stringSplit(menuList, "_")
         if s[1] == "RemoveChar" then
            menuList = s[2]
            local chars = util.GetSortedCharList(menuList)
            cm:AddDescriptor    (  s[2], level, true )
            cm:AddDescriptor    (  "-------------------", level )
            for _, cn in pairs(chars) do
               cm:AddOption  (  cn,
                                    level,
                                    function(self)
                                       util.RemoveCharacter(menuList, cn)
                                       cm:CloseMenu()
                                    end
                                 )
            end
         elseif s[1] == "ResetTimes" then
            cm:AddDescriptor    (  "Time", level, true )
            cm:AddDescriptor    (  "-------------------", level )
            for _, v in pairs(time.GetTimeList()) do
               cm:AddOption(time.TimeSetTitles[v], level, function(self) util.ResetTime(v) cm:CloseMenu() end)
            end
            cm:AddDescriptor    (  "-------------------", level )
            cm:AddOption("Reset All", level, function(self) util.ResetAllTime() cm:CloseMenu() end)
         elseif s[1] == "ResetAvgs" then
            cm:AddDescriptor    (  "Averages", level, true )
            cm:AddDescriptor    (  "-------------------", level )
            for _, v in pairs(time.GetTimeList()) do
               if util.getSetValue(time.TimeSetAvg, v) then
                  cm:AddOption(format("%s Avg", v), level, function(self) util.ResetAvg(v) cm:CloseMenu() end)
               end
            end
            cm:AddDescriptor    (  "-------------------", level )
            cm:AddOption("Reset All", level, function(self) util.ResetAllAvg() cm:CloseMenu() end)
         elseif s[1] == "ResetCatagories" then
            cm:AddDescriptor    (  "Catagories", level, true )
            cm:AddDescriptor    (  "-------------------", level )
            for k, v in pairs(mt.DisplayNames) do
               cm:AddMenu(v, level, "ResetTracker_"..k)
            end
            cm:AddDescriptor    (  "-------------------", level )
            cm:AddOption("Reset All", level, function(self) util.RemoveTracker(realm, "ALL") cm:CloseMenu() end)
         elseif s[1] == "ResetZones" then
            cm:AddDescriptor    (  "Zones", level, true )
            cm:AddDescriptor    (  "-------------------", level )
            for k, v in pairs(_G.WOWMSZone[realm].AllChars) do
               cm:AddMenu(k, level, "ResetZone_"..k)
            end
            cm:AddDescriptor    (  "-------------------", level )
            cm:AddOption("Reset All", level, function(self) util.RemoveZone(realm, "ALL") cm:CloseMenu() end)
         elseif s[1] == "Characters" or s[1] == "Servers" or s[1] == "MoneyXfers" or s[1] == "TimeBased" then
            tt.OptionalSettingMenu(cm, level, menuList)
         elseif s[1] == "AssociateProfile" then
            cm:AddDescriptor    (  "Associate", level, true )
            cm:AddDescriptor    (  "-------------------", level )
            for name, _ in pairs(_G.WOWMSProfile.Saved) do
               cm:AddRadioOption( name,
                                    function(self)
                                       local setting = profile.GetProfileName()
                                       return setting == name
                                    end,
                                    level,
                                    function(self, _, _, _)
                                       profile.SetProfileName(name)
                                       cm:CloseMenu()
                                    end
                                  )
            end
         elseif s[1] == "DeleteProfile" then
            cm:AddDescriptor    (  "Delete", level, true )
            cm:AddDescriptor    (  "-------------------", level )
            for name, _ in pairs(_G.WOWMSProfile.Saved) do
               cm:AddOption(name, level, function(self) profile.DeleteProfile(name) cm:CloseMenu() end)
            end
         end
      elseif level == 4 then
         local s = util.stringSplit(menuList, "_")
         if s[1] == "ResetTracker" then
            menuList = s[2]
            local chars = util.GetSortedCharList(realm)
            cm:AddDescriptor    (  mt.DisplayNames[menuList], level, true )
            cm:AddDescriptor    (  "-------------------", level )
            for _, cn in pairs(chars) do
               cm:AddOption  (  cn,
                                    level,
                                    function(self)
                                       util.RemoveCharacterTracker(realm, cn, menuList)
                                       cm:CloseMenu()
                                    end
                                 )
            end
            cm:AddDescriptor    (  "-------------------", level )
            cm:AddOption("Reset All", level, function(self) util.RemoveTracker(realm, menuList) cm:CloseMenu() end)
         elseif s[1] == "ResetZone" then
            menuList = s[2]
            local chars = util.GetSortedCharList(realm)
            cm:AddDescriptor    (  menuList, level, true )
            cm:AddDescriptor    (  "-------------------", level )
            for _, cn in pairs(chars) do
               if _G.WOWMSZone[realm][cn] and _G.WOWMSZone[realm][cn][menuList] ~= nil then
                  cm:AddOption  (  cn,
                                       level,
                                       function(self)
                                          util.RemoveCharacterZone(realm, cn, menuList)
                                          cm:CloseMenu()
                                       end
                                    )
               end
            end
            cm:AddDescriptor    (  "-------------------", level )
            cm:AddOption("Reset All", level, function(self) util.RemoveZone(realm, menuList) cm:CloseMenu() end)
         end
      end
   end
end

cm = Prototype_Menu:NewContextMenu  (addon_name.."ContextMenu",
                                       {
                                          OnLoad = ContextMenu_OnLoad,
                                       }
                                    )

function menu.IsMenuOpen()
   return cm and cm:IsMenuOpen()
end

function menu.ToggleMenu(anchor)
   if cm then
      cm:ToggleMenu(anchor)
   end
end

function menu.OpenMenu(anchor)
   if cm then
      cm:OpenMenu(anchor)
   end
end

function menu.CloseMenu()
   if cm then
      cm:CloseMenu()
   end
end
