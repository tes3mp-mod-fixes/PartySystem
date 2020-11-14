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
local partySetup = {}

local function quickLog(msg)
    tes3mp.LogMessage(enumerations.log.INFO, msg)
end

local function hideButton(button)
    button.displayConditions = {{
        conditionType = "hidden"
    }}
end

local function showButton(button)
    button.displayConditions = nil
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

function PartySystem.setupParty(leaderpid, pid)
    leaderpid = tonumber(leaderpid)
    partySetup[leaderpid] = {
        invitee = tonumber(pid),
        name = nil
    }
    if PartySystem.config.allowNamedParties then
        --quickLog("PID BEING USED BY INPUT DIALOG: " .. tostring(leaderpid))
        tes3mp.InputDialog(leaderpid, PartySystem.config.partyNameMenuId, "Name your party", Players[leaderpid].name .. "'s party.'")
    else
        PartySystem.createParty(leaderpid)
    end
end

function PartySystem.createParty(leaderpid)
    if Players[leaderpid] ~=nil and Players[leaderpid]:IsLoggedIn() then
        leaderpid = tonumber(leaderpid)
        local pid = partySetup[leaderpid].invitee
        local partyName = partySetup[leaderpid].name

        local name = Players[leaderpid].name
        if partyName == nil then
            partyName = name .. "'s party"
        end
        local partyId = tostring(#PartySystem.data.parties)
        PartySystem.data.parties[partyId] = {
            name = partyName,
            id = partyId,
            leader = name,
            members = {name}
        }
        invites[partyId] = {}

        setPlayerParty(name, partyId)
        PartySystem.inviteMember(partyId, pid, name)
        partySetup[leaderpid] = nil
        return partyId
    end
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
            if #party.members == 1 and #invites[partyId] == 0 then
                setPlayerParty(party.members[1], nil)
                PartySystem.data.parties[partyId] = nil
                invites[partyId] = nil
            end
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

                if #party.members == 1 and #invites[partyId] == 0 then
                    setPlayerParty(party.members[1], nil)
                    PartySystem.data.parties[partyId] = nil
                elseif party.leader == name then
                    party.leader = party.members[1]
                end

                return
            end
        end
        --quickLog("Attempt to removed " .. tostring(name) .. " from party " .. tostring(partyId) .. " failed")
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

function PartySystem.onPlayerActivateHandler(eventStatus, me, them,menu, cellDescription)
    if eventStatus.validDefaultHandler then
        local partyButton = {
            caption = "Party",
            destinations = nil
        }
        table.insert(menu.buttons, 1, partyButton)
        local myPartyId = PartySystem.getPartyId(me)
        local myName = Players[me].name
        local iAmLeader = PartySystem.isPartyLeader(myPartyId, me)
        local theirPartyId = PartySystem.getPartyId(them)

        showButton(partyButton)

        if myPartyId ~= nil then
            -- I'm in a party
            if theirPartyId ~= nil then
                -- They are also in a party
                if myPartyId == theirPartyId then
                    -- We're in the same party
                    if iAmLeader then
                        partyButton.caption = "Kick from party"
                        partyButton.destinations = {menuHelper.destinations.setDefault(nil, {menuHelper.effects
                            .runGlobalFunction("PartySystem", "removeMember", {myPartyId, them})})}
                    else
                        partyButton.caption = "Leave Party"
                        partyButton.destinations = {menuHelper.destinations.setDefault(nil, {menuHelper.effects
                            .runGlobalFunction("PartySystem", "removeMember", {myPartyId, me})})}
                    end
                else
                    -- We're in different parties
                    hideButton(partyButton)
                end
            else
                -- They are not in a party but I am
                if PartySystem.isInvited(myPartyId, them) then
                    -- I've already invited them
                    partyButton.caption = "Cancel invite to party"
                    partyButton.destinations = {menuHelper.destinations.setDefault(nil, {menuHelper.effects
                        .runGlobalFunction("PartySystem", "removeInvite", {myPartyId, them})})}
                else
                    partyButton.caption = "Invite to party"
                    partyButton.destinations = {menuHelper.destinations.setDefault(nil, {menuHelper.effects
                        .runGlobalFunction("PartySystem", "inviteMember", {myPartyId, them, myName})})}
                end
            end
        else
            -- I am not in a party

            if theirPartyId ~= nil then
                -- they are in a party but I am not

                if PartySystem.isInvited(theirPartyId, me) then
                    partyButton.caption = "Accept invite to party"
                    partyButton.destinations = {menuHelper.destinations.setDefault(nil, {menuHelper.effects
                        .runGlobalFunction("PartySystem", "acceptInvite", {theirPartyId, me})})}
                else
                    hideButton(partyButton)
                end

            else
                -- We're both not in a party
                partyButton.caption = "Invite to party"
                partyButton.destinations = {menuHelper.destinations.setDefault(nil, {menuHelper.effects
                    .runGlobalFunction("PartySystem", "setupParty", {me, them})})}

            end
        end
    end
end

function PartySystem.OnServerPostInitHandler()
    PartySystem.loadData()
    PartySystem.saveData()
    local GetChatName = logicHandler.GetChatName
    logicHandler.GetChatName = function(pid)
        if Players[pid] ~= nil  and PartySystem.config.showPartyNameInChat and PartySystem.config.allowNamedParties then
            local partyId = PartySystem.getPartyId(pid)
            if partyId ~= nil then
                return color.Gray .. "-" .. PartySystem.data.parties[partyId].name .. "- " .. color.Default .. GetChatName(pid)
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

function PartySystem.OnGuiAction(eventStatus, pid, menuId, data)
    if eventStatus.validDefaultHandler and menuId == PartySystem.config.partyNameMenuId then
        --quickLog(tostring(Menus[menuId] == nil))
        if partySetup[pid] ~= nil then
            partySetup[pid].name = data
            PartySystem.createParty(pid)
        end
    end
end


customEventHooks.registerHandler("OnPlayerActivate", PartySystem.onPlayerActivateHandler)
customEventHooks.registerHandler("OnServerPostInit", PartySystem.OnServerPostInitHandler)
customEventHooks.registerHandler("OnGUIAction", PartySystem.OnGuiAction)
customEventHooks.registerHandler("OnServerExit", PartySystem.OnServerExitHandler)
require("custom.PartySystem.journal")
require("custom.PartySystem.topic")
return PartySystem
