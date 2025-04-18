local _, addon = ...

local mt = addon.mt
local util = addon.utility
local profile = addon.profile
local _G = _G

local player = UnitName("player")
local realm = GetRealmName()

local MailTracker = CreateFrame("Frame") -- Hidden Frame used for holding information about the current contents of the mailbox
MailTracker.Mail = {}
MailTracker.MailItemCount = {}
MailTracker.LetterCount = 0
MailTracker.Parsable = false
MailTracker.rCount = 0
MailTracker.SentMoney = 0
MailTracker.SentPostage = 0
MailTracker.CurrentSender = ""

local MAXIMUM_RETRIES = 100

local MAIL_IN_AUCTION_UUID = 'MAIL_IN_01'          -- Profits from the Auction House
local MAIL_IN_AUCTION_REFUND_UUID = 'MAIL_IN_02'   -- Auction Refund - Will not contribute to Profits; will reduce Expenses if appropriate
local MAIL_IN_COD_UUID = 'MAIL_IN_03'              -- Profits from Cash on Delivery sales
local MAIL_IN_ALT_UUID = 'MAIL_IN_04'              -- "Profits" from Alts, will only effect the player specific Profits if the user has alt transactions turned on
local MAIL_IN_TRADE_UUID = 'MAIL_IN_05'            -- Profits from other players through the mail ( Not Alt or COD )
local MAIL_IN_BMAH_REFUND_UUID = 'MAIL_IN_06'      -- Black Market Auction House Refund - Will not contribute to Profits; will reduce Expenses if appropriate

local MAIL_OUT_ALT_UUID = 'MAIL_OUT_01'            -- "Expenses" to Alts, will only effect the player specific Expenses if the user has alt transactions turned on
local MAIL_OUT_TRADE_UUID = 'MAIL_OUT_02'          -- Expenses to other players through the mail ( Not Alt )
local MAIL_OUT_POSTAGE_UUID = 'MAIL_OUT_03'        -- Expenses from Postage

local function ParseMail()
   local letterCount = GetInboxNumItems()

   -- If we have no letters to parse then we don't have any money stored from alts.
   -- Quick fix for mail indicator getting stuck for some reason
   if letterCount == 0 then
      util.ClearAltMoneyXfer(player)
   end

   if MailTracker.LetterCount ~= letterCount then
      MailTracker.LetterCount = letterCount
      wipe(MailTracker.Mail)
      wipe(MailTracker.MailItemCount)

      for i = 1, letterCount do
         local _, _, sender, subject, money, CODAmount, _, itemCount = GetInboxHeaderInfo(i)
         local hasMoney = C_Mail.HasInboxMoney(i)
         local mailType = util.GetIncomingMailType(subject)
         addon.debugPrint("Parse Mail ", i, ": ", sender, subject, mailType)

         if hasMoney then
            itemCount = itemCount or 0
            itemCount = itemCount + 1
         end

         tinsert(MailTracker.MailItemCount, i, itemCount)
         if hasMoney then
            if mailType == "AHOutbid" then
               if sender == "Black Market Auction House" then
                  tinsert(MailTracker.Mail, i, { uuid = MAIL_IN_BMAH_REFUND_UUID, Money = money, Sender = sender })
               else
                  tinsert(MailTracker.Mail, i, { uuid = MAIL_IN_AUCTION_REFUND_UUID, Money = money, Sender = sender })
               end
            elseif mailType == "AHSuccess" then
               tinsert(MailTracker.Mail, i, { uuid = MAIL_IN_AUCTION_UUID, Money = money, Sender = sender })
            elseif mailType == "CODPayment" then
               tinsert(MailTracker.Mail, i, { uuid = MAIL_IN_COD_UUID, Money = money, Sender = sender })
            elseif util.IsAlt(sender) then
               tinsert(MailTracker.Mail, i, { uuid = MAIL_IN_ALT_UUID, Money = money, Sender = sender })
            elseif sender then
               tinsert(MailTracker.Mail, i, { uuid = MAIL_IN_TRADE_UUID, Money = money, Sender = sender })
            else
               addon.debugError("Might have parsed the mail too early or possibly an unhandled mail type?")
            end
         else
            if CODAmount > 0 then
               tinsert(MailTracker.Mail, i, { uuid = MAIL_IN_COD_UUID, Money = (-1 * CODAmount), Sender = sender })
            else
               tinsert(MailTracker.Mail, i, { uuid = nil, Money = 0, Sender = sender })
            end
         end
      end
   end
end

local function ClassifyIncoming(uuid, id)
   if MailTracker.Mail[id] then
      local m = MailTracker.Mail[id].Money
      if uuid == MailTracker.Mail[id].uuid and m ~= 0 then
         MailTracker.CurrentSender = MailTracker.Mail[id].Sender
         addon.debugPrint("Classify", uuid, id)
         return uuid, m
      end
   end
end

local function CheckItems(uuid)
   local mailID = InboxFrame.openMailID
   local letterCount = GetInboxNumItems()
   if mailID ~= nil and mailID ~= 0 and letterCount ~= 0 then
      if uuid == MailTracker.Mail[mailID].uuid then
         local parsedCount = MailTracker.MailItemCount[mailID]
         local itemCount = select(8, GetInboxHeaderInfo(mailID))
         local hasMoney = C_Mail.HasInboxMoney(mailID)
         if hasMoney then
            itemCount = itemCount or 0
            itemCount = itemCount + 1
         end

         if itemCount < parsedCount then
            MailTracker.CurrentSender = MailTracker.Mail[mailID].Sender
            return uuid, MailTracker.Mail[mailID].Money
         end
      end
   end
end

local function ClassifyOutgoing(uuid)
   local c_uuid
   if MailTracker.SentMoney ~= 0 then
      if util.IsAlt(MailTracker.SentRecipient) then
         c_uuid = MAIL_OUT_ALT_UUID
      else
         c_uuid = MAIL_OUT_TRADE_UUID
      end
   end

   if c_uuid == uuid then
      return uuid, MailTracker.SentMoney
   end

   if uuid == MAIL_OUT_POSTAGE_UUID then
      local postage = MailTracker.SentPostage
      MailTracker.SentPostage = 0
      return uuid, postage
   end
end

local function WaitToParseMail(self)
   MailTracker.Parsable = false
   local cmdPending = C_Mail.IsCommandPending()
   if cmdPending == false then
      self:SetScript("OnUpdate", nil)

      local letterCount = GetInboxNumItems()
      local sender = ""
      local subject = ""
      local readyToParse = true
      if letterCount > 0 then
         for i = 1, letterCount do
            sender, subject = select(3, GetInboxHeaderInfo(i))
            addon.debugPrint("Check InboxHeaderInfo", sender, subject)
            if sender == nil or subject == "Retrieving data" then
               readyToParse = false
               break
            end
         end
      end

      -- System wasn't ready for us to parse yet.
      if readyToParse == false and MailTracker.rCount < MAXIMUM_RETRIES then 
         addon.debugPrint("Mail System not ready")
         MailTracker.rCount = MailTracker.rCount + 1
         self:SetScript("OnUpdate", WaitToParseMail)
         return
      else
         MailTracker.rCount = 0
         MailTracker.Parsable = true
      end
      ParseMail()
   end
end

local function EventHandler(self, event, ...)
   addon.debugPrint("MailTracker Event", event, ...)
   if event == "MAIL_INBOX_UPDATE" then
      if MailTracker.Parsable then
         ParseMail()
      end
   end

   if event == "MAIL_SHOW" then
      self:SetScript("OnUpdate", WaitToParseMail)
   end

   if event == "SEND_MAIL_MONEY_CHANGED" then
      local sentMoney = -1 * GetSendMailMoney()
      if sentMoney < MailTracker.SentMoney then
         MailTracker.SentMoney = sentMoney
      end

      local postageCost = GetSendMailMoney() - GetSendMailPrice()
      if postageCost < MailTracker.SentPostage then
         MailTracker.SentPostage = postageCost
      end
      MailTracker.SentRecipient = SendMailNameEditBox:GetText()
   end
end

local function OnTrigger(uuid, t, m)
   if uuid == MAIL_IN_AUCTION_REFUND_UUID then
      if m > 0 and _G.WOWMSTracker[realm][player].AUCTION.Spent >= m then
         _G.WOWMSTracker[realm].AllChars.AUCTION.Spent = _G.WOWMSTracker[realm].AllChars.AUCTION.Spent - m
         _G.WOWMSTracker[realm][player].AUCTION.Spent = _G.WOWMSTracker[realm][player].AUCTION.Spent - m
      else
         m = 0
      end
   elseif uuid == MAIL_IN_BMAH_REFUND_UUID then
      if m > 0 and _G.WOWMSTracker[realm][player].BMAH.Spent >= m then
         _G.WOWMSTracker[realm].AllChars.BMAH.Spent = _G.WOWMSTracker[realm].AllChars.BMAH.Spent - m
         _G.WOWMSTracker[realm][player].BMAH.Spent = _G.WOWMSTracker[realm][player].BMAH.Spent - m
      else
         m = 0
      end
   elseif uuid == MAIL_IN_ALT_UUID or uuid == MAIL_OUT_ALT_UUID then
      local isAltIgnored = profile.GetAltSetting()
      local money = m
      if m > 0 then
         if isAltIgnored then
            m = 0
         else
            _G.WOWMSTracker[realm][player][t].Earned = _G.WOWMSTracker[realm][player][t].Earned + m
         end
         util.UpdateAltMoneyXfer(MailTracker.CurrentSender, player, money)
         MailTracker.CurrentSender = nil
      else
         if isAltIgnored then
            m = 0
         else
            local money = math.abs(m)
            _G.WOWMSTracker[realm][player][t].Spent = _G.WOWMSTracker[realm][player][t].Spent + money
         end
         util.UpdateAltMoneyXfer(player, MailTracker.SentRecipient, money)
      end
   else
      if m > 0 then
         _G.WOWMSTracker[realm].AllChars[t].Earned = _G.WOWMSTracker[realm].AllChars[t].Earned + m
         _G.WOWMSTracker[realm][player][t].Earned = _G.WOWMSTracker[realm][player][t].Earned + m
      else
         local money = math.abs(m)
         _G.WOWMSTracker[realm].AllChars[t].Spent = _G.WOWMSTracker[realm].AllChars[t].Spent + money
         _G.WOWMSTracker[realm][player][t].Spent = _G.WOWMSTracker[realm][player][t].Spent + money
      end
   end
   local pcash = _G.WOWMMGlobal[realm].Chars[player].Cash
   local cash = pcash + m
   util.UpdateEarnedSpent(cash, pcash)
   util.UpdatePlayerCash()
   util.UpdateZoneEarnedSpent(m)
end

mt.RegisterDeterminant(MAIL_IN_AUCTION_UUID, 'CLOSE_INBOX_ITEM', ClassifyIncoming)
mt.RegisterDeterminant(MAIL_IN_AUCTION_REFUND_UUID, 'CLOSE_INBOX_ITEM', ClassifyIncoming)
mt.RegisterDeterminant(MAIL_IN_COD_UUID, 'CLOSE_INBOX_ITEM', ClassifyIncoming)
mt.RegisterDeterminant(MAIL_IN_ALT_UUID, 'CLOSE_INBOX_ITEM', ClassifyIncoming)
mt.RegisterDeterminant(MAIL_IN_TRADE_UUID, 'CLOSE_INBOX_ITEM', ClassifyIncoming)
mt.RegisterDeterminant(MAIL_IN_BMAH_REFUND_UUID, 'CLOSE_INBOX_ITEM', ClassifyIncoming)

-- Determinants for when a user has a mail item open and is clicking items one at a time
mt.RegisterDeterminant(MAIL_IN_AUCTION_UUID, 'PLAYER_MONEY', CheckItems)
mt.RegisterDeterminant(MAIL_IN_AUCTION_REFUND_UUID, 'PLAYER_MONEY', CheckItems)
mt.RegisterDeterminant(MAIL_IN_COD_UUID, 'PLAYER_MONEY', CheckItems)
mt.RegisterDeterminant(MAIL_IN_ALT_UUID, 'PLAYER_MONEY', CheckItems)
mt.RegisterDeterminant(MAIL_IN_TRADE_UUID, 'PLAYER_MONEY', CheckItems)
mt.RegisterDeterminant(MAIL_IN_BMAH_REFUND_UUID, 'PLAYER_MONEY', CheckItems)

mt.RegisterDeterminant(MAIL_OUT_ALT_UUID, 'MAIL_SEND_SUCCESS', ClassifyOutgoing)
mt.RegisterDeterminant(MAIL_OUT_TRADE_UUID, 'MAIL_SEND_SUCCESS', ClassifyOutgoing)
mt.RegisterDeterminant(MAIL_OUT_POSTAGE_UUID, 'MAIL_SEND_SUCCESS', ClassifyOutgoing)

mt.RegisterTracker(MAIL_IN_AUCTION_UUID, 'AUCTION', 'MAIL_SHOW', 'MAIL_CLOSED', OnTrigger)
mt.RegisterTracker(MAIL_IN_AUCTION_REFUND_UUID, 'AUCTION_REFUND', 'MAIL_SHOW', 'MAIL_CLOSED', OnTrigger)
mt.RegisterTracker(MAIL_IN_COD_UUID, 'COD', 'MAIL_SHOW', 'MAIL_CLOSED', OnTrigger)
mt.RegisterTracker(MAIL_IN_ALT_UUID, 'ALT', 'MAIL_SHOW', 'MAIL_CLOSED', OnTrigger)
mt.RegisterTracker(MAIL_IN_TRADE_UUID, 'TRADE', 'MAIL_SHOW', 'MAIL_CLOSED', OnTrigger)
mt.RegisterTracker(MAIL_IN_BMAH_REFUND_UUID, 'BMAH_REFUND', 'MAIL_SHOW', 'MAIL_CLOSED', OnTrigger)

mt.RegisterTracker(MAIL_OUT_ALT_UUID, 'ALT', 'MAIL_SHOW', 'MAIL_CLOSED', OnTrigger)
mt.RegisterTracker(MAIL_OUT_TRADE_UUID, 'TRADE', 'MAIL_SHOW', 'MAIL_CLOSED', OnTrigger)
mt.RegisterTracker(MAIL_OUT_POSTAGE_UUID, 'POSTAGE', 'MAIL_SHOW', 'MAIL_CLOSED', OnTrigger)

util.RegisterEvents(MailTracker, EventHandler,  'MAIL_SHOW',
                                                'SEND_MAIL_MONEY_CHANGED',
                                                'MAIL_INBOX_UPDATE')
