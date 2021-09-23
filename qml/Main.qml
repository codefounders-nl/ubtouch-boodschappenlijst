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

import QtQuick 2.7
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

    width: units.gu(45)
    height: units.gu(75)


    Page {
        id: mainPage
        anchors.fill: parent
        // var testModel = ["een", "twee", "drie"]

        header: PageHeader {
            id: header
            title: i18n.tr('Shopping list')
            StyleHints {
                    foregroundColor: UbuntuColors.black
                    backgroundColor: "lightgrey"
                    dividerColor: UbuntuColors.slate
                }
            }

        Column {
            anchors.topMargin: 5
            anchors.leftMargin: 10
            
            anchors {
                top: header.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }

            Column{
                spacing: 10

                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    bottom: bottomRow.top
                }

                Label {
                    id: label
                    text: i18n.tr('Check the logs!')
                    verticalAlignment: Label.AlignVCenter
                    horizontalAlignment: Label.AlignHCenter
                }

                Row {
                    id: topRow
                    spacing: 10

                    TextField {
                        id: textField1
                        maximumLength: 100
                        color: UbuntuColors.orange
                        StyleHints {
                            foregroundColor: UbuntuColors.black
                            backgroundColor: "orange"
                            dividerColor: UbuntuColors.red
                        }

                    }

                    Button {
                        id: button
                        text: "Add"
                        onClicked: python.call('example.speak', [textField1.text], function(returnValue) {
                            console.log('example.speak returned ' + returnValue);
                            textField1.text = returnValue;
                            if (textField1.text == "" ) {
                                return
                            }
                            mylist.append(
                                {
                                    "name": textField1.text,
                                    "selected": false
                                }
                            );
                        })
                    }
                }

                // check doc MouseArea met onclicked event,
                // fotn kan aangpast worden zodat deze strike-through krijgt
                // heet decoration

                ListModel {
                    id: mylist
                    ListElement {
                        name: "Add some stuff"
                        selected: false
                    }
                }

                ListView {
                    width: parent.width
                    height: parent.height - label.height - topRow.height
                    spacing: 5
                    // model: ['string1', 'string2']
                    model: mylist
                    delegate: Text {
                        // text: testModel.get(index)
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
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


            }

            Row {
                id: bottomRow
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
                        mylist.clear()
                    }
                }

                Button {
                    id: buttonCleanup
                    text: "Remove selected"
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.bottom: parent.bottom

                    onClicked: {
                        console.log(mylist)
                        // mylist.remove(0,1)
                        console.log("list length " + mylist.count)
                        for (var i=mylist.count-1; i >= 0 ; i--) {
                            // console.log("XXX " + mylist.get(i).attributes.get(0));
                            if (mylist.get(i).selected == true) {
                                mylist.remove(i);
                            }
                            console.log(i);
                        }
                    }
                }
            }
        }
    }


    Python {
        id: python

        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('../src/'));

            importModule('example', function() {
                console.log('module imported');
                python.call('example.speak', ['Hello World!'], function(returnValue) {
                    console.log('example.speak returned ' + returnValue);
                })
            });
            console.log("0 - INIT");
            mylist.append("jaja");
            mylist.append("neenee");
        }

        onError: {
            console.log('python error: ' + traceback);
        }
    }
}
