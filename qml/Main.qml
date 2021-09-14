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
        anchors.fill: parent
        // var testModel = ["een", "twee", "drie"]

        header: PageHeader {
            id: header
            title: i18n.tr('Boodschappenlijst')
        }

        Column{
            anchors {
                top: header.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }

            Label {
                text: i18n.tr('Check the logs!')
                verticalAlignment: Label.AlignVCenter
                horizontalAlignment: Label.AlignHCenter
            }

            TextField {
                id: textField1
            }

            Button {
                id: button
                text: "Add item"
                onClicked: python.call('example.speak', [textField1.text], function(returnValue) {
                    console.log('example.speak returned ' + returnValue);
                    textField1.text = returnValue;
                    // e = ListElement("jajajaja");
                    // e.name = textField1.text;
                    mylist.append(
                          {
                            name: textField1.text
                        }
                    );
                    // mylist.append(textField1.text);
                    for (var i=0; i<mylist.length; i++) {
                        console.log(i);
                    }
                })
            }

            ListModel {
                id: mylist
                ListElement {
                    name: "Piet"
                }
                ListElement {
                    name: "Jan"
                }

            }

            ListView {
                width: 180; height: 200
                // model: ['string1', 'string2']
                model: mylist
                delegate: Text {
                    // text: testModel.get(index)
                    text: "hoi " + name
                }
                moveDisplaced: Transition {
                    NumberAnimation { properties: "x,y"; duration: 1000 }
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
