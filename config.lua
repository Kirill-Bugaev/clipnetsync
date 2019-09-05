local port              = 46843                -- server tcp port
local connto            = 0.1                  -- connection/send/receive timeout (sec)
local loopto            = 0.5                  -- main loop (before reconnect, update clipboard) timeout (sec)
local ssl                                      -- when tls switched off it is insecure, you should install lua-sec and
pcall(function() ssl    = require "ssl" end)   -- create PKI (see https://wiki.archlinux.org/index.php/Easy-RSA)
local hsto              = 5                    -- tls handshake timeout
local server_tls_params = {
	mode                  = "server",
	protocol              = "tlsv1_2",
	key                   = "./certs/clipnetsync-server.key",
	certificate           = "./certs/clipnetsync-server.crt",
	cafile                = "./certs/ca.crt",
	verify                = {"peer", "fail_if_no_peer_cert"},
	options               = "all"
}
local client_tls_params = {
	mode                  = "client",
	protocol              = "any",
	key                   = "./certs/clipnetsync-client.key",
	certificate           = "./certs/clipnetsync-client.crt",
	cafile                = "./certs/ca.crt",
	verify                = "peer",
	options               = {"all", "no_sslv3"}
}
local sel               = "--primary"          -- X11 selection: --primary, --secondary or --clipboard for xsel
local forktobg          = false                -- fork to background after start (no works yet)
local debug             = false                -- debug (verbose) mode

local function factory(mode)
	local tls_params
	if mode == "server" then
		tls_params = server_tls_params
	elseif mode == "client" then
		tls_params = client_tls_params
	end
	return port, connto, loopto, ssl, hsto, tls_params, sel, forktobg, debug
end

return factory
