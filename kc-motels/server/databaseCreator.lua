if Config.AutoDatabaseCreator then
	local sqlQuery = {}
	MySQL.ready(function()
		table.insert(sqlQuery, function(callback)
            MySQL.Async.execute([[
                CREATE TABLE IF NOT EXISTS `kc_motels` (
                    `interiorId` longtext NOT NULL,
                    `roomOwner` varchar(50) NOT NULL,
                    `roomData` text NOT NULL,
                    `latestPayment` bigint(20) NOT NULL,
                    FULLTEXT KEY `interiorId` (`interiorId`)
                ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
			]], {}, function(rowsChanged)
                callback(rowsChanged > 0)
            end)
		end)

		Async.parallel(sqlQuery, function(responses)
			if #responses >= #sqlQuery then
				print("Tabla [kc_motels] creada en la BD.")
			end
		end)
    end)
end