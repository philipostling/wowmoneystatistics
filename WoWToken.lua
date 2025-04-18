local addon_name, addon = ...
local token = addon.token

local util = addon.utility

local price = 0
local TOKEN_REFRESH_TIMER = 300 -- 5 minutes

local function UpdateTokenPrice()
   price = C_WowTokenPublic:GetCurrentMarketPrice()
end

local function RequestTokenPrice()
   C_WowTokenPublic.UpdateMarketPrice()
end

function token.GetTokenPrice()
   return price
end

local frame = CreateFrame("Frame")

frame:SetScript("OnUpdate",  function(self, elapsed)
                                self.Elapsed = (self.Elapsed or 0) + elapsed
                                if self.Elapsed >= TOKEN_REFRESH_TIMER then
                                   RequestTokenPrice()
                                   self.Elapsed = 0
                                end
                             end
               )

local loaded = false
local function EventHandler(self, event, ...)
   local args = {...}
   if event == "ADDON_LOADED" and args[1] ~= addon_name then
      return
   end

   if event == "PLAYER_ENTERING_WORLD" and loaded then
      return
   elseif event == "PLAYER_ENTERING_WORLD" then
      loaded = true
   end

   addon.debugPrint("WoWToken Event", event, ...)
   if event == "TOKEN_MARKET_PRICE_UPDATED" then
      UpdateTokenPrice()
   elseif event == "PLAYER_ENTERING_WORLD" then
      if price == 0 or not price then
         RequestTokenPrice()
      end
   elseif event == "ADDON_LOADED" and args[1] == addon_name then
      if price == 0 or not price then
         RequestTokenPrice()
      end
   end
end

util.RegisterEvents(frame, EventHandler,
                           'PLAYER_ENTERING_WORLD',
                           'ADDON_LOADED',
                           'TOKEN_MARKET_PRICE_UPDATED')
