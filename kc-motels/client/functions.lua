Init = function()
	ESX.TriggerServerCallback("kc-motels:fetchMotelRooms", function(fetchedMotels)
		if fetchedMotels then
			cachedData["motelRooms"] = fetchedMotels
		else
			Trace(fetchedMotels)
		end
	end)
end

OpenStash = function(interiorId, storageName)
	if Config.DiscInventory then
		TriggerEvent("esx_inventoryhud:openInventory", {
			["type"] = "kc-motels",
			["owner"] = interiorId .. " - " .. storageName
		})
	else
		StashMenu(interiorId, storageName)
	end
end

RaidRoom = function(roomId)
	RequestAnimDict('missheistfbisetup1')
    while not HasAnimDictLoaded('missheistfbisetup1') do
        Wait(0)
    end
	local timer = 0
    TaskPlayAnim(cachedData["ped"], 'missheistfbisetup1', 'hassle_intro_loop_f', 8.0, -8, -1, 11, 0, 0, 0, 0)
	Wait(600)
	DrawBusySpinner("La puerta se abre...")
	while true do
        if IsEntityPlayingAnim(PlayerPedId(), 'missheistfbisetup1', 'hassle_intro_loop_f', 3) then
            timer = timer+10
            if math.floor((timer / 1000) / Config.RaidTimer * 100) >= 100 then
				cachedData["motelRooms"][roomId]["roomLocked"] = 0
				DoorSystemSetDoorState(cachedData["doorHandle"], 0, true, true)
				TriggerServerEvent("kc-motels:syncDoorState", roomId, 0)
                break
            end
        else
            ESX.ShowNotification('cancelaste el proceso de pelado.')
            break
        end
        Wait(0)
    end
	RemoveLoadingPrompt()
end

RoomManagment = function(roomId, roomNumber, motelData)
	local menuElements = {}
	local setTime = true
	
	if motelData["roomFinish"] then
		table.insert(menuElements, {
			["label"] = " -Diseños de habitaciones - ",
		})

		for _, designData in pairs(Config.RoomFinishes) do
			table.insert(menuElements, {
				["label"] = designData["name"] .. " - $" .. designData["price"] .. (cachedData["motelRooms"][roomId]["roomFinish"] == designData["finish"] and " - Diseño actual" or ""),
				["roomFinish"] = designData["finish"],
				["price"] = designData["price"],
				["action"] = cachedData["motelRooms"][roomId]["roomFinish"] == designData["finish"] and "currentDesign" or "changeDesign"
			})
		end
	end

	table.insert(menuElements, {
		["label"] = " - gestión de habitaciones - ",
	})
	
	if Config.EnableKeySystem then
		table.insert(menuElements, {
			["label"] = "Obtén una llave extra por $" ..Config.KeyPrice,
			["action"] = "key"
		})
	end

	local setTime = true

	if motelData["rentMode"] then
		setTime = false
		ESX.TriggerServerCallback("kc-motels:fetchRentTime", function(fetchedTime, error)
			if fetchedTime then
				local h, m = ConvertTime(Config.RentTimer - fetchedTime)
				local missedPayment = fetchedTime > Config.RentTimer or false
				local payments = MissedPayments(fetchedTime)
				 --local paymentLabel = missedPayment and (days > 1 and days .. " dias " (hours > 0 and " y " .. hours .. (hours > 1 "horas " or "hora ")) .. " pagar ahora." or hours .. " horas desde el pago.") or .. "pago atrasado, pague ahora." or "El próximo pago sera en " .. (h > 0 and h .. " horas y " .. math.floor(m) .. " minutos" or math.floor(m) .. " minutos")
				local paymentLabel = missedPayment and "" .. (payments > 1 and payments .. " facturas impagas" or payments .." facturas impagas")  or "Siguiente pago " .. (h > 0 and h .. " horas " .. math.floor(m) .. " minuto" or math.floor(m) .. " minuto")
				table.insert(menuElements, {
					["label"] = paymentLabel,
					["time"] = fetchedTime,
					["missedPayments"] = payments or 0,
					["action"] = "payment"
				})
				setTime = true
			else
				Trace(error)
			end
		end, roomId)
	end

	while not setTime do
		Citizen.Wait(0)
	end

	ESX.UI.Menu.Open("default", GetCurrentResourceName(), "management_menu", {
		["title"]    = "GESTIÓN DE HABITACIONES",
		["align"]    = "center",
		["elements"] = menuElements
	}, function(menuData, menuHandle)
		local current = menuData["current"]

		if current["action"] == "payment" then
			if current["missedPayments"] > 0 then
				DrawBusySpinner("transacción de procesamiento...")
				ESX.TriggerServerCallback("kc-motels:payRent", function(proccesed)
					while not proccesed do
						Citizen.Wait(0)
					end
					RemoveLoadingPrompt()
					ESX.ShowNotification("Pagaste el alquiler de tu habitación. $" ..motelData["motelPrice"] * current["missedPayments"])
				end, roomId, current["missedPayments"], motelData)
			else
				local h, m = ConvertTime(Config.RentTimer - current["time"]) 

				ESX.ShowNotification("Alquiler pagado, " .. (h > 0 and h .. "horas y " .. math.floor(m) .. " minutos" or math.floor(m) .. " minutos") .. " para pagar.")
			end

			menuHandle.close()
		elseif current["action"] == "changeDesign" then
			cachedData["previewingDesign"] = true
			local previewInterior = GetInteriorFromEntity(cachedData["ped"])
			local pedCoords = GetEntityCoords(cachedData["ped"])
			DoScreenFadeOut(1200)
			Citizen.Wait(1200)
			DeactivateInteriorEntitySet(previewInterior, cachedData["motelRooms"][roomId]["roomFinish"])
			ActivateInteriorEntitySet(previewInterior, current["roomFinish"])
			Wait(250)
			RefreshInterior(previewInterior)
			DoScreenFadeIn(1200)
			DrawBusySpinner("Mirando el diseño de la habitación...")
			menuHandle.close()
			while cachedData["previewingDesign"] do
				fetchDoor = false
				Citizen.Wait(0)

				local dstCheck = #(GetEntityCoords(cachedData["ped"]) - pedCoords)

				if IsControlJustReleased(0, 74) then
					ESX.TriggerServerCallback("kc-motels:updateInteriorFinish", function(changed, errorMessage)
						if changed then
							cachedData["previewingDesign"] = false
						else
							ESX.ShowNotification(errorMessage)
							cachedData["previewingDesign"] = false
						end
					end, current["price"], roomId, cachedData["motelRooms"][roomId]["roomFinish"], current["roomFinish"])
				elseif IsControlJustReleased(0, 177) then
					DoScreenFadeOut(1200)
					Citizen.Wait(1500)
					DoScreenFadeIn(1500)
					DeactivateInteriorEntitySet(previewInterior, current["roomFinish"])
					RefreshInterior(previewInterior)
					cachedData["previewingDesign"] = false
				end
				if dstCheck > 10.0 then
					DeactivateInteriorEntitySet(previewInterior, current["roomFinish"])
					ActivateInteriorEntitySet(previewInterior, cachedData["motelRooms"][roomId]["roomFinish"])
					RefreshInterior(previewInterior)
					ESX.ShowNotification("Te mudaste muy lejos.")
					cachedData["previewingDesign"] = false
				end
				ESX.ShowHelpNotification("Pulse ~INPUT_VEH_HEADLIGHT~ para confirmar la compra o ~INPUT_CELLPHONE_CANCEL~ para cancelar.")
			end
			RefreshInterior(previewInterior)
			RemoveLoadingPrompt()
		elseif current["action"] == "currentDesign" then
			ESX.ShowNotification("Ya tienes este diseño.")
		elseif current["action"] == "key" then
			if cachedData["motelRooms"][roomId]["roomOwner"] == ESX.PlayerData["identifier"] then
				ESX.TriggerServerCallback("kc-motels:canBuyKey", function(buykey)
					if buykey then
						exports["kc-keys"]:AddKey({
							["label"] = motelData["motelName"] .. " - room " .. roomNumber,
							["keyId"] = "room-" .. roomId,
							["uuid"] = NetworkGetRandomInt()
						})
					else
						ESX.ShowNotification("Tu dinero es insuficiente.")
					end
				end)	
			end
		else
			menuHandle.close()
		end	
		menuHandle.close()
	end, function(menuData, menuHandle)

		menuHandle.close()
	end)
end

StashMenu = function(roomId, storageName)
	local menuElements = {
		{
			["label"] = "Poner artículos",
			["action"] = "store"
		},
	}

	if Config.StoreCash then
		table.insert(menuElements, {
			["label"] = "Pon dinero",
			["action"] = "storeCurrency",
			["currency"] = "cash"
		})
	end
	if Config.StoreBlackMoney then
		table.insert(menuElements, {
			["label"] = "Pon dinero negro",
			["action"] = "storeCurrency",
			["currency"] = "black_money"
		})
	end

	if Config.StoreCash or Config.StoreBlackMoney then
		table.insert(menuElements, {
			["label"] = " - CAJA DE DINERO - ",
		})
	end
	
	if Config.StoreCash then
		if cachedData["motelRooms"][roomId] and cachedData["motelRooms"][roomId]["roomData"]["roomStorages"][storageName]["cash"] > 0 then
			table.insert(menuElements, {
				["label"] = "Dinero: $" .. cachedData["motelRooms"][roomId]["roomData"]["roomStorages"][storageName]["cash"],
				["action"] = "takeCurrency",
				["currency"] = "cash"
			})
		end
	end

	if Config.StoreBlackMoney then
		if cachedData["motelRooms"][roomId]["roomData"]["roomStorages"][storageName]["black_money"] > 0 then
			table.insert(menuElements, {
				["label"] = "Dinero negro: " .. cachedData["motelRooms"][roomId]["roomData"]["roomStorages"][storageName]["black_money"],
				["action"] = "takeCurrency",
				["currency"] = "black_money"
			})
		end
	end
	
	if not roomId then return end

	ESX.TriggerServerCallback("kc-motels:fetchStorage", function(fetchedStorage, errorMessage)
		
		if fetchedStorage then
			table.insert(menuElements, {
				["label"] = " - Armario -",
			})

			for _, itemData in ipairs(fetchedStorage["items"]) do
				if itemData["item"] then
					table.insert(menuElements, {
						["label"] = itemData["amount"] .. " " .. itemData["label"],
						["item"] = itemData["item"],
						["realLabel"] = itemData["label"],
						["amount"] = itemData["amount"],
						["action"] = "take"
					})
				end
			end

			OpenMenu(menuElements, roomId, storageName)
		else
			table.insert(menuElements, {
				["label"] = "tu armario esta vacio.",
			})
			OpenMenu(menuElements, roomId, storageName)
		end
	end, roomId, storageName)
end

Wardrobe = function()
	ESX.TriggerServerCallback('esx_eden_clotheshop:getPlayerDressing', function(dressing)

		local elements = {}

		for i=1, #dressing, 1 do
		  table.insert(elements, {label = dressing[i], value = i})
		end

		ESX.UI.Menu.Open(
			'default', GetCurrentResourceName(), 'player_dressing',
			{
				title    = "Ropas",
				align    = 'right',
				elements = elements,
			},
			function(data, menu)

				TriggerEvent('skinchanger:getSkin', function(skin)

				ESX.TriggerServerCallback('esx_eden_clotheshop:getPlayerOutfit', function(clothes)

					TriggerEvent('skinchanger:loadClothes', skin, clothes)
					TriggerEvent('esx_skin:setLastSkin', skin)

					TriggerEvent('skinchanger:getSkin', function(skin)
						TriggerServerEvent('esx_skin:save', skin)
					end)
					
					ESX.ShowNotification("Tu atuendo ha cambiado.")
					HasLoadCloth = true

				end, data.current.value)

				end)
			end,
		function(data, menu)
			menu.close()
		end)
	end)
end

OpenMenu = function(menuElements, roomId, storageName)
	Trace(storageName)
	ESX.UI.Menu.Open("default", GetCurrentResourceName(), "storage_menu", {
		["title"]    = "Menú de alijo",
		["align"]    = "center",
		["elements"] = menuElements
	}, function(menuData, menuHandle)
		local current = menuData["current"]

		if current["action"] == "store" then
			local inventoryTable = {}
			local inventory = ESX.GetPlayerData().inventory

			for i=1, #inventory, 1 do
				if inventory[i]["count"] > 0 then
					table.insert(inventoryTable, {
						["label"] = inventory[i]["label"] .. " - " .. inventory[i]["count"],
						["realLabel"] = inventory[i]["label"],
						["amount"] = inventory[i]["count"],
						["item"] = inventory[i]["name"],
						["action"] = "insert"
					})
				end
			end
			menuHandle.close()
			Wait(250)
			OpenMenu(inventoryTable, roomId, storageName)
		elseif current["action"] == "take" then
			menuHandle.close()
			local input = OpenInput("Cuanto quieres poner, tienes " .. current["amount"], "input")
			local amount = tonumber(input)

			if amount and amount > 0 then
				ESX.TriggerServerCallback("kc-motels:updateStorage", function(stored, errorMessage)
					if stored then
						ESX.ShowNotification("Tomaste " .. amount .. " ".. current["realLabel"])
					else
						ESX.ShowNotification(errorMessage)
					end
				end, roomId, {
					["storageName"] = storageName,
					["take"] = true,
					["itemData"] = {
						["itemName"] = current["item"],
						["itemLabel"] = current["realLabel"],
						["itemAmount"] = amount
					}
				})
			else
				ESX.ShowNotification("Elija una cantidad correcta.")
			end
		elseif current["action"] == "insert" then
			menuHandle.close()
			local input = OpenInput("Cuanto quieres poner, tienes " .. current["amount"], "input")
			local amount = tonumber(input)

			if amount and amount > 0 then

				ESX.TriggerServerCallback("kc-motels:updateStorage", function(stored, errorMessage)
					if stored then
						ESX.ShowNotification("Acabas de guardar " .. amount .. " ".. current["realLabel"])
					else
						ESX.ShowNotification(errorMessage)
					end
				end, roomId, {
					["storageName"] = storageName,
					["store"] = true,
					["itemData"] = {
						["itemName"] = current["item"],
						["itemLabel"] = current["realLabel"],
						["itemAmount"] = amount
					}
				})
			else
				ESX.ShowNotification("Elija una cantidad correcta.")
			end
		elseif current["action"] == "storeCurrency" then
			menuHandle.close()
			local input = OpenInput("Cuanto " .. (current["currency"] == "cash" and "efectivo quieres almacenar?" or "dinero negro quieres almacenar?"), "input")
			local amount = tonumber(input)

			if amount and amount > 0 then

				ESX.TriggerServerCallback("kc-motels:updateStorage", function(stored, errorMessage)
					if stored then
						ESX.ShowNotification("Guardaste " .. amount .. " ".. (current["currency"] == "cash" and "dinero en efectivo" or "dinero negro"))
					else
						ESX.ShowNotification(errorMessage)
					end
				end, roomId, {
					["storageName"] = storageName,
					[current["action"]] = true,
					["currency"] = current["currency"],
					["amount"] = amount
				})
				
			else
				ESX.ShowNotification("Elija una cantidad correcta.")
			end
		elseif current["action"] == "takeCurrency" then
			menuHandle.close()
			local input = OpenInput("Cuanto " .. (current["currency"] == "cash" and "dinero en efectivo quieres llevar?" or "dinero negro quieres llevar?"), "input")
			local amount = tonumber(input)

			if amount and amount > 0 then

				ESX.TriggerServerCallback("kc-motels:updateStorage", function(stored, errorMessage)
					if stored then
						ESX.ShowNotification("Tomaste " .. amount .. " ".. (current["currency"] == "cash" and "Dinero en efectivo" or "Dinero negro"))
					else
						ESX.ShowNotification(errorMessage)
					end
				end, roomId, {
					["storageName"] = storageName,
					[current["action"]] = true,
					["currency"] = current["currency"],
					["amount"] = amount
				})
				
			else
				ESX.ShowNotification("Elija una cantidad correcta.")
			end
		end
	end, function(menuData, menuHandle)

		menuHandle.close()
	end)
end

CreateBlips = function(motelData)
	if not cachedData["blips"][motelData["motelName"]] then
		cachedData["blips"][motelData["motelName"]] = AddBlipForCoord(motelData["motelPosition"])
		SetBlipDisplay(cachedData["blips"][motelData["motelName"]], 4)
		SetBlipScale(cachedData["blips"][motelData["motelName"]], 0.8)
		SetBlipSprite(cachedData["blips"][motelData["motelName"]], 476)
		BeginTextCommandSetBlipName("STRING")
		SetBlipColour(cachedData["blips"][motelData["motelName"]], 75)
		AddTextComponentString(motelData["motelName"])
		EndTextCommandSetBlipName(cachedData["blips"][motelData["motelName"]])
	end
end

HelpNotification = function(msg)
	BeginTextCommandDisplayHelp("STRING")
	AddTextComponentSubstringPlayerName(msg)
	EndTextCommandDisplayHelp(0, false, true, -1)
end

DrawButtons = function(buttonsToDraw)
	local instructionScaleform = RequestScaleformMovie("instructional_buttons")

	while not HasScaleformMovieLoaded(instructionScaleform) do
		Wait(0)
	end

	PushScaleformMovieFunction(instructionScaleform, "CLEAR_ALL")
	PushScaleformMovieFunction(instructionScaleform, "TOGGLE_MOUSE_BUTTONS")
	PushScaleformMovieFunctionParameterBool(0)
	PopScaleformMovieFunctionVoid()

	for buttonIndex, buttonValues in ipairs(buttonsToDraw) do
		PushScaleformMovieFunction(instructionScaleform, "SET_DATA_SLOT")
		PushScaleformMovieFunctionParameterInt(buttonIndex - 1)

		PushScaleformMovieMethodParameterButtonName(buttonValues["button"])
		PushScaleformMovieFunctionParameterString(buttonValues["label"])
		PopScaleformMovieFunctionVoid()
	end

	PushScaleformMovieFunction(instructionScaleform, "DRAW_INSTRUCTIONAL_BUTTONS")
	PushScaleformMovieFunctionParameterInt(-1)
	PopScaleformMovieFunctionVoid()
	DrawScaleformMovieFullscreen(instructionScaleform, 255, 255, 255, 255)
end

DrawBusySpinner = function(text)
    SetLoadingPromptTextEntry("STRING")
    AddTextComponentSubstringPlayerName(text)
    ShowLoadingPrompt(3)
end

ConvertTime = function(h)
	local minutes = h * 60
	local hours = 0

	while minutes > 60 do
		minutes = minutes - 60
		hours = hours + 1
	end

	return hours, minutes
end

MissedPayments = function(h)
	local payments = 0
	local hours = h

	while hours >= Config.RentTimer do
		hours = hours - Config.RentTimer
		payments = payments + 1
	end

	return payments > 0 and payments or false
end

PlayAnimation = function(ped, dict, anim, settings)
	if dict then
        RequestAnimDict(dict)

        while not HasAnimDictLoaded(dict) do
            Citizen.Wait(0)
        end

        if settings == nil then
            TaskPlayAnim(ped, dict, anim, 1.0, -1.0, 1.0, 0, 0, 0, 0, 0)
        else 
            local speed = 1.0
            local speedMultiplier = -1.0
            local duration = 1.0
            local flag = 0
            local playbackRate = 0

            if settings["speed"] then
                speed = settings["speed"]
            end

            if settings["speedMultiplier"] then
                speedMultiplier = settings["speedMultiplier"]
            end

            if settings["duration"] then
                duration = settings["duration"]
            end

            if settings["flag"] then
                flag = settings["flag"]
            end

            if settings["playbackRate"] then
                playbackRate = settings["playbackRate"]
            end

            TaskPlayAnim(ped, dict, anim, speed, speedMultiplier, duration, flag, playbackRate, 0, 0, 0)

            while not IsEntityPlayingAnim(ped, dict, anim, 3) do
                Citizen.Wait(0)
            end
        end
    
        RemoveAnimDict(dict)
	else
		TaskStartScenarioInPlace(ped, anim, 0, true)
	end
end

LoadModels = function(models)
	for index, model in ipairs(models) do
		if IsModelValid(model) then
			while not HasModelLoaded(model) do
				RequestModel(model)
	
				Citizen.Wait(10)
			end
		else
			while not HasAnimDictLoaded(model) do
				RequestAnimDict(model)
	
				Citizen.Wait(10)
			end    
		end
	end
end

CleanupModels = function(models)
	for index, model in ipairs(models) do
		if IsModelValid(model) then
			SetModelAsNoLongerNeeded(model)
		else
			RemoveAnimDict(model)  
		end
	end
end

DrawScriptMarker = function(markerData)
    DrawMarker(markerData["type"] or 1, markerData["pos"] or vector3(0.0, 0.0, 0.0), 0.0, 0.0, 0.0, (markerData["type"] == 6 and -90.0 or markerData["rotate"] and -180.0) or 0.0, 0.0, 0.0, markerData["size"] or vector3(1.0, 1.0, 1.0), markerData["r"] or 1.0, markerData["g"] or 1.0, markerData["b"] or 1.0, 100, markerData["bob"] and true or false, true, 2, false, false, false, false)
end

DrawScriptText = function(coords, text)
	local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z)
	local px, py, pz = table.unpack(GetGameplayCamCoords())
	SetTextScale(0.35, 0.35)
	SetTextFont(4)
	SetTextProportional(1)
	SetTextColour(255, 255, 255, 215)
	SetTextEntry("STRING")
	SetTextCentre(1)
	AddTextComponentString(text)
	DrawText(_x, _y)
	local factor = (string.len(text)) / 370
	DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 41, 11, 41, 68)
end

DrawBusySpinner = function(text)
    SetLoadingPromptTextEntry("STRING")
    AddTextComponentSubstringPlayerName(text)
    ShowLoadingPrompt(3)
end

OpenInput = function(label, type)
	AddTextEntry(type, label)

	DisplayOnscreenKeyboard(1, type, "", "", "", "", "", 30)

	while UpdateOnscreenKeyboard() == 0 do
		DisableAllControlActions(0)
		Wait(0)
	end

	if GetOnscreenKeyboardResult() then
	  	return GetOnscreenKeyboardResult()
	end
end

function round(x, decimals)
	-- Esto debería ser menos ingenuo sobre la multiplicación y la división si está
	-- se preocupan por la precisión alrededor de los bordes como: números cercanos al más alto
	-- valores de un flotante o si está redondeando a un gran número de decimales.
    local n = 10^(decimals or 0)
    x = x * n
    if x >= 0 then x = math.floor(x + 0.5) else x = math.ceil(x - 0.5) end
    return x / n
end