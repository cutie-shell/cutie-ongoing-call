import Cutie
import Cutie.Wlc
import QtQuick
import QtMultimedia
import Qt5Compat.GraphicalEffects

Item {
	id: root
    visible: true
    width: Screen.width
    height: Screen.height
	property var lineId: ""
	property var call: null
	property bool wasIncoming: false
	property bool answered: false
	property bool hangupMode: false

	Component.onDestruction: {
		CutieModemSettings.modems[0].audioMode = 0;
		root.call.hangup();
	}

	Component.onCompleted: {
		CutieModemSettings.modems.forEach((m) => {
			if (m.calls.length > 0 ) 
				root.call = m.calls[0];
		});

		if (!root.call) Qt.quit();
		root.lineId = root.call.data["LineIdentification"];
		root.wasIncoming = root.call.data["State"] === "incoming";
		if (root.wasIncoming) {
			callSound.play();
		}
	}

	OutputPowerManagerV1 {
		id: outputPowerManager

		onModeChanged: {
			if (root.wasIncoming) {
				root.hangupMode = outputPowerManager.mode;
				outputPowerManager.mode = true;
			}
		}
	}

    Image {
        id: wallpaper
		width: Screen.width
		height: Screen.height
        source: "file:/" + Atmosphere.path + "/wallpaper.jpg"
        fillMode: Image.PreserveAspectCrop
        visible: false
    }

    FastBlur {
        id: wallpaperBlur
        anchors.fill: wallpaper
        source: wallpaper
        radius: 70
    }

	CutieToastHandler {
        id: toastHandler
    }

	CutieStore {
		id: logStore
		appName: "cutie-phone"
		storeName: "callLog"
	}

	SoundEffect {
        id: callSound
        source: "qrc:/sounds/ringtone.wav"
        loops: SoundEffect.Infinite
    }

	CutiePageHeader {
		id: header
		title: root.lineId
		anchors.top: parent.top
	}

	CutieButton {
		id: answer
		visible: root.call.data["State"] === "incoming"
		anchors.bottom: hangup.top
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.margins: 20
		text: qsTr("Answer")
		onClicked: {
			callSound.stop();
			CutieModemSettings.modems[0].audioMode = 1;
			root.call.answer();
			root.answered = true;
		}
	}

	CutieButton {
		id: hangup
		anchors.bottom: parent.bottom
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.margins: 20
		text: qsTr("Hangup")
		color: "red"
		onClicked: {
			callSound.stop();
			root.call.hangup();
			CutieModemSettings.modems[0].audioMode = 0;
		}
	}

	Connections {
		target: root.call
		function onDisconnected(reason) {
			callSound.stop();

			if (reason == "local") {
				toastHandler.show(qsTr("Call ended successfully"), 2000);
			}
			else if (reason == "remote") {
				toastHandler.show(qsTr("Call ended by the remote party"), 2000);
			}
			else {
				toastHandler.show(qsTr("Call ended by the network"), 2000);
			}

			let data = logStore.data;
			let logEntries = data.entries;
			if (!logEntries) logEntries = [];
			logEntries.push({
				lineId: root.lineId,
				time:  Date.now(),
				type: (root.wasIncoming 
				? (root.answered ? "Incoming" : "Missed")
				: "Outgoing")
			});
			data.entries = logEntries;
			logStore.data = data;

			quitTimer.start();
		}
	}

	Timer {
		id: quitTimer
		interval: 2500
		onTriggered: {
			if (root.wasIncoming)
				outputPowerManager.mode = root.hangupMode;
			Qt.quit();
		}
	}
}
