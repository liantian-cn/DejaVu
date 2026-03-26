--[[
文件定位:
  DejaVu 德鲁伊职业特色Cell组配置模块, 定义德鲁伊形态相关的Cell布局。



状态:
  draft
]]

-- 插件入口
local addonName, addonTable = ... -- luacheck: ignore addonName addonTable


-- Lua 原生函数
local insert                            = table.insert
local pairs                             = pairs

-- WoW 官方 API
local CreateFramew                      = CreateFrame
local SetOverrideBindingClick           = SetOverrideBindingClick
local UnitClass                         = UnitClass
local GetSpecialization                 = GetSpecialization
-- 专精错误则停止
local className, classFilename, classId = UnitClass("player")
local currentSpec                       = GetSpecialization()
if classFilename ~= "DRUID" then return end
if currentSpec ~= 3 then return end
local logging = addonTable.Logging

local macroList = {}
insert(macroList, { title = "reloadUI", key = "CTRL-F12", text = "/reload" })
insert(macroList, { title = "target月火术", key = "ALT-NUMPAD1", text = "/cast [@target] 月火术" })
insert(macroList, { title = "focus月火术", key = "ALT-NUMPAD2", text = "/cast [@focus] 月火术" })
insert(macroList, { title = "target裂伤", key = "ALT-NUMPAD3", text = "/cast [@target] 裂伤" })
insert(macroList, { title = "focus裂伤", key = "ALT-NUMPAD4", text = "/cast [@focus] 裂伤" })
insert(macroList, { title = "target毁灭", key = "ALT-NUMPAD5", text = "/cast [@target] 毁灭" })
insert(macroList, { title = "focus毁灭", key = "ALT-NUMPAD6", text = "/cast [@focus] 毁灭" })
insert(macroList, { title = "target摧折", key = "ALT-NUMPAD7", text = "/cast [@target] 摧折" })
insert(macroList, { title = "focus摧折", key = "ALT-NUMPAD8", text = "/cast [@focus] 摧折" })
insert(macroList, { title = "target重殴", key = "ALT-NUMPAD9", text = "/cast [@target] 重殴" })
insert(macroList, { title = "focus重殴", key = "ALT-NUMPAD0", text = "/cast [@focus] 重殴" })
insert(macroList, { title = "target赤红之月", key = "SHIFT-NUMPAD1", text = "/cast [@target] 赤红之月" })
insert(macroList, { title = "focus赤红之月", key = "SHIFT-NUMPAD2", text = "/cast [@focus] 赤红之月" })
insert(macroList, { title = "target明月普照", key = "SHIFT-NUMPAD3", text = "/cast [@target] 明月普照" })
insert(macroList, { title = "focus明月普照", key = "SHIFT-NUMPAD4", text = "/cast [@focus] 明月普照" })
insert(macroList, { title = "enemy痛击", key = "SHIFT-NUMPAD5", text = "/cast 痛击" })
insert(macroList, { title = "enemy横扫", key = "SHIFT-NUMPAD6", text = "/cast 横扫" })
insert(macroList, { title = "any切换目标", key = "SHIFT-NUMPAD7", text = "/targetenemy\n/focus\n/targetlasttarget" })
insert(macroList, { title = "player狂暴", key = "SHIFT-NUMPAD8", text = "/cast 狂暴" })
insert(macroList, { title = "player化身：乌索克的守护者", key = "SHIFT-NUMPAD9", text = "/cast 狂暴" })
insert(macroList, { title = "player铁鬃", key = "SHIFT-NUMPAD0", text = "/cast 铁鬃" })
insert(macroList, { title = "player狂暴回复", key = "ALT-F2", text = "/cast 狂暴回复" })
insert(macroList, { title = "player树皮术", key = "ALT-F3", text = "/cast 树皮术" })
insert(macroList, { title = "player生存本能", key = "ALT-F5", text = "/cast 生存本能" })
insert(macroList, { title = "target迎头痛击", key = "ALT-F6", text = "/cast [@target] 迎头痛击" })
insert(macroList, { title = "focus迎头痛击", key = "ALT-F7", text = "/cast [@focus] 迎头痛击" })
insert(macroList, { title = "any熊形态", key = "ALT-F8", text = "/cast [noform:1] 熊形态" })
insert(macroList,
       { title = "nearest裂伤", key = "ALT-F9", text = "/cleartarget \n/targetenemy [noharm][dead][noexists][help] \n/cast [nocombat] 裂伤 \n/stopmacro [channeling] \n/startattack \n/cast [harm]裂伤 \n/targetlasttarget" })
insert(macroList,
       { title = "nearest毁灭", key = "ALT-F10", text = "/cleartarget \n/targetenemy [noharm][dead][noexists][help] \n/cast [nocombat] 毁灭 \n/stopmacro [channeling] \n/startattack \n/cast [harm]毁灭 \n/targetlasttarget" })


for _, macro in pairs(macroList) do --输出2 test2, 6 test3, 4 test1
    local buttonName = addonName .. "Button" .. macro.title
    local frame = CreateFrame("Button", buttonName, UIParent, "SecureActionButtonTemplate")
    frame:SetAttribute("type", "macro")
    frame:SetAttribute("macrotext", macro.text)
    frame:RegisterForClicks("AnyDown", "AnyUp")
    SetOverrideBindingClick(frame, true, macro.key, buttonName)
    logging("RegMacro[" .. macro.title .. "] > " .. macro.key .. " > " .. macro.text)
end
