if Autoproj.respond_to?(:post_import)
    # Override the CMAKE_BUILD_TYPE configuration parameter based on the
    # "stable" tag
    Autoproj.post_import do |pkg|
        next if !pkg.kind_of?(Autobuild::CMake)

        if !pkg.defines.has_key?('CMAKE_BUILD_TYPE')
            if pkg.has_tag?('stable')
                pkg.define "CMAKE_BUILD_TYPE", "Release"
            elsif pkg.has_tag?('needs_opt')
                pkg.define "CMAKE_BUILD_TYPE", "RelWithDebInfo"
            else
                pkg.define "CMAKE_BUILD_TYPE", "Debug"
            end
        end
    end

    Autoproj.post_import do |pkg|
        next if !pkg.importer.kind_of?(Autobuild::Git)

        hook_source_path = File.join(File.expand_path(File.dirname(__FILE__)), "git_do_not_commit_hook")
        hook_dest_path   = File.join(pkg.srcdir, '.git', 'hooks', 'pre-commit')
        if pkg.importer.branch == "next" || pkg.importer.branch == "stable"
            # Install do-not-commit hook
            FileUtils.cp hook_source_path, hook_dest_path
        else
            # Remove the do-not-commit hook
            FileUtils.rm_f hook_dest_path
        end
    end

    Autoproj.manifest.each_package do |pkg|
        if ['next', 'stable'].include?(pkg.importer.branch)
            packages = pkg.package_set.default_packages
            if !packages.include?(pkg.autobuild)
                Autoproj.warn "package #{pkg.name} import configuration lists '#{pkg.importer.branch}' as import branch, but the package itself is not enabled in the #{pkg.importer.branch} flavor of Rock. I reset the branch to master"
                pkg.importer.branch = "master"
            end
        end
    end
end

