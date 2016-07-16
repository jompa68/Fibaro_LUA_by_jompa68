--[[
%% autostart
%% properties
%% globals
--]]
-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
-- HOWTO --
-- 1. Create a virtual device with 9 labels and set the ID to like below, else this scene will not work.
-- 2. lblTemp, lblHum, lblBar, lblWind, lblRain, lblFcst, lblStation, lblUpdate, lblNotify
-- 3. Change ID of virtual device in WU.selfId

-- FIRST TIME USERS NEEDS TO COPY ALL CODE TO SCENE, after version 2.5.0 it should only be neccessary to update from "UPDATE FROM HERE" text

-- NOTE --
-- Scheduled time you set for forecast push is just an indication of time.
-- Real time will be the hour you set + minute of when scene starts.
-- Script will check server version for new updated version (default = true)

-- WU WeatherData - Fetch weather data from wunderground.com. Multilanguage support!
-- Inspired by GEA(steven), stevenvd, Krikroff and many other users.
-- Source - forum.fibaro.com, domotique-fibaro.fr and worldwideweb
-- Special thanks to petergebruers from forum.fibaro.com with demo script
--
--

-- PWS = Personal Weather Station
-- LOCID = Public station
--
-- 
-- 2014-03-22 - Permissions granted from Krikroff :)
-- 2014-03-23 - Added rain and forecast, Added FR language. 
-- 2014-03-23 - Language variable changed to get the translation from wunderground.com in forcast
-- 2014-03-24 - Added PL language
-- 2014-03-24 - Select between PWS or LOCID to download weather data
-- 2015-10-23 - New source code.
-- 2015-10-23 - Added NL translation
-- 2015-11-16 - Added DE, FR translation. Fixed some bug in the code(hardcoded smartphoneID,inch to metric for rain value)
-- 2015-11-18 - Script moved to scene instead of mainloop in VD. VD is only used as GUI.
-- 2015-11-18 - Send push if script cannot fetch data
-- 2015-11-26 - adjustment of code. Function from sebcbien at domotique-fibaro.fr
-- 2015-11-27 - Oops! Removed forecast push by mistace.
-- 2016-02-11 - send push if new version of script is out
-- 2016-03-31 - Added NO translation, did cleanup the code a little bit.
-- 2016-03-31 - It is now posible to use Telegram as push. Change WU.pushOption value to Telegram or Fibaro. 
--            - also change WU.Telegramtoken and WU.Telegramchat_id to your values
-- 2016-04-01 - Fixed bug when using Telegram push, forecast must send with lowercases.
-- 2016-05-26 - Added support for multiple smartphone id when sending push
-- 2016-05-30 - Implemented "UPDATE SECTION"
-- 2016-07-13 - Bug fixed some code for sendPush to fibaro app
-- 2016-07-14 - Telegram, possible to have forecast pushed to 2 different chat_id's
-- 2016-07-15 - Save all importent values to variable. 
-- 2016-07-15 - Added RO, GR, PT, RU and CZ translation

version = "{2.5.0}"

WU = {}


versionCheck = true   -- check if new version of script exist on server

WU.language = "SW";  -- EN, FR, SW, PL, NL, DE, NO, RO, CZ, GR, PT, RU (default is en)


-- WU settings
WU.APIkey = "14eaxxxxxxxxx"       -- Put your WU api key here
WU.PWS = "IGVLEBOR5"          -- The PWS location to get data for (Personal Weather Station)
WU.LOCID = "SWXX0076"         -- The location ID to get data for (City location)
WU.station = "PWS"            -- PWS or LOCID
  
-- Other settings
WU.smartphoneID = {281,32}      -- your smartphone ID's ie 211,233,333
WU.push_fcst1 = "06:30"       -- time when forecast for today will be pushed to smartphone
WU.push_fcst2 = "17:00"       -- time when forecast for tonight will be pushed to smartphone
WU.sendPush = true            -- send forecast with push
WU.pushOption = "Telegram"      -- Use Fibaro or Telegram?

-- Telegram settings
-- IMPORTANT --
-- Telegramtoken needs to splitted into 2 parts. First part1 is before the ":", part2 is after the ":"
WU.Telegramtoken1_part1 = "1877xxxxx"
WU.Telegramtoken1_part2 = "AAHfzhTcsxxxxxxxxxxxxxxxxxx"
WU.Telegramchat_id1 = "2025xxxxx"
-- If you want forecast to be pushed to a second phone
WU.dualChat_ID = false         -- set to true if more then 1 smartphone that should have forecast pushed.
WU.Telegramtoken2_part1 = "1877xxxxx"
WU.Telegramtoken2_part2 = "AAHfzhTcsxxxxxxxxxxxxxxxxxx"
WU.Telegramchat_id2 = "2025xxxxx"

updateEvery = 5               -- get data every xx minutes
WU.selfId = 150               -- ID of virtual device


---- UPDATE FROM HERE ----
-- Read settings from variable
if not(fibaro:getGlobal("WUAPI") == nil) and (fibaro:getGlobal("Telegramtoken_part1") == nil) and (fibaro:getGlobal("Telegramtoken_part2") == nil) and (fibaro:getGlobal("Telegramchat_id") == nil) and (fibaro:getGlobal("Telegramchat_id2") == nil ) then
  WU.APIkey = fibaro:getGlobal("WUAPI")
  WU.Telegramtoken1 = fibaro:getGlobal("Telegramtoken1_part1")..":"..fibaro:getGlobal("Telegramtoken1_part2")
  WU.Telegramchat_id1 = fibaro:getGlobal("Telegramchat_id1")
  WU.Telegramurl1 = "https://api.telegram.org/bot"..WU.Telegramtoken1.."/sendMessage?chat_id="..WU.Telegramchat_id1.."&text="
 
  if WU.dualChat_ID then
    WU.Telegramtoken2 = fibaro:getGlobal("Telegramtoken2_part1")..":" fibaro:getGlobal("Telegramtoken2_part2")
    WU.Telegramchat_id2 = fibaro:getGlobal("Telegramchat_id2")
    WU.Telegramurl2 = "https://api.telegram.org/bot"..WU.Telegramtoken2.."/sendMessage?chat_id="..WU.Telegramchat_id2.."&text="
  end
end
-- End read settings from variable

WU.translation = {true}
WU.currentDate = os.date("*t"); 
DoNotRecheckBefore = os.time()
WU.scheduler = os.time()+60*updateEvery

WU.translation["EN"] = {
    Exiting_loop_push = "Exiting_loop_push",
    Push_forecast = "Push forecast",
    Temperature = "Temperature",
    Humidity = "Humidity",
    Pressure = "Pressure",
    Wind = "Wind",
    Rain = "Rain",
    Forecast = "Forecast",
    Station = "Station",
    Fetched = "Fetched",
    Data_processed = "Data processed",
    Update_interval = "Next update will be in (min)",
    No_data_fetched = "No data fetched",
    new_version = "New version of WUWeather.lua script is out! ",
    script_url = "http://jonnylarsson.se/JL/",
    NO_STATIONID_FOUND = "No stationID found",
    NO_DATA_FOUND = "No data found"
  }
  
WU.translation["FR"] = {
    Exiting_loop_push = "Exiting_loop_push",
    Push_forecast = "Push prévisions",
    Temperature = "Température",
    Humidity = "Humidité",
    Pressure = "Pression",
    Wind = "Vent",
    Rain = "Pluie",
    Forecast = "Prévisions",
    Station = "Station",
    Fetched = "Reçu",
    Data_processed = "Données Analysées",
    Update_interval = "Prochaine update prévue dans (min)",
    No_data_fetched = "Pas de données reçues",
    new_version = "New version of WUWeather.lua script is out! ",
    script_url = "http://jonnylarsson.se/JL/",
    NO_STATIONID_FOUND = "StationID non trouvée",
    NO_DATA_FOUND = "Pas de données disponibles"
  }
 
WU.translation["SW"] = {
    Exiting_loop_push = "Push loop avslutad",
    Push_forecast = "Push forecast",
    Temperature = "Temperatur",
    Humidity = "Fuktighet",
    Pressure = "Barometer",
    Wind = "Vind",
    Rain = "Regn",
    Forecast = "Prognos",
    Station = "Station",
    Fetched = "Hämtat",
    Data_processed = "All data processat",
    new_version = "New version of WUWeather.lua script is out! ",
    script_url = "http://jonnylarsson.se/JL/",
    Update_interval = "Nästa uppdatering är om (min)",
    No_data_fetched = "Inget data hämtat",
    NO_STATIONID_FOUND = "StationID ej funnet",
    NO_DATA_FOUND = "Ingen data hos WU"
 }
 
WU.translation["PL"] = {
    Exiting_loop_push = "Exiting_loop_push",
    Push_forecast = "Push prognoza",
    Temperature = "Temperatura",
    Humidity = "Wilgotność",
    Pressure = "Pressure",
    Wind = "Wiatr",
    Rain = "Deszcz",
    Forecast = "Prognoza",
    Station = "Stacja",
    Fetched = "Nie pobrano danyc",
    Data_processed = "Dane przetworzone",
    new_version = "New version of WUWeather.lua script is out! ",
    script_url = "http://jonnylarsson.se/JL/",
    No_data_fetched = "Brak danych",
    Update_interval = "Następna aktualizacja za (min)",
    NO_STATIONID_FOUND = "No stationID found",
    NO_DATA_FOUND = "Brak danych"
  }
  
WU.translation["NL"] = {
    Exiting_loop_push = "Exiting_loop_push",
    Push_forecast = "Push verwachting",
    Temperature = "Temperatuur",
    Humidity = "Vochtigheid",
    Pressure = "Druk",
    Wind = "Wind",
    Rain = "Regen",
    Forecast = "Verwachting",
    Station = "Weerstation",
    Fetched = "Ontvangen",
    Data_processed = "Gegevens verwerkt",
    new_version = "New version of WUWeather.lua script is out! ",
    script_url = "http://jonnylarsson.se/JL/",
    Update_interval = "Volgende update in (min)",
    No_data_fetched = "Geen gegevens ontvangen",
    NO_STATIONID_FOUND = "Geen stationID gevonden",
    NO_DATA_FOUND = "Geen gegevens gevonden"
}

WU.translation["DE"] = {
    Exiting_loop_push = "Exiting_loop_push",
    Push_forecast = "Push vorhersage",
    Temperature = "Temperatur",
    Humidity = "Luftfeuchtigkeit",
    Pressure = "Luftdruck",
    Wind = "Wind",
    Rain = "Regen",
    Forecast = "Vorhersage",
    Station = "Station",
    Fetched = "Abgerufen",
    Data_processed = "Daten verarbeitet",
    new_version = "New version of WUWeather.lua script is out! ",
    script_url = "http://jonnylarsson.se/JL/",
    No_data_fetched = "Keine Daten abgerufen",
    Update_interval = "Das nächste Update in (min)",
    NO_STATIONID_FOUND = "Keine stationID gefunden",
    NO_DATA_FOUND = "Keine Daten gefunden"
}

WU.translation["NO"] = {
    Exiting_loop_push = "Exiting_loop_push",
    Push_forecast = "Push værmelding",
    Temperature = "Temperatur",
    Humidity = "Fuktighet",
    Pressure = "Barometer",
    Wind = "Vind",
    Rain = "Regn",
    Forecast = "Prognose",
    Station = "Stasjon",
    Fetched = "Hentet",
    Data_processed = "All data prosessert",
    Update_interval = "Neste oppdatering om (min)",
    No_data_fetched = "Ingen data hentet",
    NO_STATIONID_FOUND = "StasjonID ikke funnet",
    NO_DATA_FOUND = "Ingen data hos WU"
}

WU.translation["CZ"] = {
    Exiting_loop_push = "Exiting_loop_push",
    Push_forecast = "Push forecast",
    Temperature = "Teplota",
    Humidity = "Vlhkost",
    Pressure = "(Atmosférický) Tlak",
    Wind = "Vítr",
    Rain = "Déšť ",
    Forecast = "Předpověď",
    Station = "Stanice",
    Fetched = "Předána",
    Data_processed = "Data_zpracována",
    Update_interval = "Časová_prodleva_mezi_aktualizacemi",
    No_data_fetched = "Data_nebyla_předána",
    NO_STATIONID_FOUND = "Stanice_nenalezena",
    NO_DATA_FOUND = "Data_Nenalezena"
}

WU.translation["RO"] = {
    Exiting_loop_push = "Exiting_loop_push",
    Push_forecast = "Prognoza apăsare",
    Temperature = "Temperatura",
    Humidity = "Umiditate",
    Pressure = "Presiune",
    Wind = "Vant",
    Rain = "Ploaie",
    Forecast = "Prognoza",
    Station = "Statie",
    Fetched = "Preluat",
    Data_processed = "Datele prelucrate",
    Update_interval = "Urmatorul update va fi in (min)",
    No_data_fetched = "Nu exista date preluate",
    NO_STATIONID_FOUND = "Nu a fost gasit stationID ",
    NO_DATA_FOUND = "Datele nu au fost gasite"
}

WU.translation["GR"] = {
    Exiting_loop_push = "Exiting_loop_push",
    Push_forecast = "Πρόγνωση push",
    Temperature = "Θερμοκρασία",
    Humidity = "Υγρασία",
    Pressure = "Πίεση",
    Wind = "Άνεμος",
    Rain = "Βροχή",
    Forecast = "Πρόβλεψη",
    Station = "Σταθμός",
    Fetched = "Παραλήφθηκαν",
    Data_processed = "Επεξεργασμένα δεδομένα",
    Update_interval = "Η επόμενη ενημέρωση θα γίνει σε (min)",
    No_data_fetched = "Δεν παραλήφθηκαν δεδομένα",
    NO_STATIONID_FOUND = "Δεν βρέθηκε το Station ID",
    NO_DATA_FOUND = "Δεν βρέθηκαν δεδομένα"
}

WU.translation["PT"] = {
    Exiting_loop_push = "Exiting_loop_push",
    Push_forecast = "Previsão do impulso",
    Temperature = "Temperatura",
    Humidity = "Humidade",
    Pressure = "Pressão",
    Wind = "Vento",
    Rain = "Chuva",
    Forecast = "Previsão",
    Station = "Estação",
    Fetched = "Procurar",
    Data_processed = "Dados processados",
    Update_interval = "Próxima atualização será em (min)",
    No_data_fetched = "Não foram encontrados dados",
    NO_STATIONID_FOUND = "Não foi detetada nenhuma estação",
    NO_DATA_FOUND = "Não foram encontrados dados"
}

WU.translation["RU"] = {
    Exiting_loop_push = "Exiting_loop_push",
    Push_forecast = "Прогноз Нажмите",
    Temperature = "Температура",
    Humidity = "Влажность",
    Pressure = "Давление",
    Wind = "Ветер",
    Rain = "Дождь",
    Forecast = "Прогноз",
    Station = "Станция",
    Fetched = "Получено",
    Data_processed = "Данные обработаны",
    Update_interval = "Следующее обновление через (мин.)",
    No_data_fetched = "Данные не получены",
    NO_STATIONID_FOUND = "Данная станция не найдена",
    NO_DATA_FOUND = "Данные не найдены"
}

if WU.station == "LOCID" then
    locationID = WU.LOCID
elseif 
    WU.station == "PWS" then
    locationID = WU.PWS
end

Debug = function ( color, message )
  fibaro:debug(string.format('<%s style="color:%s;">%s</%s>', "span", color, message, "span")); 
end
local function log(str) if debug then fibaro:debug(str); end; end
local function errorlog(str) fibaro:debug("<font color='red'>"..str.."</font>"); end

function Telegrambot(msg)
local selfhttp = net.HTTPClient({timeout=2000})
url = WU.Telegramurl1 .. msg

selfhttp:request(url, {
  options={
    headers = selfhttp.controlHeaders,
    data = requestBody,
    method = 'GET'
    },
  success = function(status)
    local result = json.decode(status.data);
    if result.ok == true then
      Debug("grey", "Sucessfully sent message to Telegram Bot...") 
    else
      --errorlog("failed");
      print(status.data);
    end
  end,
  error = function(error)
    --errorlog("ERROR")
    Debug("red", error) 
  end
})

if WU.dualChat_ID then
url2 = WU.Telegramurl2 .. msg

selfhttp:request(url2, {
  options={
    headers = selfhttp.controlHeaders,
    data = requestBody,
    method = 'GET'
    },
  success = function(status)
    local result = json.decode(status.data);
    if result.ok == true then
      Debug("grey", "Sucessfully sent message to Telegram Bot...") 
    else
      --errorlog("failed");
      print(status.data);
    end
  end,
  error = function(error)
    --errorlog("ERROR")
    Debug("red", error) 
  end
})  
end
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
content = "WUWeather.lua"
local url = 'http://jonnylarsson.se/JL/'..content

getMethod(url, function(resp)
  s = resp.data
    serverVersion = string.match(s, "{(.-)}");
    scriptVersion = string.match(version, "{(.-)}");
    if serverVersion > scriptVersion then
      Debug("grey", "Checking script version...") 
      Debug("yellow", "There is a new version out! "..'<a href="http://jonnylarsson.se/JL/WUWeather.lua" target="_blank" style="display:inline;color:Cyan">Get it!</a>')
    if WU.sendPush then
      if WU.pushOption == "Fibaro" then
        fibaro:call(WU.smartphoneID , "sendPush", WU.translation[WU.language]["new_version"].." "..WU.translation[WU.language]["script_url"])
        elseif WU.pushOption == "Telegram" then
        Telegrambot(WU.translation[WU.language]["new_version"].." "..WU.translation[WU.language]["script_url"])
      end
    end
    end
    end,
    function(err)
    print('error' .. err)
end
)
end

local http = net.HTTPClient()

local function errorWU(err)
  if WU.pushOption == "Fibaro" then
    fibaro:call(WU.smartphoneID , "sendPush", "[WUWeather scene]. Error: "..err )
  elseif WU.pushOption == "Telegram" then
    Telegrambot("[WUWeather scene]. Error: "..err )
  end
  Debug( "red", "[HTTPClient:request]. Error: "..err );
end

local function sendPopup()
-- variable containing path of Motion Sensor’s icon
local imgUrl = popupIMG
-- pop-up call
HomeCenter.PopupService.publish({
        -- title (required)
    title = 'Weather forecast',
        -- subtitle(optional), e.g. time and date of the pop-up call
    subtitle = os.date("%I:%M:%S %p | %B %d, %Y"),
        -- content header (optional)
    contentTitle = 'Forecast from WU Weather',
        -- content (required)
    contentBody = fcastday.." - "..fcast,
        -- notification image (assigned from the variable)
    img = imgUrl,
        -- type of the pop-up
    type = 'Info',
}) 
end


function createGlobalIfNotExists(varName, defaultValue)
  if (fibaro:getGlobal(varName) == nil) then
    Debug("cyan", "Creating the variable: "..varName.." with value: "..defaultValue) 
    newVar = {}
    newVar.name = varName
    newVar.value = defaultValue
    local http = net.HTTPClient()
    http:request("http://127.0.0.1:11111/api/globalVariables", { options = { method = 'POST', data = json.encode(newVar)}}) 
  end
end

local function processWU(response)
  http:request("http://api.wunderground.com/api/"..WU.APIkey.."/conditions/forecast/lang:"..WU.language.."/q/"..WU.station..":"..locationID..".json",{
      options = {method = 'GET'},
      success = processWU,
      error = errorWU
    })
  Debug( "green", "Now downloading data from www.wunderground.com");
  if response then -- the first time you enter the loop, this will be nil
    if response.status~=200 then
    Debug( "red", "Server returned an error, but will retry. Error: "..response.status)
    else
        WU.now = os.date("%H:%M")
        jsonTable = json.decode(response.data)
        stationID = jsonTable.current_observation.station_id
        city = jsonTable.current_observation.observation_location.city
        humidity = jsonTable.current_observation.relative_humidity
        temperature = jsonTable.current_observation.temp_c
        pression = jsonTable.current_observation.pressure_mb
        wind = jsonTable.current_observation.wind_kph
        rain = jsonTable.current_observation.precip_today_metric
        icon = jsonTable.current_observation.icon
        weathericon = jsonTable.current_observation.icon_url
        fcstday1 = jsonTable.forecast.txt_forecast.forecastday[1].title
        fcst1 = jsonTable.forecast.txt_forecast.forecastday[1].fcttext_metric
        fcst1icon = jsonTable.forecast.txt_forecast.forecastday[1].icon_url
        fcstday2 = jsonTable.forecast.txt_forecast.forecastday[2].title
        fcst2 = jsonTable.forecast.txt_forecast.forecastday[2].fcttext_metric
        fcst2icon = jsonTable.forecast.txt_forecast.forecastday[2].icon_url
        if (stationID ~= nil) then
          fibaro:call(WU.selfId , "setProperty", "ui.lblStation.value", locationID);
          fibaro:call(WU.selfId , "setProperty", "ui.lblCity.value", city);
          fibaro:call(WU.selfId , "setProperty", "ui.lblTemp.value", WU.translation[WU.language]["Temperature"].." "..temperature.." °C");
          fibaro:call(WU.selfId , "setProperty", "ui.lblHum.value", WU.translation[WU.language]["Humidity"].." "..humidity);
          fibaro:call(WU.selfId , "setProperty", "ui.lblBar.value", WU.translation[WU.language]["Pressure"].." "..pression.." mb");
          fibaro:call(WU.selfId , "setProperty", "ui.lblWind.value", WU.translation[WU.language]["Wind"].." "..wind.." km/h");
          fibaro:call(WU.selfId , "setProperty", "ui.lblRain.value", WU.translation[WU.language]["Rain"].." "..rain.." mm");
              if (WU.now >= "03:00" and WU.now <= "15:59") then
                  fibaro:call(WU.selfId , "setProperty", "ui.lblFcst.value",WU.translation[WU.language]["Forecast"].." "..fcstday1.." - "..fcst1);
                  --fibaro:call(WU.selfId , "setProperty", "ui.lblIcon.value","<img src=http://jonnylarsson.se/JL/png/"..icon..".png>");
                elseif (WU.now >= "16:00" and WU.now <= "23:59") then
                  --fibaro:call(WU.selfId , "setProperty", "ui.lblIcon.value","<img src=http://jonnylarsson.se/JL/png/nt_"..icon..".png>");
                fibaro:call(WU.selfId , "setProperty", "ui.lblFcst.value", WU.translation[WU.language]["Forecast"].." "..fcstday2.." - "..fcst2);
              end
            if WU.sendPush then
                if (os.date("%H:%M") == WU.push_fcst1) then
                  if versionCheck then
                    versionChecker()
                  end
                  if WU.pushOption == "Fibaro" then
                    fcastday = fcstday1
                    fcast = fcst1
                    for i, j in pairs(WU.smartphoneID) do
                      fibaro:call(j, "sendPush", fcstday1.." - "..fcst1)
                      popupIMG = "http://jonnylarsson.se/JL/png/"..icon..".png"
                      sendPopup()
                    end
                  elseif WU.pushOption == "Telegram" then
                  Telegrambot(fcstday1.." - "..string.lower(fcst1).." - "..fcst1icon)
                  end
                elseif (os.date("%H:%M") == WU.push_fcst2) then
                  if WU.pushOption == "Fibaro" then
                  fcastday = fcstday2
                  fcast = fcst2
                    for i, j in pairs(WU.smartphoneID) do
                      fibaro:call(j , "sendPush", fcstday2.." - "..fcst2)
                      popupIMG = "http://jonnylarsson.se/JL/png/nt_"..icon..".png"
                      sendPopup()
                    end
                  elseif WU.pushOption == "Telegram" then
                      Telegrambot(fcstday2.." - "..string.lower(fcst2).." - "..fcst2icon)
                  end
                end
            end
            if WU.sendPush then
              fibaro:call(WU.selfId , "setProperty", "ui.lblNotify.value", WU.translation[WU.language]["Push_forecast"].."  = true");
              else fibaro:call(WU.selfId , "setProperty", "ui.lblNotify.value",WU.translation[WU.language]["Push_forecast"].."  = false");
            end
          WU.scheduler = os.time()+updateEvery*60
          fibaro:call(WU.selfId, "setProperty", "ui.lblUpdate.value", os.date("%c"));
          fibaro:debug(WU.translation[WU.language]["Data_processed"])
              fibaro:debug(WU.translation[WU.language]["Update_interval"].." "..updateEvery)
          else
        fibaro:debug(WU.translation[WU.language]["NO_STATIONID_FOUND"])
      end
    end
    sleepAndcheck = 0
  while sleepAndcheck <= 20*updateEvery do
    fibaro:sleep(3000)
    sleepAndcheck = sleepAndcheck+1
    if (DoNotRecheckBefore <= os.time()) and ((WU.scheduler == os.time) or (os.date("%H:%M") == WU.push_fcst1) or (os.date("%H:%M") == WU.push_fcst2)) then
      fibaro:debug(WU.translation[WU.language]["Push_forecast"])
      Debug("orange", WU.translation[WU.language]["Exiting_loop_push"]);
      DoNotRecheckBefore = os.time()+60
      sleepAndcheck = 20*updateEvery
    end
  end
  end
end


Debug( "orange", "WU Weather - LUA Scripting by Jonny Larsson 2015/2016" );
Debug( "orange", "Version: "..version);
if versionCheck then
versionChecker()
end
createGlobalIfNotExists("WUAPI", WU.APIkey)
createGlobalIfNotExists("Telegramtoken1_part1", WU.Telegramtoken1_part1)
createGlobalIfNotExists("Telegramtoken1_part2", WU.Telegramtoken1_part2)
createGlobalIfNotExists("Telegramchat_id1", WU.Telegramchat_id1)
if WU.dualChat_ID then
  createGlobalIfNotExists("Telegramtoken2_part1", WU.Telegramtoken2_part1)
  createGlobalIfNotExists("Telegramtoken2_part2", WU.Telegramtoken2_part2)
  createGlobalIfNotExists("Telegramchat_id2", WU.Telegramchat_id2)
end
Debug( "yellow", "Morning forecast push will be: "..WU.push_fcst1);
Debug( "yellow", "Afternoon forecast push will be: "..WU.push_fcst2);
processWU() --this starts an endless loop, until an error occurs

---- END OF UPDATE ----
