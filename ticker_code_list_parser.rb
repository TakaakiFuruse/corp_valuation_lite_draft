require 'httpclient'
require 'pry'
require 'spreadsheet'
require './ticker_code'

class TickerCodeListParser
  attr_accessor :codes, :http_client

  BASE_URL = "http://www.jpx.co.jp/markets/statistics-equities/misc/tvdivq0000001vg2-att/"
  FILE_NAME_AR = ['data_j.xls']
  STOCK_NAME_TO_REJECT =  [
    'ETF・ETN',
    'PRO Market',
    'REIT・ベンチャーファンド・カントリーファンド',
    'マザーズ（外国株）',
    '出資証券',
    '市場第一部（外国株）',
    '市場第二部（外国株）',
    'JASDAQ(スタンダード・外国株）'
  ]


  def initialize(args={})
    @base_url = args[:base_url] || BASE_URL
    @file_name_array = args[:file_name_array] || FILE_NAME_AR
    @http_client = HTTPClient.new
    @codes = []
  end

  def download_and_extract_codes
    download_list
    return_ticker_codes
  end

  def download_list
    file_name_array.each do |xls|
      xls_url = base_url + xls
      open(xls, 'wb') do |file|
        file.write http_client.get_content("#{xls_url}")
      end
    end
  end

  def return_ticker_codes
    read_xls
    codes.map!(&:to_i)
  end

  def read_xls
    FILE_NAME_AR.each do |xls|
      sheet = Spreadsheet.open(xls).worksheets.first
      row_count = sheet.row_count
      (1..row_count).to_a.each do |num|
        unless reject_ticker_codes?(sheet.row(num)[1], sheet.row(num)[3])
          codes.push(sheet.row(num)[1])
        end
      end
    end
  end

  private

  def reject_ticker_codes?(ticker_code, stock_name)
    ticker_code == 25935.0 || \
      !ticker_code.is_a?(Numeric) || \
      STOCK_NAME_TO_REJECT.include?(stock_name)
  end
end

result_ar = TickerCodeListParser.new.return_ticker_codes
p ticker_code.delete_if{|elm| result_ar.include?(elm)} == []
