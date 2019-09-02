-- escape all lines with '*', add '*' to the end (end of data mark)
local function sendclip(socket, clip)
	clip = "*" .. clip
	clip:gsub("\n", "\n*")
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

return {receiveclip = receiveclip, sendclip = sendclip}
