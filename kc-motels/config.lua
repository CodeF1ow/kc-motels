Config = {}

-- [Configuaciones generales] -- 
Config.AutoDatabaseCreator = true -- Si lo activa esto creara la base de datos automaticamente, si desea puede desactivarlo.
Config.EnableKeySystem = false -- Esto se establece en verdadero si tiene el recurso kc-Keys.
Config.NewESX = false -- Establezca esto en verdadero si tiene la versión final de esx.
Config.DiscInventory = false -- Habilite si usa disc inventorhud o si desea usar su interfaz de usuario para almacenamiento.
Config.EnableDebug = false

-- [Configuración de motel] --
Config.RentTimer = 24 -- Tiempo entre pagos si el modo de alquiler está habilitado. (1 = 1h)
Config.AutoRemoveRoom = Config.RentTimer * 7 -- Esto eliminará la habitación después de 7 pagos atrasados. (Puede ser inferior a superior depende de los pagos que desea que la gente tenga atrasados)
Config.StoreCash = true -- Habilite si desea que el jugador pueda almacenar efectivo en el almacenamiento.
Config.StoreBlackMoney = true -- Habilite si desea que el jugador pueda almacenar dinero negro en el almacenamiento.
Config.KeyPrice = 10 -- Precio para comprar llave extra.
Config.RaidJob = "police" -- El trabajo que debes tener para hacer una incursión. (Este rango podra entrar si la habitacion esta siendo robada).
Config.RaidTimer = 10 -- Tiempo en segundos que le toma a un policía abrir la puerta. (1 = 1s)
Config.RaidEnabled = true -- Habilite esto si desea que la policía tenga la capacidad de asaltar habitaciones.
Config.CancelRoomCommand = "hotel" -- Configúrelo en falso si no desea tener la capacidad de cancelar la habitación.

Config.Motels = {
     { -- Motel de Breze Sandy
         ["motelName"] = "Motel Pink Cage", -- Nombre que aparece en el mapa como un blip.
         ["motelPosition"] = vector3(326.92, -210.41, 53.6), -- Posición del motel.
         ["doorHash"] = -1156992775,
         ["doorOffset"] = vector3(1.0, 0.0, 0.0),
         ["motelPrice"] = 25, -- Precio de compra si rentMode es "falso" o tambien sera el precio que paga por el alquiler cada vez si rentMode esta en "true".
         ["rentMode"] = true, -- Si es "true", las habitaciones solo se alquilan, si se establece en "false", usted compra la habitación y no se realizan otros cargos después..
         ["roomFinish"] = "sandy_motel",
         ["furniture"] = {
             ["drawer"] = {
                 ["restricted"] = true, -- Si solo el propietario de la habitación debe acceder, establezca el valor "true"
                 ["offset"] = vector3(2.85, -0.9, -0.4), -- Desplaza las coordenadas de la puerta a la posición establecida de los muebles.
                 ["text"] = "Alijo", -- Texto que aparece en texto 3D.
                 ["type"] = "storage", -- Establezca el tipo de almacenamiento si desea poder almacenar cosas.
                 ["callback"] = function(interiorId, furnitureName)
                     OpenStash(interiorId, furnitureName)
                 end
             },
             ["wardrobe"] = {
                 ["restricted"] = true, -- Si solo el propietario de la habitación debe acceder, establezca el valor "true"
                 ["offset"] = vector3(-0.3, 2.6, -0.4), -- Desplaza las coordenadas de la puerta a la posición establecida de los muebles.
                 ["text"] = "Armario de ropa",
                 ["callback"] = function(interiorId, furnitureName)
                     Wardrobe()
                 end
             },
             ["manager"] = {
                 ["restricted"] = true,-- Si solo el propietario de la habitación debe acceder, establezca el valor "true"
                 ["offset"] = vector3(-4.85, -1.3, -0.4), -- Desplaza las coordenadas de la puerta a la posición establecida de los muebles.
                 ["text"] = "Gestión de habitaciones",
                 ["callback"] = function(interiorId, roomNumber, motelData)
                     RoomManagment(interiorId, roomNumber, motelData)
                 end
             },
         }
     },
	 { --Motel de Breze Sandy
         ["motelName"] = "Motel Bayview", -- Nombre que aparece en el mapa como un blip.
         ["motelPosition"] = vector3(-691.41, 5794.51, 22.35), -- Posición del motel.
         ["doorHash"] = -664582244,
         ["doorOffset"] = vector3(-1.0, 0.0, 0.0),
         ["motelPrice"] = 25, -- Precio de compra si rentMode es "falso" o tambien sera el precio que paga por el alquiler cada vez si rentMode esta en "true".
         ["rentMode"] = true, -- Si es "true", las habitaciones solo se alquilan, si se establece en "false", usted compra la habitación y no se realizan otros cargos después..
         ["roomFinish"] = "sandy_motel",
         ["furniture"] = {
             ["drawer"] = {
                 ["restricted"] = true, -- Si solo el propietario de la habitación debe acceder, establezca el valor "true"
                 ["offset"] = vector3(-0.5, -0.5, -0.4), -- Desplaza las coordenadas de la puerta a la posición establecida de los muebles.
                 ["text"] = "Alijo", -- Texto que aparece en texto 3D.
                 ["type"] = "storage", -- Establezca el tipo de almacenamiento si desea poder almacenar cosas.
                 ["callback"] = function(interiorId, furnitureName)
                     OpenStash(interiorId, furnitureName)
                 end
             },
             ["wardrobe"] = {
                 ["restricted"] = true, -- Si solo el propietario de la habitación debe acceder, establezca el valor "true"
                 ["offset"] = vector3(-1, -3, -0.4), -- Desplaza las coordenadas de la puerta a la posición establecida de los muebles.
                 ["text"] = "Armario de ropa",
                 ["callback"] = function(interiorId, furnitureName)
                     Wardrobe()
                 end
             },
             ["manager"] = {
                 ["restricted"] = true,-- Si solo el propietario de la habitación debe acceder, establezca el valor "true"
                 ["offset"] = vector3(1.85, -1.8, -0.4), -- Desplaza las coordenadas de la puerta a la posición establecida de los muebles.
                 ["text"] = "Gestión de habitaciones",
                 ["callback"] = function(interiorId, roomNumber, motelData)
                     RoomManagment(interiorId, roomNumber, motelData)
                 end
             },
         }
     },
	 { -- Motel de la playa 
         ["motelName"] = "Motel de playa Perrera", -- Nombre que aparece en el mapa como un blip.
         ["motelPosition"] = vector3(-1472.64, -659.33, 29.08), -- Posición del motel.
         ["doorHash"] = -2123441472,
         ["doorOffset"] = vector3(-1.0, 0.0, 0.0),
         ["motelPrice"] = 25, -- Precio de compra si rentMode es "falso" o tambien sera el precio que paga por el alquiler cada vez si rentMode esta en "true".
         ["rentMode"] = true, -- Si es "true", las habitaciones solo se alquilan, si se establece en "false", usted compra la habitación y no se realizan otros cargos después..
         ["roomFinish"] = "sandy_motel",
         ["furniture"] = {
             ["drawer"] = {
                 ["restricted"] = true, -- Si solo el propietario de la habitación debe acceder, establezca el valor "true"
                 ["offset"] = vector3(-1.7, 1.5, -0.4), -- Desplaza las coordenadas de la puerta a la posición establecida de los muebles.
                 ["text"] = "Alijo", -- Texto que aparece en texto 3D.
                 ["type"] = "storage", -- Establezca el tipo de almacenamiento si desea poder almacenar cosas.
                 ["callback"] = function(interiorId, furnitureName)
                     OpenStash(interiorId, furnitureName)
                 end
             },
             ["wardrobe"] = {
                 ["restricted"] = true, -- Si solo el propietario de la habitación debe acceder, establezca el valor "true"
                 ["offset"] = vector3(-1.7, -0.5, -0.4), -- Desplaza las coordenadas de la puerta a la posición establecida de los muebles.
                 ["text"] = "Armario de ropa",
                 ["callback"] = function(interiorId, furnitureName)
                     Wardrobe()
                 end
             },
             ["manager"] = {
                 ["restricted"] = true,-- Si solo el propietario de la habitación debe acceder, establezca el valor "true"
                 ["offset"] = vector3(1.3, -0.3, -0.4), -- Desplaza las coordenadas de la puerta a la posición establecida de los muebles.
                 ["text"] = "Gestión de habitaciones",
                 ["callback"] = function(interiorId, roomNumber, motelData)
                     RoomManagment(interiorId, roomNumber, motelData)
                 end
             },
         }
     },
}

Config.RoomFinishes = { -- Estos son los diseños de interiores que puedes cambiar en la habitación..
    {
        ["name"] = "Diseño predeterminado", -- Nombre que aparece en el menú.
        ["finish"] = "sandy_motel", -- No toques si no sabes que es esto. (Interiores que podras cambiar)
        ["price"] = 1 -- El precio que cuesta cambiar a este interior..
    }
}