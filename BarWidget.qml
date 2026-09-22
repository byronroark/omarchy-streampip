import QtQuick
import Quickshell
import qs.Ui

// Marketplace bar-widget entry point. The actual chooser is deliberately a
// separate shell script: it owns the private stream URL store and passes URLs
// to mpv as arguments, never through a shell-evaluated command string.
BarWidget {
  id: root
  moduleName: "byronroark.streampip"

  readonly property string launcherPath: decodeURIComponent(
    Qt.resolvedUrl("stream-pip").toString().replace("file://", "")
  )

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  StreamPopup { id: popup; anchorItem: button; bar: root.bar; launcherPath: root.launcherPath }
  function launch() { popup.open = !popup.open }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰑊"
    tooltipText: "Open Stream PiP"
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.LeftButton) root.launch()
    }
  }
}
