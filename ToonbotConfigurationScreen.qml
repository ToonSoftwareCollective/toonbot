import QtQuick 2.1
import qb.components 1.0
import BasicUIControls 1.0;
 
Screen {
	id: toonbotConfigurationScreen
	screenTitle: "Instellingen ToonBot app"

	property string qrCodeID


	onShown: {
		addCustomTopRightButton("Opslaan");
		enableSystrayToggle.isSwitchedOn = app.enableSystray;
		enableRefreshToggle.isSwitchedOn = app.enableRefresh;
		tokenLabel.inputText = app.toonbotTelegramToken;
		intervalLabel.inputText = app.toonbotRefreshIntervalSeconds;
		enableSecurityToggle.isSwitchedOn = app.enableSecurity;
		alarmChatIdLabel.inputText = app.toonbotAlarmChatId;
		if (app.toonbotAlarmChatId.length === 0 ) {
			app.enableSmokeAlarm = false;
		}
		enableSmokeAlarmToggle.isSwitchedOn = app.enableSmokeAlarm;
	}

	onCustomButtonClicked: {
		app.saveSettings();
		app.refreshGetMeDone = false;   // Start over. needed when token is changed
		hide();
		app.toonbotScreen.refreshData();
	}

	function validateCoordinate(text, isFinalString) {
		return null;
	}

	function saveToken(text) {
		if (text) {
			app.toonbotTelegramToken = text;
			tokenLabel.inputText = app.toonbotTelegramToken;
		}
	}

	function saveInterval(text) {
		if (text) {
			app.toonbotRefreshIntervalSeconds = parseInt(text);
			intervalLabel.inputText = app.toonbotRefreshIntervalSeconds;
		}
	}

	function saveAlarmChatId(text) {
		if (text) {
			app.toonbotAlarmChatId = text;
			alarmChatIdLabel.inputText = app.toonbotAlarmChatId;
		}
	}

	
	EditTextLabel4421 {
		id: tokenLabel
		width: isNxt ? 350 : 280
		height: isNxt ? 45 : 35
		leftText: "Token:"
		leftTextAvailableWidth: isNxt ?  175 : 140

		anchors {
			left: parent.left
			leftMargin: 40
			top: parent.top
			topMargin: 10
		}

		onClicked: {
			qkeyboard.open("Telegram Bot token", tokenLabel.inputText, saveToken);
		}
	}

	IconButton {
		id: tokenButton
		width: isNxt ? 50 : 40

		iconSource: "qrc:/tsc/edit.png"

		anchors {
			left: tokenLabel.right
			leftMargin: 6
			top: tokenLabel.top
		}

		bottomClickMargin: 3
		onClicked: {
			qkeyboard.open("Telegram Bot token", tokenLabel.inputText, saveToken);
		}
	}

	StandardButton {
		id: btnHelpTokenTemp
		text: "?"
		anchors.left: tokenButton.right
		anchors.bottom: tokenButton.bottom
		anchors.leftMargin: 10
		onClicked: {
			qdialog.showDialog(qdialog.SizeLarge, "Token Telegram", "Invoeren token van Telegram van de aangemaakte Bot via BotFather. Zie ook onder knop uitleg\n", "Sluiten");
		}
	}



	EditTextLabel4421 {
		id: intervalLabel
		width: tokenLabel.width
		height: isNxt ? 45 : 35
		leftText: "Refresh:"
		leftTextAvailableWidth: isNxt ?  175 : 140

		anchors {
			left: tokenLabel.left
			top: tokenLabel.bottom
			topMargin: 12
		}

		onClicked: {
			qnumKeyboard.open("Ververs interval Telegram in seconden", intervalLabel.inputText, app.toonbotRefreshIntervalSeconds, 1 , saveInterval, validateCoordinate);
		}
	}

	IconButton {
		id: intervalButton
		width: isNxt ? 50 : 40
		iconSource: "qrc:/tsc/edit.png"

		anchors {
			left: intervalLabel.right
			leftMargin: 6
			top: intervalLabel.top
		}

		topClickMargin: 3
		onClicked: {
			qnumKeyboard.open("Ververs interval Telegram in seconden", intervalLabel.inputText, app.toonbotRefreshIntervalSeconds, 1 , saveInterval, validateCoordinate);
		}
	}

	StandardButton {
		id: btnHelpIntervalTemp
		text: "?"
		anchors.left: intervalButton.right
		anchors.bottom: intervalButton.bottom
		anchors.leftMargin: 10
		onClicked: {
			qdialog.showDialog(qdialog.SizeLarge, "Refresh interval", "Geeft aan hoe vaak Telegram om een update moet worden gevraagd in seconden en dus hoe snel Toon reageert. Zet deze niet te laag ivm belasting Toon. Advies: 60 sec of hoger.\n", "Sluiten");
		}
	}

	EditTextLabel4421 {
		id: alarmChatIdLabel
		width: tokenLabel.width
		height: isNxt ? 45 : 35
		leftText: "Alarm ChatId:"
		leftTextAvailableWidth: isNxt ?  175 : 140

		anchors {
			left: tokenLabel.left
			top: intervalLabel.bottom
			topMargin: 12
		}

		onClicked: {
			qkeyboard.open("Alarm ChatId", alarmChatIdLabel.inputText, saveAlarmChatId);
		}
	}

	IconButton {
		id: alarmChatIdButton
		width: isNxt ? 50 : 40

		iconSource: "qrc:/tsc/edit.png"

		anchors {
			left: alarmChatIdLabel.right
			leftMargin: 6
			top: alarmChatIdLabel.top
		}

		bottomClickMargin: 3
		onClicked: {
			qkeyboard.open("Alarm ChatId", alarmChatIdLabel.inputText, saveAlarmChatId);
		}
	}

	StandardButton {
		id: btnHelpAlarmChatIdTemp
		text: "?"
		anchors.left: alarmChatIdButton.right
		anchors.bottom: alarmChatIdButton.bottom
		anchors.leftMargin: 10
		onClicked: {
			qdialog.showDialog(qdialog.SizeLarge, "Alarm ChatId", "Het ChatId van de Telegram gebruiker of groep waar een alarm bericht naar toe wordt gestuurd als de rookmelder afgaat.\n" +
									"Je kunt het chatid achterhalen door onbekend commando (bijv /blabla) te sturen naar de telegram Bot. ChatId staat op de 2de regel van de respons.", "Sluiten");
		}
	}

	StandardButton {
		id: testAlarmButton
		text: "Stuur test alarm bericht"

		anchors {
			left: btnHelpAlarmChatIdTemp.right
			leftMargin: 20
			top: btnHelpAlarmChatIdTemp.top
		}

		rightClickMargin: 2
		bottomClickMargin: 5

		selected: false
		visible : (app.toonbotAlarmChatId.length > 0 ? true : false )

		onClicked: {
			app.alarmtest(app.toonbotAlarmChatId);
		}
	}


	Text {
		id: enableRefreshLabel
		width: isNxt ? 240 : 200
		height: isNxt ? 45 : 36
		text: "Ontvang berichten"
		font.family: qfont.semiBold.name
		font.pixelSize: isNxt ? 25 : 20
		anchors {
			left: tokenLabel.left
			top: alarmChatIdLabel.bottom
			topMargin: 5
		}
	}
	
	OnOffToggle {
		id: enableRefreshToggle
		height: isNxt ? 45 : 36
		anchors.left: enableRefreshLabel.right
		anchors.leftMargin: 10
		anchors.top: enableRefreshLabel.top
		leftIsSwitchedOn: false
		onSelectedChangedByUser: {
			if (isSwitchedOn) {
				app.enableRefresh = true;
			} else {
				app.enableRefresh = false;
			}
		}
	}

	StandardButton {
		id: btnHelpRefresh
		text: "?"
		anchors.left: enableRefreshToggle.right
		anchors.bottom: enableRefreshToggle.bottom
		anchors.leftMargin: 10
		onClicked: {
			qdialog.showDialog(qdialog.SizeLarge, "Het ontvangen van Telegram berichten", "Als je deze uitzet worden er geen Telegram berichten meer uitgelezen.\n", "Sluiten");
		}
	}


	Text {
		id: enableSystrayLabel
		width: isNxt ? 240 : 200
		height: isNxt ? 45 : 36
		text: "Icon in systray"
		font.family: qfont.semiBold.name
		font.pixelSize: isNxt ? 25 : 20
		anchors {
			left: tokenLabel.left
			top: enableRefreshLabel.bottom
			topMargin: 3
		}
	}
	
	OnOffToggle {
		id: enableSystrayToggle
		height: isNxt ? 45 : 36
		anchors.left: enableSystrayLabel.right
		anchors.leftMargin: 10
		anchors.top: enableSystrayLabel.top
		leftIsSwitchedOn: false
		onSelectedChangedByUser: {
			if (isSwitchedOn) {
				app.enableSystray = true;
			} else {
				app.enableSystray = false;
			}
		}
	}

	Text {
		id: enableSecurityLabel
		width: isNxt ? 240 : 200
		height: isNxt ? 45 : 36
		text: "Beveiliging aan"
		font.family: qfont.semiBold.name
		font.pixelSize: isNxt ? 25 : 20
		anchors {
			left: tokenLabel.left
			top: enableSystrayLabel.bottom
			topMargin: 3
		}
	}
	
	OnOffToggle {
		id: enableSecurityToggle
		height: isNxt ? 45 : 36
		anchors.left: enableSecurityLabel.right
		anchors.leftMargin: 10
		anchors.top: enableSecurityLabel.top
		leftIsSwitchedOn: false
		onSelectedChangedByUser: {
			if (isSwitchedOn) {
				app.enableSecurity = true;
			} else {
				app.enableSecurity = false;
			}
		}
	}

	StandardButton {
		id: btnHelpSecurity
		text: "?"
		anchors.left: enableSecurityToggle.right
		anchors.bottom: enableSecurityToggle.bottom
		anchors.leftMargin: 10
		onClicked: {
			qdialog.showDialog(qdialog.SizeLarge, "Beveiliging", "Als je deze uitzet kan iedereen, die de ToonBot weet te vinden, commando's sturen en worden deze verwerkt. \n" +
												  "Door deze aan te zetten worden alleen berichten van gebruikers of groepen die in de toegestane gebruikerslijst staan verwerkt." +
												  " Berichten van anderen worden wel getoond maar niet verwerkt. ", "Sluiten");
		}
	}


	StandardButton {
		id: securityButton
		text: "Beheer toegang"

		anchors {
			left: intervalButton.right
			leftMargin: 20
			top: enableSecurityLabel.top
		}

		rightClickMargin: 2
		bottomClickMargin: 5

		selected: false
		visible : true

		onClicked: {
			if (app.toonbotSecurityScreen) {
				app.toonbotSecurityScreen.show();
			}
		}
	}


	Text {
		id: enableSmokeAlarmLabel
		width: isNxt ? 240 : 200
		height: isNxt ? 45 : 36
		text: "Alarm rookmelder"
		font.family: qfont.semiBold.name
		font.pixelSize: isNxt ? 25 : 20
		anchors {
			left: tokenLabel.left
			top: enableSecurityLabel.bottom
			topMargin: 3
		}
	}
	
	OnOffToggle {
		id: enableSmokeAlarmToggle
		height: isNxt ? 45 : 36
		anchors.left: enableSmokeAlarmLabel.right
		anchors.leftMargin: 10
		anchors.top: enableSmokeAlarmLabel.top
		leftIsSwitchedOn: false
		enabled : (app.toonbotAlarmChatId.length > 0 ? true : false ) 
		onSelectedChangedByUser: {
			if (isSwitchedOn) {
				app.enableSmokeAlarm = true;
			} else {
				app.enableSmokeAlarm = false;
			}
		}
	}

	StandardButton {
		id: btnHelpSmokeAlarm
		text: "?"
		anchors.left: enableSmokeAlarmToggle.right
		anchors.bottom: enableSmokeAlarmToggle.bottom
		anchors.leftMargin: 10
		onClicked: {
			qdialog.showDialog(qdialog.SizeLarge, "Rookalarm", "Dit werkt alleen als je een gekoppelde rookmelder hebt. Als je deze toggle aanzet dan ontvang je bij een alarm (ook bij een test) een Telegram bericht. \n" +
												  "Het alarm wordt gestuurd naar de Telegram gebruiker of groep wat hierboven als ChatId staat ingesteld.\n" +
												  "Vul eerst het ChatId in om deze toggle te kunnen gebruiken.", "Sluiten");
		}
	}





	StandardButton {
		id: btnHelpUitleg
		text: "Uitleg"
		anchors.left: parent.left
		anchors.bottom: parent.bottom
		anchors.bottomMargin: 10
		anchors.leftMargin: 25
		width: parent.width - 50
		onClicked: {
			qdialog.showDialog(qdialog.SizeLarge, "Uitleg", "Voor de werking van deze app is het nodig dat er in Telegram een bot wordt aangemaakt.\n" +
											  "Ga hiervoor naar https://core.telegram.org/bots#6-botfather (of google 'Telegram bot') en volg de instructies. " +
											  "Maak een nieuwe bot aan en vul het ontvangen token hierboven bij token in.\n" +
											  "Voeg de bot toe in Telegram en stuur het commando '/start'. Na het opslaan van de instellingen zou de app moeten werken. " +
											  "Voor meer informatie zoek dan naar 'domoticaforum toonbot' (https://www.domoticaforum.eu/viewtopic.php?f=99&t=12734)\n" +
											  "Verstuur een willekeurig karakter in Telegram voor een overzicht van de commando's die je kunt gebruiken.", "Sluiten");
		}
	}

}
