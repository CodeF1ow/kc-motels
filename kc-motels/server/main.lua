local ESX

cachedData = {
    ["motelRooms"] = {}
}

TriggerEvent("esx:getSharedObject", function(library)
    ESX = library
end)

RegisterServerEvent("kc-motels:syncDoorState")
AddEventHandler("kc-motels:syncDoorState", function(roomId, roomLocked)
    cachedData["motelRooms"][roomId]["roomLocked"] = roomLocked
    TriggerClientEvent("kc-motels:syncDoorState", -1, roomId, roomLocked)
end)

ESX.RegisterServerCallback("kc-motels:fetchMotelRooms", function(source, callback)
    local currentTime = os.time()
    local fetchSqlQuery = [[
        SELECT
            *
        FROM
            kc_motels
    ]]

    MySQL.Async.fetchAll(fetchSqlQuery, {
        ["@owner"] = identifier
    }, function(fetchedData)
        if fetchedData[1] then
            for _, data in ipairs(fetchedData) do
                if not cachedData["motelRooms"][data["interiorId"]] then
                    local hoursSincePayment = os.difftime(currentTime, data["latestPayment"]) / 3600
                    local decodedRoomData = json.decode(data["roomData"])
                    if hoursSincePayment >= Config.AutoRemoveRoom then
                        RemoveRoom(data["interiorId"])
                    else
                        cachedData["motelRooms"][data["interiorId"]] = {
                            ["roomOwner"] = data["roomOwner"],  
                            ["roomLocked"] = decodedRoomData["roomLocked"],
                            ["roomFinish"] = decodedRoomData["roomFinish"],
                            ["roomStorages"] = decodedRoomData["roomStorages"],
                            ["roomData"] = decodedRoomData,
                            ["latestPayment"] = data["latestPayment"],
                            ["paymentTimer"] =  hoursSincePayment
                        }
                    end
                end
            end
            callback(cachedData["motelRooms"])
        else
            callback(false)
        end
    end)
end)

ESX.RegisterServerCallback("kc-motels:payRent", function(source, callback, roomId, payments, motelData)
    local player = ESX.GetPlayerFromId(source)

    if not player then return callback(false) end

    if cachedData["motelRooms"][roomId] then
        local sqlQuery = [[
            UPDATE
                kc_motels
            SET
                latestPayment = @latestPayment
            WHERE
                interiorId = @interiorId
        ]]

        MySQL.Async.execute(sqlQuery, {
            ["@latestPayment"] = os.time(),
            ["@interiorId"] = roomId
        }, function(rowsChanged)
            if rowsChanged > 0 then
                player.removeMoney(payments * motelData["motelPrice"])
                cachedData["motelRooms"][roomId]["latestPayment"] = os.time()
                TriggerClientEvent("kc-motels:syncRooms", -1, cachedData["motelRooms"])
                callback(true)
            else
                Trace("Room not found.")
            end
        end)
    end
end)    

ESX.RegisterServerCallback("kc-motels:fetchRentTime", function(source, callback, roomId)
    local player = ESX.GetPlayerFromId(source)

    if not player then return callback(false, "player") end
    if not roomId then return callback(false, "room") end

    if cachedData["motelRooms"][roomId] then
        local currentTime = os.time()
        local hoursSincePayment = os.difftime(currentTime, cachedData["motelRooms"][roomId]["latestPayment"]) / 3600

        callback(hoursSincePayment)
    else
        callback(false, "no existe")
    end
end)

ESX.RegisterServerCallback("kc-motels:canBuyKey", function(source, callback)
    local player = ESX.GetPlayerFromId(source)

    if not player then return callback(false, "player") end

    local money = Config.NewESX and player.getAccount("money")["money"] or player.getMoney()

    if money >= Config.KeyPrice then
        callback(true)
    else
        callback(false)
    end
end)


ESX.RegisterServerCallback("kc-motels:cancelRoom", function(source, callback, roomId, motelData)
    local player = ESX.GetPlayerFromId(source)

    if not player then return callback(false, "player") end
    if not roomId then return callback(false) end
    if not motelData then return callback(false) end

    RemoveRoom(roomId)
     
    if Config.EnableKeySystem then
        TriggerEvent("kc-keys:removeKeyByName", "room-" .. roomId)
    end

    if not motelData["rentMode"] then
        player.giveMoney(motelData["motelPrice"])
        callback(true)
    else
        callback(true)
    end
end)

ESX.RegisterServerCallback("kc-motels:updateInteriorFinish", function(source, callback, price, roomId, oldInterior, newInterior)
    local player = ESX.GetPlayerFromId(source)

    if not player then return callback(false, "player") end
    if not roomId then return callback(false, "room") end

    Trace("price:",price,"roomid:", roomId, "old:",oldInterior, "new:", newInterior)

    local playerMoney = Config.NewESX and player.getAccount("money")["money"] or player.getMoney()

    if playerMoney < price then return callback(false, "Not enough money.") end 

    if cachedData["motelRooms"][roomId] then
        cachedData["motelRooms"][roomId]["roomData"]["roomFinish"] = newInterior
        cachedData["motelRooms"][roomId]["roomFinish"] = newInterior
        cachedData["motelRooms"][roomId]["oldFinish"] = oldInterior
        UpdateRoomData(roomId, function(updated)
            if updated then
                callback(true)
                TriggerClientEvent("kc-motels:syncRooms", -1, cachedData["motelRooms"])
                return
            else
                callback(false, "No se actualizo.")
                return
            end
        end)
    else
        callback(false, "no existe")
    end
end)


ESX.RegisterServerCallback("kc-motels:rentRoom", function(source, callback, interiorId, motelData)
    local player = ESX.GetPlayerFromId(source)
    local playerMoney = Config.NewESX and player.getAccount("money")["money"] or player.getMoney()
    local playerBankMoney = player.getAccount("bank")["money"]
    local defaultRoomData = {
        ["roomFinish"] = motelData["roomFinish"],
        ["roomLocked"] = 1,
        ["roomStorages"] = {},
        ["motelName"] = motelData["motelName"]
    }

    if player then

        if not interiorId then return callback(false, "No se especificó ningún número de habitación.") end

        if playerMoney < motelData["motelPrice"] and playerBankMoney < motelData["motelPrice"] then return callback(false, "No tienes suficiente dinero, necesitas $" .. motelData["motelPrice"] - playerMoney) end
        
        if not Config.DiscInventory then
            for furnitureName, furnitureData in pairs(motelData["furniture"]) do
                if furnitureData["type"] == "storage" then
                    defaultRoomData["roomStorages"][furnitureName] = {
                        ["cash"] = 0,
                        ["black_money"] = 0,
                        ["items"] = {}
                    }
                end
            end
        end

        local sqlQuery = [[
            INSERT
                INTO
            kc_motels
                (interiorId, roomOwner, roomData, latestPayment)
            VALUES
                (@interiorId, @roomOwner, @roomData, @latestPayment)
        ]]

        MySQL.Async.execute(sqlQuery, {
            ["@interiorId"] = interiorId,
            ["@roomOwner"] = player["identifier"],
            ["@roomData"] = json.encode(defaultRoomData),
            ["@latestPayment"] = os.time()
        }, function(rowsChanged)
            if rowsChanged and rowsChanged > 0 then
                if playerMoney >= motelData["motelPrice"] then
                    player.removeMoney(motelData["motelPrice"])
                    cachedData["motelRooms"][interiorId] = {
                        ["roomOwner"] = player["identifier"],  
                        ["roomLocked"] = 1,
                        ["roomData"] = defaultRoomData,
                        ["roomFinish"] = defaultRoomData["roomFinish"],
                        ["roomStorages"] = defaultRoomData["roomStorages"],
                        ["latestPayment"] = os.time(),
                        ["paymentTimer"] =  os.difftime(os.time(), os.time()) / 3600
                    }
                    callback(true)
                    TriggerClientEvent("kc-motels:syncRooms", -1, cachedData["motelRooms"])
                elseif playerBankMoney >= motelData["motelPrice"] then
                    player.removeAccountMoney("bank", motelData["motelPrice"])
                    cachedData["motelRooms"][interiorId] = {
                        ["roomOwner"] = player["identifier"],  
                        ["roomLocked"] = 1,
                        ["roomData"] = defaultRoomData,
                        ["roomFinish"] = defaultRoomData["roomFinish"],
                        ["roomStorages"] = defaultRoomData["roomStorages"],
                        ["latestPayment"] = os.time(),
                        ["paymentTimer"] =  os.difftime(os.time(), os.time()) / 3600
                    }
                    callback(true)
                    TriggerClientEvent("kc-motels:syncRooms", -1, cachedData["motelRooms"])
                end
            else
                callback(false, "No se pudo insertar en la base de datos.")
            end
        end)
    else
        callback(false, "El jugador no existe.")
    end
end)

RemoveRoom = function(roomId)
    local sqlQuery = [[
        DELETE
            FROM
        kc_motels
            WHERE
        interiorId=@interiorId
    ]]
    MySQL.Async.execute(sqlQuery, {
        ["@interiorId"] = roomId,
    }, function(rowsChanged)
        if rowsChanged > 0 then
            cachedData["motelRooms"][roomId] = nil
            TriggerClientEvent("kc-motels:syncRooms", -1, cachedData["motelRooms"])
            Trace("[kc-motels] - Habitación eliminada " .. roomId)
        else
            Trace("[kc-motels] - No se pudo eliminada la habitación " .. roomId)
        end
    end)
end

ESX.RegisterServerCallback("kc-motels:updateStorage", function(source, callback, roomId, action)
    local player = ESX.GetPlayerFromId(source)
    local done = false

    if not player then return callback(false) end
    if not action then return callback(false) end

    if action["store"] then
        local itemAmount = player.getInventoryItem(action["itemData"]["itemName"])["count"]

        if itemAmount and itemAmount >= action["itemData"]["itemAmount"] then
            if action["storageName"] then
                local storage = cachedData["motelRooms"][roomId]["roomData"]["roomStorages"][action["storageName"]]["items"]

                for _, storageItems in ipairs(storage) do
                    if storageItems["item"] == action["itemData"]["itemName"] then
                        storageItems["amount"] = storageItems["amount"] + action["itemData"]["itemAmount"]
                        player.removeInventoryItem(action["itemData"]["itemName"], action["itemData"]["itemAmount"])

                        UpdateRoomData(roomId, function(updated)
                            if updated then
                                callback(true) 
                            else
                                callback(false, "No actualizo.")
                            end
                        end)
                        return
                    end
                end
                table.insert(storage, {
                    ["item"] = action["itemData"]["itemName"],
                    ["label"] = action["itemData"]["itemLabel"],
                    ["amount"] = action["itemData"]["itemAmount"]
                })
                player.removeInventoryItem(action["itemData"]["itemName"], action["itemData"]["itemAmount"])
                UpdateRoomData(roomId, function(updated)
                    if updated then
                        callback(true) 
                    else
                        callback(false, "No actualizo.")
                    end
                end)
                return
            else
                callback(false, "Sin almacenamiento especificado.")
            end
        else
            callback(false, "No tienes esa cantidad de ese artículo.")
        end
    elseif action["take"] then
        if action["storageName"] then
            local storage = cachedData["motelRooms"][roomId]["roomData"]["roomStorages"][action["storageName"]]["items"]

            for _, storageItems in ipairs(storage) do
                if storageItems["item"] == action["itemData"]["itemName"] then
                    if storageItems["amount"] >= action["itemData"]["itemAmount"] then
                        storageItems["amount"] = storageItems["amount"] - action["itemData"]["itemAmount"]
                        player.addInventoryItem(action["itemData"]["itemName"], action["itemData"]["itemAmount"])

                        if storageItems["amount"] == 0 then
                            table.remove(storage, _)
                        end

                        UpdateRoomData(roomId, function(updated)
                            if updated then
                                callback(true)
                                return
                            else
                                callback(false, "No actualizo.")
                                return
                            end
                        end)
                    else
                        callback(false, "La cantidad es superior a la almacenada.")
                        return
                    end
                end
            end
        else
            callback(false, "No se pudo encontrar almacenamiento.")
        end
    elseif action["storeCurrency"] then
        if action["storageName"] then
            local currency = cachedData["motelRooms"][roomId]["roomData"]["roomStorages"][action["storageName"]][action["currency"]]
            local currencyAmount = 0
            local currencyCallback

            if action["currency"] == "cash" then
                currencyAmount = Config.NewESX and player.getAccount("money")["money"] or player.getMoney()
                currencyCallback = function(amount)
                    cachedData["motelRooms"][roomId]["roomData"]["roomStorages"][action["storageName"]][action["currency"]] = cachedData["motelRooms"][roomId]["roomData"]["roomStorages"][action["storageName"]][action["currency"]] + amount
                    player.removeMoney(amount)
                    UpdateRoomData(roomId, function(updated)
                        if updated then
                            callback(true)
                        else
                            callback(false, "No actualizo.")
                        end
                    end)
                end
            elseif action["currency"] == "black_money" then
                currencyAmount = player.getAccount(action["currency"])["money"]
                currencyCallback = function(amount)
                    cachedData["motelRooms"][roomId]["roomData"]["roomStorages"][action["storageName"]][action["currency"]] = cachedData["motelRooms"][roomId]["roomData"]["roomStorages"][action["storageName"]][action["currency"]] + amount
                    player.removeAccountMoney(action["currency"], amount)
                    UpdateRoomData(roomId, function(updated)
                        if updated then
                            callback(true)
                        else
                            callback(false, "No actualizo.")
                        end
                    end)
                end
            end

            if currencyAmount >= action["amount"] then
                currencyCallback(action["amount"])
            else
                callback(false, "Not enough " .. action["cash"] and "efectivo encima." or "dinero negro encima.")
            end
        else
            callback(false, "No se pudo encontrar almacenamiento.")
        end
    elseif action["takeCurrency"] then
        if action["storageName"] then
            local currency = cachedData["motelRooms"][roomId]["roomData"]["roomStorages"][action["storageName"]][action["currency"]]
            local currencyAmount = 0
            local currencyCallback

            if action["currency"] == "cash" then
                currencyAmount = Config.NewESX and player.getAccount("money")["money"] or player.getMoney()
                currencyCallback = function(amount)
                    cachedData["motelRooms"][roomId]["roomData"]["roomStorages"][action["storageName"]][action["currency"]] = cachedData["motelRooms"][roomId]["roomData"]["roomStorages"][action["storageName"]][action["currency"]] - amount
                    player.addMoney(amount)
                    UpdateRoomData(roomId, function(updated)
                        if updated then
                            callback(true)
                            return
                        else
                            callback(false, "No actualizo.")
                            return
                        end
                    end)
                end
            elseif action["currency"] == "black_money" then
                currencyAmount = player.getAccount(action["currency"])["money"]
                currencyCallback = function(amount)
                    cachedData["motelRooms"][roomId]["roomData"]["roomStorages"][action["storageName"]][action["currency"]] = cachedData["motelRooms"][roomId]["roomData"]["roomStorages"][action["storageName"]][action["currency"]] - amount
                    player.addAccountMoney(action["currency"], amount)
                    UpdateRoomData(roomId, function(updated)
                        if updated then
                            callback(true)
                            return
                        else
                            callback(false, "No actualizo.")
                            return
                        end
                    end)
                end
            end

            if currency >= action["amount"] then
                currencyCallback(action["amount"])
            else
                callback(false, "No es suficiente " .. action["cash"] and "efectivo encima." or "dinero negro encima.")
            end
        else
            callback(false, "No se pudo encontrar almacenamiento.")
        end
    end
    TriggerClientEvent("kc-motels:syncRooms", -1, cachedData["motelRooms"])
end)


ESX.RegisterServerCallback("kc-motels:fetchStorage", function(source, callback, roomId, storageName)
    local player = ESX.GetPlayerFromId(source)

    if not player then return callback(false, "Sin jugador cerca") end
    if not roomId or not storageName then return callback(false, "Sin ID de habitación ni nombre de almacenamiento") end
    
    local storage = cachedData["motelRooms"][roomId]["roomData"]["roomStorages"][storageName]["items"]
    if storage and storage[1] then
        callback(cachedData["motelRooms"][roomId]["roomData"]["roomStorages"][storageName])
    else
        callback(false, "No se pudo encontrar almacenamiento")
    end
end)


UpdateRoomData = function(roomId, callback)
    local sqlQuery = [[
        UPDATE
            kc_motels
        SET
            roomData = @roomData
        WHERE
            interiorId = @interiorId
    ]]

    MySQL.Async.execute(sqlQuery, {
        ["@roomData"] = json.encode(cachedData["motelRooms"][roomId]["roomData"]),
        ["@interiorId"] = roomId
    }, function(rowsChanged)
        if rowsChanged > 0 then
            callback(true)
        else
            callback(false)
        end
    end)
end