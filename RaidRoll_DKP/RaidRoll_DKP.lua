RR_DKPHasLoaded = true

--------------------------------------------------------------------------
-- Personal (external) DKP supplied by the QDKP whisper bot.
--
-- The QDKP bot whispers the player in several formats. All of them carry
-- the player's current net DKP, which we capture, store per-character and
-- feed back into the Raid Roll DKP UI so a player who is NOT a member of
-- the guild can still see and use their DKP (the guild officer-note
-- lookup only works for actual guild members).
--
-- Supported whisper formats:
--   * "You have <N> DKP (...)"                 -> reply to ?dkp (self)
--   * "<Name> has <N> DKP (...)"               -> reply to ?dkp <Name>
--   * "<Award text>. Your new net DKP amount is <N>"              -> guild award/spend
--   * "<Award text> for <Reason>. Your new net DKP amount is <N>" -> item purchase
--   * "Your unuploaded changes have been cancelled. Your net DKP amount is <N>" -> cancelled
--------------------------------------------------------------------------

-- Returns the stored personal QDKP amount for the current character, or nil.
function RR_GetPersonalQDKP()
	if RaidRoll_DBPC == nil then return nil end
	local p = RaidRoll_DBPC[UnitName("player")]
	if p == nil then return nil end
	return p["RR_DKP_Personal"]
end

-- Stores the personal QDKP amount for the current character.
function RR_SetPersonalQDKP(amount)
	if RaidRoll_DBPC == nil then RaidRoll_DBPC = {} end
	if RaidRoll_DBPC[UnitName("player")] == nil then RaidRoll_DBPC[UnitName("player")] = {} end
	if amount == nil then amount = 0 end
	RaidRoll_DBPC[UnitName("player")]["RR_DKP_Personal"] = tonumber(amount)
end

-- Called once the QDKP whisper reply has been parsed. Turns on DKP mode,
-- stores the amount and refreshes the roll window (including any bids that
-- were already recorded before the reply arrived).
function RR_EnableDKPFromQDKP()
	local net = RR_GetPersonalQDKP()
	if net == nil then return end

	-- 1) Turn on DKP mode.
	if RaidRoll_DBPC == nil then RaidRoll_DBPC = {} end
	if RaidRoll_DBPC[UnitName("player")] == nil then RaidRoll_DBPC[UnitName("player")] = {} end
	RaidRoll_DBPC[UnitName("player")]["RR_DKP_Enabled"] = true
	if RR_RollCheckBox_DKPMode_panel ~= nil and RR_RollCheckBox_DKPMode_panel.SetChecked ~= nil then
		RR_RollCheckBox_DKPMode_panel:SetChecked(true)
	end

	-- 2) Refresh the Net DKP value for the player's own row in the current
	--    roll window (in case a bid was recorded before the reply arrived).
	if rr_CurrentRollID ~= nil and RR_DKPValue ~= nil and RR_DKPValue[rr_CurrentRollID] ~= nil and RollerName ~= nil and RollerName[rr_CurrentRollID] ~= nil then
		local playerKey = strlower(UnitName("player") or "")
		if playerKey ~= "" then
			for i = 1, #RollerName[rr_CurrentRollID] do
				local nm = RollerName[rr_CurrentRollID][i]
				if nm ~= nil and strlower(nm) == playerKey then
					RR_DKPValue[rr_CurrentRollID][i] = net
					if RR_DKPAboveThreshold ~= nil and RR_DKPAboveThreshold[rr_CurrentRollID] ~= nil then
						local min = 0
						if RaidRoll_DB ~= nil and RaidRoll_DB["MIN_DKP"] ~= nil then min = RaidRoll_DB["MIN_DKP"] end
						RR_DKPAboveThreshold[rr_CurrentRollID][i] = (net >= min)
					end
					break
				end
			end
		end
	end

	-- 3) Refresh the frames.
	if type(RaidRoll_CheckButton_Update_Panel) == "function" then
		RaidRoll_CheckButton_Update_Panel()
	end
	if type(RR_Display) == "function" then
		RR_Display(rr_CurrentRollID)
	end

	if RaidRoll_DB ~= nil and RaidRoll_DB["debug"] == true then
		RR_Test("QDKP personal value set to " .. net .. " and DKP mode enabled")
	end
end

-- Whisper listener for the QDKP bot replies.
-- Only the player's own DKP is ever stored. Replies about other players
-- ("$NAME has $NET DKP ...") are ignored and never written to saved variables.
local qdkpFrame = CreateFrame("Frame")
qdkpFrame:RegisterEvent("CHAT_MSG_WHISPER")
qdkpFrame:SetScript("OnEvent", function(self, event, msg, sender)
	if msg == nil then return end
	local lower = strlower(msg)

	-- Ignore replies about other players: "$NAME has $NET DKP (...)".
	-- The addon must never store another player's DKP.
	if strmatch(lower, "^%s*%S+%s+has%s+%d+%s+dkp") then
		return
	end

	-- 1) Self query: "You have $NET DKP ($SESSGAINED gained and $SESSSPENT spent in this session)."
	local amount = strmatch(lower, "you have%s*(%d+)")
	if amount ~= nil then
		RR_SetPersonalQDKP(tonumber(amount))
		RR_EnableDKPFromQDKP()
		return
	end

	-- 2) Successful bid / raid wipe:
	--    "$AWARDSPENDTXT. Your new net DKP amount is $NET"
	--    "$AWARDSPENDTXT for $REASON. Your new net DKP amount is $NET"
	amount = strmatch(lower, "your new net dkp amount is%s*(%d+)")
	if amount ~= nil then
		RR_SetPersonalQDKP(tonumber(amount))
		RR_EnableDKPFromQDKP()
		return
	end

	-- 3) Officer cancelled changes:
	--    "Your unuploaded changes have been cancelled. Your net DKP amount is $AMOUNT"
	amount = strmatch(lower, "your net dkp amount is%s*(%d+)")
	if amount ~= nil then
		RR_SetPersonalQDKP(tonumber(amount))
		RR_EnableDKPFromQDKP()
		return
	end
end)

function RR_ReallyGetDKPGuildData()
	if IsInGuild() then
		RR_GuildInfo = GetGuildInfoText();

		--[[
		-DKP-
		@MIN_DKP:0
		-DKP-
		]]

		local string_start, string_end = string.find(RR_GuildInfo, "%-DKP%-");
		if string_start ~= nil and string_end ~= nil then
			RR_GuildInfo = string.sub(RR_GuildInfo, string_end + 2)

			string_start, string_end = string.find(RR_GuildInfo, "%-DKP%-");
			if string_start ~= nil then
				RR_GuildInfo = string.sub(RR_GuildInfo, 1, string_start - 2)

				for i = 1, 10 do
					if RR_GuildInfo ~= nil then
						string_start, string_end = string.find(RR_GuildInfo, "%@+%a+%_%a+%:%d+");
						if string_start ~= nil then
							Substring = string.sub(RR_GuildInfo, string_start, string_end);
							RR_GuildInfo = string.sub(RR_GuildInfo, string_end + 2);
							if RaidRoll_DB["debug"] == true then RR_Test("Leftover String: " .. RR_GuildInfo) end

							string_start, string_end = string.find(Substring, "%@+%a+%_%a+%:");
							Type = string.upper(string.sub(Substring, string_start + 1, string_end - 1))
							if RaidRoll_DB["debug"] == true then RR_Test("Type: " .. Type) end

							string_start, string_end = string.find(Substring, "%:%d+");
							Value = tonumber(string.sub(Substring, string_start + 1, string_end));
							if RaidRoll_DB["debug"] == true then RR_Test("Value: " .. Value) end

							RaidRoll_DB[Type] = Value;
						end
					end
				end
			end
		end
	end
end

-- Parses officer note in format "Net:50 Tot:50 Hrs:0"
-- Returns net, tot, hrs. Returns nil,nil,nil if not in that format.
function RR_ParseDKPOfficerNote(officernote)
	if officernote == nil then return nil, nil, nil end

	officernote = strtrim(officernote)

	local net = nil
	local tot = nil
	local hrs = nil

	-- Match Net:XX Tot:XX Hrs:XX (case-insensitive, order-insensitive)
	local NetString = string.match(officernote, "[Nn]et[:：]%s*(%d+)")
	local TotString = string.match(officernote, "[Tt]ot[:：]%s*(%d+)")
	local HrsString = string.match(officernote, "[Hh]rs[:：]%s*(%d+)")

	if NetString ~= nil then net = tonumber(NetString) end
	if TotString ~= nil then tot = tonumber(TotString) end
	if HrsString ~= nil then hrs = tonumber(HrsString) end

	-- Must have at least a Net value to be valid DKP data
	if net ~= nil then
		if tot == nil then tot = net end
		if hrs == nil then hrs = 0 end
		return net, tot, hrs
	end

	return nil, nil, nil
end

function RR_ReallyGetDKPCharacterData(character)
	-- setup defaults
	local Net = 0
	local Tot = 0
	local Hrs = 0
	local AboveThreshold = false

	-- Personal QDKP override: if the QDKP bot has reported this character's DKP
	-- (via a "?dkp" whisper) use that value. This lets non-guild members see
	-- and use their DKP even though they have no guild officer note.
	if character ~= nil and UnitName("player") ~= nil and strlower(character) == strlower(UnitName("player")) then
		local personal = RR_GetPersonalQDKP()
		if personal ~= nil then
			Net = personal
			Tot = personal
			Hrs = 0
			if RaidRoll_DB == nil then RaidRoll_DB = {} end
			if RaidRoll_DB["MIN_DKP"] == nil then RaidRoll_DB["MIN_DKP"] = 0 end
			if Net >= RaidRoll_DB["MIN_DKP"] then AboveThreshold = true end
			return Net, Tot, Hrs, AboveThreshold
		end
	end

	if IsInGuild() then
		RR_GetDKPGuildData()
		if character ~= nil then
			character = string.lower(character)

			local playerNote = nil
			local mainName = nil

			for i = 1, GetNumGuildMembers() do
				local name, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName = GetGuildRosterInfo(i);

				name = string.lower(name)

				if character == name then
					playerNote = officernote
					break
				end
			end

			if playerNote ~= nil then
				playerNote = strtrim(playerNote)

				-- Check if the note is in the "Net:50 Tot:50 Hrs:0" format
				local pNet, pTot, pHrs = RR_ParseDKPOfficerNote(playerNote)

				if pNet ~= nil then
					-- Direct DKP data
					Net = pNet
					Tot = pTot
					Hrs = pHrs
				else
					-- Alt detection: the note contains the main character's name
					mainName = playerNote
					if RaidRoll_DB["debug"] == true then RR_Test(character .. " is an alt, main is: " .. mainName) end

					SetGuildRosterShowOffline(true)

					for j = 1, GetNumGuildMembers() do
						local name2, rank2, rankIndex2, level2, class2, zone2, note2, officernote2, online2, status2, classFileName2 = GetGuildRosterInfo(j);

						if strlower(mainName) == strlower(name2) then
							officernote2 = strtrim(officernote2)
							local mNet, mTot, mHrs = RR_ParseDKPOfficerNote(officernote2)

							if mNet ~= nil then
								Net = mNet
								Tot = mTot
								Hrs = mHrs
							end
							break
						end
					end
				end
			end

			-- Threshold check
			if RaidRoll_DB["MIN_DKP"] == nil then RaidRoll_DB["MIN_DKP"] = 0 end
			if Net >= RaidRoll_DB["MIN_DKP"] then AboveThreshold = true end

			if RaidRoll_DB["debug"] == true then RR_Test(character .. ": Net=" .. Net .. " Tot=" .. Tot .. " Hrs=" .. Hrs) end
		end
	end

	return Net, Tot, Hrs, AboveThreshold
end