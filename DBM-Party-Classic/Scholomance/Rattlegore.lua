local mod	= DBM:NewMod("Rattlegore", "DBM-Party-Classic", 13)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20261018212731")
mod:SetCreatureID(11622)
mod:SetEncounterID(--[[ mod:IsClassic() and 2811 or  ]]453)

mod:RegisterCombat("combat")
