#!/usr/bin/env lua

local socket  = require "socket"
local common = require "common"

local port, connto, loopto, ssl, hsto, tls_params, sel, posix, xsel_to, fork, debug = require("config")("client")

local host = arg[1]

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

-- connection loop
local f, clip, clipsave, conn, em, sslconn, hsres, lb
local connstage = 0
while 1 do
	-- save current clipboard value
	repeat
		clip, em = common.getcurclip(sel, posix, xsel_to)
		if debug and clip == nil then print("can't obtain local clipboard: " .. em) end
	until clip ~= nil

	if clip ~= clipsave then
		if debug then print("local clipboard: " .. clip) end
		clipsave = clip
	end

	-- try to connect
	conn, em = socket.connect(host, port)
	if not conn then
		if debug and connstage ~= 1 then
			print(string.format("can't connect to %s:%d", host, port))
			print(em)
			connstage = 1
		end
		goto reconn
	end
	if ssl then
		sslconn, em = ssl.wrap(conn, tls_params)
		if not sslconn then
			if debug and connstage ~= 2 then
				print(string.format("can't establish secure connection with %s:%d", host, port))
				print(em)
				connstage = 2
			end
			goto closeconn
		end
		conn = sslconn
		conn:settimeout(hsto)
		hsres, em = conn:dohandshake()
		if not hsres then
			if debug and connstage ~= 3 then
				print(string.format("can't do handshake with %s:%d", host, port))
				print(em)
				connstage = 3
			end
			goto closeconn
		end
		if debug then print(string.format("secure connection established with %s:%d", host, port)) end
	else
		if debug then print(string.format("insecure connection established with %s:%d", host, port)) end
	end
	conn:settimeout(connto)
	connstage = 0

	-- send clipboard on connect
	if debug then print("sending...") end
	lb, em = common.sendclip(conn, clip)
	if not lb and em == "closed" then
		if debug then print("server closed connection") end
		goto closeconn
	end
	if debug then print("sent") end

	-- client loop
	while 1 do
		-- examine server
		local r, _, to = socket.select({conn}, nil, connto)
		if not to and r[1] then
			if debug then print("receiving...") end
			clip, em = common.receiveclip(conn)
			if not clip and em == "closed" then
				if debug then print("server closed connection") end
				goto closeconn
			elseif clip then
				if debug then print("received clipboard: " .. clip) end
				-- set clipboard
				clipsave = clip
				f = io.popen("xsel -i " .. sel, "w")
				f:write(clip)
				f:close()
			end
		end

		-- check local clipboard
		repeat
			clip, em = common.getcurclip(sel, posix, xsel_to)
			if debug and clip == nil then print("can't obtain local clipboard: " .. em) end
		until clip ~= nil

		if clip ~= clipsave then
			if debug then print("clipboard changed locally: " .. clip) end
			clipsave = clip
			if debug then print("sending...") end
			lb, em = common.sendclip(conn, clip)
			if not lb and em == "closed" then
				if debug then print("server closed connection") end
				goto closeconn
			end
			if debug then print("sent") end
		end

		socket.sleep(loopto)
	end

	::closeconn::
	conn:close()
	::reconn::
	socket.sleep(loopto)
end
