local port              = 46845                -- server tcp port
local connto            = 0.1                  -- connection/send/receive timeout (sec)
local loopto            = 0.5                  -- main loop (before reconnect, update clipboard) timeout (sec)
local ssl                                      -- when tls switched off it is insecure, you should install lua-sec and
pcall(function() ssl    = require "ssl" end)   -- create PKI (see https://wiki.archlinux.org/index.php/Easy-RSA)
local hsto              = 5                    -- tls handshake timeout (sec)
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
local posix																		 -- we use posix.poll for non-blocking read,
pcall(function() posix  = require "posix" end) -- cause "xsel -o ..." hangs on sometimes
local xsel_out_to       = 1000                 -- time (ms) to wait xsel output before close pipe
local forktobg          = false                -- fork to background after start
local debug             = true                -- debug (verbose) mode

local function factory(mode)
	local tls_params
	if mode == "server" then
		tls_params = server_tls_params
	elseif mode == "client" then
		tls_params = client_tls_params
	end
	return port, connto, loopto, ssl, hsto, tls_params, sel, posix, xsel_out_to, forktobg, debug
end

return factory
