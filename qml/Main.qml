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
    // Setup de DB connection
    
    property string dbName: "ShoppingListDB" // name of the physical file (with or without full path) 
    property string version: "1.0"
    property string description: "DB for shippoing list app"
    property int    estimated_size: 10000

    property var db: LocalStorage.openDatabaseSync(dbName, version, description, estimated_size)


    /////////////////////////////////////////////////////////////////////////
    // Update shopping list View and DB
    
    property string shoppingListTable: "ShoppingList"

    // Init ListModel with previously stored data
    function shoppinglist_init() {

        db.transaction(
            function(tx) {
                // Create the database if it doesn't already exist
                // tx.executeSql('DROP TABLE ' + shoppingListTable);
                tx.executeSql('CREATE TABLE IF NOT EXISTS ' + shoppingListTable + ' (name TEXT, selected BOOLEAN)');

                // Get data from DB
                var rs = tx.executeSql('SELECT rowid, name, selected FROM ' + shoppingListTable);

                // Update ListModel
                for (var i = 0; i < rs.rows.length; i++) {
                    console.log(i, "", rs.rows.item(i).name, rs.rows.item(i).rowid)
                    appendToListModel_myList(rs.rows.item(i).rowid, rs.rows.item(i).name, Boolean(rs.rows.item(i).selected))
                }
            }
        )
    }

    function shoppinglist_clear() {
        // Update DB
        db.transaction(
            function(tx) {
                tx.executeSql('DELETE FROM ' + shoppingListTable)
            }
        )
        // Update ListModel
        mylist.clear()
    }

    function shoppinglist_addItem(name, selected) {
        var result
        // Update DB
        db.transaction(
            function(tx) {
                result = tx.executeSql('INSERT INTO ' + shoppingListTable + ' (name, selected) VALUES( ?, ? )', [name, selected]);
            }
        )
        // Update ListModel
        appendToListModel_myList(result[1], name, selected)
        console.log(name, " ", selected)
    }

    function shoppinglist_updateSelectionStatus(listIndex, dbRowid, selected) {
        console.log("UPDATE ", listIndex, " ", dbRowid, " ", selected)
        // Update DB
        db.transaction(
            function(tx) {
                tx.executeSql('UPDATE ' + shoppingListTable + ' SET selected=? WHERE rowid=?', [Boolean(selected), dbRowid])
            }
        )
        // Update ListModel
        mylist.get(listIndex).selected = ! mylist.get(listIndex).selected;
    }

    function shoppinglist_removeSelectedItems() {
        // Update DB
        db.transaction(
            function(tx) {
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
        // ListElement {
        //     name: "Nothing here yet..."
        //     selected: false
        // }
    }

    function appendToListModel_myList(rowid, name, selected) {
        console.log("XXX ", rowid, " ", name, " ", selected)
        mylist.append(
            {
                "rowid": rowid,
                "name": name,
                "selected": Boolean(selected)
            }
        )
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

        // Column {
        //     anchors.topMargin: 5
        //     anchors.leftMargin: 10
            
        //     anchors {
        //         top: header.bottom
        //         left: parent.left
        //         right: parent.right
        //         bottom: parent.bottom
        //     }

            // Column{
            //     id: shoppingListItems
            //     spacing: 10
            //     anchors.top: parent.top
            //     anchors.bottom: parent.bottom

            //     anchors {
            //         left: parent.left
            //         right: parent.right
            //     }

                Label {
                    id: label
                    anchors.top: header.bottom
                    text: i18n.tr("Don't forget this:")
                    verticalAlignment: Label.AlignVCenter
                    horizontalAlignment: Label.AlignHCenter
                }

                Row {
                    id: topRow
                    anchors.top: label.bottom
                    anchors.topMargin: 10
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: 10

                    TextField {
                        id: textFieldInput
                        // anchors.left: parent.left
                        // anchors.right: buttonAdd.left
                        anchors.leftMargin: 20
                        anchors.rightMargin: 20
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
                        // anchors.right: parent.right
                        anchors.rightMargin: 20
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

            //   Row {
            //     anchors.top: topRow.bottom
            //     anchors.bottom: parent.bottom

                ListView {
                    width: parent.width
                    // height: parent.height - label.height - topRow.height - bottomRow.height
                    anchors.top: topRow.bottom
                    anchors.topMargin: 10
                    anchors.bottom: bottomRow.top
                    anchors.bottomMargin: 10
                    spacing: 5
                    model: mylist
                    delegate: Text {
                        // text: testModel.get(index)
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                console.log(mylist.get(index).selected)
                                console.log("SELECTED ", JSON.stringify(mylist.get(index)))
                                for (const prop in parent) {
                                  console.log("PARENT ", prop)
                                }
                                shoppinglist_updateSelectionStatus(index, mylist.get(index).rowid, ! mylist.get(index).selected)
                                // mylist.get(index).selected = ! mylist.get(index).selected;
                                if (mylist.get(index).selected == true) {
                                    parent.color = 'red'; parent.font.strikeout = true ;
                                    // parent.parent.parent.color = 'black';
                                    console.log(parent.objectName);
                                    console.log(parent.parent.objectName);
                                    // Object.keys(parent).forEach((prop)=> console.log(prop));
                                } else {
                                    parent.color = 'black'; parent.font.strikeout = false 
                                }
                            }
                        }
                    text: "O " + name
                    }
                    add: Transition {
                        NumberAnimation { properties: "x,y"; from: 0; duration: 300 }
                    }
                    // NumberAnimation on x { to: 50; from: 0; duration: 1000 }
                }
            //   }

                Row {
                    id: bottomRow
                    // anchors.top: shoppingListItems.bottom
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left 
                    anchors.right: parent.right
                    anchors.bottomMargin: 10
                    spacing: 10

                    Button {
                        id: buttonRemoveAll
                        text: "Remove all"
                        anchors.bottom: parent.bottom
                        onClicked: {
                            // mylist.clear()
                            shoppinglist_clear()
                        }
                    }

                    Button {
                        id: buttonCleanup
                        text: "Remove selected"
                        // anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.bottom: parent.bottom

                        onClicked: {
                            console.log(mylist)
                            // mylist.remove(0,1)
                            console.log("list length " + mylist.count)
                            // for (var i=mylist.count-1; i >= 0 ; i--) {
                            //     // console.log("XXX " + mylist.get(i).attributes.get(0));
                            //     if (mylist.get(i).selected == true) {
                            //         mylist.remove(i);
                            //     }
                            //     console.log(i);
                            // }
                            shoppinglist_removeSelectedItems()
                        }
                    }
                }
            // }
        // }
    }

}
