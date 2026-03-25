local addonName, addonTable = ... -- luacheck: ignore addonName

-- WoW 官方 API
local CreateColorCurve = C_CurveUtil.CreateColorCurve
local Enum = Enum

-- 插件内引用
local COLOR = addonTable.COLOR

-- `05_slots` 模块命名空间
addonTable.Slots = {}


local remainingCurve = CreateColorCurve()
remainingCurve:SetType(Enum.LuaCurveType.Linear)
remainingCurve:AddPoint(0.0, COLOR.C0)
remainingCurve:AddPoint(5.0, COLOR.C100)
remainingCurve:AddPoint(30.0, COLOR.C150)
remainingCurve:AddPoint(155.0, COLOR.C200)
remainingCurve:AddPoint(375.0, COLOR.C255)


local debuffOnFriendlyCurve = CreateColorCurve()
debuffOnFriendlyCurve:AddPoint(0, COLOR.SPELL_TYPE.DEBUFF_ON_FRIENDLY)
debuffOnFriendlyCurve:AddPoint(1, COLOR.SPELL_TYPE.MAGIC)
debuffOnFriendlyCurve:AddPoint(2, COLOR.SPELL_TYPE.CURSE)
debuffOnFriendlyCurve:AddPoint(3, COLOR.SPELL_TYPE.DISEASE)
debuffOnFriendlyCurve:AddPoint(4, COLOR.SPELL_TYPE.POISON)
debuffOnFriendlyCurve:AddPoint(9, COLOR.SPELL_TYPE.ENRAGE)
debuffOnFriendlyCurve:AddPoint(11, COLOR.SPELL_TYPE.BLEED)


local buffOnFriendlyCurve = CreateColorCurve()
buffOnFriendlyCurve:AddPoint(0, COLOR.SPELL_TYPE.BUFF_ON_FRIENDLY)
buffOnFriendlyCurve:AddPoint(1, COLOR.SPELL_TYPE.MAGIC)
buffOnFriendlyCurve:AddPoint(2, COLOR.SPELL_TYPE.CURSE)
buffOnFriendlyCurve:AddPoint(3, COLOR.SPELL_TYPE.DISEASE)
buffOnFriendlyCurve:AddPoint(4, COLOR.SPELL_TYPE.POISON)
buffOnFriendlyCurve:AddPoint(9, COLOR.SPELL_TYPE.ENRAGE)
buffOnFriendlyCurve:AddPoint(11, COLOR.SPELL_TYPE.BLEED)



local debuffOnEnemyCurve = CreateColorCurve()
debuffOnEnemyCurve:AddPoint(0, COLOR.SPELL_TYPE.DEBUFF_ON_ENEMY)
debuffOnEnemyCurve:AddPoint(1, COLOR.SPELL_TYPE.MAGIC)
debuffOnEnemyCurve:AddPoint(2, COLOR.SPELL_TYPE.CURSE)
debuffOnEnemyCurve:AddPoint(3, COLOR.SPELL_TYPE.DISEASE)
debuffOnEnemyCurve:AddPoint(4, COLOR.SPELL_TYPE.POISON)
debuffOnEnemyCurve:AddPoint(9, COLOR.SPELL_TYPE.ENRAGE)
debuffOnEnemyCurve:AddPoint(11, COLOR.SPELL_TYPE.BLEED)

local zeroToOneCurve = CreateColorCurve()
zeroToOneCurve:SetType(Enum.LuaCurveType.Linear)
zeroToOneCurve:AddPoint(0.0, CreateColor(0, 0, 0, 1))
zeroToOneCurve:AddPoint(1.0, CreateColor(1, 1, 1, 1))



addonTable.Slots.remainingCurve = remainingCurve
addonTable.Slots.debuffOnFriendlyCurve = debuffOnFriendlyCurve
addonTable.Slots.buffOnFriendlyCurve = buffOnFriendlyCurve
addonTable.Slots.debuffOnEnemyCurve = debuffOnEnemyCurve
addonTable.Slots.zeroToOneCurve = zeroToOneCurve
