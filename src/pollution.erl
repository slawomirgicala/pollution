%%%-------------------------------------------------------------------
%%% @author sgica
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 01. kwi 2019 17:11
%%%-------------------------------------------------------------------
-module(pollution).
-author("sgica").

%% API
-export([create_monitor/0,add_station/3,get_ID/2,get_station/2,get_measurement/2,add_value/5,remove_value/4,get_one_value/4,average/1,average/3,get_station_mean/3,get_daily_mean/3,test/0]).

-record(station, {coordinates,name,measurement}).
-record(measurement, {temperature, 'PM2.5', 'PM10', pressure, humidity, others = []}).
-record(monitor, {by_name, by_coordinates, stations, id_counter}).


create_monitor()-> #monitor{
  by_name = maps:new(),
  by_coordinates = maps:new(),
  stations = maps:new(),
  id_counter = 0
}.

add_station(Monitor, Name, Coord) ->
  case {maps:is_key(Name, Monitor#monitor.by_name), maps:is_key(Coord, Monitor#monitor.by_coordinates)}  of
    {true, _} -> Monitor;
    {_,true}  -> Monitor;
    _ ->  #monitor{
      by_name = maps:put(Name,Monitor#monitor.id_counter,Monitor#monitor.by_name),
      by_coordinates = maps:put(Coord,Monitor#monitor.id_counter,Monitor#monitor.by_coordinates),
      stations = maps:put(Monitor#monitor.id_counter, #station{
        coordinates = Coord,
        name = Name,
        measurement = maps:new()
      }, Monitor#monitor.stations),
      id_counter = Monitor#monitor.id_counter+1
    }
  end.

get_ID(Coord_or_Name, Monitor) ->
  case Coord_or_Name of
    {_,_} -> maps:get(Coord_or_Name, Monitor#monitor.by_coordinates);
    _ -> maps:get(Coord_or_Name, Monitor#monitor.by_name)
  end.

get_station(Monitor, Coord_Or_Name)->
  maps:get(get_ID(Coord_Or_Name, Monitor),Monitor#monitor.stations).

get_measurement(Station,Date)->
  maps:get(Date,Station#station.measurement, #measurement{}).

add_measurement(Monitor, Coord_or_Name, Date, Measurement, Station)->
  NewStation = Station#station{measurement = maps:put(Date,Measurement,Station#station.measurement)},
  Monitor#monitor{stations = maps:update(get_ID(Coord_or_Name,Monitor), NewStation, Monitor#monitor.stations)}.

add_value(Monitor, Coord_or_Name, DateTime, Type, Value) ->
  {Date, Time}=DateTime,
  Station = get_station(Monitor,Coord_or_Name),
  Measurement = get_measurement(Station,Date),

  case Type of
    "PM2.5"       ->  add_measurement(Monitor, Coord_or_Name, Date, Measurement#measurement{'PM2.5' = Value}, Station);
    "PM10"        ->  add_measurement(Monitor, Coord_or_Name, Date, Measurement#measurement{'PM10' = Value}, Station);
    "temperature" ->  add_measurement(Monitor, Coord_or_Name, Date, Measurement#measurement{temperature = Value}, Station);
    "pressure"    ->  add_measurement(Monitor, Coord_or_Name, Date, Measurement#measurement{pressure = Value}, Station);
    "humidity"    ->  add_measurement(Monitor, Coord_or_Name, Date, Measurement#measurement{humidity = Value}, Station);
    _             ->  Others = Measurement#measurement.others,
      add_measurement(Monitor, Coord_or_Name, Date, Measurement#measurement{others = Others++[{Type,Value}]}, Station)

  end.

remove_value(Monitor, Coord_or_Name, Date, Type)->
  add_value(Monitor,Coord_or_Name,Date,Type,undefined).


get_one_value(Monitor,Cord_or_Name,Date,Type)->
  Measure = get_measurement(get_station(Monitor,Cord_or_Name),Date),
  case Type of
    "PM2.5"       ->  Measure#measurement.'PM2.5';
    "PM10"        ->  Measure#measurement.'PM10';
    "temperature" ->  Measure#measurement.temperature;
    "pressure"    ->  Measure#measurement.pressure;
    "humidity"    ->  Measure#measurement.humidity;
    _             ->  Measure#measurement.others
  end.


average(X) -> average(X, 0, 0).

average([H|T], Length, Sum) -> average(T, Length + 1, Sum + H);
average([], Length, Sum) -> Sum / Length.

get_station_mean(Monitor,Coord_or_Name,Type)->
  Station = get_station(Monitor,Coord_or_Name),
  Measure = maps:values(Station#station.measurement),
  case Type of
    "PM2.5"       -> List = lists:map(fun (X) -> X#measurement.'PM2.5' end, Measure),
                     L = lists:filter(fun (X) -> X /= undefined end, List),
                     A = average(L),
                     A;
    "PM10"        ->  average(lists:filter(fun (X) -> X /= undefined end, lists:map(fun (X) -> X#measurement.'PM10' end, Measure)));
    "temperature" ->  average(lists:filter(fun (X) -> X /= undefined end, lists:map(fun (X) -> X#measurement.temperature end, Measure)));
    "pressure"    ->  average(lists:filter(fun (X) -> X /= undefined end, lists:map(fun (X) -> X#measurement.pressure end, Measure)));
    "humidity"    ->  average(lists:filter(fun (X) -> X /= undefined end, lists:map(fun (X) -> X#measurement.humidity end, Measure)));
    _             ->  lists:map(fun (X) -> X#measurement.others end, Measure)
  end.


get_daily_mean(Monitor, DateTime, Type)->
  {Date, Time} = DateTime,
  Stations = maps:values(Monitor#monitor.stations),
  Measurements = lists:map(fun(X) -> maps:get(Date,X) end, lists:filter(fun (X) -> maps:is_key(Date, X) end, lists:map(fun(X)-> X#station.measurement end,Stations))),
  case Type of
    "PM2.5"       ->  average(lists:filter(fun (X) -> X /= undefined end, lists:map(fun (X) -> X#measurement.'PM2.5' end, Measurements)));
    "PM10"        ->  average(lists:filter(fun (X) -> X /= undefined end, lists:map(fun (X) -> X#measurement.'PM10' end, Measurements)));
    "temperature" ->  average(lists:filter(fun (X) -> X /= undefined end, lists:map(fun (X) -> X#measurement.temperature end, Measurements)));
    "pressure"    ->  average(lists:filter(fun (X) -> X /= undefined end, lists:map(fun (X) -> X#measurement.pressure end, Measurements)));
    "humidity"    ->  average(lists:filter(fun (X) -> X /= undefined end, lists:map(fun (X) -> X#measurement.humidity end,Measurements)));
    _             ->  lists:map(fun (X) -> X#measurement.others end, Measurements)

  end.


test()->
  M=create_monitor(),
  M1=add_station(M,"nazwa1",{12,31}),
  M2=add_station(M1,"nazwa2",{122,31}),
  M3=add_station(M2,"nazwa2",{122,318}),
  M4=add_station(M3,"nazwa3",{122,311}),
  M5=add_value(M4,"nazwa2",calendar:local_time(),"PM2.5",23),
  M6=add_value(M5,"nazwa2",calendar:local_time(),"PM10",23),
  M7=add_value(M6,"nazwa2",calendar:local_time(),"temperature",30),
  M8=add_value(M7,"nazwa2",calendar:local_time(),"pressure",70),
  M9=add_value(M8,"nazwa2",calendar:local_time(),"humidity",60),
  M10=add_value(M9, {12,31},calendar:local_time(),"whatever","ad"),
  M11=add_value(M10,"nazwa2",calendar:local_time(),"PM2.5",45).