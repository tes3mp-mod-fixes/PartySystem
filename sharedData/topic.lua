function PartySystem.CopyTopicsToParty(pid)
    local stateObject = Players[pid]
    if stateObject.data.topics == nil then
        stateObject.data.topics = {}
    end

    for i = 0, tes3mp.GetTopicChangesSize(pid) - 1 do

        local topicId = tes3mp.GetTopicId(pid, i)

        if not tableHelper.containsValue(stateObject.data.topics, topicId) then
            table.insert(stateObject.data.topics, topicId)
        end

        local partyId = PartySystem.getPartyId(pid)
        local party = PartySystem.data.parties[partyId]
        if party ~= nil then
            for _, member in pairs(party.members) do
                local player = logicHandler.GetPlayerByName(member)
                if player ~= nil and player.pid ~= pid and player:IsLoggedIn() then
                    
                    if not tableHelper.containsValue(player.data.topics, topicId) then
                        table.insert(player.data.topics, topicId)
                    end
                    player:QuicksaveToDrive()
                    tes3mp.AddTopic(player.pid, topicId)
                    tes3mp.SendTopicChanges(player.pid, false, false)
                end
            end
        end
    end

    stateObject:QuicksaveToDrive()
end

function PartySystem.OnPlayerTopicValidator(eventStatus,pid)
  return customEventHooks.makeEventStatus(false,true)
end
function PartySystem.OnPlayerTopicHandler(eventStatus,pid)
  if not eventStatus.validDefaultHandlers and eventStatus.validCustomHandlers and Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
    PartySystem.CopyTopicsToParty(pid)
  end
end

customEventHooks.registerValidator("OnPlayerTopic",PartySystem.OnPlayerTopicValidator)
customEventHooks.registerHandler("OnPlayerTopic",PartySystem.OnPlayerTopicHandler)