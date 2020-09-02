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
		text: "Beveilging aan"
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
		id: uitlegToken
		text: "Voor de werking van deze app is het nodig dat er in Telegram een bot wordt aangemaakt.\n" +
			  "Ga hiervoor naar https://core.telegram.org/bots#6-botfather (of google 'Telegram bot') en volg de instructies. " +
			  "Maak een nieuwe bot aan en vul het ontvangen token hierboven bij token in.\n" +
			  "Voeg de bot toe in Telegram en stuur het commando '/start'. Na het opslaan van de instellingen zou de app moeten werken. " +
			  "Voor meer informatie zoek dan naar 'domoticaforum toonbot' (https://www.domoticaforum.eu/viewtopic.php?f=99&t=12734)\n" +
			  "Verstuur een willekeurig karakter in Telegram voor een overzicht van de commando's die je kunt gebruiken."
		  
       	width: parent.width - 50
		wrapMode: Text.WordWrap
		anchors {
			left: parent.left
			leftMargin: 20
			top: enableSecurityLabel.bottom
		}
		font {
			family: qfont.semiBold.name
			pixelSize: isNxt ? 20 : 16
		}
		color: colors.rbTitle
	}


}
