
require "option_parser"
require "uri"
require "file"
require "http"

errors = 0

destination = ""
uris = [] of URI

parser = OptionParser.parse! do |parser|
	parser.banner = "usage: fetch [options] url"

	parser.on "-h", "--help", "Show this help" do |parse|
		puts parser

		exit 0
	end

	parser.on "-o name", "--output name", "Sets the destination filename" do |filename|
		destination = filename
	end

	parser.unknown_args do |before, after|
		before.each do |e|
			uri = URI.parse e

			unless uri
				STDERR << "Hey, don’t give me unparsable URIs!\n"
			end

			uris.push uri
		end
	end
end

if uris.size < 1
	STDERR << parser
	STDERR << "\n"

	exit 1
end

if destination != "" && uris.size > 1
	STDERR << "Do NOT use -o with more than one URI.\n"

	exit 1
end

uris.each do |uri|
	destfile = if destination != ""
		destination
	else
		File.basename uri.path.to_s
	end

	if destfile == ""
		STDERR << " You need to have a path in your URI… or to use -o.\n"

		errors += 1

		next
	end

	puts "[#{uri.scheme}] #{uri} -> #{destfile}"

	file = File.open destfile, "w"

	if ! uri.scheme
		file << File.read uri.path.to_s
	elsif uri.scheme =~ /https?/
		HTTP::Client.get uri do |response|
			if response.status_code == 200
				while str = response.body_io.gets
					file << str
				end
			else
				STDERR << " Could not download that {{#{response.status_code}}}.\n"

				errors += 1
			end
		end
	else
		STDERR << " Does not know how to download #{uri.scheme} URIs.\n"

		errors += 1
	end

	file.close
end

exit errors

