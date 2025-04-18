local addon_name, addon = ...
local tt = addon.tooltip

local core = addon.core
local token = addon.token
local util = addon.utility
local profile = addon.profile
local time = addon.time
local global = addon.global
local _G = _G

local tooltip
local realm = GetRealmName()
local player = UnitName("player")
local faction = UnitFactionGroup("player")
local TTGap = 10

local MailboxMoney = false

local Optional = {}
Optional.ShowDefault = {}
Optional.DispFunc = {}
Optional.MenuFunc = {}
Optional.LenFunc = {}
Optional.DispName = {}
Optional.CalcAvg = {}
Optional.TimeBased = {}
Optional.SpaceAfter = {}
Optional.Keys = {}
local function RegisterOptionalSetting(key, dispName, defaultShow, dispFunc, menuFunc, lenFunc, calcAvg, spaceAfter,  timeBased)
   if key == nil or type(key) ~= "string" then 
      error("key should be a string")
      return
   end

   if dispName == nil or type(dispName) ~= "string" then 
      error("dispName should be a string")
      return
   end

   if defaultShow == nil or type(defaultShow) ~= "boolean" then 
      error("defaultShow should be a boolean")
      return
   end

   if dispFunc == nil or type(dispFunc) ~= "function" then 
      if dispFunc then
         error("dispFunc should be a function")
         return
      end
   end

   if menuFunc == nil or type(menuFunc) ~= "function" then 
      if menuFunc then
         error("menuFunc should be a function")
         return
      end
   end

   if lenFunc == nil or type(lenFunc) ~= "function" then 
      if lenFunc then
         error("lenFunc should be a function")
         return
      end
   end

   if calcAvg == nil then
      calcAvg = false
   end

   if type(calcAvg) ~= "boolean" then 
      error("calcAvg should be a boolean")
      return
   end

   if type(timeBased) ~= "boolean" then 
      error("timeBased should be a boolean")
      return
   end

   if type(spaceAfter) ~= "boolean" then 
      error("spaceAfter should be a boolean")
      return
   end

   if not Optional.DispFunc[key] then
      Optional.DispName[key] = dispName
      Optional.ShowDefault[key] = defaultShow
      Optional.DispFunc[key] = dispFunc
      Optional.MenuFunc[key] = menuFunc
      Optional.LenFunc[key] = lenFunc
      Optional.CalcAvg[key] = calcAvg
      Optional.TimeBased[key] = timeBased
      Optional.SpaceAfter[key] = spaceAfter
      table.insert(Optional.Keys, key)
   end
end

local function AddCashItem(title, cash, pos, class)
   local r, g, b = 1, 1, 1
   if class then
      r, g, b = util.GetClassRGB(class)
   end
   if pos then
      tooltip:AddDoubleLine(title, util.FormatMoney(cash), r, g, b, 1, 1, 1)
   else
      tooltip:AddDoubleLine(title, util.FormatMoney(cash), r, g, b, 1, 0, 0)
   end
end

local function AddSeperator()
   local total = 0
   local longestLeft = "Character:"

   local moneyXferSetting = profile.GetMoneyXferSetting()
   if moneyXferSetting == "FROM_TO_MONEY" or moneyXferSetting == "TO_MONEY" then
      longestLeft = "Money Transfers:"
   end

   for name, value in pairs(_G.WOWMMGlobal) do
      if type(value) == "table" then
         total = total + value.Total
      end
   end

   local ToTable = {}
   if moneyXferSetting == "FROM_TO_MONEY" or moneyXferSetting == "TO_MONEY" then
      for sender, v in pairs(_G.WOWMMGlobal[realm].MoneyXfer) do
         for receiver, money in pairs(v) do
            if moneyXferSetting == "FROM_TO_MONEY" then
               local s = sender.." => "..receiver
               if #s > #longestLeft then
                  longestLeft = s
               end
            else
               local m = ToTable[receiver] or 0
               ToTable[receiver] = m + money
            end
         end
      end
   end

   for name, _ in pairs(_G.WOWMMGlobal[realm].Chars) do
      if #name > #longestLeft then
         longestLeft = name
      end
   end

   for name, v in pairs(_G.WOWMMGlobal) do
      if type(v) == "table" then
         if #name > #longestLeft then
            longestLeft = name
         end
      end
   end

   local longestRight = util.FormatMoney(total)

   for _, m in pairs(ToTable) do
      local money = util.FormatMoney(m)
      if #money > #longestRight then
         longestRight = m
      end
   end

   for i = 1, #Optional.Keys do
      local key = Optional.Keys[i]
      if profile.GetOptionalSettingShown(key, Optional.ShowDefault[key]) then
         if Optional.LenFunc[key] then
            local left, right = Optional.LenFunc[key]()
            if #left > #longestLeft then
               longestLeft = left
            end
            if #right > #longestRight then
               longestRight = right
            end
         end
      end
   end

   tooltip:AddSeperator("-", longestLeft, longestRight, TTGap)
end

local function GetAvg(key)
   local E, S, N, C = 0
   local setting = profile.GetFactionDisplaySetting()

   if setting then
      E = _G.WOWMMGlobal[realm][key][faction].Earned
      S = _G.WOWMMGlobal[realm][key][faction].Spent
      N = _G.WOWMMGlobal[realm][key][faction].Net
      C = _G.WOWMMGlobal[realm][key][faction].Count
   else
      E = _G.WOWMMGlobal[realm][key].Earned
      S = _G.WOWMMGlobal[realm][key].Spent
      N = _G.WOWMMGlobal[realm][key.."Net"]
      C = _G.WOWMMGlobal[realm][key.."Count"]
   end

   if C > 0 then
      local A = floor(N / C)
      return A
   else
      return (E - S)
   end
end

local function PopulateTooltip()
   local TimeBasedShown = false
   local DisplayingTimeBased = false
   local PrevDisplayingTimeBased = false

   for i = 1, #Optional.Keys do
      local key = Optional.Keys[i]
      local isTimeBased = Optional.TimeBased[key]
      local isDisplayable = Optional.DispFunc[key] ~= nil
      local isShown = false

      if isTimeBased then
         local earnedShown = profile.GetOptionalSettingShown(key.."Earned", Optional.ShowDefault[key.."Earned"])
         local spentShown = profile.GetOptionalSettingShown(key.."Spent", Optional.ShowDefault[key.."Spent"])
         local netShown = profile.GetOptionalSettingShown(key.."Net", Optional.ShowDefault[key.."Net"])
         local avgShown = profile.GetOptionalSettingShown(key.."Avg", Optional.ShowDefault[key.."Avg"])
         isShown = earnedShown or spentShown or netShown or (key ~= "AllTime" and avgShown)
      else
         isShown = profile.GetOptionalSettingShown(key, Optional.ShowDefault[key])
      end

      if isShown then
         DisplayingTimeBased = isTimeBased
         TimeBasedShown = isTimeBased or TimeBasedShown

         if PrevDisplayingTimeBased and DisplayingTimeBased == false then
            -- Transitioned from displaying time based to non-time based
            -- Do I need to add a seperator?
            if TimeBasedShown and isDisplayable then
               AddSeperator()
               tooltip:AddLine(' ')
            end
         end

         if isDisplayable then
            Optional.DispFunc[key]()
         end
         if Optional.SpaceAfter[key] then
            tooltip:AddLine(' ')
         end
         PrevDisplayingTimeBased = DisplayingTimeBased
      end
   end

   AddCashItem("Total:", util.GetTotalCash(), true)

   if MailboxMoney and profile.GetMoneyXferSetting() == "ASTERISK" then
      AddSeperator()
      tooltip:AddLine('(*) - Alt Money Transfer')
   end
end

function tt.ShowTooltip(self)
   tooltip:Init(self)
   PopulateTooltip()
   tooltip:Show()
end

function tt.HideTooltip()
   tooltip:Hide()
end

local function SetFont(font)
   tooltip:SetFont(font)
end

local function GetFont()
   tooltip:GetFont()
end

local function SetFontSize(fontSize)
   tooltip:SetFontSize(fontSize)
end

local function GetFontSize()
   tooltip:GetFontSize()
end

local function UpdateFontInfo()
   SetFont(profile.GetFontSetting())
   SetFontSize(profile.GetFontSizeSetting())
end

local function StandardOnOffOptionalMenu(key, menu, level)
   local text = "Show "..Optional.DispName[key]
   menu:AddCheckOption( text,
                        function(self)
                           return profile.GetOptionalSettingShown(key, Optional.ShowDefault[key])
                        end,
                        level,
                        function(self, _, _, checked)
                           profile.SetOptionalSetting(key, checked)
                        end
                      )
end

local function StandardOptionalMenu(key, menu, level)
   menu:AddMenu(time.TimeSetTitles[key], level, "TimeBased_"..key)
end

function tt.OptionalSettingMenu(menu, level, menuList)
   for i = 1, #Optional.Keys do
      local key = Optional.Keys[i]
      Optional.MenuFunc[key](menu, level, menuList)
   end
end

tt.UpdateFontInfo = UpdateFontInfo

tooltip = Prototype_Tooltip:new()

local function Registrations()
   RegisterOptionalSetting ("WowTokenPrice",
                              "WoW Token Price",
                              false,
                              function()
                                 if C_WowTokenPublic.GetCommerceSystemStatus() then
                                    AddCashItem("WoW Token Price:", token.GetTokenPrice(), true)
                                 else
                                    tooltip:AddDoubleLine("WoW Token Price:", "System Offline", 1, 1, 1, 1, 1, 1)
                                 end
                                 tooltip:AddLine(' ')
                                 AddSeperator()
                              end,
                              function(menu, level, menuList)
                                 if level ~= 2 then return end
                                 local key = "WowTokenPrice"
                                 StandardOnOffOptionalMenu(key, menu, level)
                              end,
                              function()
                                 return "WoW Token Price:", util.FormatMoney(token.GetTokenPrice())
                              end,
                              false,
                              true,
                              false
                           )
   
   RegisterOptionalSetting ("WatchedCurrencies",
                              "Watched Currencies",
                              false,
                              function()
                                 local currencyCount = C_CurrencyInfo.GetCurrencyListSize()
                                 local shownCount = 0
                                 for i = 1, currencyCount do
                                    local ci = C_CurrencyInfo.GetCurrencyListInfo(i)
                                    if not ci.isHeader and not ci.isTypeUnused and ci.isShowInBackpack then
                                       shownCount = shownCount + 1
                                       tooltip:AddDoubleLine(util.FormatCurrency(ci.name..":", ci.iconFileID), ci.quantity, 1, 1, 1, 1, 1, 1)
                                    end
                                 end
                                 if shownCount ~= 0 then
                                    tooltip:AddLine(' ')
                                    AddSeperator()
                                    tooltip:AddLine(' ')
                                 end
                              end,
                              function(menu, level, menuList)
                                 if level ~= 2 then return end
                                 local key = "WatchedCurrencies"
                                 StandardOnOffOptionalMenu(key, menu, level)
                                 menu:AddDescriptor(  "-------------------", level )
                              end,
                              function()
                                 local currencyCount = C_CurrencyInfo.GetCurrencyListSize()
                                 local left = ""
                                 local right = ""
                                 for i = 1, currencyCount do
                                    local ci = C_CurrencyInfo.GetCurrencyListInfo(i)
                                    if not ci.isHeader and not ci.isTypeUnused and ci.isShowInBackpack then
                                       local formattedLeft = util.FormatCurrency(ci.name..":", ci.iconFileID)
                                       if #left < #formattedLeft then
                                          left = formattedLeft
                                       end
                                       count = format("%d", count)
                                       if #right < #count then
                                          right = count
                                       end
                                    end
                                 end
                                 return left, right
                              end,
                              false,
                              false,
                              false
                           )
   
   -- Register all Time based Optional Settings
   for _, v in pairs(time.GetTimeList()) do
      RegisterOptionalSetting (  v,                                                          -- Persistance Key
                                 time.TimeSetTitles[v],                                      -- Display Title
                                 true,                                                       -- Default Show
                                 function()                                                  -- Display Function
                                    local setting = profile.GetFactionDisplaySetting()
                                    local E, S = 0
   
                                    if setting then
                                       E = _G.WOWMMGlobal[realm][v][faction].Earned
                                       S = _G.WOWMMGlobal[realm][v][faction].Spent
                                    else
                                       E = _G.WOWMMGlobal[realm][v].Earned
                                       S = _G.WOWMMGlobal[realm][v].Spent
                                    end

                                    local earnedShown = profile.GetOptionalSettingShown(v.."Earned", Optional.ShowDefault[v.."Earned"])
                                    local spentShown = profile.GetOptionalSettingShown(v.."Spent", Optional.ShowDefault[v.."Spent"])
                                    local netShown = profile.GetOptionalSettingShown(v.."Net", Optional.ShowDefault[v.."Net"])
                                    local avgShown = profile.GetOptionalSettingShown(v.."Avg", Optional.ShowDefault[v.."Avg"])
   
                                    if earnedShown or spentShown or netShown or (v ~= "AllTime" and avgShown) then
                                       tooltip:AddLine(format("%s:", time.TimeSetTitles[v]))
                                       if earnedShown then
                                          AddCashItem("Earned:", E, true)
                                       end

                                       if spentShown then
                                          AddCashItem("Spent:", S, (S == 0))
                                       end

                                       if netShown then
                                          AddCashItem("Net:", (E - S), E >= S)
                                       end

                                       if util.getSetValue(time.TimeSetAvg, v) then
                                          if Optional.CalcAvg[v] and avgShown then
                                             local avg = GetAvg(v)
                                             AddCashItem("Avg:", avg, avg >= 0, "EMPHASIS")
                                          end
                                       end
                                    end
                                 end,
                                 function(menu, level, menuList)                             -- Menu Function
                                    if level ~= 2 then return end
                                    local key = v 
                                    --StandardOnOffOptionalMenu(key, menu, level)
                                    StandardOptionalMenu(key, menu, level)
                                 end,
                                 function()                                                  -- Length Function
                                    local left = format("%s:", time.TimeSetTitles[v])
                                    local right = ""
                                    
                                    if #left < #("Earned:") then
                                       left = "Earned:"
                                    end
   
                                    local setting = profile.GetFactionDisplaySetting()
                                    local E, S = 0
   
                                    if setting then
                                       E = _G.WOWMMGlobal[realm][v][faction].Earned
                                       S = _G.WOWMMGlobal[realm][v][faction].Spent
                                    else
                                       E = _G.WOWMMGlobal[realm][v].Earned
                                       S = _G.WOWMMGlobal[realm][v].Spent
                                    end
   
                                    local earned = util.FormatMoney(E)
                                    local spent = util.FormatMoney(S)
                                    local net = util.FormatMoney(E-S)
                                    local avg = ""
                                    if util.getSetValue(time.TimeSetAvg, v) then
                                       avg = util.FormatMoney(GetAvg(v))
                                    end
                                    if #right < #earned then
                                       right = earned
                                    end
                                    if #right < #spent then
                                       right = spent
                                    end
                                    if #right < #net then
                                       right = net
                                    end
                                    if #right < #avg then
                                       right = avg
                                    end
                                    return left, right
                                 end,
                                 util.getSetValue(time.TimeSetAvg, v),                       -- Calculate Average
                                 true,                                                       -- Space After Display
                                 true                                                        -- Time Based Optional Setting
                              )

      RegisterOptionalSetting (v.."All",
                                 "All",
                                 true,
                                 nil, -- All is not a Display feature
                                 function(menu, level, menuList)
                                    if level == 3 and menuList == "TimeBased_"..v then
                                       local earnedShown = profile.GetOptionalSettingShown(v.."Earned", Optional.ShowDefault[v.."Earned"])
                                       local spentShown = profile.GetOptionalSettingShown(v.."Spent", Optional.ShowDefault[v.."Spent"])
                                       local netShown = profile.GetOptionalSettingShown(v.."Net", Optional.ShowDefault[v.."Net"])
                                       local avgShown = profile.GetOptionalSettingShown(v.."Avg", Optional.ShowDefault[v.."Avg"])
                                       local isHide = earnedShown and spentShown and netShown and (v == "AllTime" or avgShown)
                                       local key = v.."All" 
                                       local text = "Show "..Optional.DispName[key]
                                       if isHide then
                                          text = "Hide "..Optional.DispName[key]
                                       end
                                       menu:AddDescriptor    (  time.TimeSetTitles[v], level, true )
                                       menu:AddDescriptor    (  "-------------------", level )
                                       menu:AddOption( text,
                                                         level,
                                                         function(self)
                                                            profile.SetOptionalSetting(v.."Earned", not isHide)
                                                            profile.SetOptionalSetting(v.."Spent", not isHide)
                                                            profile.SetOptionalSetting(v.."Net", not isHide)
                                                            if v~= "AllTime" then
                                                               profile.SetOptionalSetting(v.."Avg", not isHide)
                                                            end
                                                         end
                                                     )
                                       menu:AddDescriptor    (  "-------------------", level )
                                    end
                                 end,
                                 nil, -- All is not a Display feature
                                 false,
                                 false,
                                 true
                              )
   
      RegisterOptionalSetting (v.."Earned",
                                 "Earned",
                                 true,
                                 nil, -- Earned Display is handled internally in other options
                                 function(menu, level, menuList)
                                    if level == 3 and menuList == "TimeBased_"..v then
                                       local key = v.."Earned" 
                                       local text = "Show "..Optional.DispName[key]
                                       menu:AddCheckOption( text,
                                                            function(self)
                                                               return profile.GetOptionalSettingShown(key, Optional.ShowDefault[key])
                                                            end,
                                                            level,
                                                            function(self, _, _, checked)
                                                               profile.SetOptionalSetting(key, checked)
                                                            end
                                                          )
                                    end
                                 end,
                                 nil, -- Earned Length is handled internally in other options
                                 false,
                                 false,
                                 true
                              )
   
      RegisterOptionalSetting (v.."Spent",
                                 "Spent",
                                 true,
                                 nil, -- Spent Display is handled internally in other options
                                 function(menu, level, menuList)
                                    if level == 3 and menuList == "TimeBased_"..v then
                                       local key = v.."Spent" 
                                       local text = "Show "..Optional.DispName[key]
                                       menu:AddCheckOption( text,
                                                            function(self)
                                                               return profile.GetOptionalSettingShown(key, Optional.ShowDefault[key])
                                                            end,
                                                            level,
                                                            function(self, _, _, checked)
                                                               profile.SetOptionalSetting(key, checked)
                                                            end
                                                          )
                                    end
                                 end,
                                 nil, -- Spent Length is handled internally in other options
                                 false,
                                 false,
                                 true
                              )
   
      RegisterOptionalSetting (v.."Net",
                                 "Net",
                                 true,
                                 nil, -- Net Display is handled internally in other options
                                 function(menu, level, menuList)
                                    if level == 3 and menuList == "TimeBased_"..v then
                                       local key = v.."Net" 
                                       local text = "Show "..Optional.DispName[key]
                                       menu:AddCheckOption( text,
                                                            function(self)
                                                               return profile.GetOptionalSettingShown(key, Optional.ShowDefault[key])
                                                            end,
                                                            level,
                                                            function(self, _, _, checked)
                                                               profile.SetOptionalSetting(key, checked)
                                                            end
                                                          )
                                       if v ~= "AllTime" then
                                          menu:AddDescriptor    (  "-------------------", level )
                                       end
                                    end
                                 end,
                                 nil, -- Net Length is handled internally in other options
                                 false,
                                 false,
                                 true
                              )
   
      RegisterOptionalSetting (v.."Avg",
                                 "Average",
                                 true,
                                 nil, -- Avg Display is handled internally in other options
                                 function(menu, level, menuList)
                                    if level == 3 and menuList == "TimeBased_"..v and v ~= "AllTime" then
                                       local key = v.."Avg" 
                                       local text = "Show "..Optional.DispName[key]
                                       menu:AddCheckOption( text,
                                                            function(self)
                                                               return profile.GetOptionalSettingShown(key, Optional.ShowDefault[key])
                                                            end,
                                                            level,
                                                            function(self, _, _, checked)
                                                               profile.SetOptionalSetting(key, checked)
                                                            end
                                                          )
                                    end
                                 end,
                                 nil, -- Avg Length is handled internally in other options
                                 false,
                                 false,
                                 true
                              )
   end
   
   RegisterOptionalSetting ("Invert",
                              "Invert Time Display",
                              false,
                              nil, -- Invert Display is handled internally in other options
                              function(menu, level, menuList)
                                 if level ~= 2 then return end
                                 local key = "Invert" 
                                 local text = Optional.DispName[key]
                                 menu:AddCheckOption( string.format("|cFF%06X%s|r", 0x00FF96, text),
                                                      function(self)
                                                         return profile.GetOptionalSettingShown(key, Optional.ShowDefault[key])
                                                      end,
                                                      level,
                                                      function(self, _, _, checked)
                                                         profile.SetOptionalSetting(key, checked)
                                                         ReloadUI()
                                                      end
                                                    )
                                 menu:AddDescriptor(  "-------------------", level )
                              end,
                              nil, -- Invert Display is handled internally in other options
                              false,
                              false,
                              false
                           )
   
   RegisterOptionalSetting (  "MoneyXfers",
                              "Money Transfers",
                              true,
                              function()
                                 local setting = profile.GetMoneyXferSetting()
                                 if setting == "FROM_TO_MONEY" or setting == "TO_MONEY" then
                                    tooltip:AddLine("Money Transfers:")
                                    local haveTransfers = false
                                    local ToTable = {}
                                    for sender, v in pairs(_G.WOWMMGlobal[realm].MoneyXfer) do
                                       for receiver, money in pairs(v) do
                                          if money > 0 then
                                             haveTransfers = true
   
                                             if setting == "FROM_TO_MONEY" then
                                                local senderColor = util.GetClassRGBHex(_G.WOWMMGlobal[realm].Classes[sender])
                                                local receiverColor = util.GetClassRGBHex(_G.WOWMMGlobal[realm].Classes[receiver])
                                                AddCashItem("|c"..string.format("FF%06X", senderColor)..sender.."|r".." => ".."|c"..string.format("FF%06X", receiverColor)..receiver.."|r", money, true)
                                             else
                                                local m = ToTable[receiver] or 0
                                                ToTable[receiver] = m + money
                                             end
                                          end
                                       end
                                    end
   
                                    if setting == "TO_MONEY" then
                                       for receiver, money in pairs(ToTable) do
                                          local receiverColor = util.GetClassRGBHex(_G.WOWMMGlobal[realm].Classes[receiver])
                                          AddCashItem("|c"..string.format("FF%06X", receiverColor)..receiver.."|r", money, true)
                                       end
                                    end
   
                                    if not haveTransfers then
                                       tooltip:AddLine("None", 1, 1, 1)
                                    end
                                    tooltip:AddLine(' ')
                                    AddSeperator()
                                    tooltip:AddLine(' ')
                                 end
                              end,
                              function(menu, level, menuList)
                                 if level == 2 then
                                    menu:AddMenu(  "Money Transfers", 2, "MoneyXfers" )
                                    menu:AddDescriptor(  "-------------------", level )
                                 elseif level == 3 and menuList == "MoneyXfers" then
                                    menu:AddDescriptor    (  "Money Transfers", level, true )
                                    menu:AddDescriptor    (  "-------------------", level )
                                    menu:AddRadioOption( "Asterisk",
                                                         function(self)
                                                            local setting = profile.GetMoneyXferSetting()
                                                            return setting == "ASTERISK"
                                                         end,
                                                         level,
                                                         function(self, _, _, _)
                                                            profile.SetMoneyXferSetting("ASTERISK")
                                                            menu:Refresh()
                                                         end
                                                       )
   
                                    menu:AddRadioOption( "From => To",
                                                         function(self)
                                                            local setting = profile.GetMoneyXferSetting()
                                                            return setting == "FROM_TO_MONEY"
                                                         end,
                                                         level,
                                                         function(self, _, _, _)
                                                            profile.SetMoneyXferSetting("FROM_TO_MONEY")
                                                            menu:Refresh()
                                                         end
                                                       )
   
                                    menu:AddRadioOption( "To",
                                                         function(self)
                                                            local setting = profile.GetMoneyXferSetting()
                                                            return setting == "TO_MONEY"
                                                         end,
                                                         level,
                                                         function(self, _, _, _)
                                                            profile.SetMoneyXferSetting("TO_MONEY")
                                                            menu:Refresh()
                                                         end
                                                       )
   
                                    menu:AddRadioOption( "None",
                                                         function(self)
                                                            local setting = profile.GetMoneyXferSetting()
                                                            return setting == "NONE"
                                                         end,
                                                         level,
                                                         function(self, _, _, _)
                                                            profile.SetMoneyXferSetting("NONE")
                                                            menu:Refresh()
                                                         end
                                                       )
                                 end
                              end,
                              function()
                                 return "", ""
                              end,
                              false,
                              false,
                              false
                           )
   
   RegisterOptionalSetting (  "Characters",
                              "Characters",
                              true,
                              function()
                                 local chars = util.GetSortedCharList(realm)
                                 local setting = profile.GetTooltipCharacterSetting()
                                 local factionSetting = profile.GetFactionDisplaySetting()
                                 MailboxMoney = false
                                 if setting ~= "NONE" then
                                    tooltip:AddLine("Character:")
                                    for _, name in pairs(chars) do
                                       local n = name
                                       if (setting == "CURRENT" and n == player) or setting == "ALL" and ((factionSetting and util.GetCharacterFaction(realm, n) == faction) or not factionSetting) then
                                          if util.GetPlayerMailIndicator(n) and profile.GetMoneyXferSetting() == "ASTERISK" then
                                             n = n.." (*)"
                                             MailboxMoney = true
                                          end
                                          AddCashItem(n, _G.WOWMMGlobal[realm].Chars[name].Cash, true, _G.WOWMMGlobal[realm].Classes[name])
   
                                          if profile.GetBankCharacterSetting(realm, name) then
                                             local gbm = _G.WOWMMGlobal[realm].Chars[name].GuildBankMoney
                                             if gbm and gbm ~= 0 then
                                                AddCashItem("  Bank", gbm, true, _G.WOWMMGlobal[realm].Classes[name])
                                             end
                                          end
                                       end
                                    end
                                    tooltip:AddLine(' ')
                                 end
                              end,
                              function(menu, level, menuList)
                                 if level == 2 then
                                    menu:AddMenu(  "Characters", 2, "Characters" )
                                 elseif level == 3 and menuList == "Characters" then
                                    menu:AddDescriptor    (  "Characters", level, true )
                                    menu:AddDescriptor    (  "-------------------", level )
                                    menu:AddRadioOption( "All",
                                                         function(self)
                                                            local setting = profile.GetTooltipCharacterSetting()
                                                            return setting == "ALL"
                                                         end,
                                                         level,
                                                         function(self, _, _, _)
                                                            profile.SetTooltipCharacterSetting("ALL")
                                                            menu:Refresh()
                                                         end
                                                       )
   
                                    menu:AddRadioOption( "Current Only",
                                                         function(self)
                                                            local setting = profile.GetTooltipCharacterSetting()
                                                            return setting == "CURRENT"
                                                         end,
                                                         level,
                                                         function(self, _, _, _)
                                                            profile.SetTooltipCharacterSetting("CURRENT")
                                                            menu:Refresh()
                                                         end
                                                       )
   
                                    menu:AddRadioOption( "None",
                                                         function(self)
                                                            local setting = profile.GetTooltipCharacterSetting()
                                                            return setting == "NONE"
                                                         end,
                                                         level,
                                                         function(self, _, _, _)
                                                            profile.SetTooltipCharacterSetting("NONE")
                                                            menu:Refresh()
                                                         end
                                                       )
                                 end
                              end,
                              function()
                                 return "", ""
                              end,
                              false,
                              false,
                              false
                           )
   
   RegisterOptionalSetting (  "Servers",
                              "Servers",
                              true,
                              function()
                                 local setting = profile.GetTooltipServerSetting()
                                 if setting ~= "NONE" then
                                    tooltip:AddLine("Server:")
                                    for name, value in pairs(_G.WOWMMGlobal) do
                                       if type(value) == "table" and ((setting == "CURRENT" and name == realm) or setting == "ALL") then
                                          local realmCash = util.GetRealmTotalCash(name)
                                          if realmCash ~= 0 then
                                             AddCashItem(name, realmCash, true)
                                          end
                                       end
                                    end
                                    tooltip:AddLine(' ')
                                 end
                              end,
                              function(menu, level, menuList)
                                 if level == 2 then
                                    menu:AddMenu(  "Servers", 2, "Servers" )
                                 elseif level == 3 and menuList == "Servers" then
                                    menu:AddDescriptor    (  "Servers", level, true )
                                    menu:AddDescriptor    (  "-------------------", level )
                                    menu:AddRadioOption( "All",
                                                         function(self)
                                                            local setting = profile.GetTooltipServerSetting()
                                                            return setting == "ALL"
                                                         end,
                                                         level,
                                                         function(self, _, _, _)
                                                            profile.SetTooltipServerSetting("ALL")
                                                            menu:Refresh()
                                                         end
                                                       )
   
                                    menu:AddRadioOption( "Current Only",
                                                         function(self)
                                                            local setting = profile.GetTooltipServerSetting()
                                                            return setting == "CURRENT"
                                                         end,
                                                         level,
                                                         function(self, _, _, _)
                                                            profile.SetTooltipServerSetting("CURRENT")
                                                            menu:Refresh()
                                                         end
                                                       )
   
                                    menu:AddRadioOption( "None",
                                                         function(self)
                                                            local setting = profile.GetTooltipServerSetting()
                                                            return setting == "NONE"
                                                         end,
                                                         level,
                                                         function(self, _, _, _)
                                                            profile.SetTooltipServerSetting("NONE")
                                                            menu:Refresh()
                                                         end
                                                       )
                                 end
                              end,
                              function()
                                 return "", ""
                              end,
                              false,
                              false,
                              false
                           )
end

local frame = CreateFrame("Frame")

local function EventHandler(self, event, ...)
   local args = {...}
   if event == "ADDON_LOADED" and args[1] ~= addon_name then
      return
   end

   addon.debugPrint("Tooltip Event", event, ...)
   if event == "ADDON_LOADED" and args[1] == addon_name then
      global.InitGlobals()

      self:SetScript("OnUpdate",
         function(self, elapsed)
            if core.VersionChangesApplied then
               UpdateFontInfo()
               Registrations()
               self:SetScript("OnUpdate", nil)
            end
         end
      )
   end
end

util.RegisterEvents(frame, EventHandler, 'ADDON_LOADED')
