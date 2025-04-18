local addon_name, addon = ...
local mt = addon.mt

local util = addon.utility
local profile = addon.profile
local sd = addon.statDisplay
local core = addon.core
local _G = _G

local player = UnitName("player")
local realm = GetRealmName()

local MainTracker = CreateFrame("Frame")
MainTracker.Elapsed = 0
MainTracker.Timeout = .05

local PurgeTimer = CreateFrame("Frame")
PurgeTimer.TimeToPurge = 1

local DeterminantTimer = CreateFrame("Frame")
DeterminantTimer.Elapsed = 0
DeterminantTimer.Timeout = 1

local DeterminantTimerCount = {}
local DETERMINANT_RESET_COUNT = 2

local ActiveTrackers = 
{
   ActiveCount = 0,
   Trackers = {}
}

mt.DisplayNames =
{
   TAXI                 = "Taxi",
   TRADE                = "Trade",
   TRAINER              = "Trainer",
   AUCTION              = "Auction",
   BMAH                 = "Black Market",
   ARCHITECT            = "Garrison Arch",
   MISSION              = "Mission Table",
   SHIPYARD             = "Shipyard",
   TRANSMOG             = "Transmog",
   VOID                 = "Void Storage",
   GUILDBANK            = "Guild",
   LOOT                 = "Loot",
   REPAIR               = "Repair",
   MERCH                = "Vendor",
   COD                  = "C.O.D.",
   ALT                  = "Alt",
   POSTAGE              = "Postage",
   QUEST                = "Quest",
   AZERITEREFORGE       = "Reforge",
   BARBER               = "Barber",
   STORAGEUPGRADE       = "Storage Upgrade",
   LFG                  = "LFG Rewards",
   UNKNOWN              = "Unknown",
}

local RegisteredTrackers = {}
RegisteredTrackers.ActivationFunction = {}
RegisteredTrackers.OnTriggerFunction = {}
RegisteredTrackers.OnActivationFunction = {}
RegisteredTrackers.DeactivationFunction = {}
RegisteredTrackers.OnDeactivationFunction = {}
RegisteredTrackers.DeterminantFunction = {}
RegisteredTrackers.InformationFunction = {}
RegisteredTrackers.Keys = {}

local function isTrackerActive(uuid)
   local trackerActive = false
   for k, _ in pairs(ActiveTrackers.Trackers) do
      trackerActive = trackerActive or (uuid == k)
   end

   return trackerActive
end

local function ActivateTracker(uuid, t, ...)
   if not ActiveTrackers.Trackers[uuid] then
      ActiveTrackers.ActiveCount = ActiveTrackers.ActiveCount + 1
      ActiveTrackers.Trackers[uuid] =
      {
         Tracker = t,
         Money = 0,
         DeterminantTriggered = false,
         Catagorized = false,
         DeterminantCount = 0,
      }
   end

   -- Trackers with Determinants are only available when the determinant gets set
   if RegisteredTrackers.DeterminantFunction[uuid] then
      ActiveTrackers.Trackers[uuid].Catagorized = true
   end

   -- On Activation
   if RegisteredTrackers.OnActivationFunction[uuid] then
      RegisteredTrackers.OnActivationFunction[uuid](...)
   end
end

local function DeactivateTracker(uuid, ...)
   -- On Deactivation
   if RegisteredTrackers.OnDeactivationFunction[uuid] then
      RegisteredTrackers.OnDeactivationFunction[uuid](...)
   end

   if ActiveTrackers.Trackers[uuid] then
      ActiveTrackers.LastDeactivatedTracker = 
      {
         UUID = uuid,
         Tracker = ActiveTrackers.Trackers[uuid].Tracker,
         Money = ActiveTrackers.Trackers[uuid].Money,
      }
      ActiveTrackers.ActiveCount = ActiveTrackers.ActiveCount - 1
      ActiveTrackers.Trackers[uuid] = nil

      -- Start timer for cleanup
      local timeElapsed = 0
      PurgeTimer:SetScript("OnUpdate",
         function(self, elapsed)
            -- Rational: Some trackers deactivate on death but a user can still receive money from the last thing they were doing before death.  Don't purge until alive.
            if UnitIsDead("player") or UnitIsGhost("player") then return end
            timeElapsed = timeElapsed + elapsed
            if timeElapsed >= PurgeTimer.TimeToPurge then
               addon.debugPrint("Purge: ", timeElapsed)
               ActiveTrackers.LastDeactivatedTracker = nil
               self:SetScript("OnUpdate", nil)
            end
         end)
   end
end

local function ResetDeterminant(self, elapsed)
   self.Elapsed = self.Elapsed + elapsed
   if self.Elapsed >= self.Timeout then
      addon.debugPrint("Timeout")
      local TriggeredCount = 0
      for k, _ in pairs(RegisteredTrackers.Keys) do
         -- Look for Trackers with no deactivation function
         if not RegisteredTrackers.DeactivationFunction[k] then
            -- Is this Tracker active?
            if ActiveTrackers.Trackers[k] then
               -- Has a Determinant been set true?
               if ActiveTrackers.Trackers[k].DeterminantTriggered then
                  TriggeredCount = TriggeredCount + 1
                  local count = util.getSetValue(DeterminantTimerCount, k) or 0
                  count = count + 1
                  if count >= DETERMINANT_RESET_COUNT then
                     addon.debugPrint("Tracker Reset: ", k)
                     ActiveTrackers.Trackers[k].Catagorized = true
                     ActiveTrackers.Trackers[k].DeterminantTriggered = false
                     ActiveTrackers.Trackers[k].Money = 0
                     ActiveTrackers.Trackers[k].DeterminantCount = 0
                     util.removeFromSet(DeterminantTimerCount, k)
                     TriggeredCount = TriggeredCount - 1
                  else
                     util.addToSet(DeterminantTimerCount, k, count)
                  end
               end
            end
         end
      end

      if TriggeredCount == 0 then
         DeterminantTimer:SetScript("OnUpdate", nil)
      end

      self.Elapsed = 0
   end
end

local function SetDeterminant(uuid, money)
   if not uuid then
      return
   end

   if ActiveTrackers.Trackers[uuid] then
      ActiveTrackers.Trackers[uuid].DeterminantTriggered = true
      ActiveTrackers.Trackers[uuid].Catagorized = false
      ActiveTrackers.Trackers[uuid].Money = ActiveTrackers.Trackers[uuid].Money + money
      ActiveTrackers.Trackers[uuid].DeterminantCount = ActiveTrackers.Trackers[uuid].DeterminantCount + 1

      if not RegisteredTrackers.DeactivationFunction[uuid] then
         util.removeFromSet(DeterminantTimerCount, uuid)
         DeterminantTimer:SetScript("OnUpdate", ResetDeterminant)
      end
   end
end

function MainTracker:DetermineSource()
   local money = GetMoney() - MainTracker.Money
   addon.debugPrintTable(ActiveTrackers)
   addon.debugPrint(money)
   local c = _G.DEFAULT_CHAT_FRAME;
   local catagorized = false

   local UnderSpecified
   for uuid, v in pairs(ActiveTrackers.Trackers) do
      local m, t
      local reset = true
      if v.DeterminantTriggered and v.Catagorized == false then
         if v.DeterminantCount > 1 and math.abs(v.Money) > math.abs(money) then
            m = money
            v.Money = v.Money - m
            reset = false
         else
            m = v.Money
         end
         t = v.Tracker

         if m ~= 0 and money ~= 0 then
            money = money - m
            RegisteredTrackers.OnTriggerFunction[uuid](uuid, t, m)

            if profile.GetVerboseSetting() then
               c:AddMessage("|cffff6600"..format("%s - ", mt.DisplayNames[t]).."|r"..util.FormatMoney(m, true))
            end
            addon.debugPrint("DetermineSource", "DeterminantTriggered Activation", t, mt.DisplayNames[t], m)
            
            if money == 0 then
               catagorized = true
            end

            if reset then
               v.DeterminantTriggered = false
               v.Catagorized = true
               v.Money = 0
               v.DeterminantCount = 0
            end
         else
            UnderSpecified = uuid
         end
      end
   end

   if catagorized == false and ActiveTrackers.LastDeactivatedTracker ~= nil then
      if ActiveTrackers.LastDeactivatedTracker.Money == 0 then
         ActiveTrackers.LastDeactivatedTracker.Money = money
      end
      local m = ActiveTrackers.LastDeactivatedTracker.Money
      local t = ActiveTrackers.LastDeactivatedTracker.Tracker
      local uuid = ActiveTrackers.LastDeactivatedTracker.UUID

      RegisteredTrackers.OnTriggerFunction[uuid](uuid, t, m)
      money = money - m
      if money == 0 then
         catagorized = true
      end

      if profile.GetVerboseSetting() then
         c:AddMessage("|cffff6600"..format("%s - ", mt.DisplayNames[t]).."|r"..util.FormatMoney(m, true))
      end
      addon.debugPrint("DetermineSource", "LastDeactivatedTracker Activation", t, mt.DisplayNames[t], m)
   end

   if UnderSpecified then
      if money ~= 0 then
         local m, t, v, uuid
         uuid = UnderSpecified
         m = money
         money = money - m
         v = ActiveTrackers.Trackers[uuid]
         t = v.Tracker
         catagorized = true
         v.DeterminantTriggered = false
         v.Catagorized = true
         RegisteredTrackers.OnTriggerFunction[uuid](uuid, t, m)

         if profile.GetVerboseSetting() then
            c:AddMessage("|cffff6600"..format("%s - ", mt.DisplayNames[t]).."|r"..util.FormatMoney(m, true))
         end
         addon.debugPrint("DetermineSource", "UnderSpecified Activation", t, mt.DisplayNames[t], m)
      else
         local v, uuid
         uuid = UnderSpecified
         v = ActiveTrackers.Trackers[uuid]
         v.DeterminantTriggered = false
         v.Catagorized = true
      end
   end

   if catagorized == false and money ~= 0 and ActiveTrackers.ActiveCount > 0 then
      local count = 0
      local uuid
      for k, v in pairs(ActiveTrackers.Trackers) do
         if v.Catagorized == false and not RegisteredTrackers.DeterminantFunction[k] then
            uuid = k
            count = count + 1
         end
      end

      if count == 1 then
         local t = ActiveTrackers.Trackers[uuid].Tracker
         local m = money
         money = money - m

         RegisteredTrackers.OnTriggerFunction[uuid](uuid, t, m)
         catagorized = true

         if profile.GetVerboseSetting() then
            c:AddMessage("|cffff6600"..format("%s - ", mt.DisplayNames[t]).."|r"..util.FormatMoney(m, true))
         end
         addon.debugPrint("DetermineSource", "One Active Activation", t, mt.DisplayNames[t], m)
      end
   end

   if catagorized == false then
      local t = 'UNKNOWN'
      local m = money
      money = money - m
      if m > 0 then
         _G.WOWMSTracker[realm].AllChars[t].Earned = _G.WOWMSTracker[realm].AllChars[t].Earned + m
         _G.WOWMSTracker[realm][player][t].Earned = _G.WOWMSTracker[realm][player][t].Earned + m
      else
         local money = math.abs(m)
         _G.WOWMSTracker[realm].AllChars[t].Spent = _G.WOWMSTracker[realm].AllChars[t].Spent + money
         _G.WOWMSTracker[realm][player][t].Spent = _G.WOWMSTracker[realm][player][t].Spent + money
      end
      core.UpdatePersistantVariables()

      if profile.GetVerboseSetting() then
         c:AddMessage("|cffff6600".."! - WMS - UNKNOWN Transaction - ! - ".."|r"..util.FormatMoney(m, true))
         --[===[@debug
         PlaySound(SOUNDKIT.ALARM_CLOCK_WARNING_2)
         --@end-debug]===]
      end
      addon.debugError("DetermineSource", "UNKNOWN Transaction")
   end

   MainTracker.Money = GetMoney()
   addon.debugPrint("TrackerMoney", MainTracker.Money)
   sd.UpdateStatDialog()
end

local function InitPersistance()
   _G.WOWMSTracker[realm] = _G.WOWMSTracker[realm] or {}
   _G.WOWMSTracker[realm][player] = _G.WOWMSTracker[realm][player] or {}

   _G.WOWMSTracker[realm].AllChars = _G.WOWMSTracker[realm].AllChars or {}

   _G.WOWMSZone[realm] = _G.WOWMSZone[realm] or {}
   _G.WOWMSZone[realm][player] = _G.WOWMSZone[realm][player] or {}

   _G.WOWMSZone[realm].AllChars = _G.WOWMSZone[realm].AllChars or {}

   for k, t in pairs(RegisteredTrackers.Keys) do
      _G.WOWMSTracker[realm].AllChars[t] = _G.WOWMSTracker[realm].AllChars[t] or {}
      _G.WOWMSTracker[realm].AllChars[t].Earned = _G.WOWMSTracker[realm].AllChars[t].Earned or 0
      _G.WOWMSTracker[realm].AllChars[t].Spent = _G.WOWMSTracker[realm].AllChars[t].Spent or 0

      _G.WOWMSTracker[realm][player][t] = _G.WOWMSTracker[realm][player][t] or {}
      _G.WOWMSTracker[realm][player][t].Earned = _G.WOWMSTracker[realm][player][t].Earned or 0
      _G.WOWMSTracker[realm][player][t].Spent = _G.WOWMSTracker[realm][player][t].Spent or 0
   end

   _G.WOWMSTracker[realm].AllChars.UNKNOWN = _G.WOWMSTracker[realm].AllChars.UNKNOWN or {}
   _G.WOWMSTracker[realm].AllChars.UNKNOWN.Earned = _G.WOWMSTracker[realm].AllChars.UNKNOWN.Earned or 0
   _G.WOWMSTracker[realm].AllChars.UNKNOWN.Spent = _G.WOWMSTracker[realm].AllChars.UNKNOWN.Spent or 0

   _G.WOWMSTracker[realm][player].UNKNOWN = _G.WOWMSTracker[realm][player].UNKNOWN or {}
   _G.WOWMSTracker[realm][player].UNKNOWN.Earned = _G.WOWMSTracker[realm][player].UNKNOWN.Earned or 0
   _G.WOWMSTracker[realm][player].UNKNOWN.Spent = _G.WOWMSTracker[realm][player].UNKNOWN.Spent or 0
end

local loaded = false
local function EventHandler(self, event, ...)
   if event == "PLAYER_ENTERING_WORLD" and loaded then
   elseif event == "PLAYER_ENTERING_WORLD" then
      loaded = true
      addon.debugPrint("Tracker Event", event, ...)
   elseif event == "PLAYER_MONEY" then
      addon.debugPrint("Tracker Event", event, ...)
   end

   for k, _ in pairs(RegisteredTrackers.Keys) do
      RegisteredTrackers.ActivationFunction[k](event, ...)
      if RegisteredTrackers.DeactivationFunction[k] then
         RegisteredTrackers.DeactivationFunction[k](event, ...)
      end

      if RegisteredTrackers.DeterminantFunction[k] then
         for _, v in pairs(RegisteredTrackers.DeterminantFunction[k]) do
            v(event, ...)
         end
      end

      if RegisteredTrackers.InformationFunction[k] then
         for _, v in pairs(RegisteredTrackers.InformationFunction[k]) do
            v(event, ...)
         end
      end
   end

   if event == "PLAYER_ENTERING_WORLD" then
      MainTracker.Money = GetMoney()
      addon.debugPrint("TrackerMoney", MainTracker.Money)

      InitPersistance()
   end

   if event == "PLAYER_MONEY" then
      MainTracker.Elapsed = 0
      MainTracker:SetScript("OnUpdate", 
         function(self, elapsed)
            MainTracker.Elapsed = MainTracker.Elapsed + elapsed
            if MainTracker.Elapsed > MainTracker.Timeout then
               self:SetScript("OnUpdate", nil)
               self:DetermineSource()
            end
         end)
   end
end

function mt.ManualEvent(event, ...)
   EventHandler(MainTracker, event, ...)
end

function mt.RegisterTracker(uuid, t, activationEvent, deactivationEvent, onTrigger)
   if not uuid or not t or not activationEvent or not onTrigger then
      error("RegisterTracker failed - Not enough arguments")
   end

   -- Create Key
   if not util.setContains(RegisteredTrackers.Keys, uuid) then
      util.addToSet(RegisteredTrackers.Keys, uuid, t)
   end

   -- ActivationFunction
   if not RegisteredTrackers.ActivationFunction[uuid] then
      RegisteredTrackers.ActivationFunction[uuid] =
      function (event, ...)
         if event == activationEvent then
            addon.debugPrint("Activate Tracker", event, ...)
            ActivateTracker(uuid, t, ...)
         end
      end
   end

   -- DeactivationFunction
   if not RegisteredTrackers.DeactivationFunction[uuid] and deactivationEvent then
      RegisteredTrackers.DeactivationFunction[uuid] = 
      function(event, ...)
         if event == deactivationEvent then
            addon.debugPrint("Deactivate Tracker", event, ...)
            DeactivateTracker(uuid, ...)
         end
      end
   end

   -- OnInitialization
   if not RegisteredTrackers.OnTriggerFunction[uuid] then
      RegisteredTrackers.OnTriggerFunction[uuid] = onTrigger
   end

   -- Register Events
   util.RegisterEvents(MainTracker, EventHandler, activationEvent, deactivationEvent)
end

function mt.RegisterDeterminant(uuid, determinantEvent, classifier, manualEvent)
   if not uuid or not determinantEvent or not classifier then
      error("RegisterDeterminant failed - Not enough arguments")
   end

   if not manualEvent then
      manualEvent = false
   end

   -- DeterminantFunction
   if not RegisteredTrackers.DeterminantFunction[uuid] then
      RegisteredTrackers.DeterminantFunction[uuid] = {}
   end

   tinsert(RegisteredTrackers.DeterminantFunction[uuid],
   function(event, ...)
      if event == determinantEvent then
         if isTrackerActive(uuid) == true then
            SetDeterminant(classifier(uuid, ...))
         end
      end
   end)

   -- Register Events
   if manualEvent == false then
      util.RegisterEvents(MainTracker, EventHandler, determinantEvent)
   end
end

function mt.RegisterInformationEvent(uuid, informationEvent, informationFunc, requireActive)
   if not uuid or not informationEvent or not informationFunc then
      error("RegisterInformationEvent failed - Not enough arguments")
   end

   if requireActive == nil then
      requireActive = true
   end

   -- InformationFunction
   if not RegisteredTrackers.InformationFunction[uuid] then
      RegisteredTrackers.InformationFunction[uuid] = {}
   end

   tinsert(RegisteredTrackers.InformationFunction[uuid],
   function(event, ...)
      if event == informationEvent then
         if requireActive then
            if isTrackerActive(uuid) == true then
               informationFunc(uuid, event, ...)
            end
         else
            informationFunc(uuid, event, ...)
         end
      end
   end)

   -- Register Events
   util.RegisterEvents(MainTracker, EventHandler, informationEvent)
end

function mt.RegisterOnActivation(uuid, func)
   RegisteredTrackers.OnActivationFunction[uuid] = func
end

function mt.RegisterOnDeactivation(uuid, func)
   RegisteredTrackers.OnDeactivationFunction[uuid] = func
end

util.RegisterEvents(MainTracker, EventHandler, "PLAYER_MONEY")
util.RegisterEvents(MainTracker, EventHandler, "PLAYER_ENTERING_WORLD")

mt.InitPersistance = InitPersistance

--[===[@test
-- Test Fixture
mt.MainTracker = MainTracker
mt.EventHandler = EventHandler
--@end-test]===]

function mt.debugActiveTrackers()
   addon.debugPrintTable(ActiveTrackers)
end
