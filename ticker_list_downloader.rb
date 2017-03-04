require 'rubygems'
require 'httpclient'

class TickerListsDownloader
  #  TickerListsDownloader.new().run => downloads lists of ticker codes
  attr_reader :base_url, :xls_ar
  attr_accessor :http_client

  def initialize(args={})
    @base_url = args[:base_url] || base_url
    @xls_ar = args[:xls_ar] || xls_ar
    @http_client = HTTPClient.new
  end

  def base_url
    "http://www.jpx.co.jp/markets/statistics-equities/misc/tvdivq0000001vg2-att/"
  end

  def xls_ar
    ['data_j.xls']
  end

  def run
    xls_ar.each do |xls|
      xls_url = base_url + xls
      open(xls, 'wb') do |file|
        file.write http_client.get_content("#{xls_url}")
      end
    end
  end

end
