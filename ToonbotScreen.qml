import QtQuick 2.1
import qb.components 1.0
 

Screen {
	id: toonbotScreen
	screenTitle: "Laatste ontvangen Toon Bot berichten"

	property alias toonBotListModel: toonBotModel

	// Function (triggerd by a signal) updates the toonbot list model and the header text
	function updateToonbotList() {
		console.log("********* ToonBot updateToonbotList");
	}

	function refreshButtonEnabled(enabled) {
		refreshButton.enabled = enabled;
	}

	anchors.fill: parent

	Component.onCompleted: {
		app.toonbotUpdated.connect(updateToonbotList)
	}

	onShown: {
		console.log("********* ToonBot ToonbotScreen onShown");
		addCustomTopRightButton("Instellingen");
	}

	onCustomButtonClicked: {
		if (app.toonbotConfigurationScreen) app.toonbotConfigurationScreen.show();
	}

	function refreshData() {
		console.log("********* ToonBot refreshData");
		refreshButton.enabled = false;
		app.toonbotLastResponseStatus = 0;  // reset otherwise wrong messages shown

		if (app.refreshGetMeDone) {
			app.getTelegramUpdates();
		} else {
			app.refreshGetMe();
		}
		setEnableRefreshButtonTimer.start();  // enable button after a few seconds
	}

	Text {
		id: txtBot
		text: app.tileBotName
		color: colors.clockTileColor
		anchors {
			baseline: parent.top
			horizontalCenter: parent.horizontalCenter
		}
		font.pixelSize: isNxt ? 20 : 16
		font.family: qfont.italic.name
       	visible: !dimState
		clip: true
	}
	
	Item {
		id: header
		height: isNxt ? 55 : 45
		anchors.horizontalCenter: parent.horizontalCenter
		width: isNxt ? parent.width - 95 : parent.width - 76

		Text {
			id: headerText1
			text: "Datum/tijd"
			font.family: qfont.semiBold.name
			font.pixelSize: isNxt ? 25 : 20
			anchors {
				left: header.left
				bottom: parent.bottom
			}
		}
		Text {
			id: headerText2
			text: "Status"
			font.family: qfont.semiBold.name
			font.pixelSize: isNxt ? 25 : 20
			anchors {
				left: headerText1.right
				leftMargin: 45
				bottom: parent.bottom
			}
			width: isNxt ? 100 :70
		}
		Text {
			id: headerText3
			text: "Commando ontvangen"
			font.family: qfont.semiBold.name
			font.pixelSize: isNxt ? 25 : 20
			anchors {
				left: headerText2.right
				leftMargin: 5
				bottom: parent.bottom
			}
			width: isNxt ? 400 :300
		}
		Text {
			id: headerText4
			text: "Afzender"
			font.family: qfont.semiBold.name
			font.pixelSize: isNxt ? 25 : 20
			anchors {
				left: headerText3.right
				leftMargin: 15
				bottom: parent.bottom
			}
		}

		IconButton {
			id: refreshButton
			anchors.right: parent.right
			anchors.bottom: parent.bottom
			leftClickMargin: 3
			bottomClickMargin: 5
			iconSource: "qrc:/tsc/refresh.svg"
			onClicked: {
				// Get new Telegram data
				refreshData();
			}
		}
	}

    ListView {
            id: toonBotListView

            model: toonBotModel
            delegate: Rectangle
                {
                    width:  parent.width
                    height: 30

                    Text {
                        id: txtTime
                        text: time
                        font.pixelSize:  isNxt ? 20 : 16
                        font.family: qfont.regular.name
//                        color: colors.clockTileColor
                        anchors {
                            top: parent.top
                            left: parent.left
                            leftMargin: 5
                        }
                    }

                    Text {
                        id: txtStatus
                        text: status
                        font.pixelSize:  isNxt ? 20 : 16
                        font.family: qfont.regular.name
//                        color: colors.clockTileColor
                        anchors {
                            top: parent.top
                            left: txtTime.right
                            leftMargin: 5
                        }
                        width: isNxt ? 100 : 70
                    }

                    Text {
                        id: txtCmd
                        text: cmd + ":" + subcmd
                        font.pixelSize:  isNxt ? 20 : 16
                        font.family: qfont.regular.name
//                        color: colors.clockTileColor
                        anchors {
                            top: parent.top
                            left: txtStatus.right
                            leftMargin: 5
                        }
						clip: true
                        width: isNxt ? 400 :300
                    }

                    Text {
                        id: txtFirstname
                        text: fromname
                        font.pixelSize:  isNxt ? 20 : 16
                        font.family: qfont.regular.name
//                        color: colors.clockTileColor
                        anchors {
                            top: parent.top
                            left: txtCmd.right
                            leftMargin: 15
							right: parent.right
							rightMargin: 5
                        }
						clip: true
                    }

                }

            visible: true

            anchors {
                top: header.bottom
                bottom: parent.bottom
                left: parent.left
                right: parent.right
                topMargin: 5
                leftMargin:  20
                rightMargin:  20
            }
    }


	Text {
		id: footer
		text: "Laatste gelukte update van: " + ((app.toonbotLastUpdateTime.length == 0 ) ? "N/A" : app.toonbotLastUpdateTime) + ". Verversing elke " + app.toonbotRefreshIntervalSeconds + " sec. Laatste responscode: " + app.toonbotLastResponseStatus
		anchors {
			baseline: parent.bottom
			baselineOffset: -5
			right: parent.right
			rightMargin: 15
		}
		font {
			pixelSize: isNxt ? 18 : 15
			family: qfont.italic.name
		}
	}

    ListModel {
            id: toonBotModel
    }


	// Timer for enable refresh button after 5 seconds
    Timer {
        id: setEnableRefreshButtonTimer
        interval: 5000        // 5 seconds
        triggeredOnStart: false
        running: false
        repeat: false
        onTriggered: {
            console.log("********* ToonBot setEnableRefreshButtonTimer start");
            refreshButton.enabled = true;
        }

    }


}
