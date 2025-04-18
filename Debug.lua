local _, addon = ...
local debug = addon.debug
local util = addon.utility
local profile = addon.profile
local time = addon.time
local core = addon.core

local COPPER = 1;
local SILVER = 100 * COPPER;
local GOLD = 100 * SILVER;

addon.SECOND = 1
addon.MINUTE = 60 * addon.SECOND
addon.HOUR = 60 * addon.MINUTE
addon.DAY = 24 * addon.HOUR

function addon.debugPrint(...)
   local isDebugOn = profile.GetDebugSetting()

   if isDebugOn then
      print(...)
   else
      -- Rational: This feature was causing lag for some users so I am turning it off as it is not necessary.
      --local s = ""
      --local arg = {...}
      --s = s..format("%d$$", time.GetTimeSinceEpoch(0))
      --for _, v in pairs(arg) do
         --s = s..format("%s$$", tostring(v))
      --end

      --_G.WOWMSDebug.Val = _G.WOWMSDebug.Val or ""
      --_G.WOWMSDebug.Val = _G.WOWMSDebug.Val..s.."^^"
   end
end

function addon.debugPrintTable(table, depth)
   local space = " "
   local indentCount = 5

   if not depth then
      depth = 0
   end

   addon.debugPrint(format("%s{", string.rep(space, depth)))
   for k, v in pairs(table) do
      local indent = depth + indentCount
      if type(v) == "table" then
         addon.debugPrint(format("%s[%s] =", string.rep(space, indent), tostring(k)))
         addon.debugPrintTable(v, indent)
      else
         addon.debugPrint(format("%s[%s] = [%s]", string.rep(space, indent), tostring(k), tostring(v)))
      end
   end
   addon.debugPrint(format("%s}", string.rep(space, depth)))
end

function addon.debugError(msg)
   local cTime = time.GetTimeSinceEpoch(0)
   if (_G.WOWMSDebug.ID + addon.DAY) < cTime then
      _G.WOWMSDebug.ID = cTime
   end
   addon.debugPrint("ERROR:", msg)
end

function debug.debugContextMenu(menu, level)
   menu:AddOption  (  "Advance Time - Day",
         level,
         function(self)
            time.AdvanceDays(1)
            core.InitializePersistantVariables(false)
            menu:CloseMenu()
         end
         )
   menu:AddOption  (  "Advance Time - Week",
         level,
         function(self)
            time.AdvanceDays(7)
            core.InitializePersistantVariables(false)
            menu:CloseMenu()
         end
         )
   menu:AddOption  (  "Advance Time - Month",
         level,
         function(self)
            local dta = time.GetDaysToAdvance()
            local _, m, d, y, md = time.GetCalendarDate(dta)
            time.AdvanceDays(md - d + 1)
            core.InitializePersistantVariables(false)
            menu:CloseMenu()
         end
         )
   menu:AddOption  (  "Reset Time",
         level,
         function(self)
            time.ResetDays()
            core.InitializePersistantVariables(false)
            menu:CloseMenu()
         end
         )
   menu:AddDescriptor    (  "-------------------", level )
   menu:AddOption  (  "Earn 99 Gold",
         level,
         function(self)
            local cash = GetMoney()
            util.UpdateEarnedSpent(cash + (99 * GOLD), cash)
            menu:CloseMenu()
         end
         )
   menu:AddOption  (  "Spend 99 Gold",
         level,
         function(self)
            local cash = GetMoney()
            util.UpdateEarnedSpent(cash - (99 * GOLD), cash)
            menu:CloseMenu()
         end
         )
   menu:AddOption  (  "Earn 99 Silver",
         level,
         function(self)
            local cash = GetMoney()
            util.UpdateEarnedSpent(cash + (99 * SILVER), cash)
            menu:CloseMenu()
         end
         )
   menu:AddOption  (  "Spend 99 Silver",
         level,
         function(self)
            local cash = GetMoney()
            util.UpdateEarnedSpent(cash - (99 * SILVER), cash)
            menu:CloseMenu()
         end
         )
   menu:AddOption  (  "Earn 99 Copper",
         level,
         function(self)
            local cash = GetMoney()
            util.UpdateEarnedSpent(cash + (99 * COPPER), cash)
            menu:CloseMenu()
         end
         )
   menu:AddOption  (  "Spend 99 Copper",
         level,
         function(self)
            local cash = GetMoney()
            util.UpdateEarnedSpent(cash - (99 * COPPER), cash)
            menu:CloseMenu()
         end
         )
end
