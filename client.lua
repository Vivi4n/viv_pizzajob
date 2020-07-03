ESX = nil
local PlayerLoaded HasAlreadyEnteredMarker, clockedIn, vehicleSpawned, getPizza, pizzaDeposit = false, false, false, false, false, false
local DeliveryJobs = {}
local mainblip, work_car, currentstop

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(100)
	end

	PlayerData = ESX.GetPlayerData()

	if PlayerData.job.name == 'pizza' then
		mainblip = AddBlipForCoord(Config.Zones[1].pos)

		SetBlipSprite (mainblip, 103)
		SetBlipDisplay(mainblip, 4)
		SetBlipScale  (mainblip, 0.8)
		SetBlipColour (mainblip, 5)
		SetBlipAsShortRange(mainblip, true)

		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString(_U('blip_job'))
		EndTextCommandSetBlipName(mainblip)
	end
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	PlayerData = xPlayer
	PlayerLoaded = true
	--TriggerServerEvent('viv_pizza:setConfig')
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	PlayerData.job = job
	TriggerEvent('viv_pizza:checkJob')
end)

RegisterNetEvent('viv_pizza:updateJobs')
AddEventHandler('viv_pizza:updateJobs', function(newjobtable)
	DeliveryJobs = newjobtable
end)

RegisterNetEvent('viv_pizza:leftArea')
AddEventHandler('viv_pizza:leftArea', function()
	ESX.UI.Menu.CloseAll()    
    CurrentAction = nil
	CurrentActionMsg = ''
end)

AddEventHandler('viv_pizza:checkJob', function()
	if PlayerData.job.name ~= 'pizza' then
		if mainblip ~= nil then
			RemoveBlip(mainblip)
			mainblip = nil
		end
	elseif mainblip == nil then
		mainblip = AddBlipForCoord(Config.Zones[1].pos)

		SetBlipSprite (mainblip, 103)
		SetBlipDisplay(mainblip, 4)
		SetBlipScale  (mainblip, 0.8)
		SetBlipColour (mainblip, 5)
		SetBlipAsShortRange(mainblip, true)

		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString(_U('blip_job'))
		EndTextCommandSetBlipName(mainblip)
	end
end)

RegisterNetEvent('viv_pizza:enteredArea')
AddEventHandler('viv_pizza:enteredArea', function(zone)
	CurrentAction = zone.name

	if CurrentAction == 'timeclock'  and IsPizzaJob() then
		OpenCloakRoomMenu()
	end

	if CurrentAction == 'vehiclelist' then
		if clockedin and not vehiclespawned then 
			MenuVehicleSpawner()
		end
	end

	if CurrentAction == 'endmission' and vehiclespawned then
		CurrentActionMsg = _U('cancel_mission')
	end

	if CurrentAction == 'collection' and not albetogetbags then
		if IsPedInAnyVehicle(GetPlayerPed(-1)) and GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(-1), false)) == worktruckplate then
			CurrentActionMsg = _U('collection')
		else
			CurrentActionMsg = _U('need_work_truck')
		end

	end

function IsPizzaJob()
	if ESX ~= nil then
		local isJob = false
		if PlayerData.job.name == 'pizza' then
			isJob = true
		end
		return isJob
	end
end

function OpenCloakRoomMenu()
	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'cloakroom', {
			title    = _U('cloakroom'),
			elements = {
				{label = _U('citizen_wear'), value = 'citizen_wear'},
				{label = _U('job_wear'), value = 'job_wear'}
			}}, function(data, menu)

			if data.current.value == 'citizen_wear' then
				ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
					TriggerEvent('skinchanger:loadSkin', skin)
				end)
				clockedIn = false
			  end
			  
			if data.current.value == 'job_wear' then
				ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
					if skin.sex == 0 then
						TriggerEvent('skinchanger:loadClothes', skin, jobSkin.skin_male)
					else
						TriggerEvent('skinchanger:loadClothes', skin, jobSkin.skin_female)
					end
				end)
				clockedIn = true
			end
			
			if data.current.value == 'job_wear' then
				setUniform(data.current.value, playerPed)
			end

			--menu.close()
		end, function(data, menu)
			menu.close()
		end)
end

function setUniform(job, playerPed)
	TriggerEvent('skinchanger:getSkin', function(skin)
		if skin.sex == 0 then
			if Config.Uniforms[job].male then
				TriggerEvent('skinchanger:loadClothes', skin, Config.Uniforms[job].male)
			else
				ESX.ShowNotification(_U('no_outfit'))
			end
		else
			if Config.Uniforms[job].female then
				TriggerEvent('skinchanger:loadClothes', skin, Config.Uniforms[job].female)
			else
				ESX.ShowNotification(_U('no_outfit'))
			end
		end
	end)
end

function OpenVehicleSpawnerMenu()
	local elements = {}

	for i=1, #Config.Cars, 1 do
		table.insert(elements, {label = GetLabelText(GetDisplayNameFromVehicleModel(Config.Cars[i])), value = Config.Cars[i]})
	end

	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehiclespawner', {
			title    = _U('vehiclespawner'),
			elements = elements
		}, function(data, menu)
			ESX.Game.SpawnVehicle(data.current.value, Config.VehicleSpawn.pos, 270.0, function(vehicle)
				local carplatenum = Config.CarPlateNumb + 1
				if carplatenum <= 9 then
					SetVehicleNumberPlateText(vehicle, 'PIZZA00'..carplatenum)
					workcarplate =   'PIZZA00'..carplatenum 
				elseif carplatenum <= 99 then
					SetVehicleNumberPlateText(vehicle, 'PIZZA0'..carplatenum)
					workcarplate =   'PIZZA0'..carplatenum 
				else
					SetVehicleNumberPlateText(vehicle, 'PIZZA'..carplatenum)
					workcarplate =   'PIZZA'..carplatenum 
				end

				TriggerServerEvent('esx_garbagecrew:movetruckcount')   
				SetEntityAsMissionEntity(vehicle, true, true)
					local vehNet = NetworkGetNetworkIdFromEntity(vehicle)
  			  		local plate = GetVehicleNumberPlateText(vehicle)
   					TriggerServerEvent("VIVS_Locking:GiveKeys", vehNet, plate)
				TaskWarpPedIntoVehicle(GetPlayerPed(-1), vehicle, -1)  
				vehicleSpawned = true 
				getPizza = false
				work_car = vehicle
				currentstop = 0
				FindDeliveryLoc()
			end)

			menu.close()
		end, function(data, menu)
			menu.close()
		end)
end