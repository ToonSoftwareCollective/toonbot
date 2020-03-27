import QtQuick 2.1
import qb.components 1.0
import qb.base 1.0
import FileIO 1.0
 
App {
	id: toonbotApp

	property url tileUrl : "ToonbotTile.qml"
	property url thumbnailIcon: "qrc:/tsc/toonbotSmallNoBG.png"
	
	property url toonbotScreenUrl : "ToonbotScreen.qml"
	property url toonbotConfigurationScreenUrl : "ToonbotConfigurationScreen.qml"
	property url trayUrl : "ToonbotTray.qml"

	property ToonbotConfigurationScreen toonbotConfigurationScreen
	property ToonbotScreen toonbotScreen

	// for Tile
    property string tileStatus : "Wachten op data....."
    property string tileLastcmd : ""
    property string tileBotName : ""

    property variant telegramData
    property variant getMeData
	property variant thermostatInfoData

    property string lastUpdateId		// id from last receivede telegram message, so last message will not be retrieved again
    property string chatId				// used to send message to right chat

	// settings
    property string toonbotTelegramToken : ""			// Telegram Bot token 
    property int toonbotRefreshIntervalSeconds  : 60	// interval to retrieve telegram messages
	property bool enableSystray : false
	property bool enableRefresh : false					// enable retrieving Telegram messages

	// user settings from config file
	property variant toonbotSettingsJson 

	property string toonbotLastUpdateTime
	property string toonbotLastResponseStatus : "N/A"

	property bool refreshGetMeDone : false					// GetMe succesvol received
	property int numberMessagesOnScreen : (isNxt ? 15 : 12)  

	property bool debugOutput : false						// Show console messages. Turn on in settings file !


	// signal, used to update the listview 
	signal toonbotUpdated()


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
		registry.registerWidget("systrayIcon", trayUrl, this, "toonbotTray");
	}

	function saveSettings() {
		// save user settings
		if (debugOutput) console.log("********* ToonBot saveSettings");

		var tmpTrayIcon = "";
		var tmpRefreshOn = "";
		var tmpDebugOn = "";
		
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

		
 		var tmpUserSettingsJson = {
			"Token"      				: toonbotTelegramToken,
			"RefreshIntervalSeconds"	: toonbotRefreshIntervalSeconds,
 			"TrayIcon"      			: tmpTrayIcon,
			"RefreshOn"					: tmpRefreshOn,
			"DebugOn"					: tmpDebugOn
		}

  		var doc = new XMLHttpRequest();
   		doc.open("PUT", "file:///mnt/data/tsc/toonbot.userSettings.json");
   		doc.send(JSON.stringify(tmpUserSettingsJson ));
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
			try {
				fromName = telegramData['result'][i]['message']['from']['first_name'];
				fromName = fromName + " " + telegramData['result'][i]['message']['from']['last_name'];
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

			addCommandToList(text, update_id, fromName);
			processCommand(text,update_id);

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

		sendTelegramMessage(message);
	
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
	
    function processCommand(text,update_id) {
		var subcmd;
		var cmd;

		if (debugOutput) console.log("********* ToonBot processCommand command: " + text );

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

    function addCommandToList(command,update_id,firstName) {
        if (debugOutput) console.log("********* ToonBot addCommandToList");
        toonbotScreen.toonBotListModel.insert(0,{ time: (new Date().toLocaleString('nl-NL')),
                                updateId: update_id,
                                command: command,
                                status: "",
                                result: "",
								fromname: firstName });
		// remove oldest message from screen
        if (toonbotScreen.toonBotListModel.count >= numberMessagesOnScreen) {
            toonbotScreen.toonBotListModel.remove(numberMessagesOnScreen-1,1);
        }
    }

    function sendTelegramUnknown(cmd) {
        if (debugOutput) console.log("********* ToonBot sendTelegramUnknown");
        var messageText = "<b>Onbekend commando ontvangen: <i>" + cmd + "</i></b>\n" +
                          "De volgende commando's zijn mogelijk:\n" +
                          "  /info    Vraag Toon gegevens op\n" +
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

        sendTelegramMessage(messageText);
    }

    function sendTelegramAck(cmd) {
        if (debugOutput) console.log("********* ToonBot sendTelegramAck");
        var messageText = "Toon heeft het commando: <b><i>" + cmd + "</i></b> ontvangen."

        sendTelegramMessage(messageText);
    }

    function sendTelegramMessage(messageText) {
        if (debugOutput) console.log("********* ToonBot sendTelegramMessage");

        if (chatId.length === 0) {
            if (debugOutput) console.log("********* ToonBot sendTelegramMessage no chatId. Cannot send message");
			return;
        }

        var text = encodeURI(messageText);

        if (debugOutput) console.log("********* ToonBot sendTelegramMessage Verzenden bericht: " + text);

        var xmlhttp = new XMLHttpRequest();
        xmlhttp.open("GET", "https://api.telegram.org/bot" + toonbotTelegramToken + "/sendMessage?chat_id=" + chatId + "&text=" + text + "&parse_mode=HTML", true);
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

		var doc = new XMLHttpRequest();
		doc.open("PUT", "file:///tmp/toonbot-lastUpdateId.txt");
		doc.send(id);
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
