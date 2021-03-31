using Toybox.WatchUi;
using Toybox.Application;

class DexWatchDelegate extends WatchUi.InputDelegate {

    function initialize() {
   
         InputDelegate.initialize();
    }

    // Handle key  events
    function onKey(evt) {
    	var key = evt.getKey();
    	var app = Application.getApp();
    	
    	if (key == WatchUi.KEY_UP) { 
    		app.mainView.snooze();
    	}
    	else if (key == WatchUi.KEY_DOWN) { 
    		app.mainView.clear();
    	}
    	else {
    		return false;
    	}
    	WatchUi.requestUpdate();
    	return true;
    }
    
    // Handle swipe events
    function onSwipe(swipeEvent) {
        var direction = swipeEvent.getDirection();
        var app = Application.getApp();
        
        if (direction == WatchUi.SWIPE_UP) {
        	app.mainView.snooze();
    	}
    	else if (direction == WatchUi.SWIPE_DOWN) {
        	app.mainView.clear();
    	}
        else {
    		return false;
    	}
    	WatchUi.requestUpdate();
    	return true;
    }

}