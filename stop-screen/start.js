//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//                   Version 2, December 2004
//
// Copyright (C) 2023 Matthias Gatto <uso.cosmo.ray@gmail.com>
//
// Everyone is permitted to copy and distribute verbatim or modified
// copies of this license document, and changing it is allowed as long
// as the name is changed.
//
//            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
//
//  0. You just DO WHAT THE FUCK YOU WANT TO.

let LAST = 5

let UL_ARROW = `^
  \\
   \\
`
let DL_ARROW = `  /
 /
V
`
let UR_ARROW = `  ^
 /
/
`
let DR_ARROW = `\\
 \\
  V
`

let HELP_GUY = `
 o        o
  \\      /
    -^^-
  < Y  Y >
     WW
    \\__/
`

function y_stop_action(wid, eves)
{
    if (yevAnyMouseDown(eves) ||
	yevIsKeyDown(eves, Y_ENTER_KEY) ||
	yevIsKeyDown(eves, Y_SPACE_KEY) ||
	yevIsKeyDown(eves, Y_ESC_KEY)) {
	let data = yeGet(wid, "_stop_data")

	for (i = 0; i < LAST; ++i)
	    ywCanvasRemoveObj(wid, yeGet(data, i))

	yeRemoveChildByStr(wid, "_stop_data");
	yeRemoveChildByStr(wid, "action");
	yeRenameStrStr(wid, "_old_action", "action")
    }
}

function y_stop_helper(wid, x, y, txt)
{
    wid_pix = yeGet(wid, "wid-pix");
    if (!wid_pix) {
	print("y_stop_helper need to be called after been created !");
	return false
    }

    ww = ywRectW(wid_pix);
    wh = ywRectH(wid_pix);
    print("wid pix:");
    yePrint(wid_pix);
    print(yeCountLines(yeCreateString("hi")));
    print(yeCountLines(yeCreateString("hi\n")));
    print(yeCountLines(yeCreateString("h\ni")));

    yeRenameStrStr(wid, "action", "_old_action");
    yeCreateFunction("y_stop_action", wid, "action");
    let data = yeCreateArray(wid, "_stop_data");
    txt = yeCreateString(txt)
    yePushBack(data, ywCanvasNewRectangle(wid, 0, 0, ywRectW(wid_pix),
					  ywRectH(wid_pix),
					  "rgba: 40 100 230 150"));
    var xdir = 1
    var ydir = 1

    if (x < ww / 2) { // left
	if (y <  wh / 2) { // up
	    yePushBack(data, ywCanvasNewText(wid, x, y, yeCreateString(UL_ARROW)));
	} else {
	    yePushBack(data, ywCanvasNewText(wid, x, y, yeCreateString(DL_ARROW)));
	    ydir = -1
	}
    } else { // right
	xdir = -1
	if (y <  wh / 2) { // up
	    yePushBack(data, ywCanvasNewText(wid, x, y, yeCreateString(UR_ARROW)));
	} else {
	    yePushBack(data, ywCanvasNewText(wid, x, y, yeCreateString(DR_ARROW)));
	    ydir = -1
	}
    }


    yePushBack(data, ywCanvasNewRectangle(wid, x + 18 * xdir, y + 58  * ydir, 200,
					  20 * (1 + yeCountLines(txt)),
					  "rgba: 255 255 255 150"));
    yePushBack(data, ywCanvasNewText(wid, x + 20  * xdir,
				     y + 60 * ydir, txt));
    var head_threshold = 100
    if (ydir < 0)
	head_threshold = -200
    yePushBack(data, ywCanvasNewText(wid, x + 70  * xdir,
				     y + head_threshold, yeCreateString(HELP_GUY)));
    return true
}

function mod_init(mod)
{
    ygRegistreFunc(4, "y_stop_helper", "y_stop_helper");
    print("ygRegistreFunc good ?\n");
    return mod
}
