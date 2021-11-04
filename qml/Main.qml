/*
 * Copyright (C) 2021  Leandro
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * TEst is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.12
import QtQuick.LocalStorage 2.12
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
//import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import io.thp.pyotherside 1.3

MainView {
    id: root
    objectName: 'mainView'
    applicationName: 'test.leandro'
    automaticOrientation: true

    /////////////////////////////////////////////////////////////////////////
    // General properties

    property int    size0_5GridUnit: units.gu(0.5)
    property int    size1GridUnit: units.gu(1)
    property int    size1_5GridUnit: units.gu(1.5)
    property int    size2GridUnit: units.gu(2)

    /////////////////////////////////////////////////////////////////////////
    // Setup de DB connection
  
    property string dbName: "ShoppingListDB" // name of the physical file (with or without full path) 
    property string version: "1.0"
    property string description: "DB for shippoing list app"
    property int    estimated_size: 10000

    property var    db: LocalStorage.openDatabaseSync(dbName, version, description, estimated_size)


    /////////////////////////////////////////////////////////////////////////
    // Update shopping list View and DB
    
    property string shoppingListTable: "ShoppingList"

    // Init ListModel with previously stored data
    function shoppinglist_init() {

        db.transaction(function(tx) {
                // ToDo: add DB version check
                // tx.executeSql('DROP TABLE ' + shoppingListTable);

                // Create the database if it doesn't already exist
                tx.executeSql('CREATE TABLE IF NOT EXISTS ' + shoppingListTable + ' (name TEXT, selected BOOLEAN)');

                // Get data from DB
                var rs = tx.executeSql('SELECT rowid, name, selected FROM ' + shoppingListTable);

                // Update ListModel
                for (var i = 0; i < rs.rows.length; i++) {
                    console.log(i, "", rs.rows.item(i).name, rs.rows.item(i).rowid)
                    mylist.appendItem(rs.rows.item(i).rowid, rs.rows.item(i).name, Boolean(rs.rows.item(i).selected))
                }
            }
        )
    }

    function shoppinglist_removeAll() {
        // Update DB
        db.transaction(function(tx) {
                tx.executeSql('DELETE FROM ' + shoppingListTable)
            }
        )
        // Update ListModel
        mylist.clear()
    }

    function shoppinglist_addItem(name, selected) {
        var result
        // Update DB
        db.transaction(function(tx) {
                result = tx.executeSql('INSERT INTO ' + shoppingListTable + ' (name, selected) VALUES( ?, ? )', [name, selected]);
            }
        )
        // Update ListModel
        mylist.appendItem(result[1], name, selected)
        console.log(name, " ", selected)
    }

    function shoppinglist_updateSelectionStatus(listIndex, dbRowid, selected) {
        console.log("UPDATE ", listIndex, " ", dbRowid, " ", selected)
        // Update DB
        db.transaction(function(tx) {
                tx.executeSql('UPDATE ' + shoppingListTable + ' SET selected=? WHERE rowid=?', [Boolean(selected), dbRowid])
            }
        )
        // Update ListModel
        // mylist.set(listIndex, {"selected": selected});
        mylist.setSelected(listIndex, selected)
        // // Refresh the list to update the selected status
        // listview.refresh()
        // mylist.sync()
    }

    function shoppinglist_removeSelectedItems() {
        // Update DB
        db.transaction(function(tx) {
                tx.executeSql('DELETE FROM ' + shoppingListTable + ' WHERE selected=?', [Boolean(true)])
            }
        )
        // Update ListModel
        for (var i=mylist.count-1; i >= 0 ; i--) {
            if (mylist.get(i).selected == true) {
                mylist.remove(i);
            }
        }
    }

    /////////////////////////////////////////////////////////////////////////
    // Define the ListModel to store the items
    
    ListModel {
        id: mylist

        function setSelected(index, value) {
            mylist.get(index).selected = Boolean(value)
            // Refresh the view to show the change
            listview.refresh()
        }

        function appendItem(rowid, name, selected) {
            console.log("XXX ", rowid, " ", name, " ", selected)
            mylist.append(
                {
                    "rowid": rowid,
                    "name": name,
                    "selected": Boolean(selected)
                }
            )
        }

        // ListElement {
        //     name: "Nothing here yet..."
        //     selected: false
        // }
    }

  
    Component {
        id: messageComponent
        Popover {
            id: popover
            Column {
                id: containerLayout
                anchors {
                    left: parent.left
                    top: parent.top
                    right: parent.right
                }
                // there is no equivalent yet to ListItem.Header
                // Old_ListItem.Header { text: "Standard list items" }
                ListItem {
                    // shall specify the height when Using ListItemLayout inside ListItem
                    height: somethingLayout.height + (divider.visible ? divider.height : 0)
                    ListItemLayout {
                        id: somethingLayout
                        title.text: "Do somethings"
                    }
                    onClicked: console.log("clicked on ListItem with onClicked implemented")
                }
                ListItem {
                    // shall specify the height when Using ListItemLayout inside ListItem
                    height: somethingElseLayout.height + (divider.visible ? divider.height : 0)
                    ListItemLayout {
                        id: somethingElseLayout
                        title.text: "Do somethings"
                        subtitle.text: "else"
                    }
                }
                ListItem {
                    // shall specify the height when Using ListItemLayout inside ListItem
                    height: closeBtn.height + (divider.visible ? divider.height : 0)
                    Button {
                        id: closeBtn
                        text: "Close button"
                        onClicked: PopupUtils.close(popover);
                    }
                }
            }
        }
    }

    // Component {
    //     id: dialog
    //     Dialog {
    //         id: dialogue
    //         title: "Remove all items"
    //         text: "Are you sure to remove all items?"
    //         Button {
    //             text: "Remove"
    //             color: theme.palette.normal.negative
    //             onClicked: {
    //                 PopupUtils.close(dialogue)
    //                 shoppinglist_removeAll()
    //             }
    //         }
    //         Button {
    //             text: "Cancel"
    //             onClicked: PopupUtils.close(dialogue)
    //         }
    //     }
    // }

    Component{
        id: removeAllDialog
        MyDialog{
            title: "Remove all items"
            text: "Are you sure?"
            buttonText: "Remove all items"
            onDoAction: shoppinglist_removeAll()
        }
    }

    Component{
        id: removeSelectedDialog
        MyDialog{
            title: "Remove selected items"
            text: "Are you sure?"
            buttonText: "Remove selected items"
            onDoAction: shoppinglist_removeSelectedItems()
        }
    }

    /////////////////////////////////////////////////////////////////////////
    // Define the page elements and their functionality

    Page {
        id: mainPage
        anchors.fill: parent
        Component.onCompleted: { 
            shoppinglist_init()
        } 

        header: PageHeader {
            id: header
            title: i18n.tr('Shopping list')
            StyleHints {
                    foregroundColor: UbuntuColors.black
                    backgroundColor: "lightgrey"
                    dividerColor: UbuntuColors.slate
                }
            }

        Item {
            anchors.top: header.bottom
            anchors.leftMargin: size1GridUnit
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right

            Label {
                id: label
                anchors.top: parent.top
                anchors.topMargin: size1GridUnit
                text: i18n.tr("Don't forget this:")
                verticalAlignment: Label.AlignVCenter
                horizontalAlignment: Label.AlignHCenter
            }


            Row {
                id: topRow
                height: textFieldInput.height // define height of this row, else the ListView will overwrite the row
                anchors.top: label.bottom
                anchors.topMargin: size1GridUnit
                anchors.left: parent.left
                anchors.right: parent.right
                // spacing: size1GridUnit
                // color: "lime"

                TextField {
                    id: textFieldInput
                    anchors.left: parent.left
                    anchors.right: buttonAdd.left
                    anchors.leftMargin: size1GridUnit
                    anchors.rightMargin: size2GridUnit
                    // maximumLength: 100B
                    // color: UbuntuColors.orange
                    StyleHints {
                        foregroundColor: UbuntuColors.black
                        backgroundColor: "orange"
                        dividerColor: UbuntuColors.red
                    }

                }

                Button {
                    id: buttonAdd
                    anchors.right: parent.right
                    anchors.rightMargin: size2GridUnit
                    text: "Add"
                    onClicked:
                        {
                            if (textFieldInput.text == "" ) {
                                return
                            }
                            shoppinglist_addItem(textFieldInput.text, false)
                        }
                }
            }

            ListView {
                id: listview
                function refresh() {
                    // Refresh the list to update the selected status
                    var tmp = model
                    model = null
                    model = tmp
                }
                width: parent.width
                // height: parent.height - label.height - topRow.height - bottomRow.height
                anchors.top: topRow.bottom
                anchors.topMargin: size1_5GridUnit
                anchors.bottom: bottomRow.top
                anchors.bottomMargin: size1_5GridUnit
                spacing: size0_5GridUnit
                model: mylist
                delegate: Text {
                    // text: testModel.get(index)
                    color: mylist.get(index).selected ?'red' : 'black'
                    font{strikeout: mylist.get(index).selected}
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            console.log(mylist.get(index).selected)
                            console.log("SELECTED ", JSON.stringify(mylist.get(index)))
                            shoppinglist_updateSelectionStatus(index, mylist.get(index).rowid, ! mylist.get(index).selected)
                        }
                    }
                text: "O " + name
                }
                add: Transition {
                    NumberAnimation { properties: "x,y"; from: 0; duration: 300 }
                }
                // NumberAnimation on x { to: 50; from: 0; duration: 1000 }
            }

            Row {
                id: bottomRow
                height: buttonRemoveAll.height
                // anchors.top: shoppingListItems.bottom
                anchors.bottom: parent.bottom
                anchors.left: parent.left 
                anchors.right: parent.right
                anchors.bottomMargin: size1GridUnit
                spacing: size1GridUnit

                Button {
                    id: buttonRemoveAll
                    text: "Remove all..."
                    anchors.bottom: parent.bottom
                    onClicked: {
                        // mylist.clear()
                        PopupUtils.open(removeAllDialog)
                        // shoppinglist_removeAll()
                    }
                }

                Button {
                    id: buttonCleanup
                    text: "Remove selected..."
                    // anchors.right: parent.right
                    anchors.rightMargin: size1GridUnit
                    anchors.bottom: parent.bottom

                    onClicked: {
                        console.log(mylist)
                        // mylist.remove(0,1)
                        console.log("list length " + mylist.count)
                        PopupUtils.open(removeSelectedDialog)
                        // for (var i=mylist.count-1; i >= 0 ; i--) {
                        //     // console.log("XXX " + mylist.get(i).attributes.get(0));
                        //     if (mylist.get(i).selected == true) {
                        //         mylist.remove(i);
                        //     }
                        //     console.log(i);
                        // }
                        // shoppinglist_removeSelectedItems()
                    }
                }
            }
        }
    }

}
