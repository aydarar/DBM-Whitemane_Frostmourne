local mod	= DBM:NewMod("Ymiron", "DBM-Party-WotLK", 11)
local L		= mod:GetLocalizedStrings()

mod.statTypes = "normal,heroic,mythic"

mod:SetRevision("20261018212731")
mod:SetCreatureID(26861)
mod:SetEncounterID(583)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_SUCCESS 51750",
	"SPELL_AURA_APPLIED 48294 59301",
	"SPELL_AURA_REMOVED 48294 59301"
)

local warningBane		= mod:NewSpellAnnounce(48294, 3)
local warningScreams	= mod:NewSpellAnnounce(51750, 2)

local timerBane			= mod:NewBuffActiveTimer(5, 48294, nil, nil, nil, 5, nil, DBM_COMMON_L.MAGIC_ICON)
local timerScreams		= mod:NewBuffActiveTimer(8, 51750, nil, nil, nil, 2)
-- Frostmourne logs 2026-10-07 and 10-11 (heroic): first Screams 10.8 / 11.4, then every 14.7-20.0
local timerScreamsCD	= mod:NewCDTimer(14.5, 51750, nil, nil, nil, 2)

function mod:OnCombatStart(delay)
	if self:IsDifficulty("heroic5") then
		timerScreamsCD:Start(10.5 - delay)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args.spellId == 51750 then
		warningScreams:Show()
		timerScreams:Start()
		if self:IsDifficulty("heroic5") then
			timerScreamsCD:Start()
		end
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(48294, 59301) then
		warningBane:Show()
		timerBane:Start()
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args:IsSpellID(48294, 59301) then
		timerBane:Stop()
	end
end
