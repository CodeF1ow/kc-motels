resource_manifest_version "44febabe-d386-4d18-afbe-5e627f4af937"


client_scripts {
	"client/*",
}

server_scripts {
	'@async/async.lua',
	"@mysql-async/lib/MySQL.lua",
	"server/*"
}

shared_scripts {
	"config.lua",
	"shared/*"
}