function PartySystem.CopyJournalToParty(pid)
    local stateObject = Players[pid]
    

    if stateObject.data.journal == nil then
        stateObject.data.journal = {}
    end

    if stateObject.data.customVariables == nil then
        stateObject.data.customVariables = {}
    end

    for i = 0, tes3mp.GetJournalChangesSize(pid) - 1 do

        local journalItem = {
            type = tes3mp.GetJournalItemType(pid, i),
            index = tes3mp.GetJournalItemIndex(pid, i),
            quest = tes3mp.GetJournalItemQuest(pid, i),
            timestamp = {
                daysPassed = WorldInstance.data.time.daysPassed,
                month = WorldInstance.data.time.month,
                day = WorldInstance.data.time.day
            }
        }

        if journalItem.type == enumerations.journal.ENTRY then
            journalItem.actorRefId = tes3mp.GetJournalItemActorRefId(pid, i)
        end

        table.insert(stateObject.data.journal, journalItem)

        local partyId = PartySystem.getPartyId(pid)
        local party = PartySystem.data.parties[partyId]
        if party ~= nil then
            for _, member in pairs(party.members) do
                local player = logicHandler.GetPlayerByName(member)
                if player ~= nil and player.pid ~= pid and player:IsLoggedIn() then

                    if player.data.journal == nil then
                        player.data.journal = {}
                    end

                    if player.data.customVariables == nil then
                        player.data.customVariables = {}
                    end

                    table.insert(player.data.journal, journalItem)

                    if journalItem.quest == "a1_1_findspymaster" and journalItem.index >= 14 then
                        player.data.customVariables.deliveredCaiusPackage = true
                    end

                    tes3mp.AddJournalEntryWithTimestamp(player.pid, journalItem.quest, journalItem.index, journalItem.actorRefId, journalItem.timestamp.daysPassed, journalItem.timestamp.month, journalItem.timestamp.day)
                    tes3mp.SendJournalChanges(player.pid, false, false)

                    player:QuicksaveToDrive()
                end
            end
        end
        if journalItem.quest == "a1_1_findspymaster" and journalItem.index >= 14 then
            stateObject.data.customVariables.deliveredCaiusPackage = true
        end
    end
    stateObject:QuicksaveToDrive()
end

function PartySystem.OnPlayerJournalValidator(eventstatus, pid)
    if config.shareJournal then
        return
    end
    return customEventHooks.makeEventStatus(false, true)
end

function PartySystem.OnPlayerJournalHandler(eventStatus, pid)
    -- have pid of player updating journal
    if  not eventStatus.validDefaultHandlers and eventStatus.validCustomHandlers and Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
        PartySystem.CopyJournalToParty(pid)
    end
end

customEventHooks.registerValidator("OnPlayerJournal", PartySystem.OnPlayerJournalValidator)
customEventHooks.registerHandler("OnPlayerJournal",PartySystem.OnPlayerJournalHandler)
