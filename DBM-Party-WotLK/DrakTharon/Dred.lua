local mod	= DBM:NewMod("KingDred", "DBM-Party-WotLK", 4)
local L		= mod:GetLocalizedStrings()

mod.statTypes = "normal,heroic,mythic"

mod:SetRevision("20261018212731")
mod:SetCreatureID(27483)
mod:SetEncounterID(373)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 22686",
	"SPELL_CAST_SUCCESS 59422",
	"SPELL_AURA_APPLIED 48920 48873 48878"
)

local warningSlash	= mod:NewSpellAnnounce(48873, 3)
local warningBite	= mod:NewTargetNoFilterAnnounce(48920, 2, nil, "Healer")
local warningFear	= mod:NewSpellAnnounce(22686, 1)

local timerFearCD	= mod:NewCDTimer(15, 22686, nil, nil, nil, 2)  -- cooldown ??
local timerSlash	= mod:NewTargetTimer(10, 48873)
local timerSlashCD	= mod:NewCDTimer(18, 48873, nil, "Tank|Healer", nil, 5)
-- Fearsome Roar (heroic), Frostmourne logs 2026-10-11 and 10-15: 20.7 / 21.0 after the pull, then 18.0-23.4
local warningFearsome	= mod:NewSpellAnnounce(59422, 2)
local timerFearsomeCD	= mod:NewCDTimer(18, 59422, nil, nil, nil, 2)

function mod:OnCombatStart(delay)
	if self:IsDifficulty("heroic5") then
		timerFearsomeCD:Start(20.5 - delay)
	end
end

-- Bellowing Roar is a cast (logged as SPELL_CAST_START); the old sourceGUID == 27483 check compared a GUID with a creature ID and never matched
function mod:SPELL_CAST_START(args)
	if args.spellId == 22686 and self:GetCIDFromGUID(args.sourceGUID) == 27483 then
		warningFear:Show()
		timerFearCD:Start()
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args.spellId == 59422 then
		warningFearsome:Show()
		timerFearsomeCD:Start()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args.spellId == 48920 then
		warningBite:Show(args.destName)
	elseif args.spellId == 48873 then
		warningSlash:Show()
		timerSlash:Start(15, args.destName)
		timerSlashCD:Start()
	elseif args.spellId == 48878 then
		warningSlash:Show()
		timerSlash:Start(10, args.destName)
		timerSlashCD:Start()
	end
end
