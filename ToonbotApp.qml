import QtQuick 2.1
import qb.components 1.0
import qb.base 1.0
import FileIO 1.0
import BxtClient 1.0
 
App {
	id: toonbotApp

	property url tileUrl : "ToonbotTile.qml"
	property url thumbnailIcon: "qrc:/tsc/toonbotSmallNoBG.png"
	
	property url toonbotScreenUrl : "ToonbotScreen.qml"
	property url toonbotConfigurationScreenUrl : "ToonbotConfigurationScreen.qml"
	property url toonbotSecurityScreenUrl : "ToonbotSecurityScreen.qml"
	property url trayUrl : "ToonbotTray.qml"

	property ToonbotConfigurationScreen toonbotConfigurationScreen
	property ToonbotSecurityScreen toonbotSecurityScreen
	property ToonbotScreen toonbotScreen

	// for Tile
    property string tileStatus : "Wachten op data....."
    property string tileLastcmd : ""
    property string tileBotName : ""

    property variant telegramData
    property variant getMeData
	property variant thermostatInfoData
	property variant currentUsageData
	property variant todayGasUsageData
	property variant todayElectLTUsageData
	property variant todayElectNTUsageData

    property string lastUpdateId		// id from last receivede telegram message, so last message will not be retrieved again
    property string chatId				// used to send message to right chat

	// settings
    property string toonbotTelegramToken : ""			// Telegram Bot token 
    property int toonbotRefreshIntervalSeconds  : 60	// interval to retrieve telegram messages
	property bool enableSystray : false
	property bool enableRefresh : false					// enable retrieving Telegram messages
	property bool enableSecurity : false				// enable security (check chatid's)
    property string toonbotAlarmChatId : ""				// ChatId for alarms
	property bool enableSmokeAlarm : false				// enable smoke alarm 

	// user settings from config file
	property variant toonbotSettingsJson 

	property string toonbotLastUpdateTime
	property string toonbotLastResponseStatus : "N/A"

	property bool refreshGetMeDone : false					// GetMe succesvol received
	property int numberMessagesOnScreen : (isNxt ? 15 : 12)  

	property bool debugOutput : false						// Show console messages. Turn on in settings file !

	property variant usersNames : []  				// array of allowed user or group names
	property variant usersChatIds : []				// array of allowed corresponding chatid

	// signal, used to update the listview 
	signal toonbotUpdated()

	QtObject {
		id: p

		property string eventmgrUuid

		property string lastNotifyUuid
		property string lastNotifyTime

	}

	property variant linkedSmokedetectors: []


	FileIO {
		id: toonbotSettingsFile
		source: "file:///mnt/data/tsc/toonbot.userSettings.json"
 	}

	FileIO {
		id: toonbotLastUpdateIdFile
		source: "file:///tmp/toonbot-lastUpdateId.txt"
 	}

	Component.onCompleted: {
		// read user settings

		try {
			toonbotSettingsJson = JSON.parse(toonbotSettingsFile.read());
			if (toonbotSettingsJson['TrayIcon'] == "Yes") {
				enableSystray = true
			} else {
				enableSystray = false
			}
			if (toonbotSettingsJson['RefreshOn'] == "Yes") {
				enableRefresh = true
			} else {
				enableRefresh = false
			}
			toonbotTelegramToken = toonbotSettingsJson['Token'];		
			toonbotRefreshIntervalSeconds = toonbotSettingsJson['RefreshIntervalSeconds'];	
			
			if (toonbotSettingsJson['DebugOn'] == "Yes") {
				debugOutput = true
			} else {
				debugOutput = false
			}

			if (toonbotSettingsJson['Security'] == "Yes") {
				enableSecurity = true
			} else {
				enableSecurity = false
			}

			var tmpusersNames = [];
			var tmpusersChatIds = [];

			for (var i = 0; i < toonbotSettingsJson['Users'].length; i++) {
				var tmp = toonbotSettingsJson['Users'][i].split("@");
				tmpusersNames.push(tmp[0]);
				tmpusersChatIds.push(tmp[1]);
			}

			usersNames = tmpusersNames;
			usersChatIds = tmpusersChatIds;

			toonbotAlarmChatId = toonbotSettingsJson['AlarmChatId'];

			if (toonbotSettingsJson['SmokeAlarm'] == "Yes") {
				enableSmokeAlarm = true
			} else {
				enableSmokeAlarm = false
			}
			
		} catch(e) {
		}

		startGetTelegramUpdatesTimer();

		// Only when a Telegram token is there
		if ( toonbotTelegramToken.length > 0 ) {
			readLastUpdateId();
		} else {
			enableRefresh = false;
			tileStatus = "Token mist, zie instellingen";
		}
	}

	function init() {
		registry.registerWidget("tile", tileUrl, this, null, {thumbLabel: "ToonBot", thumbIcon: thumbnailIcon, thumbCategory: "general", thumbWeight: 30, baseTileWeight: 10, thumbIconVAlignment: "center"});
		registry.registerWidget("screen", toonbotScreenUrl, this, "toonbotScreen");
		registry.registerWidget("screen", toonbotConfigurationScreenUrl, this, "toonbotConfigurationScreen");
		registry.registerWidget("screen", toonbotSecurityScreenUrl, this, "toonbotSecurityScreen");
		registry.registerWidget("systrayIcon", trayUrl, this, "toonbotTray");
	}

	function saveSettings() {
		// save user settings
		if (debugOutput) console.log("********* ToonBot saveSettings");

		var tmpTrayIcon = "";
		var tmpRefreshOn = "";
		var tmpDebugOn = "";
		var tmpSecurity = "";
		var tmpSmokeAlarm = "";
		
		if (enableSystray == true) {
			tmpTrayIcon = "Yes";
		} else {
			tmpTrayIcon = "No";
		}
		if (enableRefresh == true) {
			tmpRefreshOn = "Yes";
		} else {
			tmpRefreshOn = "No";
		}
		if (debugOutput == true) {
			tmpDebugOn = "Yes";
		} else {
			tmpDebugOn = "No";
		}
		if (enableSecurity == true) {
			tmpSecurity = "Yes";
		} else {
			tmpSecurity = "No";
		}

		var tmpUsers = [];
		for (var i = 0; i < usersNames.length; i++) {
			tmpUsers.push(usersNames[i] + "@" + usersChatIds[i]);
		}

		if (enableSmokeAlarm == true) {
			tmpSmokeAlarm = "Yes";
		} else {
			tmpSmokeAlarm = "No";
		}

		
 		var tmpUserSettingsJson = {
			"Token"      				: toonbotTelegramToken,
			"RefreshIntervalSeconds"	: toonbotRefreshIntervalSeconds,
 			"TrayIcon"      			: tmpTrayIcon,
			"RefreshOn"					: tmpRefreshOn,
			"DebugOn"					: tmpDebugOn,
			"Security"					: tmpSecurity,
			"Users" 					: tmpUsers,
			"AlarmChatId"      			: toonbotAlarmChatId,
			"SmokeAlarm"				: tmpSmokeAlarm
			
		}

		toonbotSettingsFile.write(JSON.stringify(tmpUserSettingsJson ));

	}

	// Remove a user or group from the list of allowed users
	function deleteUsers(itemIndex) {
		if (debugOutput) console.log("********* ToonBot deleteUsers");

		// delete the item at index itemIndex from both arrays		
		var tmpUsers = [];
		var tmpChatIds = [];

		for (var i = 0; i < usersNames.length; i++) {
			if (i !== itemIndex) {		// skip the item to be deleted
				tmpUsers.push(usersNames[i]);
				tmpChatIds.push(usersChatIds[i]);
			}
		}
		usersNames = tmpUsers;
		usersChatIds = tmpChatIds;

		if (debugOutput) console.log("********* ToonBot deleteUsers left: " + usersNames.length );

	}

	// Is chat id in the list of allowed users/groups?
	function inUsersChatIdsList(chat_id) {
		if (debugOutput) console.log("********* ToonBot inUsersChatIdsList");
		
		for (var i = 0; i < usersChatIds.length; i++) {
			if (usersChatIds[i] == chat_id ) {	
				return true;
			}
		}
		return false;
	}

	// return number of users in list of allowed users/groups
	function numberOfUsersInList() {
		if (debugOutput) console.log("********* ToonBot numberOfUsersInList: " + usersNames.length );
		
		return usersNames.length;
	}


	// get some information about Bot and test Token
	function refreshGetMe() {
        if (debugOutput) console.log("********* ToonBot refreshGetMe");

        // clear Tile
		tileStatus = "Ophalen GetMe.....";
		
        var xmlhttp = new XMLHttpRequest();
        xmlhttp.open("GET", "https://api.telegram.org/bot"+toonbotTelegramToken+"/getMe", true);
        xmlhttp.onreadystatechange = function() {
            if (debugOutput) if (debugOutput) console.log("********* ToonBot refreshGetMe readyState: " + xmlhttp.readyState + " http status: " + xmlhttp.status);
            if (xmlhttp.readyState === XMLHttpRequest.DONE ) {

				// save response
				var doc = new XMLHttpRequest();
				doc.open("PUT", "file:///tmp/toonbot-response1.json");
				doc.send(xmlhttp.responseText);

				if (xmlhttp.status == 200) {
					var response = xmlhttp.responseText;
					if (debugOutput) if (debugOutput) console.log("********* ToonBot refreshGetMe response" + response );
					// if no json but html received
					try {
						getMeData = JSON.parse(xmlhttp.responseText);
						if (getMeData['ok']) {
							if (debugOutput) console.log("********* ToonBot refreshGetMe telegramData data found");

							tileBotName = getMeData['result']['first_name'];
							// username is optional
							try {
								tileBotName = tileBotName + "@" + getMeData['result']['username'];

							}
							catch(e) {}
							refreshGetMeDone = true;
							getTelegramUpdates();
						} else {
							tileStatus = "Ophalen GetMe mislukt.....";
							refreshGetMeTimer.start();  // try again
							if (debugOutput) console.log("********* ToonBot refreshGetMe failed, not ok received. try again");
						}
					}
					catch(e) {
						tileStatus = "Ophalen GetMe mislukt.....";
						refreshGetMeTimer.start();  // try again
						if (debugOutput) console.log("********* ToonBot refreshGetMe failed, no JSON received. try again");
					}
				} else {
					tileStatus = "Ophalen GetMe mislukt.....";
					refreshGetMeTimer.start();  // try again
					if (debugOutput) console.log("********* ToonBot refreshGetMe failed, no http status 200. try again");
				}
            }
        }
        xmlhttp.send();
    }

	// get the Telegram messages after lastUpdateId
    function getTelegramUpdates() {
		var url;

		if (debugOutput) console.log("********* ToonBot getTelegramUpdates");

		if ( toonbotTelegramToken.length == 0 ) {
			tileStatus = "Token mist, zie instellingen"
			return;
		}
		
		tileStatus = "Ophalen messages.....";
		
		var xmlhttp = new XMLHttpRequest();

		if (lastUpdateId.length > 0) {
		   var updId = parseInt(lastUpdateId) + 1;
		   if (debugOutput) console.log("********* ToonBot getTelegramUpdates use lastUpdateId: " + updId);
           url = "https://api.telegram.org/bot"+toonbotTelegramToken+"/getUpdates?allowed_updates=[\"message\"]&offset=" + updId;
        } else {
           url = "https://api.telegram.org/bot"+toonbotTelegramToken+"/getUpdates?allowed_updates=[\"message\"]&offset=-1";
		   if (debugOutput) console.log("********* ToonBot getTelegramUpdates use offset=-1: " );
        }
		
		// Important: allowed_updates= will be remembered, even if it is removed again. Reset with allowed_updates=[]  (empty array)
		
	    if (debugOutput) console.log("********* ToonBot getTelegramUpdates url: " + url);
		
		xmlhttp.open("GET", url, true);
        xmlhttp.onreadystatechange = function() {
            if (debugOutput) console.log("********* ToonBot getTelegramUpdates readyState: " + xmlhttp.readyState + " http status: " + xmlhttp.status);
            if (xmlhttp.readyState === XMLHttpRequest.DONE ) {
			
				toonbotLastResponseStatus = xmlhttp.status;

				// save response
				var doc = new XMLHttpRequest();
				doc.open("PUT", "file:///tmp/toonbot-response2.json");
				doc.send(xmlhttp.responseText);

				var now = new Date();
				toonbotLastUpdateTime = now.toLocaleString('nl-NL'); 
			
                if (xmlhttp.status === 200) {
                    if (debugOutput) console.log("********* ToonBot getTelegramUpdates response " + xmlhttp.responseText );

                    telegramData = JSON.parse(xmlhttp.responseText);

                    if (telegramData['ok'] && telegramData['result'].length > 0) {
                        if (debugOutput) console.log("********* ToonBot getTelegramUpdates telegramData data found");
						tileStatus = "Verwerken messages.....";
                        processTelegramUpdates();
                    } else {
                        if (debugOutput) console.log("********* ToonBot getTelegramUpdates telegramData data found but empty");
						tileStatus = "Gereed";
                    }
                } else {
                    if (debugOutput) console.log("********* ToonBot getTelegramUpdates fout opgetreden.");
					tileStatus = "Ophalen messages mislukt.....";
                }
            }
        }
        xmlhttp.send();
    }

	function getSecondsBetweenDates(endDate, startDate) {
		var diff = endDate.getTime() - startDate.getTime();
		if (debugOutput) console.log("********* ToonBot getSecondsBetweenDates diff: " + (diff/1000));
		return (diff / 1000);
	}
	
	
    function processTelegramUpdates(){
        var i;
		var messageDate;
		var update_id = lastUpdateId;
		var timediff;
		var fromName;

        if (debugOutput) console.log("********* ToonBot processTelegramUpdates results: " + telegramData['result'].length);

		var now = new Date();

        for (i = 0; i <telegramData['result'].length; i++) {

            update_id = telegramData['result'][i]['update_id'];
            if (debugOutput) console.log("********* ToonBot processTelegramUpdates update_id:" + update_id );

            if( !telegramData['result'][i].hasOwnProperty('message')){
                if (debugOutput) console.log("********* ToonBot processTelegramUpdates object message not found. Skip this one.");
                continue;
            }
            if( !telegramData['result'][i]['message'].hasOwnProperty('text')){
                if (debugOutput) console.log("********* ToonBot processTelegramUpdates object text not found. Skip this one.");
                continue;
            }

			fromName = "";
				
			// get current chatid. can be different when using a group
			chatId = telegramData['result'][i]['message']['chat']['id']
			if (debugOutput) console.log("********* ToonBot processTelegramUpdates chatId:" + chatId );

            var date = telegramData['result'][i]['message']['date'];
            var text = telegramData['result'][i]['message']['text'];
			// when using the bot in a group then @<botusername> will be added to the text. Remove it.
			text = text.split('@')[0]; 
			
			try {
				if (telegramData['result'][i]['message']['chat']['type'] == "private") {
					fromName = telegramData['result'][i]['message']['chat']['first_name'];
					fromName = fromName + " " + telegramData['result'][i]['message']['chat']['last_name'];
				} else if (telegramData['result'][i]['message']['chat']['type'] == "group") {
					fromName = telegramData['result'][i]['message']['chat']['title'];  // group name
				} else {  // do not know if this is possible. Just in case
					fromName = telegramData['result'][i]['message']['from']['first_name'];
					fromName = fromName + " " + telegramData['result'][i]['message']['from']['last_name'];
				}
			}
			catch(e) {}

            if (debugOutput) console.log("********* ToonBot processTelegramUpdates i:" + i );
            if (debugOutput) console.log("********* ToonBot processTelegramUpdates date:" + date );
            if (debugOutput) console.log("********* ToonBot processTelegramUpdates text:" + text );
            if (debugOutput) console.log("********* ToonBot processTelegramUpdates fromName:" + fromName );

			messageDate = new Date(date*1000);	
			timediff = getSecondsBetweenDates(now,messageDate);

			// do not process too old messages 
			if ( timediff > (toonbotRefreshIntervalSeconds * 10)) {
				// discard message, too old
				if (debugOutput) console.log("********* ToonBot processTelegramUpdates discard message");
				continue;
			}

			addCommandToList(text, update_id, fromName, chatId);
			processCommand(text,update_id, chatId);

        }

        if (update_id != lastUpdateId ) {
            lastUpdateId = update_id;
			saveLastUpdateId(lastUpdateId)		// save id which can be used it Toon is restarted
        }
		tileStatus = "Gereed";
    }


    function getThermostatInfo() {
		if (debugOutput) console.log("********* ToonBot getThermostatInfo");

		var xmlhttp = new XMLHttpRequest();
		
		xmlhttp.open("GET", "http://localhost/happ_thermstat?action=getThermostatInfo", true);
        xmlhttp.onreadystatechange = function() {
            if (debugOutput) console.log("********* ToonBot getThermostatInfo readyState: " + xmlhttp.readyState + " http status: " + xmlhttp.status);
            if (xmlhttp.readyState === XMLHttpRequest.DONE ) {
		
                if (xmlhttp.status === 200) {
                    if (debugOutput) console.log("********* ToonBot getThermostatInfo response " + xmlhttp.responseText );

                    thermostatInfoData = JSON.parse(xmlhttp.responseText);

                    if (thermostatInfoData['result'] === "ok" ) {
                        if (debugOutput) console.log("********* ToonBot getThermostatInfo thermostatInfoData data found");
                        processThermostatInfo();
                    } else {
                        if (debugOutput) console.log("********* ToonBot getThermostatInfo thermostatInfoData data found but status not ok");
                    }
                } else {
                    if (debugOutput) console.log("********* ToonBot getThermostatInfo fout opgetreden.");
					tileStatus = "Ophalen gegevens mislukt.....";
                }
            }
        }
        xmlhttp.send();
    }

    function getCurrentUsage() {
		if (debugOutput) console.log("********* ToonBot getCurrentUsage");

		var xmlhttp = new XMLHttpRequest();

		xmlhttp.open("GET", "http://localhost/happ_pwrusage?action=GetCurrentUsage", true);
        xmlhttp.onreadystatechange = function() {
            if (debugOutput) console.log("********* ToonBot getCurrentUsage readyState: " + xmlhttp.readyState + " http status: " + xmlhttp.status);
            if (xmlhttp.readyState === XMLHttpRequest.DONE ) {
		
                if (xmlhttp.status === 200) {
                    if (debugOutput) console.log("********* ToonBot getCurrentUsage response " + xmlhttp.responseText );

                    currentUsageData = JSON.parse(xmlhttp.responseText);

                    if (currentUsageData['result'] === "ok" ) {
                        if (debugOutput) console.log("********* ToonBot getCurrentUsage currentUsageData data found");
						getTodayGasUsage();
                    } else {
                        if (debugOutput) console.log("********* ToonBot getCurrentUsage currentUsageData data found but status not ok");
                    }
                } else {
                    if (debugOutput) console.log("********* ToonBot getCurrentUsage fout opgetreden.");
					tileStatus = "Ophalen gegevens mislukt.....";
                }
            }
        }
        xmlhttp.send();
    }

    function getTodayGasUsage() {
		if (debugOutput) console.log("********* ToonBot getTodayGasUsage");

		var xmlhttp = new XMLHttpRequest();

		var d = new Date();
		d.setHours(-1,0,0,0)
		var today = d.valueOf() / 1000;
        if (debugOutput) console.log("********* ToonBot getTodayGasUsage today " + today );
	
		xmlhttp.open("GET", "http://localhost/hcb_rrd?action=getRrdData&loggerName=gas_quantity&rra=5yrhours&readableTime=0&nullForNaN=1&from=" + today , true);
        xmlhttp.onreadystatechange = function() {
            if (debugOutput) console.log("********* ToonBot getTodayGasUsage readyState: " + xmlhttp.readyState + " http status: " + xmlhttp.status);
            if (xmlhttp.readyState === XMLHttpRequest.DONE ) {
		
                if (xmlhttp.status === 200) {
                    if (debugOutput) console.log("********* ToonBot getTodayGasUsage response " + xmlhttp.responseText );

                    todayGasUsageData = JSON.parse(xmlhttp.responseText);

                    if (debugOutput) console.log("********* ToonBot getTodayGasUsage first element" + Object.keys(todayGasUsageData).sort()[0]);
                    if (debugOutput) console.log("********* ToonBot getTodayGasUsage last element" + Object.keys(todayGasUsageData).sort().reverse()[0]);
                    if (debugOutput) console.log("********* ToonBot getTodayGasUsage aantal elementen " + Object.keys(todayGasUsageData).length);

                    if (Object.keys(todayGasUsageData).length > 1 ) {
                        if (debugOutput) console.log("********* ToonBot getTodayGasUsage todayGasUsageData data found");

                    } else {
                        if (debugOutput) console.log("********* ToonBot getTodayGasUsage todayGasUsageData data found but status not ok");
                    }
                } else {
                    if (debugOutput) console.log("********* ToonBot getTodayGasUsage fout opgetreden.");
//					tileStatus = "Ophalen gegevens mislukt.....";
                }
                getTodayElectLTUsage();
            }
        }
        xmlhttp.send();
    }


    function getTodayElectLTUsage() {
		if (debugOutput) console.log("********* ToonBot getTodayElectLTUsage");

		var xmlhttp = new XMLHttpRequest();

		var d = new Date();
		d.setHours(-1,0,0,0)
		var today = d.valueOf() / 1000;
        if (debugOutput) console.log("********* ToonBot getTodayElectLTUsage today " + today );
	
		xmlhttp.open("GET", "http://localhost/hcb_rrd?action=getRrdData&loggerName=elec_quantity_lt&rra=5yrhours&readableTime=0&nullForNaN=1&from=" + today , true);
        xmlhttp.onreadystatechange = function() {
            if (debugOutput) console.log("********* ToonBot getTodayElectLTUsage readyState: " + xmlhttp.readyState + " http status: " + xmlhttp.status);
            if (xmlhttp.readyState === XMLHttpRequest.DONE ) {
		
                if (xmlhttp.status === 200) {
                    if (debugOutput) console.log("********* ToonBot getTodayElectLTUsage response " + xmlhttp.responseText );

                    todayElectLTUsageData = JSON.parse(xmlhttp.responseText);

                    if (debugOutput) console.log("********* ToonBot getTodayElectLTUsage first element" + Object.keys(todayElectLTUsageData).sort()[0]);
                    if (debugOutput) console.log("********* ToonBot getTodayElectLTUsage last element" + Object.keys(todayElectLTUsageData).sort().reverse()[0]);
                    if (debugOutput) console.log("********* ToonBot getTodayElectLTUsage aantal elementen " + Object.keys(todayElectLTUsageData).length);

                    if (Object.keys(todayElectLTUsageData).length > 1 ) {
                        if (debugOutput) console.log("********* ToonBot getTodayElectLTUsage todayElectLTUsageData data found");

                    } else {
                        if (debugOutput) console.log("********* ToonBot getTodayElectLTUsage todayElectLTUsageData data found but status not ok");
                    }
                } else {
                    if (debugOutput) console.log("********* ToonBot getTodayElectLTUsage fout opgetreden.");
//					tileStatus = "Ophalen gegevens mislukt.....";
                }
                getTodayElectNTUsage();
            }
        }
        xmlhttp.send();
    }


    function getTodayElectNTUsage() {
		if (debugOutput) console.log("********* ToonBot getTodayElectNTUsage");

		var xmlhttp = new XMLHttpRequest();

		var d = new Date();
		d.setHours(-1,0,0,0)
		var today = d.valueOf() /1000;
        if (debugOutput) console.log("********* ToonBot getTodayElectNTUsage today " + today );
	
		xmlhttp.open("GET", "http://localhost/hcb_rrd?action=getRrdData&loggerName=elec_quantity_nt&rra=5yrhours&readableTime=0&nullForNaN=1&from=" + today , true);
        xmlhttp.onreadystatechange = function() {
            if (debugOutput) console.log("********* ToonBot getTodayElectNTUsage readyState: " + xmlhttp.readyState + " http status: " + xmlhttp.status);
            if (xmlhttp.readyState === XMLHttpRequest.DONE ) {
		
                if (xmlhttp.status === 200) {
                    if (debugOutput) console.log("********* ToonBot getTodayElectNTUsage response " + xmlhttp.responseText );

                    todayElectNTUsageData = JSON.parse(xmlhttp.responseText);

                    if (debugOutput) console.log("********* ToonBot getTodayElectNTUsage first element" + Object.keys(todayElectNTUsageData).sort()[0]);
                    if (debugOutput) console.log("********* ToonBot getTodayElectNTUsage last element" + Object.keys(todayElectNTUsageData).sort().reverse()[0]);
                    if (debugOutput) console.log("********* ToonBot getTodayElectNTUsage aantal elementen " + Object.keys(todayElectNTUsageData).length);

                    if (Object.keys(todayElectNTUsageData).length > 1 ) {
                        if (debugOutput) console.log("********* ToonBot getTodayElectNTUsage todayElectNTUsageData data found");

                    } else {
                        if (debugOutput) console.log("********* ToonBot getTodayElectNTUsage todayElectNTUsageData data found but status not ok");
                    }
                } else {
                    if (debugOutput) console.log("********* ToonBot getTodayElectNTUsage fout opgetreden.");
//					tileStatus = "Ophalen gegevens mislukt.....";
                }
                processEnergyUsage();
            }
        }
        xmlhttp.send();
    }



	function getStateText(state) {
		var activeState;
		
		switch(state) {
			case "0":
				activeState = "Comfort";
				break;
			case "1":
				activeState = "Thuis";
				break;
			case "2":
				activeState = "Slapen";
				break;
			case "3":
				activeState = "Weg";
				break;
			case "-1":
				activeState = "Handmatig";
				break;
			default:
				activeState = "onbekend";
		}
		return activeState;
	}

	function getProgramText(program) {
		var programState;

		switch(program) {
			case "0":
				programState = "Uit";
				break;
			case "1":
				programState = "Aan";
				break;
			case "2":
				programState = "Tijdelijk";
				break;
			default:
				programState = "onbekend";
		}
		return programState;
	}

	function processEnergyUsage() {
		var message = "";
		var gasUsageToday;
		var electTodayUsage;
		
		var powerUsage = currentUsageData['powerUsage']['value'];
		var powerProduction = currentUsageData['powerProduction']['value'];
		var gasUsage = currentUsageData['gasUsage']['value'];

		if (!powerUsage) {
			powerUsage = 'N/A';
		}
		if (powerProduction === null) {
			powerProduction = 'N/A';
		}
		if (gasUsage === null) {
			gasUsage = 'N/A';
		}

		if (debugOutput) console.log("********* ToonBot processEnergyUsage powerUsage:" + powerUsage );
		if (debugOutput) console.log("********* ToonBot processEnergyUsage powerProduction:" + powerProduction );
		if (debugOutput) console.log("********* ToonBot processEnergyUsage gasUsage:" + gasUsage );

		if (todayGasUsageData[Object.keys(todayGasUsageData).sort()[0]] === null) {
			gasUsageToday = 'N/A';
		} else {
			var gasBeginUsageToday = todayGasUsageData[Object.keys(todayGasUsageData).sort()[0]] / 1000;
			var gasEndUsageToday = todayGasUsageData[Object.keys(todayGasUsageData).sort().reverse()[0]] / 1000;
			gasUsageToday = Math.round((gasEndUsageToday - gasBeginUsageToday)*100)/100;
		}
		
		if (debugOutput) console.log("********* ToonBot processEnergyUsage gasUsageToday " + gasUsageToday);

		if (todayElectLTUsageData[Object.keys(todayElectLTUsageData).sort()[0]] === null) {
			electTodayUsage = 'N/A';
		} else {
			var electLTBeginUsageToday = todayElectLTUsageData[Object.keys(todayElectLTUsageData).sort()[0]] / 1000;
			var electLTEndUsageToday = todayElectLTUsageData[Object.keys(todayElectLTUsageData).sort().reverse()[0]] / 1000;
			var electLTUsageToday = electLTEndUsageToday - electLTBeginUsageToday;
			if (debugOutput) console.log("********* ToonBot processEnergyUsage electLTUsageToday " + electLTUsageToday);
		}
		
		if (todayElectNTUsageData[Object.keys(todayElectNTUsageData).sort()[0]] === null) {
			electTodayUsage = 'N/A';
		} else {
			var electNTBeginUsageToday = todayElectNTUsageData[Object.keys(todayElectNTUsageData).sort()[0]] / 1000;
			var electNTEndUsageToday = todayElectNTUsageData[Object.keys(todayElectNTUsageData).sort().reverse()[0]] / 1000;
			var electNTUsageToday = electNTEndUsageToday - electNTBeginUsageToday;
			if (debugOutput) console.log("********* ToonBot processEnergyUsage electNTUsageToday " + electNTUsageToday);
		}

		if (electTodayUsage !== 'N/A') {
			electTodayUsage = Math.round((electLTUsageToday + electNTUsageToday)*1000) /1000;
		}
	
		message = "<b>Status energie verbruik:</b>\n" + 
					  "  Stroom huidig verbruik: <b>" + powerUsage + "</b> Watt\n" +
					  "  Stroom huidig teruglevering: <b>" + powerProduction + "</b> Watt\n" +
					  "  Stroom verbruik vandaag: <b>" + electTodayUsage + "</b> kWh\n" +
//				      "  Gas huidig verbruik: <b>" + gasUsage + "</b> liters\n" +
				      "  Gas verbruik vandaag: <b>" + gasUsageToday + "</b> m3\n";
					  

		sendTelegramMessage(chatId, message);
	
	}


	function processThermostatInfo() {
		var message = "";
		var programState;
		var activeState;
		var nextProgram;
		var nextState;
		var nextTime;
		
		var currentTemp = Math.round(thermostatInfoData['currentTemp'] / 10) /10 ;
		var currentSetpoint = Math.round(thermostatInfoData['currentSetpoint'] /10) /10;
		programState = getProgramText(thermostatInfoData['programState']);
		activeState = getStateText(thermostatInfoData['activeState']);
		nextProgram = getProgramText(thermostatInfoData['nextProgram']);
		nextState = getStateText(thermostatInfoData['nextState']);
		nextTime = new Date (thermostatInfoData['nextTime'] * 1000);
		
		if (debugOutput) console.log("********* ToonBot processThermostatInfo currentTemp:" + currentTemp );
		if (debugOutput) console.log("********* ToonBot processThermostatInfo currentSetpoint:" + currentSetpoint );
		if (debugOutput) console.log("********* ToonBot processThermostatInfo programState:" + programState );
		if (debugOutput) console.log("********* ToonBot processThermostatInfo activeState:" + activeState );
		if (debugOutput) console.log("********* ToonBot processThermostatInfo nextProgram:" + nextProgram );
		if (debugOutput) console.log("********* ToonBot processThermostatInfo nextState:" + nextState );
		if (debugOutput) console.log("********* ToonBot processThermostatInfo nextTime:" + nextTime );
	
		message = "<b>Status Toon:</b>\n" + 
					  "  Temperatuur: <b>" + currentTemp + "</b> graden\n" +
					  "  Thermostaat: <b>" + currentSetpoint + "</b> graden\n" +
				      "  Programma: <b>" + activeState + "</b>\n" +
				      "  Auto programma: <b>" + programState + "</b>\n";
					  
		if (thermostatInfoData['nextTime'] !== "0") {
			message = message + "  Om " + nextTime.getHours() + ":" + nextTime.getMinutes() + " op " + nextState + " en auto programma " + nextProgram;
		}				

		sendTelegramMessage(chatId, message);
	
	}


    function setProgram(program) {
		var responseData;
		var state;

		if (debugOutput) console.log("********* ToonBot setProgram: " + program);
		
		switch(program.toUpperCase()) {
			case "C":			// comfort
				state = 0;
				break;
			case "T":			//	thuis
				state = 1;
				break;
			case "S":			// slapen
				state = 2;
				break;
			case "W":			// weg
				state = 3;
				break;
			default:
				return;
		}	
		if (debugOutput) console.log("********* ToonBot setProgram");
		var responseData;

		var xmlhttp = new XMLHttpRequest();
		
		xmlhttp.open("GET", "http://localhost/happ_thermstat?action=changeSchemeState&state=2&temperatureState=" + state, true);
        xmlhttp.onreadystatechange = function() {
            if (debugOutput) console.log("********* ToonBot setProgram readyState: " + xmlhttp.readyState + " http status: " + xmlhttp.status);
            if (xmlhttp.readyState === XMLHttpRequest.DONE ) {
                if (xmlhttp.status === 200) {
                    if (debugOutput) console.log("********* ToonBot setProgram response " + xmlhttp.responseText );

                    responseData = JSON.parse(xmlhttp.responseText);

                    if (responseData['result'] === "ok" ) {
                        if (debugOutput) console.log("********* ToonBot setProgram succeeded");
                    } else {
                        if (debugOutput) console.log("********* ToonBot setProgram failed");
                    }

                } else {
                    if (debugOutput) console.log("********* ToonBot setProgram fout opgetreden.");
                }
            }
        }
        xmlhttp.send();
    }

    function setState(state) {
		var responseData;
		var tmpState;

		if (debugOutput) console.log("********* ToonBot setState: " + state);
		
		switch(state.toUpperCase()) {
			case "U":   				// uit
				tmpState = "0";
				break;
			case "A":					// aan
				tmpState = "1";
				break;
			default:
				return;
		}	
		var xmlhttp = new XMLHttpRequest();

		if (debugOutput) console.log("********* ToonBot setState http://localhost/happ_thermstat?action=changeSchemeState&state=" + tmpState);
		
		xmlhttp.open("GET", "http://localhost/happ_thermstat?action=changeSchemeState&state=" + tmpState, true);
        xmlhttp.onreadystatechange = function() {
            if (debugOutput) console.log("********* ToonBot setState readyState: " + xmlhttp.readyState + " http status: " + xmlhttp.status);
            if (xmlhttp.readyState === XMLHttpRequest.DONE ) {
                if (xmlhttp.status === 200) {
                    if (debugOutput) console.log("********* ToonBot setState response " + xmlhttp.responseText );

                    responseData = JSON.parse(xmlhttp.responseText);

                    if (responseData['result'] === "ok" ) {
                        if (debugOutput) console.log("********* ToonBot setState succeeded");
                    } else {
                        if (debugOutput) console.log("********* ToonBot setState failed");
                    }

                } else {
                    if (debugOutput) console.log("********* ToonBot setState fout opgetreden.");
                }
            }
        }
        xmlhttp.send();
    }

  
    function setTemp(temp) {
		var responseData;
		var tmpTemp = temp * 100;

		if (debugOutput) console.log("********* ToonBot setTemp temp: " + temp);
		
		var xmlhttp = new XMLHttpRequest();
		
		xmlhttp.open("GET", "http://localhost/happ_thermstat?action=setSetpoint&Setpoint=" + tmpTemp, true);
        xmlhttp.onreadystatechange = function() {
            if (debugOutput) console.log("********* ToonBot setTemp readyState: " + xmlhttp.readyState + " http status: " + xmlhttp.status);
            if (xmlhttp.readyState === XMLHttpRequest.DONE ) {
                if (xmlhttp.status === 200) {
                    if (debugOutput) console.log("********* ToonBot setTemp response " + xmlhttp.responseText );

                    responseData = JSON.parse(xmlhttp.responseText);

                    if (responseData['result'] === "ok" ) {
                        if (debugOutput) console.log("********* ToonBot setTemp succeeded");
                    } else {
                        if (debugOutput) console.log("********* ToonBot setTemp failed");
                    }

                } else {
                    if (debugOutput) console.log("********* ToonBot setTemp fout opgetreden.");
                }
            }
        }
        xmlhttp.send();
    }

  

    function processCommandInfo() {
		getThermostatInfo();
    }

    function processCommandEnergie() {
		getCurrentUsage();
    }

    function processCommandProgram(subcmd) {
		setProgram(subcmd);
		getThermostatInfo();
    }

    function processCommandAutoprogram(subcmd) {
		setState(subcmd);
		getThermostatInfo();
    }

    function processCommandChangetemp(temp) {
		setTemp(temp);
		getThermostatInfo();
    }

	// rond getal af naar .0 of .5
	function roundToHalf(value) {
	   var converted = parseFloat(value); // Make sure we have a number
	   var decimal = (converted - parseInt(converted, 10));
	   decimal = Math.round(decimal * 10);
	   if (decimal == 5) { return (parseInt(converted, 10)+0.5); }
	   if ( (decimal < 3) || (decimal > 7) ) {
		  return Math.round(converted);
	   } else {
		  return (parseInt(converted, 10)+0.5);
	   }
	}

	// Is chat id allowed?
	function chatAllowed(chat_id) {
		if (debugOutput) console.log("********* ToonBot chatAllowed");
		
		if (!enableSecurity) {
			return true;
		}
		return inUsersChatIdsList(chat_id);
	}
	
    function processCommand(text,update_id, chat_id) {
		var subcmd;
		var cmd;

		if (debugOutput) console.log("********* ToonBot processCommand command: " + text );

		if (!chatAllowed(chat_id)) {
			if (debugOutput) console.log("********* ToonBot processCommand chat not allowed");
			setStatus(update_id, "Denied")
			return;
		}

		var command = text.replace(/\s/g,'').split("_",2);

		if (debugOutput) console.log("********* ToonBot processCommand command:" + command + " len: " + command.length);
		cmd = command[0];
		if (command.length === 2) {
			subcmd = command[1];
		} else {
			subcmd = "";
		}

		if (debugOutput) console.log("********* ToonBot processCommand cmd: " + cmd + " subcmd: " + subcmd );

		tileLastcmd = text;

        switch(cmd.toUpperCase()) {
			case "/INFO":
				if (subcmd.length == 0) {
					setStatus(update_id, "Ok")
					sendTelegramAck(text);
					processCommandInfo();
				} else {
					setStatus(update_id, "Fout")
					sendTelegramUnknown(text);
				}
				break;
			case "/ENERGIE":
				if (subcmd.length == 0) {
					setStatus(update_id, "Ok")
					sendTelegramAck(text);
					processCommandEnergie();
				} else {
					setStatus(update_id, "Fout")
					sendTelegramUnknown(text);
				}
				break;
			case "/PROG":
				if (subcmd.toUpperCase() === "C" || subcmd.toUpperCase() === "T" ||subcmd.toUpperCase() === "W" ||subcmd.toUpperCase() === "S") {
					setStatus(update_id, "Ok")
					sendTelegramAck(text);
					processCommandProgram(subcmd);
				} else {
					setStatus(update_id, "Fout")
					sendTelegramUnknown(text);
				}
				break;
          case "/AUTO":
				if (subcmd.toUpperCase() === "A" || subcmd.toUpperCase() === "U" ) {
					setStatus(update_id, "Ok")
					sendTelegramAck(text);
					processCommandAutoprogram(subcmd);
				} else {
					setStatus(update_id, "Fout")
					sendTelegramUnknown(text);
				}
				break;
          case "/THERM":
				var temp = parseFloat(subcmd);
				if (temp >=60) temp = temp / 10;
				if (temp >= 6.0 && temp <= 30.0 ) {
					setStatus(update_id, "Ok")
					temp =roundToHalf(temp);
					sendTelegramAck(text);
					processCommandChangetemp(temp);
				} else {
					setStatus(update_id, "Fout")
					sendTelegramUnknown(text);
				}
				break;
          default:
				if (debugOutput) console.log("********* ToonBot processCommand unknown command:" + cmd );
				setStatus(update_id, "Fout")
				sendTelegramUnknown(text);
        }
    }

    function setStatus(update_id, status) {
        if (debugOutput) console.log("********* ToonBot setStatus status: " + status);
        for (var n=0; n < toonbotScreen.toonBotListModel.count; n++) {
            if (toonbotScreen.toonBotListModel.get(n).updateId === update_id) {
                toonbotScreen.toonBotListModel.set(n, {"status": status});
				break;
            }
        }
    }

    function addCommandToList(command,update_id,firstName,chatid) {
        if (debugOutput) console.log("********* ToonBot addCommandToList");
        toonbotScreen.toonBotListModel.insert(0,{ time: (new Date().toLocaleString('nl-NL')),
                                updateId: update_id,
                                command: command,
                                status: "",
                                result: "",
								fromname: firstName,
								chatid: chatid});
		// remove oldest message from screen
        if (toonbotScreen.toonBotListModel.count >= numberMessagesOnScreen) {
            toonbotScreen.toonBotListModel.remove(numberMessagesOnScreen-1,1);
        }
    }

    function sendTelegramUnknown(cmd) {
        if (debugOutput) console.log("********* ToonBot sendTelegramUnknown");
        var messageText = "<b>Onbekend commando ontvangen: <i>" + cmd + "</i></b>\n" +
                          "ChatId:" + chatId + "\n" +
                          "De volgende commando's zijn mogelijk:\n" +
                          "  /info    Vraag Toon gegevens op\n" +
                          "  /energie Vraag energie verbruik op\n" +
                          "  /prog_c  Activeer programma Comfort\n" +
                          "  /prog_t  Activeer programma Thuis\n" +
                          "  /prog_w  Activeer programma Weg\n" +
                          "  /prog_s  Activeer programma Slapen\n" +
                          "  /auto_a  Zet auto programma aan\n" +
                          "  /auto_u  Zet auto programma uit\n" +
                          "  /therm_xx (6-30) Pas de thermostaat aan. Voeg een 5 toe voor een halve graad.\n\n" +
                          "  Voorbeeld:\n" +
                          "    /prog_s    voor programma Comfort\n" +
                          "    /therm_19  voor thermostaat op 19 graden\n" +
                          "    /therm_195 voor thermostaat op 19.5 graden\n";

        sendTelegramMessage(chatId, messageText);
    }

    function sendTelegramAck(cmd) {
        if (debugOutput) console.log("********* ToonBot sendTelegramAck");
        var messageText = "Toon heeft het commando: <b><i>" + cmd + "</i></b> ontvangen."

        sendTelegramMessage(chatId, messageText);
    }

    function sendTelegramMessage(chatid, messageText) {
        if (debugOutput) console.log("********* ToonBot sendTelegramMessage");

        if (chatid.length === 0) {
            if (debugOutput) console.log("********* ToonBot sendTelegramMessage no chatid. Cannot send message");
			return;
        }

        var text = encodeURI(messageText);

        if (debugOutput) console.log("********* ToonBot sendTelegramMessage Verzenden bericht: " + text);

        var xmlhttp = new XMLHttpRequest();
        xmlhttp.open("GET", "https://api.telegram.org/bot" + toonbotTelegramToken + "/sendMessage?chat_id=" + chatid + "&text=" + text + "&parse_mode=HTML", true);
        xmlhttp.onreadystatechange = function() {
            if (debugOutput) console.log("********* ToonBot sendTelegramMessage readyState: " + xmlhttp.readyState + " http status: " + xmlhttp.status);
            if (xmlhttp.readyState === XMLHttpRequest.DONE ) {
                if (xmlhttp.status === 200) {
                    if (debugOutput) console.log("********* ToonBot sendTelegramMessage response " + xmlhttp.responseText );
                    telegramData = JSON.parse(xmlhttp.responseText);

                    if (telegramData.count > 0 ) {
                        if (debugOutput) console.log("********* ToonBot sendTelegramMessage telegramData data found");
                    } else {
                        if (debugOutput) console.log("********* ToonBot sendTelegramMessage telegramData data found but empty");
                    }
                } else {
                    if (debugOutput) console.log("********* ToonBot sendTelegramMessage fout opgetreden.");
                }
            }
        }
        xmlhttp.send();
    }

	function stopGetTelegramUpdatesTimer() {
		getTelegramUpdatesTimer.stop();
	}

	function startGetTelegramUpdatesTimer() {
		getTelegramUpdatesTimer.start();
	}

   function readLastUpdateId(){   
		try {
			lastUpdateId = toonbotLastUpdateIdFile.read().trim();
			
		} catch(e) {
			lastUpdateId = "";
		}
		if (debugOutput) console.log("********* ToonBot readLastUpdateId id: " + lastUpdateId );
    }

    function saveLastUpdateId(id){  
		if (debugOutput) console.log("********* ToonBot saveLastUpdateId id: " + id);

		toonbotLastUpdateIdFile.write(id);

    }

	function alarmtest(chatid) {
		if (debugOutput) console.log("********* ToonBot alarmtest" );
		alarm(chatid, "rookmelder", "alarmTest");
	}

	function alarm(chatid, detectorName, state) {
		if (debugOutput) console.log("********* ToonBot alarm" );
		var msg = "Alarm van rookmelder: " + detectorName + " met status: " + state;
		sendTelegramMessage(chatid, msg);
	}

	function notifyUser(smokedetectorUUid, stateChangeTime, curState) {
		if (debugOutput) console.log("********* ToonBot notifyUser" );

		if ((curState === "alarmTest" || curState === "alarm") && (smokedetectorUUid !== p.lastNotifyUuid || stateChangeTime !== p.lastNotifyTime)) {
			var smokedetectorName = "";

			if (debugOutput) console.log("********* ToonBot notifyUser alarm activated" );

			// Fetch the smokedetector name from the known smokedetectors
			for (var i in linkedSmokedetectors) {
				if (linkedSmokedetectors[i].intAddr === smokedetectorUUid) {
					smokedetectorName = linkedSmokedetectors[i].name;
					break;
				}
			}

			// if the smoke detector is currently known
			if (smokedetectorName !== "" && enableSmokeAlarm ) {
				alarm(toonbotAlarmChatId, smokedetectorName, curState );

				p.lastNotifyTime = stateChangeTime;
				p.lastNotifyUuid = smokedetectorUUid;
			}
		
		}
	}


	function onEventScenariosChanged(update) {
		if (debugOutput) console.log("********* ToonBot onEventScenariosChanged update: " + update );
//		if (debugOutput) console.log("********* ToonBot onEventScenariosChanged json update: " + JSON.stringify(update) );

		if (debugOutput) console.log("********* ToonBot onEventScenariosChanged update.name: " + update.name );

/* just for debug
		var infoChild = update.child;
		while (infoChild) {
			if (debugOutput) console.log("********* ToonBot onEventScenariosChanged update while 2 infoChild.name: " + infoChild.name + " value: " + infoChild.text);
			var childChild = infoChild.child;
			while (childChild) {
				if (debugOutput) console.log("********* ToonBot onEventScenariosChanged update while 2 childChild.name: " + childChild.name + " value: " + childChild.text);
				childChild = childChild.sibling;
			}
			infoChild = infoChild.next;
//			infoChild = infoChild.sibling;
		}

*/

/*  just for debug

qml: ********* ToonBot onEventScenariosChanged update while 2 infoChild.name: scenario value:
qml: ********* ToonBot onEventScenariosChanged update while 2 childChild.name: states value:
qml: ********* ToonBot onEventScenariosChanged update while 2 childChild.name: devUuid value: 14cd1728-1e8a-41cc-9908-52291f2dd51a
qml: ********* ToonBot onEventScenariosChanged update while 2 childChild.name: intAddr value: smokeScenario
qml: ********* ToonBot onEventScenariosChanged update while 2 childChild.name: curState value: unknown
qml: ********* ToonBot onEventScenariosChanged update while 2 childChild.name: lastStateChangeTime value: 0
qml: ********* ToonBot onEventScenariosChanged update while 2 childChild.name: sType value: smokeScenario
qml: ********* ToonBot onEventScenariosChanged update while 2 infoChild.name: scenario value:
qml: ********* ToonBot onEventScenariosChanged update while 2 childChild.name: states value:
qml: ********* ToonBot onEventScenariosChanged update while 2 childChild.name: devUuid value: 8d520dfe-742c-4245-927e-12da65ee300e
qml: ********* ToonBot onEventScenariosChanged update while 2 childChild.name: intAddr value: batteryScenario
qml: ********* ToonBot onEventScenariosChanged update while 2 childChild.name: curState value: unknown
qml: ********* ToonBot onEventScenariosChanged update while 2 childChild.name: lastStateChangeTime value: 0
qml: ********* ToonBot onEventScenariosChanged update while 2 childChild.name: sType value: batteryScenario
qml: ********* ToonBot onEventScenariosChanged update while 2 infoChild.name: scenario value:
qml: ********* ToonBot onEventScenariosChanged update while 2 childChild.name: states value:
qml: ********* ToonBot onEventScenariosChanged update while 2 childChild.name: devUuid value: 7fe9d6a9-c6b2-43d9-8356-c07ee8c0c634
qml: ********* ToonBot onEventScenariosChanged update while 2 childChild.name: intAddr value: connectedScenario
qml: ********* ToonBot onEventScenariosChanged update while 2 childChild.name: curState value: unknown
qml: ********* ToonBot onEventScenariosChanged update while 2 childChild.name: lastStateChangeTime value: 0
qml: ********* ToonBot onEventScenariosChanged update while 2 childChild.name: sType value: connectedScenario


*/
		

		var scenario = update.getChild("scenario");
		for (; scenario; scenario = scenario.next) {
			if (scenario.getChildText("sType") === "smokeScenario") {

				var curState = scenario.getChildText("curState");
				var lastStateChangeByDev = scenario.getChildText("lastStateChangeByDev");
				var lastStateChangeTime = scenario.getChildText("lastStateChangeTime");
//TEST
//				curState = "alarm";
				if (debugOutput) console.log("********* ToonBot onEventScenariosChanged curState: " + curState );
				notifyUser(lastStateChangeByDev, lastStateChangeTime, curState);
			}
		}

//		initVarDone(2);

	}

	function parseSmokedetectors(update) {
		var smokedetectorNode = update.getChild("device", 0);
		var tmpSmokedetectors = [];

		if (debugOutput) console.log("********* ToonBot parseSmokedetectors update: " + update );
		if (debugOutput) console.log("********* ToonBot parseSmokedetectors json update: " + JSON.stringify(update) );
		if (debugOutput) console.log("********* ToonBot parseSmokedetectors update.name: " + update.name );

		while (smokedetectorNode) {
			var smokedetector = {};
			var childNode = smokedetectorNode.child;
			while (childNode) {
				smokedetector[childNode.name] = childNode.text;
				childNode = childNode.sibling;
				if (debugOutput) console.log("********* ToonBot parseSmokedetectors gevonden rookmelder: " + childNode.name );

			}
			tmpSmokedetectors.push(smokedetector);
			smokedetectorNode = smokedetectorNode.next;
		}
		linkedSmokedetectors = tmpSmokedetectors;

//		initVarDone(0);

	}


	BxtDiscoveryHandler {
		id: eventmgrDiscoHandler
		deviceType: "happ_eventmgr"
		onDiscoReceived: {
			p.eventmgrUuid = deviceUuid;
		}
	}

	BxtDatasetHandler {
		id: eventScenariosDsHandler
		dataset: "eventScenarios"
		discoHandler: eventmgrDiscoHandler
		onDatasetUpdate: onEventScenariosChanged(update)
	}

	BxtDatasetHandler {
		id: smokedetectorDataset
		dataset: "smokeDetectors"
		discoHandler: eventmgrDiscoHandler
		onDatasetUpdate: parseSmokedetectors(update)
	}
	
		
	Timer {               // needed for waiting toonbotScreen is loaded an functions can be used and refresh
		id: refreshGetMeTimer
		interval: 300000  // try again after 5 minutes
		triggeredOnStart: false
		running: false
		repeat: false
		onTriggered: {
			if (debugOutput) console.log("********* ToonBot refreshGetMeTimer start " + (new Date().toLocaleString('nl-NL')));
			refreshGetMe();
		}
	}

	
	Timer {
        id: getTelegramUpdatesTimer
        interval: 10 * 1000;		// first update after 10 seconds
        triggeredOnStart: false
        running: false
        repeat: true
        onTriggered: {
            if (debugOutput) console.log("********* ToonBot getTelegramUpdatesTimer triggered");
			interval = toonbotRefreshIntervalSeconds * 1000;
            if (enableRefresh) {
				if (refreshGetMeDone) {
					getTelegramUpdates();
				} else {
					refreshGetMe();
				}
			} else {
				if ( toonbotTelegramToken.length > 0 ) {
					tileStatus = "Verversing uitgeschakeld";
				}
			}
        }

    }
	
}
