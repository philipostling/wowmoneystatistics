local _, addon = ...
-- Private
local xOffset, yOffset
local fonts = addon.fonts
local FontStringList = {}

local function SetPosition(self, x, y)
   self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
end

local function UpdatePosition(self, x, y, persist)
   -- send position data back to client
   if self.OnPositionChange and persist then
      self.OnPositionChange(x, y)
   end

   SetPosition(self, x, y)
end

local function onUpdate(self)
   local x, y = GetCursorPosition()
   local scale = self:GetEffectiveScale()
   x = (x / scale) - xOffset
   y = (y / scale) - yOffset

   UpdatePosition(self:GetParent(), x, y, true)
end

local isDragging = false
local function onDragStart(self)
   isDragging = true
   local parent = self:GetParent()
   local x, y = GetCursorPosition()
   local px, py = parent:GetCenter()
   local scale = parent:GetEffectiveScale()
   xOffset = (x / scale) - px
   yOffset = (y / scale) - py
   self:SetScript("OnUpdate", onUpdate)
end

local function onDragStop(self)
   isDragging = false
   self:SetScript("OnUpdate", nil)
end

local function onClose(self)
   IsShown = false
   self:GetParent():Hide()
end

local function OnHideEditBox(self)
   self:SetText("");
end

local function OnEscapePressedEditBox(self)
   self:ClearFocus();
end

local function OnEditFocusLost(self)
   self:HighlightText(0, 0);
end

local function OnEditFocusGained(self)
   self:HighlightText();
end

-- Prototype
Prototype_Dialog =
{
   BackgroundTexture = "Interface\\DialogFrame\\UI-DialogBox-Background",
   BorderTexture = "Interface\\DialogFrame\\UI-DialogBox-Border",
   BorderSize = 16,
   HeaderTexture = "Interface\\DialogFrame\\UI-DialogBox-Header",
   TileSize = 32,
   Font = "Friz",
   FontHeight = 12,
   Title = "",
   OnLoad = nil,
   OnDragStart = onDragStart,
   OnDragStop = onDragStop,
   OnClick = nil,
   OnPositionChange = nil,
   IsMovable = true,
   FrameStrata = "DIALOG",
}

local borderWidth = 0
function Prototype_Dialog:new(o)
   o = o or {}
   setmetatable(o, self)
   self.__index = self

   o.frame = CreateFrame("Frame", "Prototype_Dialog__Frame", UIParent, "BackdropTemplate")
   o.frame:SetBackdrop( {
                           bgFile = o.BackgroundTexture,
                           edgeFile = o.BorderTexture,
                           edgeSize = o.BorderSize,
                           tileSize = o.TileSize,
                           insets = { left= 5, right = 5, top = 5, bottom = 5 }
                        })

   o.frame:SetFrameStrata(o.FrameStrata)
   o.frame:SetClampedToScreen(true)
   o.frame:SetSize(450, 600)
   o.frame:SetPoint("CENTER")
   o.frame.OnPositionChange = o.OnPositionChange

   o.isShown = false

local IsAddOnLoaded = C_AddOns.IsAddOnLoaded or IsAddOnLoaded;
   if IsAddOnLoaded("ElvUI") then
      o.frame:StripTextures()
      o.frame:SetTemplate("Default")
   end

   if o.IsMovable then
      local headerYOffset = 20
      if o.HeaderTexture == nil then
         headerYOffset = 0
      end

      o.header = CreateFrame("Frame", "Prototype_Dialog__Frame_Header", o.frame, "BackdropTemplate")
      if IsAddOnLoaded("ElvUI") then
         o.header:StripTextures()
         o.header:SetTemplate("Transparent")
      else
         borderWidth = 5
      end
      o.header:SetPoint("TOPLEFT", borderWidth, -borderWidth)
      o.header:SetSize(450 - (borderWidth * 2), 20)

      o:AddHeaderString("Title", o.Title, "OVERLAY")
      o.headerString:SetSize(150, 40)
      o.headerString:SetPoint("CENTER", o.header)

      o.dragButton = CreateFrame("Button", "Prototype_Dialog__DragButton", o.frame)
      o.dragButton:EnableMouse(true)
      o.dragButton:SetMovable(true)

      o.dragButton:SetSize(450, 20)
      o.dragButton:SetPoint("TOP", 0, 0)

      o.dragButton:RegisterForClicks("LeftButtonDown")
      if o.IsMovable then
         o.dragButton:RegisterForDrag("LeftButton")
      end
      o.dragButton:SetScript("OnDragStart", o.OnDragStart)
      o.dragButton:SetScript("OnDragStop", o.OnDragStop)
      o.dragButton:SetScript("OnClick", o.OnClick)
      o.dragButton:Show()
   end

   return o
end

function Prototype_Dialog:SetSize(w, h)
   self.frame:SetSize(w, h)

   if self.IsMovable then
      self.header:SetWidth(w - borderWidth)
      self.dragButton:SetWidth(w - borderWidth)
   end
end

function Prototype_Dialog:Show()
   self.isShown = true
   self.frame:Show()
end

function Prototype_Dialog:Hide()
   self.isShown = false
   self.frame:Hide()
end

function Prototype_Dialog:Toggle()
   if self.isShown then
      self:Hide()
   else
      self:Show()
   end
end

function Prototype_Dialog:IsShown()
   return self.isShown
end

function Prototype_Dialog:SetPosition(x, y)
   SetPosition(self.frame, x, y)
end

function Prototype_Dialog:SetFont(font)
   self.Font = font

   for _, v in pairs(FontStringList) do
      local test = v:SetFont(fonts[self.Font], self.FontHeight, nil)
   end
end

function Prototype_Dialog:SetFontSize(size)
   self.FontHeight = size

   for _, v in pairs(FontStringList) do
      v:SetFont(fonts[self.Font], self.FontHeight, nil)
   end
end

function Prototype_Dialog:SetScript(event, callback)
   self.frame:SetScript(event, callback)
end

function Prototype_Dialog:UpdatePosition(x, y)
   SetPosition(self.frame, x, y)
end

function Prototype_Dialog:IsDragging()
   return isDragging
end

function Prototype_Dialog:AddEditBox(name, w, h, maxLetters)
   local editBox = CreateFrame("EditBox", name, self.frame, "InputBoxTemplate")
   editBox:SetWidth(w)
   editBox:SetHeight(h)
   editBox:SetAutoFocus(false)
   editBox:SetMultiLine(false)
   editBox:SetMaxLetters(maxLetters)

local IsAddOnLoaded = C_AddOns.IsAddOnLoaded or IsAddOnLoaded;
   if IsAddOnLoaded("ElvUI") then
      cSkinEditBox(editBox)
   end
   editBox:SetScript("OnHide", OnHideEditBox)
   editBox:SetScript("OnEscapePressed", OnEscapePressedEditBox)
   editBox:SetScript("OnEditFocusLost", OnEditFocusLost)
   editBox:SetScript("OnEditFocusGained", OnEditFocusGained)

   return editBox
end

function Prototype_Dialog:AddHeaderString(name, text, layer)
   if not self.headerString then
      self.headerString = self.header:CreateFontString("Prototype_Dialog__Frame_"..name, layer)
   end

   self.headerString:SetTextColor(1, 1, 1, 1)
   self.headerString:SetFont(fonts["Friz"], 10, nil)
   self.headerString:SetText(text)
end 

function Prototype_Dialog:AddFontString(name, text, layer, w, h)
   local fs = self.frame:CreateFontString("Prototype_Dialog__Frame_"..name, layer)
   fs:SetTextColor(1, 1, 1, 1)
   fs:SetFont(fonts[self.Font], self.FontHeight, nil)
   fs:SetText(text)

   if w ~= nil then
      fs:SetWidth(w)
   end

   if h ~= nil then
      fs:SetHeight(h)
   end

   FontStringList[#FontStringList + 1] = fs

   return fs
end 

function Prototype_Dialog:AddCloseButton(name, text, w, h)
   local button = CreateFrame("Button", name, self.header, "UIPanelCloseButton")
   button:SetText(text)
   button:SetSize(w, h)
   button:SetPoint("BOTTOMRIGHT", self.header, "BOTTOMRIGHT", 0, -5)
   button:RegisterForClicks("LeftButtonUp")
   button:Show()

local IsAddOnLoaded = C_AddOns.IsAddOnLoaded or IsAddOnLoaded;
   if IsAddOnLoaded("ElvUI") then
      cSkinCloseButton(button)
      button:SetSize(30, 30)
   end

   return button
end

function Prototype_Dialog:AddButton(name, text, w, h, inherits)
   if not inherits then
      inherits = "UIPanelButtonTemplate"
   end
   local button = CreateFrame("Button", name, self.frame, inherits)
   button:SetText(text)
   button:SetSize(w, h)
   button:RegisterForClicks("LeftButtonDown")
   button:Show()

local IsAddOnLoaded = C_AddOns.IsAddOnLoaded or IsAddOnLoaded;
   if IsAddOnLoaded("ElvUI") and inherits == "UIPanelButtonTemplate" then
      cSkinButton(button)
   end

   return button
end
