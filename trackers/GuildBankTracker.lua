local _, addon = ...

local mt = addon.mt
local util = addon.utility
local profile = addon.profile
local _G = _G

local player = UnitName("player")
local realm = GetRealmName()

local GUILD_BANK_UUID = 'GUILDBANK_01'             -- Profits and Expenses from the Guild Bank

local GBTracker = CreateFrame("Frame") -- Hidden Frame used for updating information about the Guild Bank

local function UpdateGuildBankReserves(...)
   local gbm = GetGuildBankMoney()
   addon.debugPrint(gbm)
   _G.WOWMMGlobal[realm].Chars[player].GuildBankMoney = gbm
   util.UpdatePlayerCash()
end

local function OnTrigger(uuid, t, m)
   if profile.GetBankCharacterSetting() then
      m = 0
   end

   if m > 0 then
      _G.WOWMSTracker[realm].AllChars[t].Earned = _G.WOWMSTracker[realm].AllChars[t].Earned + m
      _G.WOWMSTracker[realm][player][t].Earned = _G.WOWMSTracker[realm][player][t].Earned + m
   else
      local money = math.abs(m)
      _G.WOWMSTracker[realm].AllChars[t].Spent = _G.WOWMSTracker[realm].AllChars[t].Spent + money
      _G.WOWMSTracker[realm][player][t].Spent = _G.WOWMSTracker[realm][player][t].Spent + money
   end
   local pcash = _G.WOWMMGlobal[realm].Chars[player].Cash
   local cash = pcash + m
   util.UpdateEarnedSpent(cash, pcash)
   util.UpdatePlayerCash()
   util.UpdateZoneEarnedSpent(m)
end

local function EventHandler(self, event, ...)
   addon.debugPrint("GuildBankTracker Event", event, ...)
   UpdateGuildBankReserves()
end

mt.RegisterTracker(GUILD_BANK_UUID, 'GUILDBANK', 'GUILDBANKFRAME_OPENED', 'GUILDBANKFRAME_CLOSED', OnTrigger)

util.RegisterEvents(GBTracker, EventHandler,  'GUILDBANKFRAME_OPENED',
                                              'GUILDBANKFRAME_CLOSED',
                                              'GUILDBANK_UPDATE_MONEY')
