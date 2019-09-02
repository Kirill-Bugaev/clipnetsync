local socket  = require "socket"
--local ssl     = require "ssl"
local common = require "common"

local port, connto, loopto, tls_params, sel = require("config")()
tls_params.mode = "client"
local host = arg[1]

-- connection loop
local f, clipsave, conn, sslconn, clip, lb, em
while 1 do
	-- save current clipboard value
	f = io.popen("xsel -o " .. sel, "r")
	clipsave = f:read("*a")
	f:close()

	-- try to connect
	conn = socket.connect(host, port)
	if not conn then goto reconn end
--	sslconn = ssl.wrap(conn, tls_params)
--	if not sslconn then goto closeconn end
--	conn = sslconn
--	conn:settimeout(connto)
--	if not conn:dohandshake() then goto closeconn end

	-- client loop
	while 1 do
		-- examine server
		local r, _, to = socket.select({conn}, nil, connto)
		if not to and r[1] then
			clip, em = common.receiveclip(conn)
			if not clip and em == "closed" then
				goto closeconn
			elseif clip then
				-- set clipboard
				clipsave = clip
				f = io.popen("xsel -i " .. sel, "w")
				f:write(clip)
				f:close()
			end
		end

		-- check local clipboard
		f = io.popen("xsel -o " .. sel, "r")
		clip = f:read("*a")
		f:close()
		if clip ~= "" and clip ~= clipsave then
			clipsave = clip
			lb, em = common.sendclip(conn, clip)
			if not lb and em == "closed" then goto closeconn end
		end

		socket.sleep(loopto)
	end

	::closeconn::
	conn:close()
	::reconn::
	socket.sleep(loopto)
end
