require 'roo'
require 'rubygems'
require 'httpclient'
require './ticker_array'

class TickerCodeListParser
  # p TickerCodeExtractor.new.codes[0..10]
  # => [1301, 1332, 1333, 1352, 1377, 1379, 1414, 1417, 1419, 1420, 1514]
  attr_accessor :codes, :http_client
  attr_reader :base_url, :xls_ar

  def initialize(args={})
    @base_url = args[:base_url] || base_url
    @xls_ar = args[:xls_ar] || xls_ar
    @http_client = HTTPClient.new
    @codes = []
    @xls = xls
  end

  def run
    download_list
    extract_code
  end

  private

  def base_url
    "http://www.jpx.co.jp/markets/statistics-equities/misc/tvdivq0000001vg2-att/"
  end

  def xls_ar
    ['data_j.xls']
  end

  def download_list
    xls_ar.each do |xls|
      xls_url = base_url + xls
      open(xls, 'wb') do |file|
        file.write http_client.get_content("#{xls_url}")
      end
    end
  end

  def xls
    ['data_j.xls']
  end

  def cell_to_reject
    [
      'ETF・ETN',
      'PRO Market',
      'REIT・ベンチャーファンド・カントリーファンド',
      'マザーズ（外国株）',
      '出資証券',
      '市場第一部（外国株）',
      '市場第二部（外国株）',
      'JASDAQ(スタンダード・外国株）'
    ]
  end

  def read_xls
    xls.each do |xls|
      sheet = Roo::Spreadsheet.open(xls, extension: :xlsx)
      code_kubun_ar = sheet.column(2).zip(sheet.column(4))
      code_kubun_ar.each do |elm|
        codes.push(elm[0]) unless reject_ticker_codes(elm[0], elm[1])
      end
    end
  end

  def reject_ticker_codes(elm1, elm2)
    elm1 == 25935.0 && elm1.is_a?(Numeric) && cell_to_reject.include?(elm2)
  end

  def extract_code
    read_xls
    codes.map!(&:to_i)
  end
end


result_ar = TickerCodeListParser.new.run

p TickerArray.ticker_array == result_ar