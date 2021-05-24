using Toybox.Application;
using Toybox.WatchUi;
using Toybox.System as Sys;
using Toybox.Application as App;
using Toybox.Attention;

	//shared variables
	//var m_server;
	var m_username;
	var m_password;
	var m_unit;
	var m_alarm;
	var m_bgLow;
	var m_snoozeTime;
	var m_snoozeUntil = 0;
	var m_prevAlarm = 0;
	var m_showAlarmMenu = false;
	
	const MMOL = 0;
	const MGDL = 1;

class DexWatchApp extends Application.AppBase {

	static const EU_SERVER = 0;
	static const US_SERVER = 1;	
	
	var mainView;
    var mainDelegate;
	
    function initialize() {
        AppBase.initialize();
         
       	
        // Load user settings here
     	m_unit = App.getApp().getProperty("Unit");
        m_username = App.getApp().getProperty("Username");
        m_password = App.getApp().getProperty("Password");
        m_alarm = App.getApp().getProperty("Alarm");
 		m_bgLow = App.getApp().getProperty("LowAlarm");
        m_snoozeTime = App.getApp().getProperty("SnoozeTime");
    
    	//frsal use for testing
    	//m_username = "fsallstrom";
    	//m_password = "Saknonlaa1";
    	//m_username = "CharlieCatalano";
        //m_password = "ccdexcom2015";
       	//m_alarm = true;
       	// end testing
    
    	Sys.println("Account: " + m_username + " | pwd: " + m_password + " | Unit: " + m_unit + " |  Alarms: " + m_alarm + " | Low Alert: " + m_bgLow);
    }

    // onStart() is called on application start up
    function onStart(state) {
    	
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    }

    // Return the initial view of your application here
    function getInitialView() {
    	mainView = new DexWatchView();
    	mainDelegate = new DexWatchDelegate();
        return [ mainView, mainDelegate ];
    }
    
    function onSettingsChanged() {
        
        m_username = App.getApp().getProperty("Username");
        m_password = App.getApp().getProperty("Password");
        m_unit = App.getApp().getProperty("Unit");
        m_alarm = App.getApp().getProperty("Alarm");
        m_bgLow = App.getApp().getProperty("LowAlarm");
        m_snoozeTime = App.getApp().getProperty("SnoozeTime");
        Sys.println("Settings changed: Account: " + m_username + " pwd: " + m_password + " Unit: " + m_unit +  " Alarms: " + m_alarm + " Low Alert: " + m_bgLow);
        WatchUi.requestUpdate();
    }
    
    

}
