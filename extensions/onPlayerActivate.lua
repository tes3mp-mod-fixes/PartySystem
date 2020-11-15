local function hideButton(button)
    button.displayConditions = {{
        conditionType = "hidden"
    }}
end

local function showButton(button)
    button.displayConditions = nil
end

function PartySystem.__setup_party__(leaderpid, pid)
    leaderpid = tonumber(leaderpid)
    pid = tonumber(pid)

    local partyId = PartySystem.createParty(leaderpid)

    if PartySystem.config.allowNamedParties then
        Players[leaderpid].data.customVariables.partyInvitee = pid
        tes3mp.InputDialog(leaderpid, PartySystem.config.partyNameMenuId, "Name your party", "")
    else
        PartySystem.inviteMember(partyId, pid, leaderpid)
    end
end

local function onPlayerActivateHandler(eventStatus, me, them,menu, cellDescription)
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
                    .runGlobalFunction("PartySystem", "__setup_party__", {me, them})})}

            end
        end
    end
end

local function OnGuiAction(eventStatus, pid, menuId, data)
    if eventStatus.validDefaultHandler and menuId == PartySystem.config.partyNameMenuId then
        local invitee = Players[leaderpid].data.customVariables.partyInvitee
        local partyId = PartySystem.getPartyId(pid)
        if partyId ~= nil and invitee ~= nil then
            local party = PartySystem.data.parties[partyId]
            party.name = data
            Players[leaderpid].data.customVariables.partyInvitee = nil
            PartySystem.inviteMember(partyId, invitee, pid)
        end
    end
end

if PlayerActivationApi == nil then
    tes3mp.LogMessage(enumerations.log.WARN, "PlayerActivationApi is missing OnPlayerActivate gui will not be used." )
end

customEventHooks.registerHandler("OnPlayerActivate", onPlayerActivateHandler)
customEventHooks.registerHandler("OnGUIAction", OnGuiAction)