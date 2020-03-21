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
	}

	onCustomButtonClicked: {
		app.saveSettings();
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
	
	Text {
		id: title
		text: "Invoeren token van Telegram van aangemaakte Bot via BotFather."
       	width: isNxt ? 500 : 400
        wrapMode: Text.WordWrap
		font.pixelSize: isNxt ? 20 : 16
		font.family: qfont.semiBold.name
		color: colors.rbTitle

		anchors {
			left: tokenButton.right
			leftMargin: 20
			top: tokenButton.top
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
			topMargin: 30
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

	Text {
		id: uitlegInterval
		text: "Geeft aan hoe vaak Telegram om een update moet worden gevraagd in seconden en dus hoe snel Toon reageert. Zet deze niet te laag ivm belasting Toon. Advies: 60 sec of hoger."
       	width: isNxt ? 500 : 400
		wrapMode: Text.WordWrap
		anchors {
			left: intervalButton.right
			leftMargin: 20
			top: intervalLabel.top
		}
		font {
			family: qfont.semiBold.name
			pixelSize: isNxt ? 20 : 16
		}
		color: colors.rbTitle
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
			top: intervalLabel.bottom
			topMargin: 10
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
				app.stopGetTelegramUpdatesTimer();
				app.startGetTelegramUpdatesTimer();
			} else {
				app.enableRefresh = false;
				app.stopGetTelegramUpdatesTimer();
			}
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
			topMargin: 10
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
		id: uitlegToken
		text: "Voor de werking van deze app is het nodig dat er in Telegram een bot wordt aangemaakt.\n" +
			  "Ga hiervoor naar https://core.telegram.org/bots#6-botfather (of google 'Telegram bot') en volg de instructies. " +
			  "Maak een nieuwe bot aan en vul het ontvangen token hierboven bij token in.\n" +
			  "Voeg de bot toe in Telegram en stuur het commando '/start'. Na het opslaan van de instellingen zou de app moeten werken.\n\n" +
			  "Verstuur een willekeurig karakter in Telegram voor een overzicht van de commando's die je kunt gebruiken."
		  
       	width: parent.width - 50
		wrapMode: Text.WordWrap
		anchors {
			left: parent.left
			leftMargin: 20
			top: enableSystrayLabel.bottom
//			topMargin: 15
//			horizontalCenter: parent.horizontalCenter
		}
		font {
			family: qfont.semiBold.name
			pixelSize: isNxt ? 20 : 16
		}
		color: colors.rbTitle
	}


}