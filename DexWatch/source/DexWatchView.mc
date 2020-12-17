using Toybox.WatchUi;
using CGM.Dexcom as Dexcom;
//using CGM as Dexcom;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Timer as Timer;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Time.Gregorian as Calendar;
using Toybox.Math;


class DexWatchView extends WatchUi.View {


	//Coordinates
	var BG_X=0;
	var BG_Y=0;
	var BMP_X=0;
	var BMP_Y=0;
	var BAT_X=0;
	var BAT_Y=0;
	var STRIKE_X=0;
	var STRIKE_Y=0;
	var STRIKE_LENGTH=0;
	var BAR_Y=0;
	var TIME_Y=0;
	var DATE_Y=0;

	var m_authenticated = false;
	var m_dexcomData;
	var m_readTimer;
	var m_updateTimer;
	var m_alarmTimer;
	var m_responseCode = 0;
	var m_bg = 0;


    function initialize() {
        View.initialize();
        Dexcom.readLGV(m_username, m_password, m_server, method(:readResponse));
        updateUI();
        
        m_readTimer = new Timer.Timer();
        m_updateTimer = new Timer.Timer();
        m_alarmTimer = new Timer.Timer();
        m_readTimer.start( method(:readLGV), 60*1000, true );    //timer for Dexcom read requests
        m_updateTimer.start( method(:updateUI), 5*1000, true ); //timer for updateing the view
        //m_alarmTimer.start( method(:alarm), 5*60*1000, true ); //timer for alarm, 5 min
        
        
    }

    // Load your resources here
    function onLayout(dc) {
        setCoordinates(dc);
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    }

    // Update the view
    function onUpdate(dc) {
        
        var _timeElapsed = -1;
        
        // clear view
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.fillRectangle(0, 0, dc.getWidth(), dc.getHeight());
        
        //Get bg data
    	if ((m_dexcomData != null) && (m_unit == MMOL) && m_dexcomData.hasKey("BG_mmol")) { 
    		m_bg = m_dexcomData["BG_mmol"];  
    	}
    	if ((m_dexcomData != null) && (m_unit == MGDL) && m_dexcomData.hasKey("BG_mgdl")) {
    		m_bg = m_dexcomData["BG_mgdl"];  
    	}
        
        // Draw bg field
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);	
    	if ((m_bg.toNumber() > 0) && (m_unit == MMOL)) {
   			if (m_bg.toNumber() < 10) { dc.drawText(BG_X, BG_Y, Graphics.FONT_NUMBER_HOT, m_bg.toString(), Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);}
   			else { dc.drawText(BG_X + 10, BG_Y, Graphics.FONT_NUMBER_HOT, m_bg.toString(), Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);}
      	}
        if ((m_bg.toNumber() > 0) && (m_unit == MGDL)) {		
   			if (m_bg.toNumber() < 100) { dc.drawText(BG_X, BG_Y, Graphics.FONT_NUMBER_HOT, m_bg.toString(), Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);}
   			else { dc.drawText(BG_X + 10, BG_Y, Graphics.FONT_NUMBER_HOT, m_bg.toString(), Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);}
      	}
        
        //calculate elapsed time since sample
        if ((m_dexcomData != null) && m_dexcomData.hasKey("Etime") && m_dexcomData["Etime"] != null) { 
    		_timeElapsed = m_dexcomData["Etime"];
        }
        
        //display Trend bmp
        if ((m_dexcomData != null) && m_dexcomData.hasKey("Trend") && (_timeElapsed.toNumber() < 16)) {
        
        	var _bmp;
        	if (m_dexcomData["Trend"].toNumber() == 7) {_bmp = Ui.loadResource(Rez.Drawables.DoubleDown);}
        	else if (m_dexcomData["Trend"].toNumber() == 6) {_bmp = Ui.loadResource(Rez.Drawables.SingleDown);}
        	else if (m_dexcomData["Trend"].toNumber() == 5) {_bmp = Ui.loadResource(Rez.Drawables.FortyFiveDown);}
        	else if (m_dexcomData["Trend"].toNumber() == 4) {_bmp = Ui.loadResource(Rez.Drawables.Flat);}
        	else if (m_dexcomData["Trend"].toNumber() == 3) {_bmp = Ui.loadResource(Rez.Drawables.FortyFiveUp);}
        	else if (m_dexcomData["Trend"].toNumber() == 2) {_bmp = Ui.loadResource(Rez.Drawables.SingleUp);}
        	else if (m_dexcomData["Trend"].toNumber() == 1) {_bmp = Ui.loadResource(Rez.Drawables.DoubleUp);}
        	else {_bmp = Ui.loadResource(Rez.Drawables.None);}
        	
        	if (m_bg.toNumber() <10) { dc.drawBitmap(BMP_X, BMP_Y, _bmp); }
        	else { dc.drawBitmap(BMP_X + 10, BMP_Y, _bmp); }
        }
        
        //Battery warning
        var battery = System.getSystemStats().battery;
        if ((battery < 21) && (m_responseCode == Dexcom.SUCCESS)) { 
        	dc.drawBitmap(BAT_X, BAT_Y, Ui.loadResource(Rez.Drawables.BatteryAlertMid));
        	dc.drawText(BAT_X + 30, BAT_Y + 18, Gfx.FONT_XTINY, battery.format("%d") + "%", Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER);
        }
        
        //draw elapsed time since sample time OR error message       
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);   
        if (Sys.getDeviceSettings().phoneConnected) {
        	
        	if (m_bg.toNumber() == 0 && m_responseCode == 0) { 
        		dc.drawText(dc.getWidth() / 2, (dc.getHeight() / 2), Gfx.FONT_MEDIUM, "Wait...", Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
        	} 
        	else if (m_responseCode != Dexcom.SUCCESS) {
        		var _errMsg = "";
        		if (m_responseCode == 500) {_errMsg = "Server Error";}
        		else if (m_responseCode == 401) {_errMsg = "Login Error";}
        		else if ((m_responseCode == 201) || (m_responseCode == -104) || (m_responseCode == -2)) {_errMsg = "Wait...";}
        		else {_errMsg = "Error " + m_responseCode.toString();}
        		dc.drawText(dc.getWidth() / 2, (dc.getHeight() / 2), Gfx.FONT_MEDIUM, _errMsg, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
        	}
        	else {
        		dc.drawText(dc.getWidth() / 2, (dc.getHeight() / 2), Gfx.FONT_MEDIUM, _timeElapsed.toString() + " min", Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
        	}
        } 
        else { dc.drawText(dc.getWidth() / 2, (dc.getHeight() / 2), Gfx.FONT_MEDIUM, "Disconnected!", Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);}
        
        
        //strikethrough bg data field if the data is older than 15 mins
        if ((m_dexcomData != null) && (_timeElapsed.toNumber() > 15)) {
        	dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
        	if (m_bg.toNumber() < 10) { dc.fillRectangle(STRIKE_X, STRIKE_Y , STRIKE_LENGTH, 7); }
        	else { dc.fillRectangle(STRIKE_X - 10, STRIKE_Y, STRIKE_LENGTH + 20, 7); }
        	
        }
        
        //draw the color bar
        if ((m_dexcomData != null) && m_dexcomData.hasKey("Etime")) {
        	if (m_unit == MMOL) {
        		if ((m_bg.toNumber() < 1) || (_timeElapsed.toNumber() > 15)) { dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_BLACK); }
        		else if ((m_bg.toNumber() < 3.9) || (m_bg.toNumber() > 12)) {dc.setColor(Gfx.COLOR_DK_RED, Gfx.COLOR_BLACK);}
        		else if ((m_bg.toNumber() < 5) || (m_bg.toNumber() > 9)) {dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_BLACK);}
        		else {dc.setColor(Gfx.COLOR_DK_GREEN, Gfx.COLOR_BLACK);}
        		dc.fillRectangle(0, BAR_Y, dc.getWidth(), 7);
        	}
        	if (m_unit == MGDL) {
        		if ((m_bg.toNumber() < 1) || (_timeElapsed.toNumber() > 15)) { dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_BLACK); }
        		else if ((m_bg.toNumber() < 70) || (m_bg.toNumber() > 220)) {dc.setColor(Gfx.COLOR_DK_RED, Gfx.COLOR_BLACK);}
        		else if ((m_bg.toNumber() < 90) || (m_bg.toNumber() > 170)) {dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_BLACK);}
        		else {dc.setColor(Gfx.COLOR_DK_GREEN, Gfx.COLOR_BLACK);}
        		dc.fillRectangle(0, BAR_Y, dc.getWidth(), 7);
        	}
        }
        else { dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_BLACK); }
    
    	//draw current time
        var _currentTime = getCurrentTime();
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
        dc.drawText(dc.getWidth() / 2, TIME_Y, Gfx.FONT_NUMBER_MEDIUM, _currentTime, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
        
    	//draw date
    	var _now = Time.now();
    	var _dateStr = Calendar.info(_now, Time.FORMAT_MEDIUM).month + " " + Calendar.info(_now, Time.FORMAT_MEDIUM).day;
    	dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_BLACK);
    	dc.drawText(dc.getWidth() / 2, DATE_Y, Gfx.FONT_XTINY, _dateStr, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
    	
    	//raise alarm if BG is oustise range
    	/*var _mgdl = m_dexcomData["BG_mgdl"];
    	if ( (_mgdl != null) && (_mgdl > 0) && (m_alarm) && ((_mgdl <= m_bgLow) || (_mgdl >= m_bgHigh))) {
    		raiseAlarm();
    	}*/
    }
        
    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }
    
    
    	
    function readLGV() {
    	Dexcom.readLGV(m_username, m_password, m_server, method(:readResponse));
    	
    }
    
    function updateUI() {Ui.requestUpdate();}
    
    function readResponse(data, responseCode) {
    	m_responseCode = responseCode;
    	if (m_responseCode == Dexcom.SUCCESS) {
    		m_dexcomData = data;
    	}
    	
    }
    
    
    // Return the current time 
    function getCurrentTime() {
    	var timeFormat = "$1$:$2$";
        var clockTime = System.getClockTime();
        var hours = clockTime.hour;
        if (!System.getDeviceSettings().is24Hour) {
            if (hours > 12) {
                hours = hours - 12;
            }
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
    	var height = dc.getHeight();
        var width = dc.getWidth();
        
        //set coordinates based on screen size
        if (width == 218 || width == 215) {
        	BG_X= (width / 2) + 20;
        	BG_Y= height / 4;
        	BMP_X= (width / 2) + 25;
        	BMP_Y= height / 5;
        	BAT_X= width * 7/10;
        	BAT_Y= height * 2/5;
        	STRIKE_X= 55;
        	STRIKE_Y= (height / 4) - 2;
        	STRIKE_LENGTH= (width / 3) + 10;
        	BAR_Y= (height / 2) + 25;
        	TIME_Y= (height / 2) + 65;
        	DATE_Y= (height / 2) + 105;
        }
        else if (width == 240) {
        	BG_X= (width / 2) + 20;
        	BG_Y= height / 4;
        	BMP_X= (width / 2) + 25;
        	BMP_Y= height / 5;
        	BAT_X= width * 7/10;
        	BAT_Y= height * 2/5;
        	STRIKE_X= 55;
        	STRIKE_Y= (height / 4) - 2;
        	STRIKE_LENGTH= (width / 3) + 10;
        	BAR_Y= (height / 2) + 25;
        	TIME_Y= (height / 2) + 65;
        	DATE_Y= (height / 2) + 105;
        }
        else if (width == 260) {
        	BG_X= (width / 2) + 40;
        	BG_Y= height / 4 + 10;
        	BMP_X= (width / 2) + 45;
        	BMP_Y= (height / 5) + 10;
        	BAT_X= width * 7/10;
        	BAT_Y= height * 2/5;
        	STRIKE_X= 75;
        	STRIKE_Y= (height / 4) + 7;
        	STRIKE_LENGTH= (width / 3) + 15;
        	BAR_Y= (height / 2) + 25;
        	TIME_Y= (height / 2) + 75;
        	DATE_Y= (height / 2) + 115;
        }
        else if (width == 280) {
        	BG_X= (width / 2) + 40;
        	BG_Y= height / 4 + 10;
        	BMP_X= (width / 2) + 45;
        	BMP_Y= (height / 5) + 10;
        	BAT_X= width * 7/10;
        	BAT_Y= height * 2/5;
        	STRIKE_X= 75;
        	STRIKE_Y= (height / 4) + 7;
        	STRIKE_LENGTH= (width / 3) + 15;
        	BAR_Y= (height / 2) + 25;
        	TIME_Y= (height / 2) + 75;
        	DATE_Y= (height / 2) + 115;
        }
        else {
        	BG_X= (width / 2) + 20;
        	BG_Y= height / 4;
        	BMP_X= (width / 2) + 25;
        	BMP_Y= height / 5;
        	BAT_X= width * 7/10;
        	BAT_Y= height * 2/5;
        	STRIKE_X= 55;
        	STRIKE_Y= (height / 4) - 2;
        	STRIKE_LENGTH= (width / 3) + 10;
        	BAR_Y= (height / 2) + 25;
        	TIME_Y= (height / 2) + 65;
        	DATE_Y= (height / 2) + 105;
        }
    }

}
