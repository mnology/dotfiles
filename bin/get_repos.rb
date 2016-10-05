#!/usr/bin/env ruby
require 'net/http'
require 'uri'
require 'json'
require 'openssl'

@org = ARGV[0] ||= 'some-repo'
@access_token = ARGV[1].nil? ? ENV['GITHUB_ACCESS_TOKEN'] : ARGV[1]
fail('you need an access token, either as the second parameter or in your environment as GITHUB_ACCESS_TOKEN')if @access_token.nil?

Dir.mkdir(@org) unless Dir.exist?(@org)
Dir.chdir("#{Dir.pwd}/#{@org}")
puts(format("Working dir:\n\t%s", Dir.pwd))

(1..5).each do |page_number|
  puts "Page #{page_number} of 5, 100 items at a time"
  uri = URI("https://git.hostname.net/api/v3/orgs/#{@org}/repos?per_page=100&page=#{page_number}&access_token=#{@access_token}")
  https = Net::HTTP.new(uri.host, uri.port)
  https.use_ssl = true
  https.verify_mode = OpenSSL::SSL::VERIFY_NONE
  request = Net::HTTP::Get.new(uri.request_uri)
  response = https.request(request)

  JSON.parse(response.body.to_s).each { |repo| `git clone #{repo['ssh_url']}` }
end
