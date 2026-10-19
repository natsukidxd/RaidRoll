function RR_GetDKPGuildData()

	if RaidRoll_DB["DKP"] == nil then RaidRoll_DB["DKP"] = {} end
-- Setting up default Values
	if RaidRoll_DB["MIN_DKP"] == nil then RaidRoll_DB["MIN_DKP"] = 0 end	-- Min net dkp required to be eligable for loot


	if RR_DKPHasLoaded == true then
		RR_ReallyGetDKPGuildData()
	end
end


function RR_GetDKPCharacterData(character)

-- setup defaults
local Net = 0
local Tot = 0
local Hrs = 0
local AboveThreshold = false


	if RR_DKPHasLoaded == true then

		Net,Tot,Hrs,AboveThreshold = RR_ReallyGetDKPCharacterData(character)

	end
	
	return Net,Tot,Hrs,AboveThreshold
	
end

function RR_DKP_Setup()


	if RR_DKPHasLoaded == true then
		local DKP_Event = CreateFrame("Frame")
	 
		DKP_Event:RegisterEvent("CHAT_MSG_RAID")
		DKP_Event:RegisterEvent("CHAT_MSG_OFFICER")
		DKP_Event:RegisterEvent("CHAT_MSG_GUILD")
		DKP_Event:RegisterEvent("CHAT_MSG_ADDON")
		
		DKP_Event:SetScript("OnEvent", DKP_Event_Function)
	end
end


function DKP_Event_Function(self, event, ...)
	local arg1, arg2, arg3, arg4, arg5, arg6 = ...;
	
	if arg1 ~= nil then
		GuildString = string.lower(arg1)
		
		if string.find(GuildString, "dkp") then 
			if RaidRoll_DB["debug"] == true then RR_Test("DKP String Found, updating guild info") end
			if IsInGuild() then
				RR_GetDKPGuildData()
				GuildRoster();
			end
		end
	end
end
