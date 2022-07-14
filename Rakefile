desc "Build the default debug (alias)"
task default: "build:debug"

@build_dir = ENV["BUILD_DIR"] || "./build"

desc "Build debug binary (alias)"
task build: "build:debug"

namespace :build do
	desc "Build debug binary"
	task :debug do
		`dub build`
	end

	desc "Build release binary"
	task :release do
		`dub build --build=release`
	end

	namespace :release do
		desc "Build release with $DC compiler"
		task :dc do
			`dub build --build=release --compiler=#{ENV["DC"] || "dmd"}`
		end

		desc "Build release with $DC compiler and strip"
		task strip: "release:dc" do
			`strip #{@build_dir}/trash`
		end
	end
end

desc "Build and run tests"
task :test do
	`dub test`
end

namespace :test do
	desc "Build and run tests with code coverage"
	task :coverage do
		`dub test --coverage`
		coverage_dir = @build_dir + "/coverage/"
		FileUtils.mkdir_p coverage_dir
		FileUtils.mv Dir.glob("*.lst"), coverage_dir
	end
end

desc "Run linting"
task :lint do
	`dub lint`
end

desc "Format with dfmt"
task :format do
	`dub run dfmt -- -i source/**/*.d`
end

desc "Build the manpage with ronn"
task :manpage do
	FileUtils.mkdir_p @build_dir
	`ronn --roff --pipe MANUAL.md > #{@build_dir}/trash.man`
end

desc "Build DEB and RPM packages with FPM"
task package: %w[build:release:dc manpage] do
	ruby "./package.rb #{@build_dir}/"
end

desc "Remove build artifacts"
task :clean do
	FileUtils.rm_rf @build_dir
end

desc "Build every artifact"
task all: %w[build:release manpage package]
