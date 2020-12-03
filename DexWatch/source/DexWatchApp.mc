using Toybox.Application;
using Toybox.WatchUi;
using Toybox.System as Sys;
using Toybox.Application as App;

	//shared variables
	var m_server;
	var m_username;
	var m_password;
	var m_unit;
	var m_alarm;
	var m_bgHigh;
	var m_bgLow;
	
	const MMOL = 0;
	const MGDL = 1;

class DexWatchApp extends Application.AppBase {

	static const EU_SERVER = 0;
	static const US_SERVER = 1;	
	
    function initialize() {
        AppBase.initialize();
         
       	
        // Load user settings here
     	m_unit = App.getApp().getProperty("Unit");
        m_username = App.getApp().getProperty("Username");
        m_password = App.getApp().getProperty("Password");
        if (App.getApp().getProperty("Server") == EU_SERVER) {
        	m_server = "shareous1.dexcom.com";
        }
        else {
        	m_server = "share1.dexcom.com";
        }
        m_alarm = App.getApp().getProperty("Alarm");
        m_bgHigh = App.getApp().getProperty("BgHigh");
        m_bgLow = App.getApp().getProperty("BgLow");
    
    	//frsal debug
        m_unit = 0;
        m_username = "fsallstrom";
        m_password = "Saknonlaa1";
       	m_server = "shareous1.dexcom.com";
       	m_alarm = false;
       	m_bgHigh = 200;
       	m_bgLow = 80; 
    
    	Sys.println("Account: " + m_username + " | pwd: " + m_password + " | Unit: " + m_unit + " | server: " + m_server + " | Alarms: " + m_alarm + " | High Alert: " + m_bgHigh + " | Low Alert: " + m_bgLow);
    }

    // onStart() is called on application start up
    function onStart(state) {
    	
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    }

    // Return the initial view of your application here
    function getInitialView() {
    	
        return [ new DexWatchView(), new DexWatchDelegate() ];
    }
    
    function onSettingsChanged() {
        
        if (App.getApp().getProperty("Server") == EU_SERVER) {
        	m_server = "shareous1.dexcom.com";
        }
        else {
        	m_server = "share1.dexcom.com";
        }
        m_username = App.getApp().getProperty("Username");
        m_password = App.getApp().getProperty("Password");
        m_unit = App.getApp().getProperty("Unit");
        m_alarm = App.getApp().getProperty("Alarm");
        m_bgHigh = App.getApp().getProperty("BgHigh");
        m_bgLow = App.getApp().getProperty("BgLow");
        Sys.println("Settings Changed:");
        Sys.println("Account: " + m_username + " pwd: " + m_password + " Unit: " + m_unit + " server: " + m_server + " Alarms: " + m_alarm + " High Alert: " + m_bgHigh + " Low Alert: " + m_bgLow);
        WatchUi.requestUpdate();
    }

}
