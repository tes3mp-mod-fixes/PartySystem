-- basic setup
--PlayerActivationApi = require("custom.playerActivateAPI")

PartySystem = {}
PartySystem.scriptName = "PartySystem"
PartySystem.defaultConfig = require("custom.PartySystem.defaultConfig")

PartySystem.config = DataManager.loadConfiguration(PartySystem.scriptName, PartySystem.defaultConfig)
tableHelper.fixNumericalKeys(PartySystem.config)

PartySystem.defaultData = {
    parties = {},
    players = {}
}

local invites = {}
local GetChatName = logicHandler.GetChatName

local function quickLog(msg)
    tes3mp.LogMessage(enumerations.log.INFO, msg)
end

local function setPlayerParty(name, value)
    if value ~= nil then
        PartySystem.data.players[name] = tostring(value)
    else
        PartySystem.data.players[name] = value
    end
end

local function getPlayerParty(name)
    return tostring(PartySystem.data.players[name])
end

function PartySystem.loadData()
    PartySystem.data = DataManager.loadData(PartySystem.scriptName, PartySystem.defaultData)
end

function PartySystem.saveData()
    DataManager.saveData(PartySystem.scriptName, PartySystem.data)
end

function PartySystem.partyExists(partyId)
    return partyId ~= nil and PartySystem.data.parties[partyId] ~= nil
end

function PartySystem.removeLonelyParty(partyId)
    local party = PartySystem.data.parties[partyId]
    if party ~= nill and #party.members == 1 and #invites[partyId] == 0 then
        setPlayerParty(party.members[1], nil)
        PartySystem.data.parties[partyId] = nil
        invites[partyId] = nil
    end
end

function PartySystem.createParty(pid)
    if Players[pid] ~=nil and Players[pid]:IsLoggedIn() then
        leaderpid = tonumber(pid)

        -- if this player is already in a party, just return that pid
        local partyId = PartySystem.getPartyId(pid)
        if partyId ~= nil then
            return partyId
        end
        
        partyId = tostring(#PartySystem.data.parties)

        local name = Players[pid].name
        local defaultPartyName = name .. "'s party"
        
        PartySystem.data.parties[partyId] = {
            name = defaultPartyName,
            id = partyId,
            leader = name,
            members = {name}
        }
        setPlayerParty(name, partyId)
        tes3mp.SendMessage(pid, color.Default .. "Party " .. party.name .. " has been created.\n", false)
        return partyId
    end
    return nil
end

function PartySystem.addMember(partyId, pid)
    pid = tonumber(pid)
    if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
        local name = Players[pid].name
        local party = PartySystem.data.parties[partyId]
        if party ~= nil and tableHelper.containsValue(party.members, name) == false then
            local otherPartyId = PartySystem.getPartyId(pid)
            if otherPartyId ~= nil then
                PartySystem.removeMember(otherPartyId, pid)
            end
            if PartySystem.config.allowNamedParties then
                PartySystem.messageParty(partyId,color.Default .. tostring(name) .. " has joined " .. party.name .. ".")
            else
                PartySystem.messageParty(partyId, color.Default .. tostring(name) .. " has joined the party.")
            end
            table.insert(party.members, name)
            setPlayerParty(name, partyId)
            if PartySystem.config.allowNamedParties then
                tes3mp.SendMessage(pid, color.Default .. "You've joined " .. party.name .. ".\n", false)
            else
                tes3mp.SendMessage(pid, color.Default .. "You've joined a party.\n", false)
            end

            return
        end
        --quickLog("Attempt to add " .. tostring(name) .. " to party " .. tostring(partyId) .. " failed")
    end
end

function PartySystem.isInvited(partyId, pid)
    pid = tonumber(pid)
    if Players[pid] == nil or Players[pid]:IsLoggedIn() == false then
        return false 
    end
    local name = Players[pid].name
    local party = PartySystem.data.parties[partyId]
    return party ~= nil and invites[partyId] ~= nil and invites[partyId][name] ~= nil
end

function PartySystem.inviteMember(partyId, pid, inviter)
    pid = tonumber(pid)
    if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
        local name = Players[pid].name
        local party = PartySystem.data.parties[partyId]
        if party ~= nil and tableHelper.containsValue(party.members, name) == false then

            if invites[partyId] == nil then
                invites[partyId] = {}
            end

            if PartySystem.config.inviteTimeout ~= nil then
                local timerId = tes3mp.CreateTimerEx("OnPartyInviteTimeExpiration", PartySystem.config.inviteTimeout, "ii",
                                    partyId, pid)
                invites[partyId][name] = timerId
                tes3mp.StartTimer(timerId)
            else
                invites[partyId][name] = -1
            end
            if PartySystem.config.allowNamedParties then
                tes3mp.SendMessage(pid, color.Default .. tostring(inviter) .. " wants you to join " .. party.name .. ".\n", false)
            else
                tes3mp.SendMessage(pid, color.Default .. tostring(inviter) .. " wants you to join their party.\n", false)
            end
            return
        end
    --quickLog("Attempt to invite " .. tostring(name) .. " to party " .. tostring(partyId) .. " failed")
    end
end

function OnPartyInviteTimeExpiration(partyId, pid)
    PartySystem.removeInvite(partyId, pid)
end

function PartySystem.removeInvite(partyId, pid)
    pid = tonumber(pid)
    if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
        local name = Players[pid].name
        local party = PartySystem.data.parties[partyId]
        if party ~= nil and PartySystem.isInvited(partyId, pid) then
            invites[partyId][name] = nil
            return
        end
        --quickLog("Attempt to remove invite of " .. tostring(name) .. " from party " .. tostring(partyId) .. " failed")
    end
end

function PartySystem.acceptInvite(partyId, pid)
    pid = tonumber(pid)
    local name = Players[pid].name
    local party = PartySystem.data.parties[partyId]
    if party ~= nil and PartySystem.isInvited(partyId, pid) then
        local timerId = invites[partyId][name]
        if timerId >= 0 then
            tes3mp.StopTimer(timerId)
        end
        invites[partyId][name] = nil
        PartySystem.addMember(partyId, pid)
        return
    end
    tes3mp.SendMessage(pid, color.Red .. "Unable to join party.\n", false)
    --quickLog("Attempt for " .. tostring(name) .. " to accept party " .. tostring(partyId) .. " invite failed")
end

function PartySystem.removeMember(partyId, pid)
    pid = tonumber(pid)
    if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
        local name = Players[pid].name
        local party = PartySystem.data.parties[partyId]

        if party ~= nil then
            local memberIndex = nil
            for key, value in pairs(party.members) do
                if value == name then
                    memberIndex = key
                    break
                end
            end

            if memberIndex ~= nil then
                table.remove(party.members, memberIndex)
                setPlayerParty(name, nil)

                if PartySystem.config.allowNamedParties then
                    tes3mp.SendMessage(pid, color.Default .. "You've been removed from " .. party.name .. ".\n", false)
                    PartySystem.messageParty(partyId, color.Default .. tostring(name) .. " has left " .. party.name .. ".")
                else
                    tes3mp.SendMessage(pid, color.Default .. "You've been removed from the party.\n", false)
                    PartySystem.messageParty(partyId, color.Default .. tostring(name) .. " has left the party.")
                end

                if #party.members == 0 then
                    PartySystem.data.parties[partyId] = nil
                    invites[partyId] = nil
                elseif party.leader == name then
                    party.leader = party.members[1]
                end

            end
        end
    end
end

function PartySystem.getPartyId(pid)
    pid = tonumber(pid)
    local name = Players[pid].name
    local partyId = getPlayerParty(name)

    --tableHelper.print(PartySystem.data)
    if partyId ~= nil and PartySystem.data.parties[partyId] ~= nil and
        tableHelper.containsValue(PartySystem.data.parties[partyId].members, name) then
        return partyId
    end
    setPlayerParty(name, nil)
    return nil
end

function PartySystem.isPartyLeader(partyId, pid)
    pid = tonumber(pid)
    local name = Players[pid].name
    local party = PartySystem.data.parties[partyId]
    if party ~= nil then
        return party.leader == name
    end

    return false
end

function PartySystem.messageParty(partyId, message, fromPid)
    local party = PartySystem.data.parties[partyId]
    if party == nil then
        return
    end

    local msg = message
    if fromPid ~= nil then
        msg = color.White .. logicHandler.GetChatName(fromPid) .. ": " .. msg
    end
    for _, member in pairs(party.members) do
        local player = logicHandler.GetPlayerByName(member)
        if player ~= nil and player:IsLoggedIn() then
            tes3mp.SendMessage(player.pid, msg .. "\n", false)
        end
    end
end

function PartySystem.OnServerPostInitHandler()
    PartySystem.loadData()
    PartySystem.saveData()
    logicHandler.GetChatName = function(pid)
        if Players[pid] ~= nil  and PartySystem.config.showPartyNameInChat and PartySystem.config.allowNamedParties then
            local partyId = PartySystem.getPartyId(pid)
            if partyId ~= nil then
                local party = PartySystem.data.parties[partyId]
                local partyTag = party.name
                if party.leader == Players[pid].name then
                    partyTag = "★" .. partyTag
                end
                return color.Gray .. partyTag .. color.Default .. GetChatName(pid)
            end
        end
        return GetChatName(pid)
    end
end

function PartySystem.OnServerExitHandler()
    for _,party in pairs(PartySystem.data.parties) do
        if #party.members == 1 then
            setPlayerParty(party.members[1], nil)
            PartySystem.data.parties[party.id] = nil
        end
    end
    PartySystem.saveData()
end


customEventHooks.registerHandler("OnServerPostInit", PartySystem.OnServerPostInitHandler)
customEventHooks.registerHandler("OnServerExit", PartySystem.OnServerExitHandler)

require("custom.PartySystem.commands")
require("custom.PartySystem.sharedData.journal")
require("custom.PartySystem.sharedData.topic")
require("custom.PartySystem.extensions.onPlayerActivate")

return PartySystem
