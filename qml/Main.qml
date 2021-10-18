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

    // width: units.gu(45)
    // height: units.gu(75)

    property string identifier: "ShoppingListDB"
    property string version: "1.0"
    property string description: "DB for shippoing list app"
    property int    estimated_size: 10000
    property string shoppingListTable: "ShoppingList"

    property var db: LocalStorage.openDatabaseSync(identifier, version, description, estimated_size)

    function initShoppinglist() {

        db.transaction(
            function(tx) {
                // Create the database if it doesn't already exist
                // tx.executeSql('DROP TABLE ' + shoppingListTable);
                tx.executeSql('CREATE TABLE IF NOT EXISTS ' + shoppingListTable + ' (name TEXT, selected BOOLEAN)');

                // Add (another) row
                // tx.executeSql('INSERT INTO ' + shoppingListTable + ' VALUES(?, ?)', [ 'Bread', 'false' ]);

                // Show all shopping list items
                var rs = tx.executeSql('SELECT * FROM ' + shoppingListTable);

                var r = ""
                for (var i = 0; i < rs.rows.length; i++) {
                    console.log(i)
                    r += rs.rows.item(i).name + ", " + rs.rows.item(i).selected + "\n"
                    appendTo_myList(rs.rows.item(i).name, Boolean(rs.rows.item(i).selected))
                    // mylist.append(
                    //     {
                    //         "name": rs.rows.item(i).name,
                    //         "selected": Boolean(rs.rows.item(i).selected) // assign as boolean
                    //     }
                    // )
                    // mylist.get(i).parent.color = 'red';
                    //  mylist.get(i).parent.font.strikeout = 1 ;
                }
                console.log("XXXXXXXXXX " + r)
                // text = r
            }
        )
    }

    function clearShoppinglist() {
        // Update DB
        db.transaction(
            function(tx) {
                tx.executeSql('DELETE FROM ' + shoppingListTable)
            }
        )
        // Update View
        mylist.clear()
    }

    function addItemToShoppinglist(name, selected) {
        // Update DB
        db.transaction(
            function(tx) {
                tx.executeSql('INSERT INTO ' + shoppingListTable + ' VALUES(?, ?)', [ name, selected ]);
            }
        )
        // Update View
        // mylist.append(item)
        appendTo_myList(name, selected)
        console.log(name, " ", selected)
    }

    function removeSelectedItemsFromShoppinglist() {
        // Update DB
        db.transaction(
            function(tx) {
                tx.executeSql('DELETE FROM ' + shoppingListTable + ' WHERE selected = ' + Boolean(true))
            }
        )
        // Update View
        for (var i=mylist.count-1; i >= 0 ; i--) {
            if (mylist.get(i).selected == true) {
                mylist.remove(i);
            }
        }
    }


    ListModel {
        id: mylist
        // ListElement {
        //     name: "Nothing here yet..."
        //     selected: false
        // }
    }

    function appendTo_myList(name, selected) {
        console.log("XXX ", name, " ", selected)
        mylist.append(
            {
                "name": name,
                "selected": Boolean(selected)
            }
        )
    }


    Page {
        id: mainPage
        anchors.fill: parent
        Component.onCompleted: { 
            initShoppinglist()
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
                                // appendTo_myList(textFieldInput.text, false)
                                addItemToShoppinglist(textFieldInput.text, false)
                                // addItemToShoppinglist(
                                //     {
                                //         "name": textFieldInput.text,
                                //         "selected": false
                                //     }
                                // )
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
                                console.log(mylist.get(index).name)
                                mylist.get(index).selected = ! mylist.get(index).selected;
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
                            clearShoppinglist()
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
                            removeSelectedItemsFromShoppinglist()
                        }
                    }
                }
            // }
        // }
    }

}
