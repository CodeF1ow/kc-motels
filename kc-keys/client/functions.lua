DrawBusySpinner = function(text)
    SetLoadingPromptTextEntry("STRING")
    AddTextComponentSubstringPlayerName(text)
    ShowLoadingPrompt(3)
end

DrawScriptMarker = function(markerData)
    DrawMarker(markerData["type"] or 1, markerData["pos"] or vector3(0.0, 0.0, 0.0), 0.0, 0.0, 0.0, (markerData["type"] == 6 and -90.0 or markerData["rotate"] and -180.0) or 0.0, 0.0, 0.0, markerData["sizeX"] or 1.0, markerData["sizeY"] or 1.0, markerData["sizeZ"] or 1.0, markerData["r"] or 1.0, markerData["g"] or 1.0, markerData["b"] or 1.0, 100, markerData["bob"] and true or false, true, 2, false, false, false, false)
end


AddKey = function(keyData)
	ESX.TriggerServerCallback("kc-keys:addKey", function(keys)
		if keys then
			table.insert(cachedData["fetchedKeys"], keyData)
		else
			print("Failed to add key.")
		end
	end, keyData)
end

RemoveKey = function(removeKeyData)
    ESX.TriggerServerCallback("kc-keys:removeKey", function(removed)
		if removed then
			for id, keyData in ipairs(cachedData["fetchedKeys"]) do

				if keyData["uuid"] == removeKeyData["uuid"] then

					table.remove(cachedData["fetchedKeys"], id)
				end
			end
		else
			print("No se pudo quitar la clave.")
		end
	end, removeKeyData)
end

KeyMenu = function()
	local menuElements = {}

	if cachedData["fetchedKeys"] and cachedData["fetchedKeys"][1] then
		menuElements = cachedData["fetchedKeys"]
	else
		menuElements = {
			{
				["label"] = "No tienes llave!"
			}
		}
	end
	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'key_menu',
		{
			["title"]    = 'Habitaciones',
			["align"]    = 'center',
			["elements"] = menuElements,
		},
		function(menuData, menuHandle)
			if menuData["current"]["uuid"] then
				local player, distance = ESX.Game.GetClosestPlayer()

				if player ~= -1 then

					if distance < Config.TransferDistance then
						DrawBusySpinner("Esperando confirmacion...")
						ConfirmMenu(menuData["current"]["uuid"], function(transfer)
							if transfer then
								TransferKey({
									["label"] = menuData["current"]["label"],
									["keyId"] = menuData["current"]["keyId"],
									["uuid"] = menuData["current"]["uuid"]
								}, GetPlayerServerId(player))
							else
								ESX.UI.Menu.CloseAll()
								KeyMenu()
							end
						end)
					end
				end
				menuHandle.close()
			else
				menuHandle.close()
			end
		end,
	function(menuData, menuHandle)
		menuHandle.close()
	end)
end

TransferKey = function(key, player)
	ESX.TriggerServerCallback("kc-keys:transferKey", function(transfered)
		
		DrawBusySpinner("La llave esta dada...")

		if transfered then

			Wait(2500)

			RemoveLoadingPrompt()

			ESX.ShowNotification("Dio la llave.")

            TriggerServerEvent("kc-keys:giveKey", key, player)
            
			ESX.TriggerServerCallback("kc-keys:fetchKeys", function(fetchedKeys)
				if fetchedKeys then
					cachedData["fetchedKeys"] = fetchedKeys
					KeyMenu()
				else
					print("No se pudieron recuperar las llaves")
				end
			end)

		else

			RemoveLoadingPrompt()

			DrawBusySpinner("No se pudo dar la llave.")

			Wait(2500)

			RemoveLoadingPrompt()

		end

	end, key, player)
end

ConfirmMenu = function(key, cb)
    local nearestPlayer

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'transfer_menu',
		{
		["title"]    = 'Concesión de habitaciones',
		["align"]    = 'center-left',
		["elements"] = { 
			{
				["label"] = "Dar la llave.",
				["action"] = "transfer"
			},
			{
				["label"] = "Transferir la llave.",
				["action"] = "cancel"
			}
		}
		},
		function(menuData, menuHandle)
			if menuData["current"]["action"] == "transfer" then
				cb(nearestPlayer)
			else
				cb(false)
			end
			menuHandle.close()
		end,
	function(menuData, menuHandle)
		menuHandle.close()
	end)

	while ESX.UI.Menu.IsOpen('default', GetCurrentResourceName(), 'transfer_menu') do

		Wait(5)

		local player, distance = ESX.Game.GetClosestPlayer()

		if player ~= -1 then

			if distance < Config.TransferDistance then
				
				nearestPlayer = player
				local playerPed = GetPlayerPed(player)
				local playerCoords = GetEntityCoords(playerPed)
				
				DrawScriptMarker({
					["type"] = 0,
					["pos"] = playerCoords + vector3(0.0, 0.0, 1.4),
					["r"] = 55,
					["g"] = 100,
					["b"] = 200,
					["sizeX"] = 0.2,
					["sizeY"] = 0.2,
					["sizeZ"] = 0.2,
					["bob"] = true
				})
			else
				cb(false)
				break
			end
		end
	end
	RemoveLoadingPrompt()
end

FetchKeys = function()
	ESX.TriggerServerCallback("kc-keys:fetchKeys", function(fetchedKeys)
		if fetchedKeys then
			cachedData["fetchedKeys"] = fetchedKeys
		else
			cachedData["fetchedKeys"] = {}
		end
	end)
end

HasKey = function(key)
	if cachedData["fetchedKeys"] then
        
        for _, keyData in ipairs(cachedData["fetchedKeys"]) do

            if keyData["keyId"] == key then

                return true
                
            end

        end

        return false
    end
end