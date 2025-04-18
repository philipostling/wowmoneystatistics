local _, addon = ...

local mt = addon.mt
local util = addon.utility
local _G = _G

local player = UnitName("player")
local realm = GetRealmName()

local LFG_UUID = 'LFG_01'         -- Profits from LFG Rewards

local function OnTrigger(uuid, t, m)
   if m >= 0 then
      _G.WOWMSTracker[realm].AllChars[t].Earned = _G.WOWMSTracker[realm].AllChars[t].Earned + m
      _G.WOWMSTracker[realm][player][t].Earned = _G.WOWMSTracker[realm][player][t].Earned + m

      local pcash = _G.WOWMMGlobal[realm].Chars[player].Cash
      local cash = pcash + m
      util.UpdateEarnedSpent(cash, pcash)
      util.UpdatePlayerCash(cash)
      util.UpdateZoneEarnedSpent(m)
   else
      addon.debugError("Losing money while receiving LFG Reward?!")
   end
end

local function Classify(uuid)
   addon.debugPrint("Classify", uuid)
   return uuid, 0
end

mt.RegisterDeterminant(LFG_UUID, 'LFG_COMPLETION_REWARD', Classify)

-- The intention is to have this Tracker always on
mt.RegisterTracker(LFG_UUID, 'LFG', 'PLAYER_ENTERING_WORLD', nil, OnTrigger)
