local function ERROR(pid, message)
    tes3mp.SendMessage(pid, color.Red .. message .. "\n")
end

local function test(condition, pid, message)
    if not condition then
        ERROR(pid, message)
    end
    return true
end

local function create(pid, name)
    local partyId = PartySystem.getPartyId(pid)
    if test(partyId == nil, pid, "You're already in a party.") then
        partyId = PartySystem.createParty(pid)
        if partyId ~= nil and name ~= nil then
            local party = PartySystem.data.parties[partyId]
            party.name = name
        end
    end
end

local function invite(pid, other)
    local partyId = PartySystem.getPartyId(pid)
    if test(partyId ~= nil, pid, "You're not in a party.") and
        test(other ~= nil, pid, "Expected the pid of the person you want to invite.") then
        other = tonumber(other)
        PartySystem.inviteMember(partyId, other, pid)
    end
end

local function uninvite(pid, other)
    local partyId = PartySystem.getPartyId(pid)
    if test(partyId ~= nil, pid, "You're not in a party.") and
        test(other ~= nil, pid, "Expected the pid of the person you want to uninvite.") and
        test(PartySystem.isPartyLeader(partyId, pid), pid, "Only the leader can uninvite.") then
        other = tonumber(other)
        PartySystem.removeInvite(partyId, other)
    end
end

local function kick(pid, other)
    local partyId = PartySystem.getPartyId(pid)
    if test(partyId ~= nil, pid, "You're not in a party.") and
        test(other ~= nil, pid, "Expected the pid of the person you want to kick.") and
        test(PartySystem.isPartyLeader(partyId, pid), pid, "Only the leader can kick.")  then
        other = tonumber(other)
        PartySystem.removeMember(partyId, other)
    end
end

local function mainCommand(pid, cmd)

    if cmd[2] == "create" or cmd[2] == "c" then
        create(pid, cmd[3])
    elseif cmd[2] == "invite" or cmd[2] == "i" then
        invite(pid, cmd[3])
    elseif cmd[2] == "uninvite" or cmd[2] == "u" then
        uninvite(pid, cmd[3])
    elseif cmd[2] == "kick" or cmd[2] == "k" then
        kick(pid, cmd[3])
    else
        -- TODO print list of commands and descriptions
    end

end

customCommandHooks.registerCommand("party", mainCommand)
