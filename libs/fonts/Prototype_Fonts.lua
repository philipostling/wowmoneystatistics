local _, addon = ...

local FontsFolder = "Interface\\AddOns\\WoWMoneyStatistics\\libs\\fonts\\"
addon.fonts = 
{
   ["Arial"] = "Fonts\\ARIALN.TTF",
   ["Friz"] = "Fonts\\FRIZQT__.TTF",
   ["Morpheus"] = "Fonts\\MORPHEUS.ttf",
   ["Skurri"] = "Fonts\\skurri.ttf",
   -- Example font added to fonts folder
   -- Place font file in the FontsFolder
   --  Menu Name                        File Name
   --["PT Sans Narrow"] = FontsFolder.."pt-sans-narrow.ttf",
   Sizes = 
            {
               10,
               12,
               15,
               18,
            }
}
