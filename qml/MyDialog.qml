import QtQuick 2.12
import QtQuick.LocalStorage 2.12
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
//import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0

// Doesn't need to be imported in Main, as they are in the same directory
// Component {
    // id: dialog
    // property alias title: dialogue.title
    // property alias text: dialogue.text
    Dialog {
        id: dialogue
        property alias buttonText: actionButton.text
        signal doAction()
        // title: "Remove all items"
        // text: "Are you sure to remove all items?"
        Button {
            id: actionButton
            // text: "Remove"
            color: theme.palette.normal.negative
            onClicked: {
                PopupUtils.close(dialogue)
                // shoppinglist_removeAll()
                doAction()
            }
        }
        Button {
            text: "Cancel"
            onClicked: PopupUtils.close(dialogue)
        }
    }
// }