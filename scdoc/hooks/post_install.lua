function PLUGIN:PostInstall(ctx)
	local build_dir = ctx.sdkInfo[PLUGIN.name].path
	local make_result = os.execute("make -sC " .. build_dir .. " " .. PLUGIN.name .. " LDFLAGS='-fpie'")
	if make_result ~= 0 then
		error("Compilation error")
	end
end
