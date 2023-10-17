#!/usr/bin/env gjs

/*##############################################################
  # Context menu constructed via CLI args.
  # Thomas Carmichael (carmanaught) https://gitlab.com/carmanaught
  #
  # Developed for and used in conjunction with menu-engine.lua - context-menu for mpv.
  # See menu-engine.lua for more info.
  #
  # 2017-08-06 - Version 0.1 - Initial version
  # 2018-06-23 - Version 0.2 - Split the argument list on the ASCII unit separator
  # 2019-08-10 - Version 0.3 - Configure the font by parsing arguments
  # 2020-11-28 - Version 0.4 - Rename file as part of moving into the script folder
  #
  ##############################################################*/

imports.gi.versions.Gtk = '3.0';
const Gtk = imports.gi.Gtk;
imports.gi.versions.Gdk = '3.0';
const Gdk = imports.gi.Gdk;
const Gio = imports.gi.Gio;
const GLib = imports.gi.GLib;

const CANCEL = -1;

// This call is necessary to be sure that GTK3 is avaible and capable of showing some UI
Gtk.init(null);

// Get the argument list that has been passed to the script
let argList = [];
if (ARGV.length > 0) {
    let args = ARGV[0]
    argList = args.split(String.fromCharCode(31))
}

// Go through all arguments and convert any true/false strings to boolean true/false values,
// though it could also be used to handle/sanitise other arguments if need
for (let i = 0; i  <= (argList.length - 1); i++) {
    if (argList[i] == "true") { argList[i] = true };
    if (argList[i] == "false") { argList[i] = false };
}

let posX
let posY
let first = true
let fontFace = ""
let fontSize = ""
let itemClicked = false
let errorValue = "errorValue"

// Send Gtk.main_quit() when the menu is deactivated or an item is clicked
function closeMenu() { Gtk.main_quit() }

// Print a JSON object to stdout with values to be used by the menu-engine. Also identify
// that an item has been clicked. While this is also called by the deactivate, it is called
// after the itemClicked check.
function done(menuName, index, menuPath, errorValue) {
    print("{\"x\":\"" + posX + "\", \"y\":\"" + posY + "\", \"menuname\":\"" + menuName + "\", \"index\":\"" + index + "\", \"menupath\":\"" + menuPath + "\", \"errorvalue\":\"" + errorValue + "\"}\n");
    itemClicked = true;
}

// Iterate through all non-changemenu/cascade items and get the maximum length of the label
// and accelerator for each separate menu to be used when combining the items for the menu
// item labels.
let maxLabel = [];
let maxAccel = [];
for (let i = 0; i  <= (argList.length - 1); i += 7) {
    let mVal = [];

    for (let subi = 0; subi <= 6; subi++) {
        mVal[subi] = argList[subi + i];
    }

    if (mVal[0] != "changemenu" || mVal[0] != "cascade") {

        if (maxLabel[mVal[0]] == undefined) {
            maxLabel[mVal[0]] = mVal[3].length;

        } else {
            if (mVal[3].length > maxLabel[mVal[0]]) {
                maxLabel[mVal[0]] = mVal[3].length;
            }
        }

        if (maxAccel[mVal[0]] == undefined) {
            maxAccel[mVal[0]] = mVal[4].length;
        } else {
            if (mVal[4].length > maxAccel[mVal[0]]) {
                maxAccel[mVal[0]] = mVal[4].length;
            }
        }
    }
}

// Use the maxLabel/maxAccel when necessary to combine label and accelerator into the one
// label text, giving the appearance of a right-aligned accerator. This requires that the
// font in use is a monospace font.
// This is done as trying to add accelerators in GTK is more complicated than just giving
// a label to be used in the accelerator location.
function makeLabel(curMenuName, lblText, lblAccel) {
    let labelVal = "";
    if (lblAccel == "" || lblAccel == undefined) {
        labelVal = lblText + "   ";
    } else {
        let spacesCount = maxLabel[curMenuName] + 4 + maxAccel[curMenuName];
        spacesCount = spacesCount - lblText.length - lblAccel.length;
        let menuSpaces = " ".repeat(spacesCount);
        labelVal = lblText + menuSpaces + lblAccel;
    }

    return labelVal;
}

let menu = [];
let mItem = [];
let preMenu = "";
let curMenu = "";
let baseMenu = "";
let baseMenuName = ""

// The assumed values for most iterations are:
// mVal[0] = Table Name
// mVal[1] = Table Index
// mVal[2] = Item Type
// mVal[3] = Item Label
// mVal[4] = Item Accelerator/Shortcut
// mVal[5] = Item State (Check/Unchecked, etc)
// mVal[6] = Item Disable (True/False)
for (let i = 0; i  <= (argList.length - 1); i += 7) {
    let mVal = [];
    let menuItemType;

    for (let subi = 0; subi <= 6; subi++) {
        mVal[subi] = argList[subi + i];
    }

    // Set the index value for the menu item arrays so that it's 0 based
    let mIndex = mVal[1] - 1

    if (first) {
        posX = mVal[0];
        posY = mVal[1];
        if (mItem[mVal[2]] == undefined) {
            mItem[mVal[2]] = {};
        };
        if (menu[mVal[2]] == undefined) {
            menu[mVal[2]] = new Gtk.Menu();
        }
        baseMenuName = mVal[2];
        baseMenu = menu[mVal[2]];
        curMenu = mVal[2];
        preMenu = mVal[2];
        // The fallback monospace font to be used should be set here, adjusting size as desired.
        // To set the font weight, it should be done from the show_menu() function.
        if (mVal[5] != "") {
            fontFace = mVal[5];
        } else {
            fontFace = "Source Code Pro"
        }
        if (mVal[6] != "") {
            fontSize = mVal[6];
        } else {
            fontSize = 9
        }
        first = false;

        continue
    }

    if (mVal[0] == "changemenu") {
        let changeCount = 0;
        let menuLength = 0;
        // Check how many empty values are in the list and increase the $changeCount variable to
        // subtract that value from the size of the array of values (currently 7), giving the
        // total number of values that have actually been passed, which is how many times we'll
        // increment through to set our menu values.
        for (let subi = 1; subi < mVal.length; subi++) {
            if (mVal[subi] == "") { changeCount++ };
        }
        menuLength = mVal.length - changeCount
        // We're going to assume that the right-most value that isn't "" of the foreach variables
        // when doing a menu change is the highest level of menu and that there's been no gaps of
        // "" values (which there shouldn't be).
        for (let subi = 1; subi < menuLength; subi++) {
            if (mItem[mVal[subi]] == undefined) {
                mItem[mVal[subi]] = {};
            }
            if (menu[mVal[subi]] == undefined) {
                menu[mVal[subi]] = new Gtk.Menu();
            }
        }
        preMenu = mVal[menuLength - 2]
        curMenu = mVal[menuLength - 1]

        continue
    }

    if (mVal[0] == "cascade") {
        // The menu index is from mVal[2] not mVal[1] for cascade menu items
        mIndex = mVal[2] - 1
        // Reverse the curMenu and preMenu here so that the menu so that it attaches in the
        // correct order
        mItem[preMenu][mIndex] = new Gtk.MenuItem ({
            label: makeLabel(curMenu, mVal[1]),
            visible: true,
            sensitive: !mVal[6],
            submenu: menu[curMenu]
        });
        menu[preMenu].append(mItem[preMenu][mIndex]);

        continue
    }

    if (mVal[2] == "separator") {
        mItem[curMenu][mIndex] = new Gtk.SeparatorMenuItem();
        menu[curMenu].append(mItem[curMenu][mIndex]);

        continue
    } else {
        let abActive = false;
        let abInconsistent = false;
        if (mVal[2] == "ab-button") {
            if (mVal[5] == "a") { abInconsistent = true; }
            if (mVal[5] == "b") { abActive = true; }
        }

        // Command menu items are a regular MenuItem, but the remaining menu items all use CheckMenuItem
        mVal[2] == "command" ? mItem[curMenu][mIndex] = new Gtk.MenuItem() : mItem[curMenu][mIndex] = new Gtk.CheckMenuItem()

        // There are common properties between all remaining menu items
        mItem[curMenu][mIndex].label = makeLabel(curMenu, mVal[3], mVal[4]);
        mItem[curMenu][mIndex].visible = true;
        mItem[curMenu][mIndex].sensitive = !mVal[6];

        // Specific property changes for the A-B looping
        mItem[curMenu][mIndex].active = mVal[2] == "ab-button" ? abActive : true;
        mItem[curMenu][mIndex].inconsistent = mVal[2] == "ab-button" ? abInconsistent : false;

        if (mVal[2] == "radiobutton")
            mItem[curMenu][mIndex].draw_as_radio = true;

        if (mVal[2] == "checkbutton" || mVal[2] == "radiobutton")
            mItem[curMenu][mIndex].active = mVal[5];

        // For each of the regularly clickable menu items (not cascades or separators), we connect
        // to the button-release-event signal, calling the done command.
        mItem[curMenu][mIndex].connect("button_release_event", () =>
            done(mVal[0], mVal[1], curMenu, errorValue)
        );

        menu[curMenu].append(mItem[curMenu][mIndex]);

        continue
    }
}

let cssProv;

function show_menu() {
    // Use a Gtk.CssProvider to load CSS information and apply that to all items in the menu.
    cssProv = new Gtk.CssProvider();
    cssProv.load_from_data(" * { font-family: " + fontFace + "; font-size: " + fontSize + "pt; font-weight: 500; }")
    Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), cssProv, 800);

    // Show all menu items and launch the popup.
    baseMenu.show_all();
    baseMenu.popup(null, null, null, 0, Gtk.get_current_event_time());
    // Start the main application loop.
    Gtk.main();
};

// Connect to the 'deactivate' signal and if no item has been clicked, pass the CANCEL value
// back so that the menu-engine knows nothing has been clicked.
baseMenu.connect("deactivate", function() {
    if (itemClicked == false) {
        done(baseMenuName, CANCEL, baseMenuName, errorValue);
    }
    Gtk.StyleContext.remove_provider_for_screen(Gdk.Screen.get_default(), cssProv);
    closeMenu();
});

// After everything that's not inside a function has been built, call the show_menu function
// to show the menu.
show_menu();
