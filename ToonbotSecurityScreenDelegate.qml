import QtQuick 2.1
import BasicUIControls 1.0
import qb.components 1.0

Rectangle
{
	width: isNxt ? 320 : 250
	height: isNxt ? 44 : 36
	color: colors.canvas


	StandardButton {
		id: userName
		width: isNxt ? 250 : 200
		height: isNxt ? 35 : 28
		radius: 5
		text: name
		fontPixelSize: isNxt ? 25 : 20
		color: colors.background

		anchors {
			top: parent.top
			topMargin: isNxt ? 5 : 4
			left: parent.left
			leftMargin: isNxt ? 5 : 4
		}

		onClicked: {
		}
	}


	IconButton {
		id: deleteusersButton
		width: isNxt ? 35 : 28
		height: isNxt ? 35 : 28
		iconSource: "qrc:/tsc/icon_delete.png"
		anchors {
			left: userName.right
			leftMargin: 6
			top: userName.top
		}
		visible: (model.index >= 0)
		topClickMargin: 3
		onClicked: {
			qdialog.showDialog(qdialog.SizeLarge, "Bevestiging verwijdering gebruiker", "Wilt U deze gebruiker of groep echt verwijderen uit de lijst:\n\nNaam:   " + app.usersNames[model.index] + "\nChat id: " + app.usersChatIds[model.index],
					qsTr("Nee"), function(){ },
					qsTr("Ja"), function(){ 
						app.deleteUsers(model.index);
						app.toonbotSecurityScreen.initUsersList();
						app.saveSettings();
					});
			
		}
	}
}
