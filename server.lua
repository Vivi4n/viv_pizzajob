ESX = nil
local currentjobs, currentadd, currentworkers = {}, {}, {}
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterServerEvent('viv_pizzajob:movecarcount')
AddEventHandler('viv_pizzajob:movecarcount', function()
    Config.CarPlateNumb = Config.CarPlateNumb + 1
    if Config.CarPlateNumb == 1000 then
        Config.CarPlateNumb = 1
    end
    TriggerClientEvent('viv_pizzajob:movecarcount', -1, Config.CarPlateNumb)
end)