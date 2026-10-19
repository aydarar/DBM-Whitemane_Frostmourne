local mod	= DBM:NewMod("InstructorMalicia", "DBM-Party-Classic", 13)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20261018212731")
mod:SetCreatureID(10505)
mod:SetEncounterID(--[[ mod:IsClassic() and 2803 or  ]]457)

mod:RegisterCombat("combat")
