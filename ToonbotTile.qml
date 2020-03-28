import QtQuick 2.1
import qb.components 1.0

Tile {
	id: toonbotTile

	onClicked: {
		if ( app.toonbotTelegramToken.length == 0 ) {
			qdialog.showDialog(qdialog.SizeLarge, "Toon Bot configuratie mededeling", "Het token van de zelf te maken Telegram Bot is niet ingevuld. Ga naar het instellingen scherm.");	
		}
		stage.openFullscreen(app.toonbotScreenUrl);
	}


	Text {
		id: tiletitle
		text: "Toon Bot"
		anchors {
			baseline: parent.top
			baselineOffset: isNxt ? 30 : 24
			horizontalCenter: parent.horizontalCenter
		}
		font {
			family: qfont.bold.name
			pixelSize: isNxt ? 25 : 20
		}
		color: colors.waTileTextColor
       	visible: !dimState
	}

	Text {
		id: txtBot
		text: app.tileBotName
		color: colors.clockTileColor
		anchors {
			top: tiletitle.bottom
			horizontalCenter: parent.horizontalCenter
		}
		font.pixelSize: isNxt ? 20 : 16
		font.family: qfont.italic.name
       	visible: !dimState
		clip: true
	}


/*	
	Image {
		id: toonBotIcon
		source: "file:///qmf/qml/apps/toonbot/drawables/toonbotSmallNoBG.png"
		anchors {
			top: tiletitle.bottom
			horizontalCenter: parent.horizontalCenter
		}
		width: 25
		height: 25
		fillMode: Image.PreserveAspectFit
		cache: false
       	visible: !dimState
	}
*/
	Text {
		id: cmdText
		text: "Laatste commando"
		anchors {
			top: tiletitle.bottom
			topMargin: 25
			horizontalCenter: parent.horizontalCenter
		}
		font {
			family: qfont.bold.name
			pixelSize: isNxt ? 22 : 18
		}
		color: colors.waTileTextColor
       	visible: !dimState
	}

	Text {
		id: txtCmd
		text: app.tileLastcmd
		color: colors.clockTileColor
		anchors {
			top: cmdText.bottom
			horizontalCenter: parent.horizontalCenter
		}
		width : parent.width - 5
		horizontalAlignment : Text.AlignHCenter
		font.pixelSize: isNxt ? 20 : 16
		font.family: qfont.italic.name
       	visible: !dimState
		clip: true
	}

	Text {
		id: statusText
		text: "Status"
		anchors {
			bottom: txtStatus.top
			horizontalCenter: parent.horizontalCenter
		}
		font {
			family: qfont.bold.name
			pixelSize: isNxt ? 22 : 18
		}
		color: colors.waTileTextColor
       	visible: !dimState
	}

	Text {
		id: txtStatus
		text: app.tileStatus
		color: colors.clockTileColor
		anchors {
			bottom: parent.bottom
			bottomMargin: 10
			horizontalCenter: parent.horizontalCenter
		}
		font.pixelSize: isNxt ? 20 : 16
		font.family: qfont.italic.name
       	visible: !dimState
	}
}
