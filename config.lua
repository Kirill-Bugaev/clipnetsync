local port       = 46836
local connto     = 0.1 -- sec
local loopto     = 0.5 -- sec
local tls_params = {
	mode     = "",
	protocol = "tlsv1",
	verify   = "none",
	options  = "all",
}
local sel        = "--primary" -- --primary, --secondary or --clipboard for xsel

local function factory()
	return port, connto, loopto, tls_params, sel
end

return factory
