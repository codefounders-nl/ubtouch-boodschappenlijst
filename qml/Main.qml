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

    // [UI] Hiermee wordt voorkomen dat de gebruikersinterface overlapt wordt door het toetsenbord
    anchorToKeyboard: true

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
                    mylist.appendItem(rs.rows.item(i).rowid, rs.rows.item(i).name, Boolean(rs.rows.item(i).selected), 0)
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

    function shoppinglist_addItem(name, selected, price) {
        var result
        // Update DB
        db.transaction(function(tx) {
                result = tx.executeSql('INSERT INTO ' + shoppingListTable + ' (name, selected) VALUES( ?, ? )', [name, selected]);
            }
        )
        // Update ListModel
        // var rowid = result[1]
        var rowid = Number(result.insertId);
        var item = mylist.appendItem(rowid, name, selected, price)
        getItemPrice(item)
        console.log("RESULT: ", result)
        console.log("ADDED: ", result.insertId, " ", name, " ", selected, " ", price)
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

        function appendItem(rowid, name, selected, price) {
            console.log("XXX ", rowid, " ", name, " ", selected)
            var item = 
                {
                    "rowid": rowid,
                    "name": name,
                    "selected": Boolean(selected),
                    "price": price
                }
            mylist.append(item)
            return item
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
    // XMLHttpRequest

    function getItemPrice(item) {
        print("===> 1 GET item: ", item.name + " " + item.price)
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.HEADERS_RECEIVED) {
                print('HEADERS_RECEIVED');
            } else if(xhr.readyState === XMLHttpRequest.DONE) {
                var result = JSON.parse(xhr.responseText.toString());
                print("===> 2 SET item: ", item.name + " " + item.price + " result=" + result.price);
                item.price = result.price;
                print("===> 3 SET item: ", item.name + " " + item.price)
                // { "name": "itemname",
                //   "price": value
                // }
                // print(result);
                // print(JSON.stringify(object, null, 2));
            }
        }
        xhr.open("GET", "http://apishoppinglist.codefounders.nl/itemprice.php?itemname=" + encodeURIComponent(item.name));
        xhr.send();
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
            // [UI] StyleHints zijn over het algemeen niet nodig, of je app moet een volledig aangepast kleurenschema hebben.
            // Apps die hier goed op inspelen zijn bijvoorbeeld Talaan en Pesbuk (te vinden in de Open Store), die een volledig
            // aangepast kleurenschema gebruiken. Indien dit niet het geval is, kun je de StyleHints beter weglaten, zodat de app
            // automatisch meegaat in het systeembrede thema 'Ambiance' of 'SuruDark'.
            /*/ StyleHints {
                    foregroundColor: UbuntuColors.black
                    backgroundColor: "lightgrey"
                    dividerColor: UbuntuColors.slate
                } /*/
            }

        Item {
            anchors.top: header.bottom
            // [UI] Hieronder is een topMargin ingevoegd, uitleg volgt hieronder :)
            anchors.topMargin: units.gu(2)
            // [UI] Hier kun je beter gebruik maken van units.gu(). Op die manier kun je makkelijker
            // de grootte aanpassen en ook gebruik maken van de kleinere spacing variant units.dp().
            // Verder is de standaard spacing in Ubuntu Touch apps vanaf de rand units.gu(2). Kijk maar eens
            // hoe de content van de app nu gelijk loopt met de titel in de pageHeader.
            //anchors.leftMargin: size1GridUnit
            anchors.leftMargin: units.gu(2)
            anchors.bottom: parent.bottom
            // [UI] Om de styling voor onszelf wat makkelijker te maken, kun je het beste ook direct een bottomMargin (en andere margins)
            // instellen. Op die manier ankeren items binnen deze pagina direct met de juiste spacing en hoeven we daar geen
            // margins meer in te stellen.
            anchors.bottomMargin: units.gu(2)
            anchors.left: parent.left
            anchors.right: parent.right
            // [UI] Hier is dan direct een rightMargin, scheelt weer instellen van left en right margins bij de pagina content.
            anchors.rightMargin: units.gu(2)

            // [UI] Je zult merken dat het rijtje met bovenstaande anchor instellingen een beetje onoverzichtelijk wordt met al die opties.
            // Anchor instellingen kun je ook simpelweg bundelen. Ik heb hieronder een voorbeeld neergezet met de instellingen van dit item,
            // probeer maar eens uit.
            
            /*/
            anchors {
                top: header.bottom
                topMargin: units.gu(2)
                left: parent.left
                leftMargin: units.gu(2)
                right: parent.right
                rightMargin: units.gu(2)
                bottom: parent.bottom
                bottomMargin: units.gu(2)
            }
            /*/         

            Label {
                id: label
                anchors.top: parent.top
                // [UI] Deze kan wegblijven, aangezien we net de margins bepaald hebben in het overkoepelende item.
                //anchors.topMargin: size1GridUnit
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
                    // [UI] Deze kan wegblijven, aangezien we net de margins bepaald hebben in het overkoepelende item.
                    //anchors.leftMargin: size1GridUnit

                    // [UI] Bij het gebruik van margins tussen items, is 1 grid unit genoeg.
                    // anchors.rightMargin: size2GridUnit
                    anchors.rightMargin: units.gu(1)

                    // maximumLength: 100B
                    // color: UbuntuColors.orange

                    // [UI] Net als bij de pageHeader kun je de stylehints hier beten weglaten wanneer je niet een volledig aangepast
                    // kleurenschema wilt. Op die manier verandert de app mee met het systeemthema.

                    /*/
                    StyleHints {
                        foregroundColor: UbuntuColors.black
                        backgroundColor: "orange"
                        dividerColor: UbuntuColors.red
                    }
                    /*/

                }

                Button {
                    id: buttonAdd
                    anchors.right: parent.right
                    // [UI] Deze kan wegblijven, aangezien we net de margins bepaald hebben in het overkoepelende item.
                    // anchors.rightMargin: size2GridUnit
                    text: "Add"
                    onClicked:
                        {
                            if (textFieldInput.text == "" ) {
                                return
                            }
                            shoppinglist_addItem(textFieldInput.text, false, 1)
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
                // [UI] Door het gebruik van het listitem (wordt zo uitgelegd) moet de listview even breed zijn
                // als het venster. De margins van units.gu(2) aan beide kanten heffen we op door deze bij de breedte op
                // te tellen en de listview in het midden te ankeren.
                width: parent.width + units.gu(4)
                anchors.horizontalCenter: parent.horizontalCenter
                // height: parent.height - label.height - topRow.height - bottomRow.height
                anchors.top: topRow.bottom
                // [UI] Halve gridunits zijn met units.gu() ook makkelijker te noteren: units.gu(1.5) bijvoorbeeld.
                anchors.topMargin: size1_5GridUnit
                anchors.bottom: bottomRow.top
                anchors.bottomMargin: size1_5GridUnit
                // [UI] In verband met het gebruik van het listitem (wordt zo uitgelegd) kan de spacing wegblijven.
                //spacing: size0_5GridUnit
                model: mylist
                // [UI] Deze delegate heb ik herschreven met een listitem. Dit item is bij de Ubuntu Touch components inbegrepen en heeft
                // direct de stijl die nodig is.
                /*/
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
                /*/

                delegate: ListItem {
                    width: parent.width
                    height: units.gu(5)

                    // [UI] De divider is tijdelijk uitgeschakeld, aangezien die zich vreemd lijkt te gedragen binnen deze component. Soms
                    // is het wel zichtbaar, soms niet. Staat een beetje lelijk, dus laten we 'em uitgeschakeld.
                    divider.visible: false

                    CheckBox {
                        id: listCheckBox
                        anchors {
                            left: parent.left
                            leftMargin: units.gu(2)
                            verticalCenter: parent.verticalCenter
                        }

                        checked: mylist.get(index).selected
                    }

                    Text {
                        id: itemName
                        anchors {
                            left: listCheckBox.right
                            leftMargin: units.gu(1)
                            verticalCenter: parent.verticalCenter
                        }
                    
                        text: name
                        font {strikeout: mylist.get(index).selected}
                        // [UI] Met deze kleuroptie verandert de tekst automatisch met het systeemthema mee. Dit hoeft alleen expliciet
                        // aangegeven te worden bij het text component, bij een lable gebeurt dit al automatisch.
                        color: theme.palette.normal.baseText
                    }

                    Text {
                        anchors {
                            right: parent.right
                            rightMargin: units.gu(5)
                            verticalCenter: parent.verticalCenter
                        }

                        text: price
                        font {strikeout: mylist.get(index).selected}
                        color: theme.palette.normal.baseText
                        visible: price > 0
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            console.log(mylist.get(index).selected)
                            console.log("SELECTED ", JSON.stringify(mylist.get(index)))
                            shoppinglist_updateSelectionStatus(index, mylist.get(index).rowid, ! mylist.get(index).selected)
                        }
                    }

                    // [UI] In plaats van de knoppen die nu onder in de app staan, is het natuurlijker om in UT swipe actions binnen
                    // de listview aan te maken, waarmee de gebruiker ook de mogelijkheid heeft om een item per keer te verwijderen.
                    // Hieronder staat de code om per item een eigen delete knop toe te voegen. Ik heb de onTriggered
                    // bewust leeggelaten, kun je hier zelf nog eens mee rommelen.
                    leadingActions: ListItemActions {
                    actions: [
                        Action {
                            iconName: "delete"

                            onTriggered: {

                            }
                        }
                        ]
                    }
                }

                // [UI] Door clip op true te zetten, wordt voorkomen dat de listview door andere componenten heen gaat en deze overlapt
                clip: true

                // [UI] Vraag vanuit mij? Waarvoor wordt nu deze transition gebruikt? Ik heb 'em voor nu even uitgeschakeld.
                /*/
                add: Transition {
                    NumberAnimation { properties: "x,y"; from: 0; duration: 300 }
                }
                /*/
                
                // NumberAnimation on x { to: 50; from: 0; duration: 1000 }
            }

            Row {
                id: bottomRow
                height: buttonRemoveAll.height
                // anchors.top: shoppingListItems.bottom
                anchors.bottom: parent.bottom
                anchors.left: parent.left 
                anchors.right: parent.right
                // [UI] Deze kan wegblijven, aangezien we net de margins bepaald hebben in het overkoepelende item.
                // anchors.bottomMargin: size1GridUnit
                spacing: size1GridUnit

                Button {
                    id: buttonRemoveAll
                    text: "Remove all..."
                    anchors.bottom: parent.bottom

                    width: parent.width / 2 - units.gu(0.5)

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
                    // [UI] Deze kan wegblijven, aangezien we net de margins bepaald hebben in het overkoepelende item.
                    // anchors.rightMargin: size1GridUnit
                    anchors.bottom: parent.bottom

                    width: parent.width / 2  - units.gu(0.5)

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
