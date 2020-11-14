# PartySystem
 A customizeable party system for tes3mp. Activate a user to invite them to a party, or if you've been invited activate a user of that party to accept (commands coming). Share journal and topic updates with only the people in your party, parties are saved so you can jump back in and be in the same party.
 
# Install
 This requires Two other modules. To install this module add these files to a `server/scripts/custom/PartySystem` folder.  
 If you're looking for a specific release look in the [releases section](../../releases)  
 Then add `PartySystem = require("custom.PartySystem.main")` to your **customScripts.lua** after [Urm's DataManager](https://github.com/tes3mp-scripts/DataManager)
 
 ### Config
 In your **config.lua** set `shareJournal` and `shareTopics` to false, otherwise the party system will not work correctly.

### PlayerActivateApi
 [PlayerActivateApi](https://github.com/DavidMeagher1/TES3MP_SingleScripts/blob/main/playerActivateAPI.lua) introduces an "OnPlayerActivate" event that allows you to know when one player has "activated" another and has a simple option to show a menu of your choosing

### Urm's DataManager
[Urm's DataManager script](https://github.com/tes3mp-scripts/DataManager) helps us save the parties to disk when the server is shutdown, and load configuration,

# Default Configuration
  ### `inviteTimeout` = time.minutes(1)
  this is how long a invitation to join a party will last, if set to nil invitations will only expire when the server is shutdown

  ### `shareJournal` = true
  this tells the party system to update all party members journals 

  ### `shareTopics` = true
  this tells the party system to update all party members topics 
  ***Note***: This wont visually update when you are in a conversation visually until you click on something
  
  ### `sendChatmessages` = true
  ***Not implemented yet***

  ### `allowNamedParties` = true
  This will make it so when you invite a player to a party for the first time it will pop up an input dialog and that will be your parties name
  
  ### `showPartyNameInChat` = true
  This requires `allowNamedParties` to be true and makes it so your party name shows up in the chatbox

  ### `partyNameMenuId` = 12859
  This is the menu id for the party name menu, you really don't need to change this unless some other script uses this id for their menus

  after you run the script on your server for the first time you can find the config file you can change under `server/data/custom/__config_PartySystem.json`
  
  
  **Thanks for using our script**
