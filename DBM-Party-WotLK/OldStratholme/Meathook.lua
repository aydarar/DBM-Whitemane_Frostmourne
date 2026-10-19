local mod	= DBM:NewMod("Meathook", "DBM-Party-WotLK", 3)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20261018212731")
mod:SetCreatureID(26529)
mod:SetEncounterID(293)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_SUCCESS 52696 58823"
)

local warningChains		= mod:NewTargetNoFilterAnnounce(52696, 4)

local timerChains		= mod:NewTargetTimer(5, 52696, nil, nil, nil, 3)
local timerChainsCD		= mod:NewCDTimer(15, 52696, nil, nil, nil, 3)

function mod:OnCombatStart(delay)
	if self:IsDifficulty("heroic5") then
		timerChainsCD:Start(6 - delay) -- Frostmourne log 2026-10-15: first Constricting Chains at 6.0
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpellID(52696, 58823) then
		warningChains:Show(args.destName)
		timerChains:Start(args.destName)
		timerChainsCD:Start(self:IsDifficulty("heroic5") and 11 or nil) -- Frostmourne logs: 10.9-13.5 between casts (was 15)
	end
end
