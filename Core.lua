local addon_name, addon = ...
local core = addon.core

local util = addon.utility
local profile = addon.profile
local ti = addon.time
local menu = addon.menu
local global = addon.global
local _G = _G

local player = UnitName("player")
local _, class = UnitClass("player")
local faction = UnitFactionGroup("player")
local realm = GetRealmName()

local SECOND = 1
local MINUTE = 60 * SECOND
local HOUR = 60 * MINUTE
local DAY = 24 * HOUR
local WEEK = 7 * DAY

core.VersionChangesApplied = false;

local function VersionChanges() --TODO: Switch to a registeration setup?
   if not _G.WOWMMGlobal[realm] then
      _G.WOWMMGlobal[realm] = _G.WOWMMGlobal[realm] or {}
   end
   -- Changing the format of the save table from previous versions.
   -- I do not want to lose previously saved data.

   -- Version information added in 1.0.6.
   -- All version information before 1.0.6 would be nil.
   local version = _G.WOWMMGlobal.Version or "1.0.5.1"
   local realmVersion = _G.WOWMMGlobal[realm] and _G.WOWMMGlobal[realm].Version or "1.0.5.1"
   local charVersion = _G.WOWMMChar.Version or "1.0.5.1"

   -- Format change from version 1.0.5.1 to 1.0.6 for introduction of currency information.
   if _G.WOWMMGlobal[realm].Chars and realmVersion <= "1.0.5.1" then
      local OldFormat = {}
      for k, v in pairs(_G.WOWMMGlobal[realm].Chars) do
         if type(v) == "number" then
            OldFormat[k] = v
         end
      end

      for k, v in pairs(OldFormat) do
         _G.WOWMMGlobal[realm].Chars[k] = {}
         _G.WOWMMGlobal[realm].Chars[k].Cash = v
      end
   end

   -- Changing MovingAvg to just Avg which is more appropriate.
   if charVersion <= "1.0.7.1" then
      local prevSetting = _G.WOWMMChar.MovingAvgShown or true
      _G.WOWMMChar.AvgShown = prevSetting
      _G.WOWMMChar.MovingAvgShown = nil
   end

   -- Changed the way I determine a weekly reset has occurred
   if _G.WOWMMGlobal[realm].Week and realmVersion <= "1.0.7.1" then
      local wd = ti.GetCalendarDate(ti.GetDaysToAdvance())
      local id = (wd - 3) % 7
      local lastLoginTime =  _G.WOWMMGlobal[realm].Week.LLIT or 0
      local logonTime = ti.GetTimeSinceEpoch(ti.GetDaysToAdvance())
      if (logonTime - lastLoginTime) < WEEK and id >= _G.WOWMMGlobal[realm].Week.ID then
         _G.WOWMMGlobal[realm].Week.ID = ti.GetTimeOfLastReset(ti.GetDaysToAdvance())
      else
         _G.WOWMMGlobal[realm].Week.ID = 0
      end
      _G.WOWMMGlobal[realm].Week.LLIT = nil
   end

   -- Changed the ID from a date to time since epoch.  This is to save debug for a day after an error but reset otherwise.
   if _G.WOWMSDebug.ID and not tonumber(_G.WOWMSDebug.ID) and realmVersion <= "2.2.0" then
      _G.WOWMSDebug.ID = 0
      _G.WOWMSDebug.Val = ""
   end

   -- Stop storing debug information due to it causing lag for users
   if realmVersion <= "2.2.1" then
      _G.WOWMSDebug.ID = 0
      _G.WOWMSDebug.Val = ""
   end

   -- Moving to a profile setup. I need to store profile information at a global level instead of a character level
   if charVersion <= "2.2.4" then
      _G.WOWMSProfile[realm] = _G.WOWMSProfile[realm] or {}
      _G.WOWMSProfile[realm][player] = _G.WOWMSProfile[realm][player] or {}
      _G.WOWMSProfile[realm][player].Minimap = _G.WOWMSProfile[realm][player].Minimap or {}

      profile.TransferFuncToProfile("Font")
      profile.TransferFuncToProfile("FontSize")
      profile.TransferFuncToProfile("ElvUIFontSetting")
      profile.TransferFuncToProfile("IsSexyCompat")
      profile.TransferFuncToProfile("IsAltIgnored")
      profile.TransferFuncToProfile("TooltipCharacterSetting")
      profile.TransferFuncToProfile("TooltipServerSetting")
      profile.TransferFuncToProfile("MoneyXferSetting")
      profile.TransferFuncToProfile("BankCharacter")
      profile.TransferFuncToProfile("FactionDisplaySetting")
      profile.TransferFuncToProfile("GoldFormatSetting")
      profile.TransferFuncToProfile("IsVerbose")
      profile.TransferFuncToProfile("IsMinimapHidden")
      profile.TransferFuncToProfile("IsMinimapLocked")
      profile.TransferFuncToProfile("IsLocked")
      profile.TransferFuncToProfile("CurrentTab")
      profile.TransferFuncToProfile("WowTokenPriceShown")
      profile.TransferFuncToProfile("WatchedCurrenciesShown")
      profile.TransferFuncToProfile("AllTimeShown")
      profile.TransferFuncToProfile("YearShown")
      profile.TransferFuncToProfile("MonthShown")
      profile.TransferFuncToProfile("WeekShown")
      profile.TransferFuncToProfile("DayShown")
      profile.TransferFuncToProfile("SessionShown")

      -- Minimap X and Y positions
      if _G.WOWMMChar.Minimap ~= nil and  _G.WOWMMChar.Minimap.x ~= nil then
         _G.WOWMSProfile[realm][player].Minimap.x = _G.WOWMMChar.Minimap.x
         _G.WOWMMChar.Minimap.x = nil
      end

      if _G.WOWMMChar.Minimap ~= nil and _G.WOWMMChar.Minimap.y ~= nil then
         _G.WOWMSProfile[realm][player].Minimap.y = _G.WOWMMChar.Minimap.y
         _G.WOWMMChar.Minimap.y = nil
      end
   end

   if version <= "2.2.7" then
      for k, v in pairs(_G.WOWMSProfile) do
         for n, t in pairs(v) do
            for _, key in pairs(ti.TimeList) do
               if t[key.."Shown"] ~= nil then
                  _G.WOWMSProfile[k][n][key.."EarnedShown"] = t[key.."Shown"]
                  _G.WOWMSProfile[k][n][key.."SpentShown"] = t[key.."Shown"]
                  _G.WOWMSProfile[k][n][key.."NetShown"] = t[key.."Shown"]
                  if key ~= "AllTime" then
                     _G.WOWMSProfile[k][n][key.."AvgShown"] = t[key.."Shown"]
                  end
                  _G.WOWMSProfile[k][n][key.."Shown"] = nil
               end
            end
         end
      end
   end

   -- Do this last to make sure we don't overwrite the previous version
   --local cVersion = GetAddOnMetadata(addon_name, "version")
   local GetAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
   _G.WOWMMGlobal.Version = cVersion
   _G.WOWMMGlobal[realm].Version = cVersion
   _G.WOWMMChar.Version = cVersion

   core.VersionChangesApplied = true
end

local function InitializePersistantVariables(newSession)
   if newSession == nil then
      newSession = true
   end

   VersionChanges()

   _G.WOWMMGlobal[realm].Chars = _G.WOWMMGlobal[realm].Chars or {}
   _G.WOWMMGlobal[realm].Classes = _G.WOWMMGlobal[realm].Classes or {}
   _G.WOWMMGlobal[realm].MoneyXfer = _G.WOWMMGlobal[realm].MoneyXfer or {}
   _G.WOWMMGlobal[realm].Factions = _G.WOWMMGlobal[realm].Factions or {}
   _G.WOWMMGlobal[realm].Classes[player] = class
   _G.WOWMMGlobal[realm].Factions[player] = faction

   _G.WOWMSProfile[realm] = _G.WOWMSProfile[realm] or {}
   _G.WOWMSProfile[realm][player] = _G.WOWMSProfile[realm][player] or {}
   _G.WOWMSProfile[realm][player].Minimap = _G.WOWMSProfile[realm][player].Minimap or {}
   
   -- Reset Debug
   local cTime = ti.GetTimeSinceEpoch(0)
   _G.WOWMSDebug.ID = _G.WOWMSDebug.ID or cTime
   if (_G.WOWMSDebug.ID + addon.DAY) < cTime then
      _G.WOWMSDebug.Val = ""
   else
      _G.WOWMSDebug.Val = _G.WOWMSDebug.Val or ""
   end

   local IDSet = ti.GetIDSet()
   for k, v in pairs(IDSet) do

      if k ~= "Session" or newSession then
         local invalidID = false
         _G.WOWMMGlobal[realm][k] = _G.WOWMMGlobal[realm][k] or {}
         _G.WOWMMGlobal[realm][k].ID = _G.WOWMMGlobal[realm][k].ID or v

         local prevEarned = _G.WOWMMGlobal[realm][k].Earned or 0
         local prevSpent = _G.WOWMMGlobal[realm][k].Spent or 0
         if v ~= "none" then
            if k == "Week" then
               -- Rational: Weekly resets have been plagued with incorrect resets
               -- I want to make sure this resets properly so I'll make a specific check here.
               local timeDelta = difftime(v, _G.WOWMMGlobal[realm][k].ID)
               if v > _G.WOWMMGlobal[realm][k].ID and timeDelta >= WEEK then
                  _G.WOWMMGlobal[realm][k].ID = v
                  _G.WOWMMGlobal[realm][k].Earned = 0
                  _G.WOWMMGlobal[realm][k].Spent = 0
                  invalidID = true
               else
                  _G.WOWMMGlobal[realm][k].Earned = _G.WOWMMGlobal[realm][k].Earned or 0
                  _G.WOWMMGlobal[realm][k].Spent = _G.WOWMMGlobal[realm][k].Spent or 0
               end
            elseif _G.WOWMMGlobal[realm][k].ID == v then
               _G.WOWMMGlobal[realm][k].Earned = _G.WOWMMGlobal[realm][k].Earned or 0
               _G.WOWMMGlobal[realm][k].Spent = _G.WOWMMGlobal[realm][k].Spent or 0
            else
               _G.WOWMMGlobal[realm][k].ID = v
               _G.WOWMMGlobal[realm][k].Earned = 0
               _G.WOWMMGlobal[realm][k].Spent = 0
               invalidID = true
            end
         elseif k == "Session" then
            _G.WOWMMGlobal[realm][k].Earned = 0
            _G.WOWMMGlobal[realm][k].Spent = 0
            invalidID = true
         else -- AllTime
            _G.WOWMMGlobal[realm][k].Earned = _G.WOWMMGlobal[realm][k].Earned or 0
            _G.WOWMMGlobal[realm][k].Spent = _G.WOWMMGlobal[realm][k].Spent or 0
         end
         
         -- Average Information
         local netIndex = k.."Net"
         local countIndex = k.."Count"
         if util.getSetValue(ti.TimeSetAvg, k) then
            local net = prevEarned - prevSpent
            _G.WOWMMGlobal[realm][netIndex] = _G.WOWMMGlobal[realm][netIndex] or net
            _G.WOWMMGlobal[realm][countIndex] = _G.WOWMMGlobal[realm][countIndex] or 1

            if invalidID then
               _G.WOWMMGlobal[realm][netIndex] = _G.WOWMMGlobal[realm][netIndex] + net
               _G.WOWMMGlobal[realm][countIndex] = _G.WOWMMGlobal[realm][countIndex] + 1
            end
         end

         -- Faction Specific Earned and Spent
         for i = 1, #util.FactionList do
            local f = util.FactionList[i]
            _G.WOWMMGlobal[realm][k][f] = _G.WOWMMGlobal[realm][k][f] or {}
            _G.WOWMMGlobal[realm][k][f].ID = _G.WOWMMGlobal[realm][k][f].ID or v

            local prevEarned = _G.WOWMMGlobal[realm][k][f].Earned or 0
            local prevSpent = _G.WOWMMGlobal[realm][k][f].Spent or 0
            if v ~= "none" then
               if k == "Week" then
                  -- Rational: Weekly resets have been plagued with incorrect resets
                  -- I want to make sure this resets properly so I'll make a specific check here.
                  local timeDelta = difftime(v, _G.WOWMMGlobal[realm][k][f].ID)
                  if v > _G.WOWMMGlobal[realm][k][f].ID and timeDelta >= WEEK then
                     _G.WOWMMGlobal[realm][k][f].ID = v
                     _G.WOWMMGlobal[realm][k][f].Earned = 0
                     _G.WOWMMGlobal[realm][k][f].Spent = 0
                  else
                     _G.WOWMMGlobal[realm][k][f].Earned = _G.WOWMMGlobal[realm][k][f].Earned or 0
                     _G.WOWMMGlobal[realm][k][f].Spent = _G.WOWMMGlobal[realm][k][f].Spent or 0
                  end
               elseif _G.WOWMMGlobal[realm][k][f].ID == v then
                  _G.WOWMMGlobal[realm][k][f].Earned = _G.WOWMMGlobal[realm][k][f].Earned or 0
                  _G.WOWMMGlobal[realm][k][f].Spent = _G.WOWMMGlobal[realm][k][f].Spent or 0
               else
                  _G.WOWMMGlobal[realm][k][f].ID = v
                  _G.WOWMMGlobal[realm][k][f].Earned = 0
                  _G.WOWMMGlobal[realm][k][f].Spent = 0
               end
            elseif k == "Session" then
               _G.WOWMMGlobal[realm][k][f].Earned = 0
               _G.WOWMMGlobal[realm][k][f].Spent = 0
            else -- AllTime
               _G.WOWMMGlobal[realm][k][f].Earned = _G.WOWMMGlobal[realm][k][f].Earned or 0
               _G.WOWMMGlobal[realm][k][f].Spent = _G.WOWMMGlobal[realm][k][f].Spent or 0
            end

            -- Average Information
            if util.getSetValue(ti.TimeSetAvg, k) then
               local net = prevEarned - prevSpent
               _G.WOWMMGlobal[realm][k][f].Net = _G.WOWMMGlobal[realm][k][f].Net or net
               _G.WOWMMGlobal[realm][k][f].Count = _G.WOWMMGlobal[realm][k][f].Count or 1

               if invalidID and faction == f then
                  _G.WOWMMGlobal[realm][k][f].Net = _G.WOWMMGlobal[realm][k][f].Net + net
                  _G.WOWMMGlobal[realm][k][f].Count = _G.WOWMMGlobal[realm][k][f].Count + 1
               end
            end
         end
      end
   end

   util.setupCurrentPlayer(newSession)
   
   _G.WOWMMGlobal[realm].Total = util.GetRealmTotalCash(realm)
end

local function UpdatePersistantVariables()
   local pcash = _G.WOWMMGlobal[realm].Chars[player].Cash
   local cash = GetMoney()
   addon.debugPrint("UPV", cash)
   util.UpdateEarnedSpent(cash, pcash)
   util.UpdatePlayerCash(cash)
end

local loaded = false
local frame = CreateFrame("Frame")
local function EventHandler(self, event, ...)
   local args = {...}
   if event == "ADDON_LOADED" and args[1] ~= addon_name then
      return
   end

   if event =="PLAYER_ENTERING_WORLD" and loaded then
      return
   elseif event == "PLAYER_ENTERING_WORLD" then
      loaded = true
   end

   addon.debugPrint("Core Event", event, ...)

   if event == "ADDON_LOADED" and args[1] == addon_name then
      global.InitGlobals()
   end

   if event =="PLAYER_ENTERING_WORLD" then
      -- Rational: Initializing our persistant variables requires us to use the C_DateAndTime API.
      --             The C_DateAndTime API may not be fully loaded at this time resulting in invalid date and time.
      --             Wait until we are sure that we have valid data before initializing.
      --             The very act of waiting one second here is probably enough.

      self:SetScript("OnUpdate", function(self, elapsed)
                                    self.Elapsed = (self.Elapsed or 0) + elapsed
                                    if self.Elapsed >= 0.01 then
                                       self.Elapsed = 0
                                       if ti.ValidateDateAndTime() then
                                          InitializePersistantVariables()
                                          self:SetScript("OnUpdate", nil)
                                       else
                                          addon.debugPrint("Waiting on C_DateAndTime to have valid data.")
                                       end
                                    end
                                 end)
   end
end
util.RegisterEvents(frame, EventHandler,
                                    'PLAYER_ENTERING_WORLD',
                                    'ADDON_LOADED')

core.InitializePersistantVariables = InitializePersistantVariables
core.UpdatePersistantVariables = UpdatePersistantVariables
