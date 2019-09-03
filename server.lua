local socket  = require "socket"
--local ssl     = require "ssl"
local common = require "common"

local port, connto, loopto, tls_params, sel = require("config")()
tls_params.mode = "server"

-- save current clipboard value
local f = io.popen("xsel -o " .. sel, "r")
local clipsave = f:read("*a")
f:close()

local server = assert(socket.bind("*", port))
server:settimeout(connto)
local clients = {}

-- spread clipboard value among clients
local function spread(clip)
	for k, c in pairs(clients) do
		local lb, em = common.sendclip(c, clip)
		if not lb and em == "closed" then
			-- remove client
			c:close()
			table.remove(clients, k)
		end
	end
end

-- main loop
while 1 do
	local c = server:accept()
	if c then
		-- add new client
--		c = ssl.wrap(c, tls_params)
		if c then
			c:settimeout(connto)
			table.insert(clients, c)
		end
	end

	-- examine clients
	local clip, em
	local r, _, to = socket.select(clients, nil, connto)
	if not to then
		-- receive from first alive
		for _, rc in ipairs(r) do
			clip, em = common.receiveclip(rc)
			if not clip and em == "closed" then
				-- disconnect client
				rc:close()

			elseif clip then
				-- set clipboard
				clipsave = clip
				f = io.popen("xsel -i " .. sel, "w")
				f:write(clip)
				f:close()
				-- spread new clipboard value
				spread(clip)
				break
			end
		end
	end

	-- check local clipboard
	f = io.popen("xsel -o " .. sel, "r")
	clip = f:read("*a")
	f:close()
	if clip ~= "" and clip ~= clipsave then
		clipsave = clip
		spread(clip, nil)
	end

	socket.sleep(loopto)
end
