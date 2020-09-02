import QtQuick 2.1
import qb.components 1.0
import BasicUIControls 1.0;
 
Screen {
	id: toonbotSecurityScreen
	screenTitle: "Beheren gebruikers/groepen toegang"


	onShown: {
		initUsersList();
		if (app.numberOfUsersInList() == 0) {
			qdialog.showDialog(qdialog.SizeLarge, "Gebruikers", "Alle gebruikers zijn verwijderd. Als de security aan staat worden er geen enkel bericht meer verwerkt.\n", "Sluiten");							
		}

	}

	function initUsersList() {

		usersModel.clear();
		for (var i = 0; i < app.usersNames.length; i++) {
			usersModel.append({name: app.usersNames[i]});
		}

	}


	Text {
		id: gridText
		wrapMode: Text.WordWrap
		width: parent.width - 50
		text: "Deze gebruikers/groepen mogen berichten verzenden naar de ToonBot. Gebruikers/groepen kun je toevoegen door een bericht vanuit Telegram te laten sturen." + 
			  " Op het overzichtscherm kun je dan d.m.v. het +-symbool de gebruiker toevoegen.\nVergeet niet om de beveilging aan te zetten!\n" + 
			  "Klik op de prullenbak om een gebruiker of groep te verwijderen:"
		font.family: qfont.semiBold.name
		font.pixelSize: isNxt ? 20 : 16
		anchors {
			left: parent.left
			leftMargin: 40
			top: parent.top
			topMargin: 5		}
	}


	GridView {
		id: usersGridView

		model: usersModel
		delegate: ToonbotSecurityScreenDelegate {}

		interactive: false
		flow: GridView.TopToBottom
		cellWidth: isNxt ? 320 : 250
		cellHeight: isNxt ? 44 : 36
		height: isNxt ? parent.height - 150 : parent.height - 120
		width: parent.width
		anchors {
			top: gridText.bottom
			topMargin: isNxt ? 30 : 20
			left: gridText.left

		}
	}

	ListModel {
		id: usersModel
	}

}
