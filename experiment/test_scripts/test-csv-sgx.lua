require "sgx"

local map_csv = function(s)
  if not s then return nil end

  local csv

  if ccsv then
    csv = ccsv
  else
    csv = require "csv"
  end

  local array = csv.parse(s)
  return array
end

local s = "Year,Month,DayofMonth,DayOfWeek,DepTime,CRSDepTime,ArrTime,CRSArrTime,UniqueCarrier,FlightNum,TailNum,ActualElapsedTime,CRSElapsedTime,AirTime,ArrDelay,DepDelay,Origin,Dest,Distance,TaxiIn,TaxiOut,Cancelled,CancellationCode,Diverted,CarrierDelay,WeatherDelay,NASDelay,SecurityDelay,LateAircraftDelay"

local return_value = SGX:exec_func(map_csv, s)

print("Return value:", return_value)

for k,v in pairs(return_value) do
  print(k,v)
end
