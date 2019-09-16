local function tlswarn()
	print("Warning! Started without TLS.")
	print("Using it without TLS is insecure.")
	print("You should install lua-sec and create your own PKI.")
	print("See https://github.com/Kirill-Bugaev/clipnetsync#TLS")
end

local function forktobg()
	local unistd
	local _, em = pcall(function () unistd = require "posix".unistd end)
	if not unistd then
		return false, em
	end
	local fork = unistd.fork
	local pid
	pid, em = fork()
	if not pid then
		return false, em
	end
	if pid ~= 0 then
		os.exit(0)
	end
	unistd.close(0)
	unistd.close(1)
	unistd.close(2)
	return true
end

-- escape all lines with '#', add '\n*' to the end (end of data mark)
local function sendclip(socket, clip)
	clip = "#" .. clip
	clip = clip:gsub("[\n\r]", "%1#")
	clip = clip .. "\n*\n"
	return socket:send(clip) -- try to send at one go
end

local function receiveclip(socket)
	local out = ""
	while 1 do
		local line, em = socket:receive()
		if not line then return nil, em end
		if line == "*" then break end
		if out ~= "" then
			out = out .. "\n"
		end
		out = out .. line:sub(2)
	end
	return out
end

return {tlswarn = tlswarn, forktobg = forktobg, receiveclip = receiveclip, sendclip = sendclip}
