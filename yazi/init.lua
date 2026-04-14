require("starship"):setup()

require("session"):setup({ sync_yanked = true })

require("mime-ext.local"):setup({
	with_exts = {
		cs = "text/plain",
		csproj = "text/plain",
		sln = "text/plain",
		slnx = "text/plain",
		fs = "text/plain",
		fsproj = "text/plain",
		fsx = "text/plain",
		vb = "text/plain",
		vbproj = "text/plain",
		razor = "text/plain",
		cshtml = "text/plain",
		resx = "text/plain",
		nuspec = "text/plain",
		props = "text/plain",
		targets = "text/plain",
		csx = "text/plain",
		ps1 = "text/plain",
		ahk = "text/plain",
		nu = "text/plain",
	},
	with_files = {
		[".editorconfig"] = "text/plain",
		[".ideavimrc"] = "text/plain",
		[".ripgreprc"] = "text/plain",
		dockerfile = "text/plain",
		makefile = "text/plain",
	},
	fallback_file1 = false,
})

function Linemode:size_and_mtime()
	local time = math.floor(self._file.cha.mtime or 0)
	if time == 0 then
		time = ""
	elseif os.date("%Y", time) == os.date("%Y") then
		time = os.date("%b %d %H:%M", time)
	else
		time = os.date("%b %d  %Y", time)
	end

	local size = self._file:size()
	return string.format("%s %s", size and ya.readable_size(size) or "-", time)
end
