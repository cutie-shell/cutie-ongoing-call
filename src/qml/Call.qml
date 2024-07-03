import Cutie
import Cutie.Wlc
import QtQuick
import QtMultimedia
import Qt5Compat.GraphicalEffects
import QtSensors

Item {
	id: root
    visible: true
    width: Screen.width
    height: Screen.height
	property var lineId: ""
	property var call: null
	property bool wasIncoming: false
	property bool answered: false
	property bool hangupMode: true
	property var callSoundId
	property string localISO: CutiePhonenumberHelper.MCCtoISO(
		CutieModemSettings.modems[0].networkCountryCode)

	function nameForNumber(number) {
		let sender = CutiePhonenumberHelper.createPhonenumber(number, root.localISO);
		if ("contacts" in contactStore.data)
			for (let i = 0; i < contactStore.data.contacts.length; i++) {
				let contact = contactStore.data.contacts[i]
				let contactNumber = CutiePhonenumberHelper.createPhonenumber(
					contact.PhoneNumber, root.localISO);
				if (sender.locallyEqualTo(contactNumber, root.localISO)) {
					return contact.FirstName + " " + contact.LastName;
				}
			}
		return number;
	}

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
		root.lineId = root.call.lineIdentification;
		root.wasIncoming = root.call.state === CutieCall.Incoming;
		if (root.wasIncoming) {
			root.callSoundId = 
				CutieFeedback.trigger(Application.name, "phone-incoming-call", {}, 0);
		}
	}
	
	ProximitySensor {
        id: proximity
        active: true
        onReadingChanged: {
			if (root.call.state !== CutieCall.Incoming)
				outputPowerManager.mode = !reading.near;
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

	CutieStore {
		id: contactStore
		appName: "cutie-contacts"
		storeName: "contacts"
	}

	CutiePageHeader {
		id: header
		title: nameForNumber(root.lineId)
		anchors.top: parent.top
	}

	CutieButton {
		id: answer
		visible: root.call.state === CutieCall.Incoming
		anchors.bottom: hangup.top
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.margins: 20
		text: qsTr("Answer")
		onClicked: {
			CutieFeedback.end(root.callSoundId);
			CutieModemSettings.modems[0].audioMode = 1;
			root.call.answer();
			root.answered = true;
			outputPowerManager.mode = !proximity.reading.near;
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
			CutieFeedback.end(root.callSoundId);
			root.call.hangup();
			CutieModemSettings.modems[0].audioMode = 0;
		}
	}

	Connections {
		target: root.call
		function onDisconnected(reason) {
			CutieFeedback.end(root.callSoundId);

			if (reason == "local") {
				toastHandler.show(qsTr("Call ended successfully"), 2000);
			}
			else if (reason == "remote") {
				toastHandler.show(qsTr("Call ended by the remote party"), 2000);
			}
			else {
				toastHandler.show(qsTr("Call ended by the network"), 2000);
			}

			let sender = CutiePhonenumberHelper.createPhonenumber(
				root.lineId, root.localISO);
			let data = logStore.data;
			let logEntries = data.entries;
			if (!logEntries) logEntries = [];
			logEntries.unshift({
				lineId: sender.format(CutiePhonenumber.International),
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
			outputPowerManager.mode = root.hangupMode;
			Qt.quit();
		}
	}
}
