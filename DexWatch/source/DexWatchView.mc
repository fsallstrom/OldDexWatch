using CGM.Dexcom as Dexcom;
using Toybox.Application as App;
//using CGM as Dexcom;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Timer as Timer;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Time.Gregorian as Calendar;
using Toybox.Math;

class DexWatchView extends Ui.View {


	//Coordinates
	var BG_X;
	var BG_Y;
	var BMP_X;
	var BMP_Y;
	var BAT_X;
	var BAT_Y;
	var TEXT_Y;
	var STRIKE_X;
	var STRIKE_Y;
	var STRIKE_LENGTH;
	var BAR_Y;
	var TIME_Y;
	var DATE_Y;
	var ALARM_Y;
	var SNOOZE_X;
	var SNOOZE_Y;
	var CLEAR_X;
	var CLEAR_Y;
	var UP_X; 
	var UP_Y;
	var DOWN_X;
	var DOWN_Y;
	var LOW_Y;

	var m_bgMMOL;
	var m_bgMGDL;
	var m_trend;
	var m_sTime;
	var m_elapsedMinutes;
	var m_responseCode;
	var m_alarm;
	
	var m_readTimer;
	var m_updateTimer;
	var m_alarmTimer;

    function initialize() {
        m_bgMMOL = 0.0;
		m_bgMGDL = 0;
		m_alarm = false;
        
        View.initialize();
        if (System.getDeviceSettings().phoneConnected && !(m_username.equals("dexcom_account"))) {
        	Dexcom.readGV(m_username, m_password, method(:readResponse), 1);
        }
        
        m_readTimer = new Timer.Timer();
        m_updateTimer = new Timer.Timer();
        m_alarmTimer = new Timer.Timer();
        m_readTimer.start( method(:readLGV), 60*1000, true );    //timer for Dexcom read requests
        m_updateTimer.start( method(:updateUI), 5*1000, true ); //timer for updateing the view
      
        updateUI();
        
        
    }

    // Set layout depending on screen size
    function onLayout(dc) {
        setCoordinates(dc);
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    }

    // Update the view
    function onUpdate(dc) {
        
        // clear view
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.fillRectangle(0, 0, dc.getWidth(), dc.getHeight());
        
        //calculate elapsed time since sample
        if ((m_sTime != null) && (m_sTime != 0)) {
    		var _sampleTime = new Time.Moment(m_sTime.toNumber()); 
    		m_elapsedMinutes = Math.floor(Time.now().subtract(_sampleTime).value() / 60);
   		}   
        
        //frsal: Use for testing:
    	/*m_elapsedMinutes = 16;
    	m_bgMMOL = 5.3;
    	m_bgMGDL = 45;
    	m_unit = MMOL;
    	m_trend = 4;
       	m_bgLow = 300; 
       	m_snoozeTime = 120;
    	
    	// end testing*/
        
        // Draw bg field
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);	
    	if ((m_unit == MMOL) && (m_bgMMOL != 0)) {
   			if (m_bgMMOL < 10.0) { 
   				dc.drawText(BG_X, BG_Y, Graphics.FONT_NUMBER_HOT, (m_bgMMOL.format("%.1f")).toString(), Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
   			}
   			else { dc.drawText(BG_X + 10, BG_Y, Graphics.FONT_NUMBER_HOT, (m_bgMMOL.format("%.1f")).toString(), Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);}
      	}
        else if ((m_unit == MGDL) && (m_bgMGDL != 0)) {		
   			if (m_bgMGDL < 100) { dc.drawText(BG_X, BG_Y, Graphics.FONT_NUMBER_HOT, m_bgMGDL.toString(), Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);}
   			else { dc.drawText(BG_X + 10, BG_Y, Graphics.FONT_NUMBER_HOT, m_bgMGDL.toString(), Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);}
      	}
        
        //display Trend bmp
        if (m_trend != null) {
        
        	var _bmp;
        	if (m_trend.toNumber() == 7) {_bmp = Ui.loadResource(Rez.Drawables.DoubleDown);}
        	else if (m_trend.toNumber() == 6) {_bmp = Ui.loadResource(Rez.Drawables.SingleDown);}
        	else if (m_trend.toNumber() == 5) {_bmp = Ui.loadResource(Rez.Drawables.FortyFiveDown);}
        	else if (m_trend.toNumber() == 4) {_bmp = Ui.loadResource(Rez.Drawables.Flat);}
        	else if (m_trend.toNumber() == 3) {_bmp = Ui.loadResource(Rez.Drawables.FortyFiveUp);}
        	else if (m_trend.toNumber() == 2) {_bmp = Ui.loadResource(Rez.Drawables.SingleUp);}
        	else if (m_trend.toNumber() == 1) {_bmp = Ui.loadResource(Rez.Drawables.DoubleUp);}
        	else {_bmp = Ui.loadResource(Rez.Drawables.None);}
        	
        	if ((m_unit == MMOL) && (m_bgMMOL < 10.0)) { dc.drawBitmap(BMP_X, BMP_Y, _bmp); }
        	else { dc.drawBitmap(BMP_X + 10, BMP_Y, _bmp); }
        }
        
        //Battery warning
        var battery = System.getSystemStats().battery;
        if ((battery < 21) && (m_responseCode == Dexcom.SUCCESS)) { 
        	dc.drawBitmap(BAT_X, BAT_Y, Ui.loadResource(Rez.Drawables.BatteryAlertSmall));
        	dc.drawText(BAT_X + 15, BAT_Y + 7, Gfx.FONT_XTINY, battery.format("%d") + "%", Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER);
        }
        
        //draw message field      
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT); 
        
        	// BT Disconnected
        if (!System.getDeviceSettings().phoneConnected) {
        	dc.drawText(dc.getWidth() / 2, TEXT_Y, Gfx.FONT_MEDIUM, "Disconnected!", Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
        	System.println("Phone disconnected");
        
        	// Disconnected
        } else if (m_responseCode != null && m_responseCode == -104) {
        	dc.drawText(dc.getWidth() / 2, TEXT_Y, Gfx.FONT_MEDIUM, "Disconnected!", Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
        	System.println("Disconnected, Error -104");
        
        	// User settings not entered
        } else if ((m_username != null) && m_username.equals("dexcom_account")) {
        	dc.drawText(dc.getWidth() / 2, TEXT_Y, Gfx.FONT_MEDIUM, "Settings", Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
        
        	// Wrong user credentials
        }  else if (m_responseCode != null && m_responseCode == 401) {
        	dc.drawText(dc.getWidth() / 2, TEXT_Y, Gfx.FONT_MEDIUM, "Login Error", Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);	
       	
       		// General communication problem
       	} else if (m_responseCode != null && m_responseCode < 0) {
        	dc.drawText(dc.getWidth() / 2, TEXT_Y, Gfx.FONT_MEDIUM, "Comms Error", Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
        
        	// General Dexcom server problem
        } else if (m_responseCode != null && (m_responseCode == 500 || m_responseCode == 404)) {
        	dc.drawText(dc.getWidth() / 2, TEXT_Y, Gfx.FONT_MEDIUM, "Server Error", Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);	
        	
        	// No dexcom data available
        } else if (m_responseCode == 204) {
        	dc.drawText(dc.getWidth() / 2, TEXT_Y, Gfx.FONT_MEDIUM, "No Data", Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
        
        	// Waiting for first reading
        } else if (m_bgMGDL == 0) {
        	dc.drawText(dc.getWidth() / 2, TEXT_Y, Gfx.FONT_MEDIUM, "Wait", Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);	

         	// All good
        } else { 
        	dc.drawText((dc.getWidth() / 2), TEXT_Y, Gfx.FONT_MEDIUM, m_elapsedMinutes.format("%d") + " min", Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
        }
        
        //strikethrough bg data field if the data is older than 15 mins
        if ((m_elapsedMinutes != null) && (m_elapsedMinutes > 15)) {
        	dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
        	if (m_unit == MMOL) {
        		if (m_bgMMOL < 10.0) { dc.fillRectangle(STRIKE_X, STRIKE_Y , STRIKE_LENGTH, 7); }
        		else { dc.fillRectangle(STRIKE_X - 10, STRIKE_Y, STRIKE_LENGTH + 20, 7); }
        	}
        	else {
        		if (m_bgMGDL < 100) { dc.fillRectangle(STRIKE_X, STRIKE_Y , STRIKE_LENGTH, 7); }
        		else { dc.fillRectangle(STRIKE_X - 10, STRIKE_Y, STRIKE_LENGTH + 20, 7); }
        	}	
        }
        
        //draw the color bar
        if ((m_bgMGDL < 1) || (m_elapsedMinutes > 15)) { dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_BLACK); }
       	else if ((m_bgMGDL < 70) || (m_bgMGDL > 220)) {dc.setColor(Gfx.COLOR_DK_RED, Gfx.COLOR_BLACK);}
       	else if ((m_bgMGDL < 90) || (m_bgMGDL > 170)) {dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_BLACK);}
       	else {dc.setColor(Gfx.COLOR_DK_GREEN, Gfx.COLOR_BLACK);}
       	dc.fillRectangle(0, BAR_Y, dc.getWidth(), 7);   
    
    	//draw current time
        var _currentTime = getCurrentTime();
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
        dc.drawText(dc.getWidth() / 2, TIME_Y, Gfx.FONT_NUMBER_MEDIUM, _currentTime, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
        
    	//draw date
    	var _now = Time.now();
    	var _dateStr = Calendar.info(_now, Time.FORMAT_MEDIUM).month + " " + Calendar.info(_now, Time.FORMAT_MEDIUM).day;
    	dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_BLACK);
    	dc.drawText(dc.getWidth() / 2, DATE_Y, Gfx.FONT_XTINY, _dateStr, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
    	
    	// If alarm, show the alarm menu
    	if (m_showAlarmMenu) {
    		dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
    		dc.fillRectangle(0, ALARM_Y, dc.getWidth(), dc.getHeight());
    		dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_WHITE);
    		dc.drawText(dc.getWidth() / 2, LOW_Y, Gfx.FONT_MEDIUM, "LOW", Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
    		dc.drawText(SNOOZE_X, SNOOZE_Y, Gfx.FONT_SMALL, "Snooze " + m_snoozeTime + "m", Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER);
    		dc.drawText(CLEAR_X, CLEAR_Y, Gfx.FONT_SMALL, "Clear", Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER);
    		dc.drawBitmap(UP_X, UP_Y, Ui.loadResource(Rez.Drawables.TriangleUp));
    		dc.drawBitmap(DOWN_X, DOWN_Y, Ui.loadResource(Rez.Drawables.TriangleDown));
    		
    	}	
    }
      
    function snooze() {
    	
    	if (m_showAlarmMenu) {
    		// if alarm menu is visible, set snooze time, else do nothing
    		//System.println("snooze for " + m_snoozeTime + " mins");
    		var _snoozeDuration  = new Time.Duration(m_snoozeTime * 60);
    		var _now = new Time.Moment(Time.now().value());
    		m_snoozeUntil = _now.add(_snoozeDuration);
    	}
  
    	// clear alarm menu
    	clear();
    }  
    
    function clear() {m_showAlarmMenu = false;}
        
    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }
    
    	
    function readLGV() {
    	if (System.getDeviceSettings().phoneConnected && !(m_username.equals("dexcom_account")) ) {
    		Dexcom.readGV(m_username, m_password, method(:readResponse), 1);
    	} else {System.println("omitting request");}
    	
    }
    
    function readResponse(data, responseCode) {
    	m_responseCode = responseCode;
    	if (m_responseCode == Dexcom.SUCCESS) {
    		if (data[0].hasKey("BG_mmol")) {m_bgMMOL = data[0]["BG_mmol"].toFloat();}
    		if (data[0].hasKey("BG_mgdl")) {m_bgMGDL = data[0]["BG_mgdl"].toNumber();}
    		if (data[0].hasKey("Trend")) {m_trend = data[0]["Trend"];}
    		if (data[0].hasKey("Stime")) {m_sTime = data[0]["Stime"];}
    		
    		// Raise Alarm if BG below threshold
    		if (m_bgMGDL != 0 &&  m_bgMGDL <= m_bgLow) {
    			raiseAlarm();
    			m_alarmTimer.start( method(:clear), 15*1000, false ); // Display Alarm menu for 15s then hide it
    			
    		} else {m_showAlarmMenu = false;}
    		
    	updateUI();
    	}
    }
    
    function updateUI() {Ui.requestUpdate();}
    
   	function raiseAlarm() {
   
    	var _fiveMins = new Time.Duration(5 * 60);
    	var _now = new Time.Moment(Time.now().value());
    	var _soundAlarm = false;
    	
    	if (m_prevAlarm == 0) {
    		//1st time, sound alarm
    		//debugPrint("sounding alarm, 1st time");
  			_soundAlarm = true;
				
    	} else if (m_snoozeUntil !=0) {
    		// Previous alarm snoozed, check snooze time
    		if (m_snoozeUntil.lessThan(_now)) {
    			//debugPrint("not snoozed anymore, sound alarm");
    			_soundAlarm = true;
    		 	m_snoozeUntil = 0;
    		} else {
    			//debugPrint("Alarm snoozed, silent");
    			_soundAlarm = false; 
    		}
    		
    	} else if (_now.greaterThan(m_prevAlarm.add(_fiveMins))) { 
    		// Alarm not snoozed & > 5 mins since last alarm, sound alarm 
			//debugPrint("no longer snoozed, sound alarm");
			_soundAlarm = true;
			
    	} else {
    		// less than 5 mins since last alarm, do not sound alarm
    		//debugPrint("no alarm, less than 5 mins");	
    		_soundAlarm = false;
    	}
    	
    	if (_soundAlarm) {
    		m_prevAlarm = _now;
    		m_showAlarmMenu = true;
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
    }
      
    
    // Return the current time 
    function getCurrentTime() {
    	var timeFormat = "$1$:$2$";
        var clockTime = System.getClockTime();
        var hours = clockTime.hour;
        if (!System.getDeviceSettings().is24Hour) {
           hours = hours%12;
           if (hours == 0){hours = 12;}
        } else {
            if (Application.getApp().getProperty("UseMilitaryFormat")) {
                timeFormat = "$1$$2$";
                hours = hours.format("%02d");
            }
        }
        var timeString = Lang.format(timeFormat, [hours, clockTime.min.format("%02d")]);
    	return timeString;
    }
    
   
    
    function setCoordinates(dc) {
    	var m_height = dc.getHeight();
        var m_width = dc.getWidth();
        
        //set coordinates based on screen size
        if (m_width == 215) {
        	BG_X= (m_width / 2) + 20;
        	BG_Y = 35;
        	BMP_X= (m_width / 2) + 25;
        	BMP_Y= 25;
        	TEXT_Y = m_height / 2 - 10;
        	BAT_X= m_width * 7/10;
        	BAT_Y= (m_height / 2) + 25;
        	STRIKE_X= 55;
        	STRIKE_Y= 35;
        	STRIKE_LENGTH= (m_width / 3) + 40;
        	BAR_Y= (m_height / 2) + 10;
        	TIME_Y= (m_height / 2) + 45;
        	DATE_Y= (m_height / 2) + 80;
        	ALARM_Y = dc.getHeight() / 2 - 10;
        	UP_X = 50;
        	UP_Y = (m_height / 2) + 38;
        	DOWN_X = 50;
        	DOWN_Y = (m_height / 2) + 65;
        	SNOOZE_X = 80;
        	SNOOZE_Y = (m_height / 2) + 50;
        	CLEAR_X = 80;
        	CLEAR_Y = (m_height / 2) + 80;
        	LOW_Y = ALARM_Y + 20;
        }
        else if (m_width == 218) {
        	BG_X= (m_width / 2) + 25;
        	BG_Y= m_height / 4;
        	BMP_X= (m_width / 2) + 30;
        	BMP_Y= m_height / 5;
        	BAT_X= m_width * 7/10;
        	BAT_Y= (m_height / 2) + 35;
        	TEXT_Y = m_height / 2;
        	STRIKE_X= 55;
        	STRIKE_Y= (m_height / 4) - 2;
        	STRIKE_LENGTH= (m_width / 3) + 40;
        	BAR_Y= (m_height / 2) + 22;
        	TIME_Y= (m_height / 2) +55;
        	DATE_Y= (m_height / 2) + 90;
        	ALARM_Y = dc.getHeight() / 2 - 10;
        	UP_X = 45;
        	UP_Y = (m_height / 2) + 38;
        	DOWN_X = 45;
        	DOWN_Y = (m_height / 2) + 65;
        	SNOOZE_X = 75;
        	SNOOZE_Y = (m_height / 2) + 50;
        	CLEAR_X = 75;
        	CLEAR_Y = (m_height / 2) + 80;
        	LOW_Y = ALARM_Y + 20;
        
        }
        else if (m_width == 240) {
        	BG_X= (m_width / 2) + 35;
        	BG_Y= m_height / 4;
        	BMP_X= (m_width / 2) + 40;
        	BMP_Y= m_height / 5;
        	BAT_X= m_width * 7/10 + 5;
        	BAT_Y = (m_height / 2) + 38;
        	TEXT_Y = m_height / 2;
        	STRIKE_X= 55;
        	STRIKE_Y= (m_height / 4) - 2;
        	STRIKE_LENGTH= (m_width / 3) + 40;
        	BAR_Y= (m_height / 2) + 25;
        	TIME_Y= (m_height / 2) + 65;
        	DATE_Y= (m_height / 2) + 105;
        	ALARM_Y = dc.getHeight() / 2 - 10;
        	UP_X = 50;
        	UP_Y = (m_height / 2) + 38;
        	DOWN_X = 50;
        	DOWN_Y = (m_height / 2) + 65;
        	SNOOZE_X = 80;
        	SNOOZE_Y = (m_height / 2) + 50;
        	CLEAR_X = 80;
        	CLEAR_Y = (m_height / 2) + 80;
        	LOW_Y = ALARM_Y + 20;
        }
        else if (m_width == 260) {
        	BG_X= (m_width / 2) + 40;
        	BG_Y= m_height / 4 + 10;
        	BMP_X= (m_width / 2) + 45;
        	BMP_Y= (m_height / 5) + 10;
        	BAT_X= m_width * 7/10 + 10;
        	BAT_Y= (m_height / 2) + 35;
        	TEXT_Y = m_height / 2;
        	STRIKE_X= 75;
        	STRIKE_Y= (m_height / 4) + 7;
        	STRIKE_LENGTH= (m_width / 3) + 45;
        	BAR_Y= (m_height / 2) + 25;
        	TIME_Y= (m_height / 2) + 70;
        	DATE_Y= (m_height / 2) + 110;
        	ALARM_Y = dc.getHeight() / 2 - 10;
        	UP_X = 50;
        	UP_Y = (m_height / 2) + 47;
        	DOWN_X = 50;
        	DOWN_Y = (m_height / 2) + 75;
        	SNOOZE_X = 80;
        	SNOOZE_Y = (m_height / 2) + 60;
        	CLEAR_X = 80;
        	CLEAR_Y = (m_height / 2) + 90;
        	LOW_Y = ALARM_Y + 25;
        }
        else if (m_width == 280) {
        	BG_X= (m_width / 2) + 40;
        	BG_Y= m_height / 4 + 10;
        	BMP_X= (m_width / 2) + 45;
        	BMP_Y= (m_height / 5) + 10;
        	BAT_X= m_width * 7/10 + 10;
        	BAT_Y= (m_height / 2) + 35;
        	TEXT_Y = m_height / 2;
        	STRIKE_X= 75;
        	STRIKE_Y= (m_height / 4) + 7;
        	STRIKE_LENGTH= (m_width / 3) + 45;
        	BAR_Y= (m_height / 2) + 25;
        	TIME_Y= (m_height / 2) + 75;
        	DATE_Y= (m_height / 2) + 115;
        	ALARM_Y = dc.getHeight() / 2 - 15;
        	UP_X = 50;
        	UP_Y = (m_height / 2) + 47;
        	DOWN_X = 50;
        	DOWN_Y = (m_height / 2) + 77;
        	SNOOZE_X = 85;
        	SNOOZE_Y = (m_height / 2) + 60;
        	CLEAR_X = 85;
        	CLEAR_Y = (m_height / 2) + 95;
        	LOW_Y = ALARM_Y + 25;
        }
        else if (m_width == 360) {
        	BG_X= (m_width / 2) + 70;
        	BG_Y= m_height / 4;
        	BMP_X= (m_width / 2) + 75;
        	BMP_Y= (m_height / 5);
        	BAT_X= m_width * 7/10 + 10;
        	BAT_Y= (m_height / 2) + 45;
        	TEXT_Y = m_height / 2 - 10;
        	STRIKE_X= 75;
        	STRIKE_Y= (m_height / 4) + 7;
        	STRIKE_LENGTH= (m_width / 3) + 100;
        	BAR_Y= (m_height / 2) + 25;
        	TIME_Y= (m_height / 2) + 85;
        	DATE_Y= (m_height / 2) + 150;
        	ALARM_Y = (m_height / 2) - 30;
        	UP_X = 50;
        	UP_Y = (m_height / 2) + 47;
        	DOWN_X = 50;
        	DOWN_Y = (m_height / 2) + 82;
        	SNOOZE_X = 85;
        	SNOOZE_Y = (m_height / 2) + 60;
        	CLEAR_X = 85;
        	CLEAR_Y = (m_height / 2) + 100;
        	LOW_Y = ALARM_Y + 30;
        }
        else if (m_width == 390) {
        	BG_X= (m_width / 2) + 70;
        	BG_Y= m_height / 4;
        	BMP_X= (m_width / 2) + 75;
        	BMP_Y= (m_height / 5);
        	BAT_X= m_width * 7/10 + 10;
        	BAT_Y= (m_height / 2) + 45;
        	TEXT_Y = m_height / 2 - 10;
        	STRIKE_X= 75;
        	STRIKE_Y= (m_height / 4) + 7;
        	STRIKE_LENGTH= (m_width / 3) + 100;
        	BAR_Y= (m_height / 2) + 25;
        	TIME_Y= (m_height / 2) + 75;
        	DATE_Y= (m_height / 2) + 150;
        	ALARM_Y = (m_height / 2) - 30;
        	UP_X = 50;
        	UP_Y = (m_height / 2) + 47;
        	DOWN_X = 50;
        	DOWN_Y = (m_height / 2) + 82;
        	SNOOZE_X = 85;
        	SNOOZE_Y = (m_height / 2) + 60;
        	CLEAR_X = 85;
        	CLEAR_Y = (m_height / 2) + 100;
        	LOW_Y = ALARM_Y + 30;
        }
        else if (m_width == 416) {
        	BG_X= (m_width / 2) + 70;
        	BG_Y= m_height / 4;
        	BMP_X= (m_width / 2) + 75;
        	BMP_Y= (m_height / 5);
        	BAT_X= m_width * 7/10 + 10;
        	BAT_Y= (m_height / 2) + 45;
        	TEXT_Y = m_height / 2 - 10;
        	STRIKE_X= 75;
        	STRIKE_Y= (m_height / 4);
        	STRIKE_LENGTH= (m_width / 3) + 100;
        	BAR_Y= (m_height / 2) + 25;
        	TIME_Y= (m_height / 2) + 85;
        	DATE_Y= (m_height / 2) + 150;
        	ALARM_Y = (m_height / 2) - 30;
        	UP_X = 50;
        	UP_Y = (m_height / 2) + 47;
        	DOWN_X = 50;
        	DOWN_Y = (m_height / 2) + 82;
        	SNOOZE_X = 85;
        	SNOOZE_Y = (m_height / 2) + 60;
        	CLEAR_X = 85;
        	CLEAR_Y = (m_height / 2) + 100;
        	LOW_Y = ALARM_Y + 30;
        }
        else {
        	BG_X= (m_width / 2) + 20;
        	BG_Y= m_height / 4;
        	BMP_X= (m_width / 2) + 25;
        	BMP_Y= m_height / 5;
        	BAT_X= m_width * 7/10;
        	BAT_Y = (m_height / 2) + 35;
        	TEXT_Y = m_height / 2;
        	STRIKE_X= 55;
        	STRIKE_Y= (m_height / 4) - 2;
        	STRIKE_LENGTH= (m_width / 3) + 10;
        	BAR_Y= (m_height / 2) + 25;
        	TIME_Y= (m_height / 2) + 65;
        	DATE_Y= (m_height / 2) + 105;
        	ALARM_Y = dc.getHeight() / 2 - 10;
        	UP_X = 50;
        	UP_Y = (m_height / 2) + 38;
        	DOWN_X = 50;
        	DOWN_Y = (m_height / 2) + 65;
        	SNOOZE_X = 80;
        	SNOOZE_Y = (m_height / 2) + 50;
        	CLEAR_X = 80;
        	CLEAR_Y = (m_height / 2) + 80;
        	LOW_Y = ALARM_Y + 20;
        }
    }
    
    function debugPrint(str) {
    	var time = Calendar.info(Time.now(), Time.FORMAT_SHORT);
    	var timeStr = Lang.format("$1$:$2$:$3$", [time.hour, time.min.format("%02u"), time.sec.format("%02u")]);
    	System.println("T:" + timeStr + " " + str); 
    }

}
