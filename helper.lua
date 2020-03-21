-- read all content of file via posix.read()
local function freadall(rd, posix)
	local res = ""
	repeat
		local buf = posix.read(rd, 2048)
		if buf ~= nil then
			res = res .. buf
		end
	until buf == nil or buf == ""
	return res
end

return {freadall = freadall}
