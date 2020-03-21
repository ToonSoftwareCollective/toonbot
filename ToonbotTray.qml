import QtQuick 2.1

import qb.components 1.0
import qb.base 1.0

SystrayIcon {
	id: toonbotSystrayIcon
	posIndex: 9000
	property string objectName: "toonbotSystray"
	visible: app.enableSystray

	onClicked: {
		stage.openFullscreen(app.toonbotScreenUrl);
	}

	Image {
		id: imgNewMessage
		anchors.centerIn: parent
		source: "file:///qmf/qml/apps/toonbot/drawables/toonbotSmallNoBG.png"
		width: 25
		height: 25
		fillMode: Image.PreserveAspectFit

	}
}
