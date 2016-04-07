--[[
%% autostart
%% properties
%% globals
AlarmClockStatus
AlarmClockDays1
AlarmClockDays2
AlarmClockTime1
AlarmClockTime2

--]]

--[[ 

INSTRUCTIONS
* 
* add those devices you want to use in this script to "devices"
* set dimmer device to a "_maxValue"
* set "_duration" to a value in minutes for how long the dim function should be active
* to activate debug, helper and versionCheck set the value to true or false

* helper is to show all "lights" in your system.
* debug is debug :)
* versionCheck checks if script is updated. Click on "Get it" 

--]]

-- SCENE SCENARIO
-- Advanced wakeup scene to turnOn lights at specified time, time you set in
-- alarm clock virtual device
-- Set value for how much the blinds should open with the slider in VD.


-- REFERENCE
-- forum.fibaro.com, lua.org, domotique-fibaro.fr, www.gronahus.se 
-- Thanks to robmac, stevenvd for good LUA functions code.

-- 2015-11-01 ver 2.0.0 new version of scene and virtual device. Supports 2 alarm.
-- 2015-11-02 ver 2.0.1 list all lights in scene. Add those you want to use in 'User Settings' section
-- 2015-11-27 ver 2.1.1 adjustment of debug lines and added variable to %% globals

version = "{2.1.1}"

-------------------- USER SETTINGS -----------------------
devices = {339,341,24,256,335,337,25}	-- Lights, dimmers and blinds
_maxValue = 50	 			-- When dimmer reach this value it will stop there
_duration = 5				-- Time in minutes for how long wakeUp should be active
debug = true				-- set debug to true or false
helper = false				-- loop through all devices and search for lights/dimmers/binarySwitch etc
versionCheck = true		-- check if new version of script exist on server

-- EXTRA FUNCTIONS, OPTIONS
-- Start Sonos/Internet Radio
vDeviceID = 393 			-- Id of Sonos virtual device
vDeviceButton = 7 			-- Play
vDeviceFunc = false			-- set to true to activate Sonos/Internet Radio

-- Dimmers to set to fixed value when alarmWakeup
Dimdevices = {343}			-- Dimmers to set to fixed value
fixedValue = 50				-- Dimmer value
DimdevicesFunc = false		-- set to true or false

--TimeOfDay variable --
varTOD = "TimeOfDay"		-- TOD translate
varTODMorning = "Morgon"	-- TOD Morning translate
varState = "SleepState"		-- TOD translate
varStateMorning = "Vaken"	-- TOD Morning translate
variableFunc = true			-- set to true or false
-----------------------------------------------------------
timeNow = os.date("%H:%M")
dayName = os.date("%A")

------------- DO NOT CHANGE LINES BELOW -------------------
startSource = fibaro:getSourceTrigger();
sortedtbl = {}
tmptbl = {}
runOnce = true
alarmTime1 = fibaro:getGlobal("AlarmClockTime1")
alarmTime2 = fibaro:getGlobal("AlarmClockTime2")
alarmDay1 = fibaro:getGlobal("AlarmClockDays1")
alarmDay2 = fibaro:getGlobal("AlarmClockDays2")
blindUpLevel = fibaro:getGlobal("openBlinds")

alarmTimes = {alarmTime1, alarmTime2}
alarmDays = {alarmDay1, alarmDay2}


-- Give debug a fancy color
Debug = function ( color, message )
  fibaro:debug(string.format('<%s style="color:%s;">%s</%s>', "span", color, message, "span")); 
end

Debug( "orange", "WakeUpTime scene - LUA Scripting by Jonny Larsson 2015" );
Debug( "orange", "Version: "..version);
Debug( "lightgreen", "-- Set alarmtime in virtual device --");
Debug( "lightgreen", "-- Set slider to how much blinds should open --");
if alarmDay1 ~= "Off" then 
  Debug( "grey", "Next alarm time is set to next "..alarmDay1..":"..alarmTime1)
end
if alarmDay2 ~= "Off" then 
  Debug( "grey", "Next alarm time is set to next "..alarmDay2..":"..alarmTime2)
end

function timerFunction()
timeNow = os.date("%H:%M") 
-- Check if alarmDay2 is in use, else remove it from tables
if alarmDay2 == "Off" then
   table.remove(alarmDays, 2)
   table.remove(alarmTimes, 2)
end
for i = 1,#alarmDays do
    	--Check if day and time is same as alarmDays and alarmTimes
    	if timeNow == alarmDays[i] and alarmTimes[i] then
      		-- Sort table of devices
			sortTable()
    	--else 
    		--if (debug) then
    			--Debug( "grey", "Next alarmTime is set to next "..alarmDays[i]..":"..alarmTimes[i]);
    		--end
      	end
end

setTimeout(timerFunction, 60*1000)
end


sortTable = function()
   for i = 1,#devices do
      lightItems = devices[i];
        if fibaro:getType(lightItems) == "com.fibaro.FGR221" or fibaro:getType(lightItems) == "com.fibaro.FGRM222" or fibaro:getType(lightItems) == "com.fibaro.rollerShutter" or fibaro:getType(lightItems) == "com.fibaro.FGWP101" then
            table.insert(sortedtbl,lightItems)
       elseif fibaro:getType(lightItems) == "com.fibaro.binarySwitch" then
          table.insert(sortedtbl,lightItems)
       elseif fibaro:getType(lightItems) == "com.fibaro.multilevelSwitch" then
          table.insert(sortedtbl,lightItems)
         end
   end
     turnLightOn()
end


-- TurnOn lights, functions
turnLightOn = function()
   for i = 1,#sortedtbl do
      lightItems = sortedtbl[i];
       if fibaro:getType(lightItems) == "com.fibaro.FGR221" or fibaro:getType(lightItems) == "com.fibaro.FGRM222" or fibaro:getType(lightItems) == "com.fibaro.rollerShutter" or fibaro:getType(lightItems) == "com.fibaro.FGWP101" then
      		fibaro:call(lightItems, "setValue", blindUpLevel)
         elseif fibaro:getType(lightItems) == "com.fibaro.binarySwitch" then
            fibaro:call(lightItems, "turnOn")
         elseif fibaro:getType(lightItems) == "com.fibaro.multilevelSwitch" then
         	table.insert(tmptbl,lightItems)
       end
    end
		if (DimdevicesFunc) then
   			for i = 1,#Dimdevices do
       			DimItems = Dimdevices[i];
       			fibaro:call(DimItems, "setValue", fixedValue);
    		end
		end
if (vDeviceFunc) then
   		fibaro:call(vDeviceID, "pressButton", vDeviceButton)
end
if tmptbl == nil then
if (debug) then
	Debug( "red",'No dimmers in table, will not run next function')
end
else wakeUpFunc()end

end

-- Now its time to turnOn some lights
wakeUpFunc = function()
if (debug) then
	Debug( "green",'Start soft wakeup light')
end
for i = 1,#tmptbl do
    lightItems = tmptbl[i];
    fibaro:call(lightItems, "setValue", "0");
	fibaro:sleep(200);
	addValue = _maxValue / tonumber(_duration);
    local currentValueLights = tonumber(fibaro:getValue(lightItems, "value"));
    local newValue = currentValueLights + addValue;
end
fibaro:sleep(1000);
  
for variable = 0, _maxValue - 1, addValue do
  		local currentValueLights = tonumber(fibaro:getValue(lightItems, "value"));
  		if (variable ~= 0 and currentValueLights == 0 ) then
    		if (debug) then
     			Debug( "blue","timer stop, lights turned off");
    		end
    		break;
  		end
  		local newValue = currentValueLights + addValue;
  		if (debug) then
  			Debug( "yellow",'Increase value to ' ..  newValue) 
  		end
  		--Increases the value of the lamp
    	for i = 1,#tmptbl do
    	lightItems = tmptbl[i];
  			fibaro:call(lightItems, "setValue", newValue);
      	end
  		--Waits before the next step
    	fibaro:sleep(60*1000);
end
end

insert2Table = function()
if runOnce then
sortedtbl = {}
  for i = 1, 500 do
    if ("com.fibaro.FGR221" == fibaro:getType(i) or "com.fibaro.FGRM222" == fibaro:getType(i) or "com.fibaro.rollerShutter" == fibaro:getType(i) or "com.fibaro.multilevelSwitch" == fibaro:getType(i) or "com.fibaro.multilevelSwitch" == fibaro:getType(i) or "com.fibaro.binarySwitch" == fibaro:getType(i) or "com.fibaro.FGWP101" == fibaro:getType(i)) then
      	table.insert(sortedtbl,i)
    end
  end
end
  Debug( "grey","All your lights will be listed in a table below, add them in devices in 'User Settings' section")
  Debug( "grey",json.encode(sortedtbl))
  runOnce = false
end

------ CHECK SCRIPT VERSION ON SERVER ------
function versionChecker()
local function getMethod(requestUrl, successCallback, errorCallback)
local http = net.HTTPClient()
  http:request(requestUrl, {
      options = {
        method = 'GET',
        headers = {
        },
      },
      success = successCallback,
      error = errorCallback
  })
end
content = "ACWUT.lua"
local url = 'http://jonnylarsson.se/JL/'..content

getMethod(url, function(resp)
	s = resp.data
    serverVersion = string.match(s, "{(.-)}");
    scriptVersion = string.match(version, "{(.-)}");
    if serverVersion > scriptVersion then
    	Debug("grey", "Checking script version...") 
    	Debug("yellow", "There is a new version out! "..'<a href="http://jonnylarsson.se/JL/ACWUT.lua" target="_blank" style="display:inline;color:Cyan">Get it!</a>')

    end
    end,
  	function(err)
    print('error' .. err)
end
)
end
---------------- SCRIPT CHECK END ---------------------



------------------ START OF SCENE ----------------------
if ( startSource["type"] == "autostart" ) or ( startSource["type"] == "global" ) then
	if helper then
		insert2Table()
	end
	if versionCheck then
		versionChecker()
	end
  	if alarmDay1 ~= "Off" or alarmDay2 ~= "Off" then
		timerFunction()
    else Debug( "blue","Scene is not active until you set alarmclock time and day in virtual device")
    end
end
