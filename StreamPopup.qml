import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

PopupCard {
  id: root
  required property string launcherPath
  property int selectedRow: -1
  property string errorText: ""
  readonly property var anchorWindow: anchorItem ? anchorItem.QsWindow.window : null
  readonly property color bg: Color.popups.background
  readonly property color border: Color.popups.border
  readonly property color accent: Color.accent
  readonly property color fg: Color.popups.text
  readonly property color muted: Color.muted
  readonly property string fontFamily: bar ? bar.fontFamily : "monospace"

  contentWidth: 342
  // PopupCard supplies the only frame and its own padding. Reserve the
  // StreamPiP content inset too, so the action row never clips at the bottom.
  contentHeight: Math.max(102, content.implicitHeight + 28)
  triggerMode: "hover"

  function close() { open = false }
  function refresh() { streams.clear(); selectedRow = -1; listProcess.running = true }
  function run(args) { actionProcess.command = ["/usr/bin/env", "bash", launcherPath].concat(args); actionProcess.running = true }
  function parseStream(line) {
    var fields = line.split("\t")
    if (fields.length >= 3) streams.append({ row: Number(fields[0]), name: fields[1], audio: fields[2] })
  }
  function select(row) { selectedRow = selectedRow === row ? -1 : row }
  function selectedStreamIsMuted() {
    return selectedRow > 0 && selectedRow <= streams.count
      && streams.get(selectedRow - 1).audio === "muted"
  }

  onOpenChanged: if (open) refresh()

  Item {
    id: card
    anchors.fill: parent
    opacity: root.open ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    Process {
      id: listProcess
      command: ["/usr/bin/env", "bash", root.launcherPath, "--list"]
      stdout: SplitParser { onRead: line => root.parseStream(line) }
    }
    Process { id: actionProcess; onExited: root.refresh() }
    Column {
      id: content
      width: parent.width - 28
      anchors.centerIn: parent
      spacing: 9
      Text { text: "▣  STREAM PIP"; color: root.fg; font.family: root.fontFamily; font.bold: true; font.pixelSize: 14 }
      Text { text: "Choose a saved live stream"; color: root.muted; font.family: root.fontFamily; font.pixelSize: 11 }
      Rectangle { width: parent.width; height: 1; color: root.border }
      Repeater {
        model: ListModel { id: streams }
        delegate: Rectangle {
          required property int row; required property string name; required property string audio
          width: content.width; height: 38; color: root.selectedRow === row ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.16) : "transparent"
          border.color: root.selectedRow === row ? root.accent : root.border; border.width: 1
          Row { anchors.fill: parent; anchors.margins: 9; spacing: 8
            Text { text: "▣"; color: root.fg; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
            Text { text: name; color: root.fg; font.family: root.fontFamily; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter; width: parent.width - status.width - 28; elide: Text.ElideRight }
            Text { id: status; text: audio === "muted" ? "MUTED" : "AUDIO"; color: root.muted; font.family: root.fontFamily; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
          }
          MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.select(row); onDoubleClicked: { root.run(["--launch", String(row)]); root.close() } }
        }
      }
      Text { visible: streams.count === 0; text: "No saved streams yet."; color: root.muted; font.family: root.fontFamily; font.pixelSize: 12 }
      Row { width: parent.width; spacing: 7
        PopupButton { label: "+ Add"; width: (parent.width - 14) / 3; onClicked: addForm.visible = !addForm.visible }
        PopupButton {
          // State labels describe the action: mute audible streams, restore
          // audio for muted ones.
          label: root.selectedStreamIsMuted() ? "Audio" : "Mute"
          width: (parent.width - 14) / 3
          enabled: root.selectedRow > 0
          onClicked: root.run(["--toggle", String(root.selectedRow)])
        }
        PopupButton { label: "Remove"; width: (parent.width - 14) / 3; enabled: root.selectedRow > 0; onClicked: root.run(["--delete", String(root.selectedRow)]) }
      }
      Column {
        id: addForm; width: parent.width; visible: false; spacing: 6
        Text { text: "ADD STREAM"; color: root.muted; font.family: root.fontFamily; font.pixelSize: 10; font.bold: true }
        PopupInput { id: nameInput; placeholder: "Name (e.g. Front door)" }
        PopupInput { id: urlInput; placeholder: "rtsp://camera.example/live" }
        Row { spacing: 8
          PopupButton { label: "Save"; width: 110; onClicked: { root.run(["--add", nameInput.text, urlInput.text, mutedToggle.on ? "muted" : "audible"]); nameInput.text = ""; urlInput.text = ""; addForm.visible = false } }
          PopupButton { id: mutedToggle; property bool on: false; label: on ? "Muted" : "Audio on"; width: 110; onClicked: on = !on }
        }
      }
      Text { visible: root.errorText.length > 0; text: root.errorText; color: "#ef4444"; font.family: root.fontFamily; font.pixelSize: 11 }
    }
  }
  component PopupButton: Rectangle {
    property string label: ""; signal clicked()
    height: 31; color: enabled ? "transparent" : Qt.rgba(root.muted.r, root.muted.g, root.muted.b, .1); border.color: root.border; border.width: 1
    Text { anchors.centerIn: parent; text: parent.label; color: parent.enabled ? root.fg : root.muted; font.family: root.fontFamily; font.pixelSize: 11 }
    MouseArea { anchors.fill: parent; enabled: parent.enabled; cursorShape: Qt.PointingHandCursor; onClicked: parent.clicked() }
  }
  component PopupInput: Rectangle {
    property alias text: field.text; property string placeholder: ""
    width: parent.width; height: 32; color: "transparent"; border.color: root.border; border.width: 1
    TextInput { id: field; anchors.fill: parent; anchors.margins: 8; color: root.fg; font.family: root.fontFamily; font.pixelSize: 11; clip: true }
    Text { anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter; visible: !field.text; text: parent.placeholder; color: root.muted; font.family: root.fontFamily; font.pixelSize: 11 }
  }
}
