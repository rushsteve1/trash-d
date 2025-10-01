function PLUGIN:PreInstall(ctx)
	return {
		version = ctx.version,
		url = "https://git.sr.ht/~sircmpwn/" .. PLUGIN.name .. "/archive/" .. ctx.version .. ".tar.gz",
		sha256 = "4c5c6136540384e5455b250f768e7ca11b03fdba1a8efc2341ee0f1111e57612"
	}
end
