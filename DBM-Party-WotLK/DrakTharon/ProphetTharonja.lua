local mod	= DBM:NewMod("ProphetTharonja", "DBM-Party-WotLK", 4)
local L		= mod:GetLocalizedStrings()

mod.statTypes = "normal,heroic,mythic"

mod:SetRevision("20261018212731")
mod:SetCreatureID(26632)
mod:SetEncounterID(375)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_SUCCESS 49548 59969",
	"SPELL_AURA_APPLIED 49356",
	"UNIT_HEALTH"
)

local warningDecayFleshSoon		= mod:NewSoonAnnounce(49356, 2)
local warningCloud				= mod:NewSpellAnnounce(49548, 3)
local warningFleshSoon			= mod:NewSoonAnnounce(49356, 3)
local warningFlesh				= mod:NewSpellAnnounce(49356, 3)
-- Frostmourne logs 2026-10-11 and 10-15: Decay Flesh at 50% health, Return Flesh 23.2 / 23.3 later
local timerBonePhase			= mod:NewBuffActiveTimer(23.2, 49356, nil, nil, nil, 6)

mod.vb.warnedDecay = false

function mod:OnCombatStart()
	self.vb.warnedDecay = false
end

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpellID(49548, 59969) then
		warningCloud:Show()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args.spellId == 49356 and self:AntiSpam(1) then
		warningFleshSoon:Show()
		warningFlesh:Schedule(5)
		timerBonePhase:Start()
	end
end

function mod:UNIT_HEALTH(uId)
	if not self.vb.warnedDecay and self:GetUnitCreatureId(uId) == 26632 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.58 then
		self.vb.warnedDecay = true
		warningDecayFleshSoon:Show()
	end
end
