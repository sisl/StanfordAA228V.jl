function get_version(pkg::Module)
	pkgname = string(pkg)
	deps = Pkg.dependencies()
	for (uuid, info) in deps
		if info.name == pkgname
			return info.version
		end
	end
	return missing
end

function validate_version(pkg::Module)
	if haskey(ENV, "JL_SKIP_228V_UPDATE_CHECK")
		# Skip for Gradescope
		return true
	else
		pkgname = string(pkg)
		current_version = string(get_version(pkg))
		local latest_version

		try
			for reg in Pkg.Registry.reachable_registries()
			    for (uuid, pkgdata) in reg.pkgs
					if pkgdata.name == pkgname
						path = joinpath(reg.path, pkgdata.path)
						package_toml = TOML.parsefile(joinpath(path, "Package.toml"))
						repo = package_toml["repo"]
						repo = replace(repo, "git@github.com:"=>"https://github.com/")
						github_path = replace(repo, "https://github.com/"=>"")
						github_path = replace(github_path, ".git"=>"")
						branch = match(r"refs/heads/(\w+)", readchomp(`git ls-remote --symref $repo HEAD`)).captures[1]
						raw_url = "https://raw.githubusercontent.com/$github_path/refs/heads/$branch/Project.toml"
						github_toml = TOML.parse(read(Downloads.download(raw_url), String))
						latest_version = github_toml["version"]
						break
			        end
			    end
			end
			return current_version == latest_version
		catch err
			@warn err
			return true
		end
	end
end

function validate_project_version(project_dir; github_path="sisl/AA228VProjects")
	if haskey(ENV, "JL_SKIP_228V_UPDATE_CHECK")
		# Skip for Gradescope
		return true
	else
		try
			current_version = read(joinpath(project_dir, ".version"), String)
			version_url =
				"https://raw.githubusercontent.com/$github_path/refs/heads/main/$(basename(project_dir))/.version"
			latest_version = read(Downloads.download(version_url), String)
			return strip(current_version) == strip(latest_version)
		catch err
			@warn err
			return true
		end
	end
end