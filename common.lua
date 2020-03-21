local helper  = require "helper"

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

-- get current clipboard value
local function getcurclip(sel, posix, to)
	local rd, wd = posix.pipe()
	if rd == nil then
		return nil, wd
	end

	local clip = nil

	local pid, em = posix.fork()
	if pid == nil then
		goto finish
	end

	if pid == 0 then
		-- child
		posix.close(rd)

		-- redirect stdout to pipe
		if posix.dup2(wd, posix.fileno(io.stdout)) == nil then
			os.exit(2)
		end

		posix.exec("/usr/bin/xsel", {[0] = "-o", sel})

		-- failed to execute
		os.exit(3)
	else
		-- parent
		posix.close(wd)

		-- set non-blocking read for pipe
		local flags
		flags, em = posix.fcntl(rd, posix.F_GETFL)
		if flags == nil then
			posix.kill(pid, posix.SIGINT)
			goto finish
		end
		local res
		res, em = posix.fcntl(rd, posix.F_SETFL, flags | posix.O_NONBLOCK)
		if res == nil then
			posix.kill(pid, posix.SIGINT)
			goto finish
		end

		-- wait xsel output on pipe
		local fds = { [rd] = { events = { IN = true } } }
		res, em = posix.poll(fds, to)
		if res == 1 then
			-- pipe is ready for read, get child terminate status,
			-- data on pipe appears only after child process terminates
			-- so can call wait without WNOHANG
			local _, _, status = posix.wait(pid)
			if status == 0 then
				-- xsel exited normally, get xsel output
				-- don't make lua file from pipe descriptor by posix.fdopen(rd, "r")!
				-- lua file should be closed individually, but if we will close it here,
				-- then posix.close() at the end of function will try to close already closed pipe
				clip = helper.freadall(rd, posix)
			elseif status == 1 then
				em = "xsel exited with error"
			elseif status == 2 then
				em = "failed to redirect child process stdout to pipe"
			elseif status == 3 then
				em = "failed to execute xsel (is installed?)"
			else
				em = "child process failed with code = " .. status
			end
		else
			-- something wrong: child process hangs on or can't poll pipe
			-- kill child (or zombie)
			local kres = posix.kill(pid, posix.SIGINT)
			if res == 0 then
				em = "child process (xsel, probably) hangs on, "
				if kres ~= 0 then
					-- failed kill
					em = em .. "not "
				end
				em = em .. "killed"
			end
		end
	end

	::finish::
	posix.close(rd)
	return clip, em
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

return {tlswarn = tlswarn, forktobg = forktobg, getcurclip = getcurclip, receiveclip = receiveclip, sendclip = sendclip}
