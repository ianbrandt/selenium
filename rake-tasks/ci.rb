require 'uri'
require 'net/http'
require 'digest/md5'
require 'json'
require 'pathname'

def net_http
  http_proxy = ENV['http_proxy'] || ENV['HTTP_PROXY']
  if http_proxy
    http_proxy = "http://#{http_proxy}" unless http_proxy.start_with?("http://")
    proxy_uri = URI.parse(http_proxy)

    Net::HTTP::Proxy(proxy_uri.host, proxy_uri.port)
  else
    Net::HTTP
  end
end

namespace :ci do
  task :upload_to_sauce do
    upload_path = ENV["UPLOAD_PATH"]
    username = ENV["SAUCE_USERNAME"]
    apikey = ENV["SAUCE_APIKEY"]
    upload_filename = Pathname.new(upload_path).basename
    upload_url = "http://saucelabs.com/rest/v1/storage/#{username}/#{upload_filename}"
    body = nil

    File.open(find_file(upload_path), "r") do |infile|
      body = infile.read
    end

    uri = URI.parse(upload_url)
    request = Net::HTTP::Post.new(uri.request_uri)
    request.basic_auth(username, apikey)
    request["Content-Type"] = "application/octet-stream"
    request.body = body
    response = net_http.new(uri.host, uri.port).request(request)
    metadata = JSON.parse(response.body)
    local_digest = Digest::MD5.hexdigest(body)
    if metadata['md5'] == local_digest
      puts "file successfully uploaded: #{metadata['filename']}"
    else
      puts "issues uploading file: #{response.code} - #{response.body}"
    end
  end
end
