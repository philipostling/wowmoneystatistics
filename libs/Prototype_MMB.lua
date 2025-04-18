-- Private
local function SetPosition(self, x, y)
   if self.IsMinimapLocked == true then
      self:SetPoint("CENTER", Minimap, "CENTER", x, y)
   else
      self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
   end
end

local mmHyp = 80
local function UpdatePosition(self, x, y, persist)
   -- send position data back to client
   if self.OnPositionChange and persist then
      self.OnPositionChange(x, y)
   end

   if self.IsMinimapLocked == true then
      local mmx, mmy = Minimap:GetCenter()
      local rad = math.atan2(y - mmy, x - mmx)

      x = mmHyp * math.cos(rad)
      y = mmHyp * math.sin(rad)
   end

   SetPosition(self, x, y)
end

local function onUpdate(self)
   local x, y = GetCursorPosition()
   local scale = self:GetEffectiveScale()
   x = (x / scale)
   y = (y / scale)
   UpdatePosition(self, x, y, true)
end

local isDragging = false
local function onDragStart(self)
   if not self.IsLocked then
      isDragging = true
      self:LockHighlight()
      self:SetScript("OnUpdate", onUpdate)
   end
end

local function onDragStop(self)
   if not self.IsLocked then
      isDragging = false
      self:UnlockHighlight()
      self:SetScript("OnUpdate", nil)
   end
end

-- Prototype
Prototype_MMB =
{
   HighlightTexture = "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight",
   BorderTexture = "Interface\\Minimap\\MiniMap-TrackingBorder",
   BackgroundTexture = "Interface\\Minimap\\UI-Minimap-Background",
   IconTexture = "Interface\\Icons\\INV_Misc_QuestionMark",
   IsClickable = true,
   IsLocked = true,
   IsMinimapLocked = false,
   IsMinimapHidden = false,
   OnLoad = nil,
   OnEnter = nil,
   OnLeave = nil,
   OnClick = nil,
   OnDragStart = onDragStart,
   OnDragStop = onDragStop,
   OnPositionChange = nil,
}

function Prototype_MMB:new(o)
   o = o or {}
   setmetatable(o, self)
   self.__index = self

   return o
end

function Prototype_MMB:Initialize(name, defaultX, defaultY)
   self.button = CreateFrame("Button", "Prototype_MMB_"..name, Minimap)
   self.button:SetFrameStrata("MEDIUM")
   self.button:SetSize(31, 31)
   self.button:SetFrameLevel(8)
   self.button:SetClampedToScreen(true)
   self.button:SetHighlightTexture(self.HighlightTexture)

   if self.IsClickable then
      self.button:RegisterForClicks("anyUp", "anyDown")
   end

   self.button:RegisterForDrag("LeftButton")

   local overlay = self.button:CreateTexture(nil, "OVERLAY")
   overlay:SetSize(53, 53)
   overlay:SetTexture(self.BorderTexture)
   overlay:SetPoint("TOPLEFT")
   
   local background = self.button:CreateTexture(nil, "BACKGROUND")
   background:SetSize(21, 21)
   background:SetTexture(self.BackgroundTexture)
   background:SetPoint("TOPLEFT", 7, -5)
   
   local icon = self.button:CreateTexture(nil, "ARTWORK")
   icon:SetSize(17, 17)
   icon:SetTexture(self.IconTexture)
   icon:SetPoint("TOPLEFT", 7, -6)
   

   self.button:SetScript("OnLoad", self.OnLoad)
   self.button:SetScript("OnEnter", self.OnEnter)
   self.button:SetScript("OnLeave", self.OnLeave)
   self.button:SetScript("OnClick", self.OnClick)
   self.button:SetScript("OnDragStart", self.OnDragStart)
   self.button:SetScript("OnDragStop", self.OnDragStop)

   self.button.IsClickable = self.IsClickable
   self.button.IsLocked = self.IsLocked
   self.button.IsMinimapLocked = self.IsMinimapLocked
   self.button.IsMinimapHidden = self.IsMinimapHidden
   self.button.OnPositionChange = self.OnPositionChange

   self:SetMinimapHidden(self.button.IsMinimapHidden)
   UpdatePosition(self.button, defaultX, defaultY, false)
end

function Prototype_MMB:SetScript(event, callback)
   self.button:SetScript(event, callback)
end

function Prototype_MMB:SetLock(lock)
   self.button.IsLocked = lock
   self.IsLocked = self.button.IsLocked

   return lock
end

function Prototype_MMB:SetMinimapLock(lock)
   self.button.IsMinimapLocked = lock
   self.IsMinimapLocked = self.button.IsMinimapLocked

   if lock then
      local x, y = self.button:GetCenter()
      UpdatePosition(self.button, x, y, true)
   end

   return lock
end

function Prototype_MMB:SetMinimapHidden(hide)
   self.button.IsMinimapHidden = hide
   self.IsMinimapHidden = self.button.IsMinimapHidden

   if hide then
      self.button:Hide()
   else
      self.button:Show()
   end

   return hide
end

function Prototype_MMB:UpdatePosition(x, y)
   SetPosition(self.button, x, y)
end

function Prototype_MMB:IsDragging()
   return isDragging
end
