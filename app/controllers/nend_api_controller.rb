require 'net/http'
require 'uri'

class NendApiController < ApplicationController

  def index
    nend_uri = "https://www.nend.net/api/report/agency_image?api_key=e063b0b43cf8c437dfab8d37e1192440&format=json"

    today = Time.now.yesterday.strftime("%Y-%m-%d")
    yesterday = Time.now.yesterday.yesterday.strftime("%Y-%m-%d")

    # nend API をひっぱってきてview に渡す
    uri = URI.parse("#{nend_uri}&date=#{today}")
    response = Net::HTTP.get(uri)
    @today = JSON.parse(response)
    
    uri = URI.parse("#{nend_uri}&date=#{yesterday}")
    response = Net::HTTP.get(uri)
    @yesterday = JSON.parse(response)

    
  end

  def list

    uri = URI.parse("https://www.nend.net/api/report/agency_image?api_key=e063b0b43cf8c437dfab8d37e1192440&format=json")
    response = Net::HTTP.get(uri)
    @json = JSON.parse(response)
    logger.info @json

  end

end
