using Toybox.WatchUi;

class DexWatchDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() {
        WatchUi.pushView(new Rez.Menus.MainMenu(), new DexWatchMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }
    
   /* function onKey(evt) {
    	var key = evt.getKey();
    	var keyStr = "";
    	if (key == KEY_UP) { keyStr = "UP";}
    	else if (key == KEY_DOWN) { keyStr = "DOWN";}
    	System.println("Key pressed: " + keyStr);
    	
    	return true;
    }*/

}