--!strict
local CURRENT_VERSION = "version 1c"
local DEVFORUM_LINK = ""
local MARKETPLACE_SERVICE = game:GetService("MarketplaceService")
local PRODUCT = 129701135137689
local VersionCheck = {}

function VersionCheck:check()
	local ok = pcall(function(...) 
		local product_info = MARKETPLACE_SERVICE:GetProductInfo(PRODUCT)
		local marketplace_ver : string = product_info["Description"]
		if CURRENT_VERSION ~= marketplace_ver then
			warn(`BeauChevalet has a new update, the latest version is {marketplace_ver}`)
			warn(`download the new version by going into the Toolbox, then clicking the Inventory section, then search BeauChevalet.`)
			warn(`you can see the changelogs here : {DEVFORUM_LINK}`)

		end
	end)
	if not ok then
		warn("version check failed")
	end

end


return VersionCheck