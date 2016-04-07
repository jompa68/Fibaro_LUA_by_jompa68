--[[
%% autostart
%% properties
%% globals
--]]
-----------------------------------------------------------------------------
-- Sunnyplaces.com/PVOutput.org data
-----------------------------------------------------------------------------
-- HOWTO --
-- Create a empty VD with 6 labels, ID = Label1 to Label6
-- Fill in your API_KEY and StationID to Settings section
-----------------------------------------------------------------------------

-- 2016-02-09 ver 0.0.1 - First draft
-- 2016-02-10 ver 0.0.3 - Send push with todays energy
-- 2016-02-11 ver 0.0.4 - correction of some part of the code
-- 2016-02-11 ver 0.0.5 - send push if new version of script is out


version = "{0.0.5}"

JL = {}
versionCheck = true		-- check if new version of script exist on server

JL.language = "SW";	 -- EN, FR, SW, PL, NL, DE (default is en)


-- USER SETTINGS --
JL.APIkey = "API_KEY"  	-- Put your WU api key here
JL.SID = "40857" 							-- StationID
JL.selfId = 215								-- ID of virtual device
JL.smartphoneID = 211						-- ID of smartphone
JL.sendPush = true							-- set to true or false
JL.push_energy = "21:00"					-- send push message with todays energy
	
-- Other settings
updateEvery = 5								-- get data every xx minutes
JL.scheduler = os.time()+60*updateEvery
JL.translation = {true}

-- DONT CHANGE FROM HERE TO END --
DoNotRecheckBefore = os.time()

JL.translation["EN"] = {
  	Exiting_loop_push = "Push loop ended",
  	Errors = "Server returned an error, but will retry. Error:",
    Push_msg = "Sending push",
	Todays_value = "Todays value:",
	download = "Downloading data",
	check_script = "Checking script version on server...",
	new_version = "New version of PVOutput.org.lua script is out! ",
	script_url = "http://jonnylarsson.se/JL/",
	get_it = "Click to get it!",
    Data_processed = "All dat processed",
    Update_interval = "Updates every (min) ",
	No_data_fetched = "No data fetched",
	NO_STATIONID_FOUND = "StationID not found",
	NO_DATA_FOUND = "No data found!"
  }

JL.translation["SW"] = {
  	Exiting_loop_push = "Push loop avslutad",
  	Errors  = "Servern returnerade ett fel, omförsök pågår. Felkod:",
    Push_msg = "Skickar push",
	Todays_value = "Dagens värde:",
	download = "Laddar ner data",
	check_script = "Kollar script version på server...",
	new_version = "Det finns en ny PVOutput.org.lua version av skriptet! ",
	script_url = "http://jonnylarsson.se/JL/",
	get_it = "Klicka här för att hämta den!",
    Data_processed = "All data processat",
    Update_interval = "Uppdateras var (min) ",
	No_data_fetched = "Inget data hämtat",
	NO_STATIONID_FOUND = "StationID ej funnet",
	NO_DATA_FOUND = "Ingen data finns"
 }

Debug = function ( color, message )
  fibaro:debug(string.format('<%s style="color:%s;">%s</%s>', "span", color, message, "span")); 
end

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
content = "PVOutput.org.lua"
local url = 'http://jonnylarsson.se/JL/'..content

getMethod(url, function(resp)
	s = resp.data
    serverVersion = string.match(s, "{(.-)}");
    scriptVersion = string.match(version, "{(.-)}");
    if serverVersion > scriptVersion then
    	Debug("grey",  JL.translation[JL.language]["check_script"]) 
    	Debug("yellow", JL.translation[JL.language]["new_version"]..'<a href="http://jonnylarsson.se/JL/PVOutput.org.lua" target="_blank" style="display:inline;color:Cyan">'..JL.translation[JL.language]["get_it"]..'</a>')
		if JL.sendPush then
			fibaro:call(JL.smartphoneID , "sendPush", JL.translation[JL.language]["new_version"].." "..JL.translation[JL.language]["script_url"])
		end
    end
    end,
  	function(err)
    print('error' .. err)
end
)
end

local http = net.HTTPClient()

local function error(err)
  	Debug( "red", "[HTTPClient:request]. Error: "..err );
end

local function process(response)
  http:request("http://pvoutput.org/service/r2/getstatus.jsp?key="..JL.APIkey.."&sid="..JL.SID,{
      options = {method = 'GET'},
      success = process,
      error = error
    })
	if response then -- the first time you enter the loop, this will be nil
    	if response.status~=200 then
			Debug( "red", JL.translation[JL.language]["Errors"]..response.status)
    		else
      			JL.now = os.date("%H:%M")
				local myString = response.data
				local myTable = myString:split(",")
      			fibaro:call(JL.selfId , "setProperty", "ui.Label1.value", myTable[1]);
      			fibaro:call(JL.selfId , "setProperty", "ui.Label2.value", myTable[2]);
      			fibaro:call(JL.selfId , "setProperty", "ui.Label3.value", (myTable[3]/1000).." kWh");
      			fibaro:call(JL.selfId , "setProperty", "ui.Label4.value", myTable[4].." W");
      			fibaro:call(JL.selfId , "setProperty", "ui.Label5.value", myTable[7].." kW/kW");
      			fibaro:call(JL.selfId , "setProperty", "ui.Label6.value", myTable[9].." V");
    			if JL.sendPush then
					if (os.date("%H:%M") == JL.push_energy) then
						if versionCheck then
							versionChecker()
						end
						fibaro:call(JL.smartphoneID , "sendPush", JL.translation[JL.language]["Todays_value"]..(myTable[3]/1000).." kWh")
					end
				end      
				JL.scheduler = os.time()+updateEvery*60
				Debug("grey", JL.translation[JL.language]["Data_processed"])
        		Debug("grey", JL.translation[JL.language]["Update_interval"].." "..updateEvery)
    	end
    sleepAndcheck = 0
		while sleepAndcheck <= 20*updateEvery do
			fibaro:sleep(3000)
			sleepAndcheck = sleepAndcheck+1
			if (DoNotRecheckBefore <= os.time()) and ((JL.scheduler == os.time) or (os.date("%H:%M") == JL.push_energy)) then
				Debug("green", JL.translation[JL.language]["Push_msg"]);
        		Debug("grey", JL.translation[JL.language]["Exiting_loop_push"]);
				DoNotRecheckBefore = os.time()+60
				sleepAndcheck = 20*updateEvery
			end
		end
  	end
end

function string:split( inSplitPattern, outResults )
  if not outResults then
    outResults = { }
  end
  local theStart = 1
  local theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
  while theSplitStart do
    table.insert( outResults, string.sub( self, theStart, theSplitStart-1 ) )
    theStart = theSplitEnd + 1
    theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
  end
  table.insert( outResults, string.sub( self, theStart ) )
  return outResults
end


Debug( "orange", "Sunnyplaces.com/PVOutput.org data - LUA Scripting by Jonny Larsson 2016" );
Debug( "white", "Version: "..version);
if versionCheck then
versionChecker()
end
process() --this starts an endless loop, until an error occurs


