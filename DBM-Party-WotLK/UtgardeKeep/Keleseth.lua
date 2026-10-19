local mod	= DBM:NewMod("Keleseth", "DBM-Party-WotLK", 10)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20261018212731")
mod:SetCreatureID(23953)
mod:SetEncounterID(571)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED 48400",
	"SPELL_AURA_REMOVED 48400"
)

local warningTomb	= mod:NewTargetNoFilterAnnounce(48400, 4)

local timerTomb		= mod:NewTargetTimer(10, 48400, nil, nil, nil, 3)
local timerTombCD	= mod:NewCDTimer(17, 48400, nil, nil, nil, 3)

function mod:OnCombatStart()
	timerTombCD:Start(self:IsDifficulty("heroic5") and 29 or 17) -- Frostmourne logs (3 pulls): first Frost Tomb 29.0-30.5, then every 15
end

function mod:SPELL_AURA_APPLIED(args)
	if args.spellId == 48400 then
		warningTomb:Show(args.destName)
		timerTomb:Start(args.destName)
		timerTombCD:Start(self:IsDifficulty("heroic5") and 15 or nil)
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args.spellId == 48400 then
		timerTomb:Cancel()
	end
end
