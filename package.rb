#!/usr/bin/env ruby

# This script uses package data in dub.json and the FPM utility to build DEB and
# RPM packages for trash-d so that users can install them
# It requires Ruby and FPM to work: https://fpm.readthedocs.io/en/latest/

require 'json'
require 'fileutils'

data = JSON.parse(File.read("dub.json"))
arch = `uname -m`.chomp

targets = ["deb", "rpm"]

outdir = "pkg/"
FileUtils.mkdir_p(outdir)

for target in targets do
  file = outdir + "trash-d-#{data["version"]}-1-#{arch}.#{target}"
  cmd = <<-sh
    fpm -f -s dir \
    -t #{target} \
    -p '#{file}' \
    --no-depends \
    --name '#{data["name"]}' \
    --license '#{data["license"]}' \
    --version '#{data["version"]}' \
    --architecture '#{arch}' \
    --description '#{data["description"]}' \
    --url '#{data["homepage"]}' \
    --maintainer '#{data["authors"][0]}' \
    trash=/usr/bin/trash
  sh

  exit(1) if not system(cmd)
end
