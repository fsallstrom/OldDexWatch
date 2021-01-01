using Toybox.Application;
using Toybox.WatchUi;
using Toybox.System as Sys;
using Toybox.Application as App;
using Toybox.Attention;

	//shared variables
	var m_server;
	var m_username;
	var m_password;
	var m_unit;
	var m_alarm;
	var m_bgHigh;
	var m_bgLow;
	//var m_snoozeTime;
	//var m_snoozeUntil = 0;
	//var m_prevAlarm = 0;
	
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
        //m_alarm = App.getApp().getProperty("Alarm");
        //m_bgHigh = App.getApp().getProperty("BgHigh");
        //m_bgLow = App.getApp().getProperty("BgLow");
        //m_snoozeTime = App.getApp().getProperty("SnoozeTime");
    
    	//frsal debug
       /* m_unit = 0;
        m_username = "CharlieCatalano";
        m_password = "ccdexcom2015";
       	m_server = "share1.dexcom.com";
       	m_alarm = false;
       	m_bgHigh = 200;
       	m_bgLow = 80; */
    
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
        //m_alarm = App.getApp().getProperty("Alarm");
        //m_bgHigh = App.getApp().getProperty("BgHigh");
        //m_bgLow = App.getApp().getProperty("BgLow");
        //m_snoozeTime = App.getApp().getProperty("SnoozeTime");
        Sys.println("Settings Changed:");
        Sys.println("Account: " + m_username + " pwd: " + m_password + " Unit: " + m_unit + " server: " + m_server + " Alarms: " + m_alarm + " High Alert: " + m_bgHigh + " Low Alert: " + m_bgLow);
        WatchUi.requestUpdate();
    }
    
    // alarm if time since last alarm is > 5 minutes, and not snoozed
   /* function raiseAlarm() {
   
    	const _fiveMins = new Time.Duration(5 * 60);
    	var _now = Time.now(); 
    	
    	if (m_prevAlarm == 0) {
    		//1st time, sound alarm
    		if (Attention has :playTone) {Attention.playTone(Attention.TONE_CANARY);}
    		if (Attention has :vibrate) {
   				var vibeData =
    			[
        			new Attention.VibeProfile(50, 2000), // On for two seconds
        			new Attention.VibeProfile(0, 1000),  // Off for one second
        			new Attention.VibeProfile(50, 2000), // On for two seconds
        			new Attention.VibeProfile(0, 1000),  // Off for one second
        			new Attention.VibeProfile(50, 2000)  // on for two seconds
	    		];
				Attention.vibrate(vibeData);
			}
				
    	}
    	
    	if ((_now >= m_prevAlarm.add(_fiveMins)) &&  (_now > m_snoozeUntil)) { 
    		// sound alarm
    		if (Attention has :playTone) {Attention.playTone(Attention.TONE_CANARY);}
    		if (Attention has :vibrate) {
   				var vibeData =
    			[
        			new Attention.VibeProfile(50, 2000), // On for two seconds
        			new Attention.VibeProfile(0, 1000),  // Off for one second
        			new Attention.VibeProfile(50, 2000), // On for two seconds
        			new Attention.VibeProfile(0, 1000),  // Off for one second
        			new Attention.VibeProfile(50, 2000)  // on for two seconds
	    		];
				Attention.vibrate(vibeData);
			}	
    	}
    }*/

}
