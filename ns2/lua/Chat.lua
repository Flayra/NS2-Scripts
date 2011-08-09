//=============================================================================
//
// lua/Chat.lua
// 
// Created by Max McGuire (max@unknownworlds.com)
// Copyright 2011, Unknown Worlds Entertainment
//
//=============================================================================

// color, playername, color, message
local chatMessages = { }
local enteringChatMessage = false
local teamOnlyChat = false
// Note: Nothing clears this out but it is probably safe to assume the player won't
// mute enough clients to run out of memory.
local mutedClients = { }

/**
 * Returns true if the user is currently holding down the button to record for
 * voice chat.
 */
function ChatUI_IsVoiceChatActive()
    return Client.IsVoiceRecordingActive()
end

/**
 * Returns true if the passed in client is currently speaking.
 */
function ChatUI_GetIsClientSpeaking(clientIndex)

    // Handle the local client specially.
    local localPlayer = Client.GetLocalPlayer()
    if localPlayer and localPlayer:GetClientIndex() == clientIndex then
        return ChatUI_IsVoiceChatActive()
    end
    
    return Client.GetIsClientSpeaking(clientIndex)

end

function ChatUI_SetClientMuted(muteClientIndex, setMute)

    // Player cannot mute themselves.
    local localPlayer = Client.GetLocalPlayer()
    if localPlayer and localPlayer:GetClientIndex() == muteClientIndex then
        return
    end
    
    local message = BuildMutePlayerMessage(muteClientIndex, setMute)
    Client.SendNetworkMessage("MutePlayer", message, true)
    mutedClients[muteClientIndex] = setMute

end

function ChatUI_GetClientMuted(clientIndex)

    return mutedClients[clientIndex] == true

end

function ChatUI_Encode(msg)
	if (msg) then
		msg = string.gsub(msg, '"', '&#34')
		msg = string.gsub(msg, "'", '&#39')
	end
	return msg
end

function ChatUI_Decode(msg)
	if (msg) then
		msg = string.gsub(msg, '&#34', '"')
		msg = string.gsub(msg, '&#39', "'")
	end
	return msg
end

function ChatUI_GetMessages()

    local uiChatMessages = {}
    
    if(table.maxn(chatMessages) > 0) then
    
        table.copy(chatMessages, uiChatMessages)
        chatMessages = {}
        
    end
        
    return uiChatMessages
    
end

// Return true if we want the UI to take key input for chat
function ChatUI_EnteringChatMessage()
    return enteringChatMessage
end

// Return string prefix to display in front of the chat input
function ChatUI_GetChatMessageType()

    if teamOnlyChat then
        return "Team: "
    end
    
    return "All: "
    
end

// Called when player hits return after entering a chat message. Send it 
// to the server.
function ChatUI_SubmitChatMessageBody(chatMessage)
    
    // Quote string so spacing doesn't come through as multiple arguments
    if chatMessage ~= nil and string.len(chatMessage) > 0 then
    
        Client.ConsoleCommand(ConditionalValue(teamOnlyChat, 'teamsay', 'say') .. ' "' .. ChatUI_Encode(chatMessage) .. '"')

        teamOnlyChat = false
        
    end
    
    enteringChatMessage = false
    
end

// Client should call this when player hits key to enter a chat message
function ChatUI_EnterChatMessage(teamOnly)

    if not enteringChatMessage then
    
        enteringChatMessage = true
        teamOnlyChat = teamOnly
        
    end
    
end

/**
 * This function is called when the client receives a chat message.
 */
function OnCommandChat(teamOnly, playerName, locationId, teamNumber, message)

    local player = Client.GetLocalPlayer()

    if player then
        // color, playername, color, message        
        table.insert(chatMessages, GetColorForTeamNumber(tonumber(teamNumber)))

        // Tack on location name if any
        local locationNameText = ""
        
        // Lookup location name from passed in id
        local locationName = ""
        locationId = tonumber(locationId)
        if locationId ~= 0 then
            locationNameText = string.format("(Team, %s) ", Shared.GetString(locationId))
        end
        
        // Pre-pend "team" or "all"
        local preMessageString = string.format("%s%s: ", ConditionalValue(tonumber(teamOnly) == 1, locationNameText, "(All) "), DecodeStringFromNetwork(playerName), locationNameText)

        table.insert(chatMessages, preMessageString)
        table.insert(chatMessages, kChatTextColor)
        
        table.insert(chatMessages, message)
        
        // reserved for possible texture name
        table.insert(chatMessages, "")
        // texture x
        table.insert(chatMessages, 0)
        // texture y
        table.insert(chatMessages, 0)
        // entity id
        table.insert(chatMessages, 0)
        
        Shared.PlaySound(self, player:GetChatSound())
        
        // Only print to log if the client isn't running a local server
        // which has already printed to log.
        if not Client.GetIsRunningServer() then
            local prefixText = "Chat All"
            if tonumber(teamOnly) == 1 then
                prefixText = "Chat Team " .. tostring(teamNumber)
            end
            Shared.Message(prefixText .. " - " .. DecodeStringFromNetwork(playerName) .. ": " .. ChatUI_Decode(message))
        end
    end
end

Event.Hook("Console_chat", OnCommandChat)