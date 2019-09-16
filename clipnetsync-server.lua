#!/usr/bin/env lua

local socket  = require "socket"
local common = require "common"

local port, connto, loopto, ssl, hsto, tls_params, sel, fork, debug = require("config")("server")

-- spread clipboard value among clients
local function spread(clip, clients, peers)
	for k, c in pairs(clients) do
		if debug then print(string.format("sending to %s:%d ...", peers[k].ip, peers[k].port)) end
		local lb, em = common.sendclip(c, clip)
		if not lb and em == "closed" then
			if debug then print(string.format("%s:%d closed connection", peers[k].ip, peers[k].port)) end
			-- remove client
			c:close()
			table.remove(clients, k)
			table.remove(peers, k)
		else
			if debug then print("sent") end
		end
	end
end

-- TLS warning
if not ssl then common.tlswarn() end

-- try to fork
if fork then
	local s, em = common.forktobg()
	if s then
		if debug then print("forked to background") end
	else
		print("can't fork to background")
		print(em)
		print("stay foreground")
	end
end

-- start server
local server, em = socket.bind("*", port)
if not server then
	print("can't bind socket to port " .. port)
	print(em)
	os.exit(1)
end
server:settimeout(connto)
local clients = {}
local peers = {}

-- save current clipboard value
local f = io.popen("xsel -o " .. sel, "r")
local clipsave = f:read("*a")
f:close()
if debug then print("local clipboard: " .. clipsave) end

-- main loop
local c, pip, pport, sslc, hsres, clip, r, _, to
while 1 do
	c = server:accept()
	if not c then goto examine end

	-- save ip and port of client
	pip, pport = c:getpeername()

	if not ssl then
		-- add new client (insecure)
		if debug then print(string.format("insecure connection established with %s:%d", pip, pport)) end
		c:settimeout(connto)
		table.insert(clients, c)
		table.insert(peers, {ip = pip, port = pport})
		goto examine
	end

	-- try to establish secure connection
	sslc, em = ssl.wrap(c, tls_params)
	if not sslc then
		if debug then
			print(string.format("can't establish secure connection with %s:%d", pip, pport))
			print(em)
		end
		c:close()
		goto examine
	end

	c = sslc
	-- try to handshake
	c:settimeout(hsto)
	hsres, em = c:dohandshake()
	if not hsres then
		if debug then
			print(string.format("can't do handshake with %s:%d", pip, pport))
			print(em)
		end
		c:close()
		goto examine
	end

	-- add new client (secure)
	if debug then print(string.format("secure connection established with %s:%d", pip, pport)) end
	c:settimeout(connto)
	table.insert(clients, c)
	table.insert(peers, {ip = pip, port = pport})
	goto examine

	-- examine clients
	::examine::
	r, _, to = socket.select(clients, nil, connto)
	if to then goto checkcb end

	-- receive from first alive
	for _, rc in ipairs(r) do
		clip, em = common.receiveclip(rc)
		if not clip and em == "closed" then
			-- disconnect client
			rc:close()
			goto continue
		end

		if clip then
			if debug then print("received clipboard: " .. clip) end
			-- set clipboard
			clipsave = clip
			f = io.popen("xsel -i " .. sel, "w")
			f:write(clip)
			f:close()
			-- spread new clipboard value
			spread(clip, clients, peers)
			break
		end

		::continue::
	end

	-- check local clipboard
	::checkcb::
	f = io.popen("xsel -o " .. sel, "r")
	clip = f:read("*a")
	f:close()
	if clip ~= clipsave then
		if debug then print("clipboard changed locally: " .. clip) end
		clipsave = clip
		spread(clip, clients, peers)
	end

	socket.sleep(loopto)
end
