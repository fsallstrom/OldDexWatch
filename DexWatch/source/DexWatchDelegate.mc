using Toybox.WatchUi;

class DexWatchDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() {
        WatchUi.pushView(new Rez.Menus.MainMenu(), new DexWatchMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

}