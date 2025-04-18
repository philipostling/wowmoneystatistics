local _, addon = ...

local TooltipHeaderFontName, TooltipHeaderFontHeight, TooltipHeaderFontFlags
local FontName, FontHeight, FontFlags

local _G = _G
local fonts = addon.fonts
local util = addon.utility
local profile = addon.profile

local function GetStringWidth(self, string)
local IsAddOnLoaded = C_AddOns.IsAddOnLoaded or IsAddOnLoaded;
   if IsAddOnLoaded("ElvUI") and profile.GetElvUIFontSetting() then
      cTooltipFont(self.fontString)
   else
      self.fontString:SetFont(fonts[self.Font], self.FontHeight, nil)
   end
   self.fontString:SetText(string)
   return self.fontString:GetStringWidth()
end

Prototype_Tooltip =
{
   Font = "Friz",
   FontHeight = 12
}

function Prototype_Tooltip:SetFont(font)
   self.Font = font
end

function Prototype_Tooltip:GetFont()
   return self.Font
end

function Prototype_Tooltip:SetFontSize(size)
   self.FontHeight = size
end

function Prototype_Tooltip:GetFontSize()
   return self.FontHeight
end

function Prototype_Tooltip:new()
   self:SetFont(self.Font)
   self:SetFontSize(self.FontHeight)
   self.tooltip = GameTooltip 
   local stringTestingFrame = CreateFrame("Frame", nil, UIParent)
   self.fontString = stringTestingFrame:CreateFontString()
   self.fontString:SetSize(400, 20)
   --[===[@debug
   self.fontString:SetPoint("TOPLEFT",stringTestingFrame,"TOPLEFT")
   self.fontString:SetFont(fonts[self.Font], self.FontHeight, nil)
   self.fontString:SetText("Test Test Test Test Test")
   stringTestingFrame:SetWidth(400)
   stringTestingFrame:SetHeight(20)
   local t = stringTestingFrame:CreateTexture(nil,"BACKGROUND")
   t:SetTexture("Interface\\DialogFrame\\UI-DialogBox-BackgroundInterface")
   t:SetAllPoints(stringTestingFrame)
   stringTestingFrame.texture = t
   stringTestingFrame:SetPoint("CENTER")
   stringTestingFrame:Hide()
   --@end-debug]===]

   self.tooltip:SetOwner(UIParent, "ANCHOR_NONE")
   
   return self
end

function Prototype_Tooltip:AddLine(text, ...)
   local args = {...}
   self.tooltip:AddLine(text, args[1], args[2], args[3], args[4])
end

function Prototype_Tooltip:AddDoubleLine(textL, textR, ...)
   local args = {...}
   self.tooltip:AddDoubleLine(textL, textR, args[1], args[2], args[3], args[4], args[5], args[6])
end

function Prototype_Tooltip:AddSeperator(seperatorChar, longestLeft, longestRight, numGapChars)
   local measurementMultiplier = 20
   local seperator = ""
   -- In order to get an accurate measurement of a 
   -- single char multiply it and then divide it later
   for i = 1, measurementMultiplier do
      seperator = seperator..seperatorChar
   end
      
   local seperatorCharWidth = GetStringWidth(self, seperator) / measurementMultiplier
   local longestLeftWidth = GetStringWidth(self, longestLeft)
   local longestRightWidth = GetStringWidth(self, longestRight)

   local leftSeperatorCount = ceil(longestLeftWidth / seperatorCharWidth)
   local rightSeperatorCount = ceil(longestRightWidth / seperatorCharWidth)

   seperator = ""
   --@release@
   local seperatorCount = leftSeperatorCount + rightSeperatorCount + numGapChars
   for i = 1, seperatorCount do
      seperator = seperator..seperatorChar
   end
   --@end-release@
   --[===[@debug
   for i = 1, leftSeperatorCount do
      seperator = seperator..seperatorChar
   end
   seperator = seperator.."+"
   for i = 1, numGapChars - 2 do
      seperator = seperator..seperatorChar
   end
   seperator = seperator.."+"
   for i = 1, rightSeperatorCount do
      seperator = seperator..seperatorChar
   end
   --@end-debug]===]

   self:AddLine(seperator)
end

function Prototype_Tooltip:Init(anchor)
   TooltipHeaderFontName, TooltipHeaderFontHeight, TooltipHeaderFontFlags = GameTooltipHeaderText:GetFont()
   FontName, FontHeight, FontFlags = GameTooltipText:GetFont()

   GameTooltipHeaderText:SetFont(fonts[self.Font], self.FontHeight, '')
   GameTooltipText:SetFont(fonts[self.Font], self.FontHeight, '')

   if profile.GetElvUIFontSetting() then
      cTooltipFont(GameTooltipHeaderText)
      cTooltipFont(GameTooltipText)
   end

   if anchor == "cursor" then
      local x, y = GetCursorPosition()
      local scale = UIParent:GetEffectiveScale()
      x = x / scale
      y = y / scale
      self.tooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
      self.tooltip:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
   elseif anchor == nil then
      self.tooltip:SetOwner(UIParent, "ANCHOR_NONE")
      self.tooltip:SetPoint("TOPRIGHT", UIParent, "BOTTOMRIGHT")
   else
      local sw = GetScreenWidth()
      local sh = GetScreenHeight()
      local ax = anchor:GetLeft()
      local ay = anchor:GetBottom()

      local point
      local relativePoint
      if ax < (sw / 2) then
         if ay < (sh / 2) then
            point = "BOTTOMLEFT"
            relativePoint = "TOPLEFT"
         else
            point = "TOPLEFT"
            relativePoint = "BOTTOMLEFT"
         end
      else
         if ay < (sh / 2) then
            point = "BOTTOMRIGHT"
            relativePoint = "TOPRIGHT"
         else
            point = "TOPRIGHT"
            relativePoint = "BOTTOMRIGHT"
         end
      end

      self.tooltip:SetOwner(anchor, "ANCHOR_NONE")
      self.tooltip:SetPoint(point, anchor, relativePoint)
   end
end

function Prototype_Tooltip:Show()
   self.tooltip:Show()
end

function Prototype_Tooltip:Hide()
   self.tooltip:Hide()
   self.tooltip:SetOwner(UIParent, "ANCHOR_NONE")

   GameTooltipHeaderText:SetFont(TooltipHeaderFontName, TooltipHeaderFontHeight, TooltipHeaderFontFlags)
   GameTooltipText:SetFont(FontName, FontHeight, FontFlags)
end

-- TODO: Add ability to mouse over items
-- TODO: Detect size being too big for screen and add scroll ability
