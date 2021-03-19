ESX = nil

cachedData = {
	["motelRooms"] = {},
	["blips"] = {}
}

Citizen.CreateThread(function()
	
	while not ESX do

		TriggerEvent("esx:getSharedObject", function(library) 
			ESX = library 
		end)

		Citizen.Wait(0)
	end
	
	if ESX.IsPlayerLoaded() then
		Init()
	end

end)

RegisterNetEvent("esx:playerLoaded")
AddEventHandler("esx:playerLoaded", function(playerData)
	ESX.PlayerData = playerData
	Init()
end)

RegisterNetEvent("esx:setJob")
AddEventHandler("esx:setJob", function(newJob)
	ESX.PlayerData["job"] = newJob
end)

Citizen.CreateThread(function()
	while true do
		local sleepThread = 5000

		local ped = PlayerPedId()
		
		if ped ~= cachedData["ped"] then
			cachedData["ped"] = ped
		end

		Citizen.Wait(sleepThread)
	end
end)

Citizen.CreateThread(function()
	Citizen.Wait(500)

	if Config.EnableKeySystem and not exports["kc-keys"] then
		Trace("Obtendrá un error si no inicia el script kc-motels..")
		Config.EnableKeySystem = false
	end

	while true do
		
		local sleepThread = 500

		local ped = cachedData["ped"]
		cachedData["pedCoords"] = GetEntityCoords(ped)

		for _, motelData in pairs(Config.Motels) do
			
			local motelDistance = #(cachedData["pedCoords"] - motelData["motelPosition"])
			local raidText = nil

			CreateBlips(motelData)
			
			if motelDistance <= 50.0 then

				if not cachedData["stopSearching"] then
					cachedData["doorHandle"] = GetClosestObjectOfType(cachedData["pedCoords"], 5.0, motelData["doorHash"])
					cachedData["doorCoords"] = GetEntityCoords(cachedData["doorHandle"])
					cachedData["doorRoom"] = GetInteriorFromEntity(cachedData["doorHandle"])
				elseif cachedData["stopSearching"] and not cachedData["doorHandle"] or not cachedData["doorCoords"] or not cachedData["doorRoom"] then
					cachedData["doorHandle"] = GetClosestObjectOfType(cachedData["pedCoords"], 5.0, motelData["doorHash"])
					cachedData["doorCoords"] = GetEntityCoords(cachedData["doorHandle"])
					cachedData["doorRoom"] = GetInteriorFromEntity(cachedData["doorHandle"])
				end
				
				local interiorId = GetInteriorFromEntity(ped)
				local roomId = cachedData["doorCoords"]["y"] .. cachedData["doorCoords"]["x"]  .. cachedData["doorCoords"]["z"]
				local roomNumber = string.sub(cachedData["doorCoords"]["x"], 7, 8) .. string.sub(cachedData["doorCoords"]["y"], 4, 4) .. string.sub(cachedData["doorCoords"]["z"], 2, 2)
				local doorUnlockable = false
				local doorState = DoorSystemGetDoorState(cachedData["doorHandle"])
				local helpText = motelData["rentMode"] and "- Rentar una habitación $" .. (Config.RentTimer >= 24 and motelData["motelPrice"] .. " / por dia" or round(motelData["motelPrice"] / Config.RentTimer, 2) .. " / por hora") or " Comprar espacio por $" .. motelData["motelPrice"] .. "."
				local dstCheck = #(cachedData["pedCoords"] - cachedData["doorCoords"])
				local roomRentable = true
				
				if not IsDoorRegisteredWithSystem(cachedData["doorHandle"]) then
					AddDoorToSystem(cachedData["doorHandle"], motelData["doorHash"], cachedData["doorCoords"], 0, true, false)

					if cachedData["motelRooms"][roomId] and cachedData["motelRooms"][roomId]["roomLocked"] ~= doorState then
						DoorSystemSetDoorState(cachedData["doorHandle"], cachedData["motelRooms"][roomId]["roomLocked"], true, true)
					else
						DoorSystemSetDoorState(cachedData["doorHandle"], true, true, true)
					end
				else
					if cachedData["motelRooms"][roomId] and cachedData["motelRooms"][roomId]["roomLocked"] ~= doorState then
						DoorSystemSetDoorState(cachedData["doorHandle"], cachedData["motelRooms"][roomId]["roomLocked"], true, true)
					end
				end
				
				if cachedData["motelRooms"][roomId] then
					roomRentable = false
					helpText = ""

					if Config.EnableKeySystem then
						if exports["kc-keys"]:HasKey("room-"..roomId) then
							doorUnlockable = true
							helpText = ""
						end
					end
					
					if cachedData["motelRooms"][roomId]["roomOwner"] == ESX.PlayerData["identifier"] then
						local h, m = ConvertTime(cachedData["motelRooms"][roomId]["paymentTimer"]) 
						local latestPayment = cachedData["motelRooms"][roomId]["paymentTimer"]
						helpText = latestPayment > Config.RentTimer and "- Ödeme gerkiyor oda yönetiminden öde." or ""
						doorUnlockable = true
					end
					
					if Config.RaidEnabled and not doorUnlockable and not roomRentable or not doorState == 0 then
						if ESX.PlayerData["job"] and ESX.PlayerData["job"]["name"] == Config.RaidJob then
							raidText = "Roba la habitación " .. roomNumber
						end
					else
						raidText = nil
					end
				end
				
				if motelData["roomFinish"] then
					if not cachedData["previewingDesign"] then
						if not IsInteriorEntitySetActive(cachedData["doorRoom"], cachedData["motelRooms"][roomId] and cachedData["motelRooms"][roomId]["roomFinish"] or motelData["roomFinish"]) then
							ActivateInteriorEntitySet(cachedData["doorRoom"], cachedData["motelRooms"][roomId] and cachedData["motelRooms"][roomId]["roomFinish"] or motelData["roomFinish"])
							if cachedData["motelRooms"][roomId] and cachedData["motelRooms"][roomId]["oldFinish"] then
								DeactivateInteriorEntitySet(cachedData["doorRoom"], cachedData["motelRooms"][roomId]["oldFinish"])
							end
							RefreshInterior(cachedData["doorRoom"])
						end
					end
				end

				if dstCheck <= 10.0 then
					sleepThread = 0

					if dstCheck <= 5.0 then
						local doorOffset = GetOffsetFromEntityInWorldCoords(cachedData["doorHandle"], motelData["doorOffset"])
						
						if dstCheck <= 1.2 then
							if IsControlJustReleased(0, 47) then
								if doorUnlockable then 
									doorState = doorState == 1 and 0 or 1
									cachedData["motelRooms"][roomId]["roomLocked"] = doorState
									DoorSystemSetDoorState(cachedData["doorHandle"], doorState, true, true)
									TriggerServerEvent("kc-motels:syncDoorState", roomId, doorState)
								else
									ESX.ShowNotification("No puedes abrir esta puerta.")
								end
							end

							if roomRentable and IsControlJustReleased(0, 47) then
								ESX.TriggerServerCallback("kc-motels:rentRoom", function(rented, errorMessage)
									if rented then
										exports["kc-keys"]:AddKey({
											["label"] = motelData["motelName"] .. " - habitación " .. roomNumber,
											["keyId"] = "room-" .. roomId,
											["uuid"] = NetworkGetRandomInt()
										})
										ESX.ShowNotification("Acabas de " .. (motelData["rentMode"] and "Alquilar una habitacion " or "comprar una habitacion ") .. roomNumber .. " for $" .. motelData["motelPrice"])
									else
										ESX.ShowNotification(errorMessage)
									end
								end, roomId, motelData)
							end
							
							if raidText and IsControlJustReleased(0, 74) then
								RaidRoom(roomId, cachedData["doorHandle"])
							end

							if doorUnlockable or roomRentable or raidText then
								local displayText = not roomRentable and raidText and "Pulse ~INPUT_VEH_HEADLIGHT~ para " or "Pulse ~INPUT_DETONATE~ para "
								displayText = displayText .. (doorUnlockable and (doorState == 1 and "abrir la cerradura." or "cerrar con llave.") or roomRentable and (motelData["rentMode"] and "alquilar motel." or "Comprar.") or raidText and (not roomRentable and raidText or "") or "")
								HelpNotification(displayText)
							end
						end

						DrawScriptText(doorOffset, "Habitación " ..  roomNumber .. " - " ..(doorState == 1 and "~r~Cerrado~s~ " or "~g~ABIERTO~s~ ") .. helpText)
					end
					
					if interiorId ~= 0 then

						cachedData["stopSearching"] = true

						inRoom = true

						for furnitureName, furnitureData in pairs(motelData["furniture"]) do
							local furnitureCoords = GetOffsetFromInteriorInWorldCoords(interiorId, furnitureData["offset"])
							local furnitureDistance = #(cachedData["pedCoords"] - furnitureCoords)

							if not furnitureData["restricted"] then
								if furnitureDistance <= 1.0 then
									if IsControlJustReleased(0, 38) then
										furnitureData["callback"](roomId, furnitureName)
									end
									HelpNotification("Pulse ~INPUT_CONTEXT~ para acceder al "..furnitureData["text"])
								end
								DrawScriptText(furnitureCoords, furnitureData["text"])
							else
								if cachedData["motelRooms"][roomId] and cachedData["motelRooms"][roomId]["roomOwner"] == ESX.PlayerData["identifier"] then
									if furnitureDistance <= 1.0 then
										if IsControlJustReleased(0, 38) then
											furnitureData["callback"](roomId, roomNumber, motelData)
										end
										HelpNotification("Pulse ~INPUT_CONTEXT~ para "..furnitureData["text"])
									end
									DrawScriptText(furnitureCoords, furnitureData["text"])
								end
							end
						end
					else
						cachedData["stopSearching"] = false
					end
				end
			end
		end

		Citizen.Wait(sleepThread)
	end
end)

if Config.CancelRoomCommand then
	RegisterCommand(Config.CancelRoomCommand, function()
		local roomId = cachedData["doorCoords"]["y"] .. cachedData["doorCoords"]["x"]  .. cachedData["doorCoords"]["z"]
		
		for _, motelData in pairs(Config.Motels) do
			if #(cachedData["pedCoords"] - motelData["motelPosition"]) <= 50.0 then
				if #(cachedData["pedCoords"] - cachedData["doorCoords"]) <= 2.0 then
					if cachedData["motelRooms"][roomId] and cachedData["motelRooms"][roomId]["roomOwner"] == ESX.PlayerData["identifier"] then
						if GetInteriorFromEntity(cachedData["ped"]) == 0 then
							ESX.TriggerServerCallback("kc-motels:cancelRoom", function(canceled)
								if canceled then
									ESX.ShowNotification("Ahora ya no eres dueño de esta habitación.")
								end
							end, roomId, motelData)
						else
							ESX.ShowNotification("Salga de la habitación y asegúrese de que no haya nadie más en ella..")
						end
					else
						ESX.ShowNotification("No eres dueño de esta habitación.")
					end
				else
					ESX.ShowNotification("Acércate a la puerta.")
				end
			end
		end
	end)
end

RegisterNetEvent("kc-motels:syncRooms")
AddEventHandler("kc-motels:syncRooms", function(motelData)
	if motelData then
		cachedData["motelRooms"] = motelData
	end
end)

RegisterNetEvent("kc-motels:syncDoorState")
AddEventHandler("kc-motels:syncDoorState", function(roomId, roomLocked)
	cachedData["motelRooms"][roomId]["roomLocked"] = roomLocked
end)

RegisterNetEvent("kc-motels:changeInteriorFinish")
AddEventHandler("kc-motels:changeInteriorFinish", function(roomId, interiorId, oldInterior, newInterior)
	DeactivateInteriorEntitySet(interiorId, oldInterior)
	ActivateInteriorEntitySet(interiorId, newInterior)
	RefreshInterior(interiorId)
end)