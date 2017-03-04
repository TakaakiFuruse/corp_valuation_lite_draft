require 'open-uri'
require 'spreadsheet'
require './ticker_code'
require 'dotenv'
class TickerCodeListParser
  # TickerCodeListParser.new.download_and_extract_codes
  #  -> [.....]

  attr_accessor :codes
  attr_reader :file_name_array, :base_url

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
  COLUMN_NAME = %(
    日付 コード 銘柄名 市場・商品区分
    33業種コード 33業種区分  17業種コード
    17業種区分  規模コード 規模区分
  )

  def initialize(args={})
    @base_url = args[:base_url] || BASE_URL
    @file_name_array = args[:file_name_array] || FILE_NAME_AR
    @codes = []
  end

  def download_and_extract_codes
    download_list
    return_ticker_codes
  end

  def download_list
    file_name_array.each do |xls|
      begin
        File.write(xls, open(base_url + xls).read)
      rescue OpenURI::HTTPError => error
        raise "ERROR - Failed to download ticker list from TSE : #{error}"
      end
    end
  end

  def return_ticker_codes
    read_xls
    codes.map!(&:to_i)
  end

  def read_xls
    file_name_array.each do |xls|
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

  def column_validator(column_from_xls)
    if column_from_xls != COLUMN_NAME
      raise "ERROR - Check column values. Columns have different order than expected."
    end
  end

  def reject_ticker_codes?(ticker_code, stock_name)
    ticker_code == 25935.0 || \
      !ticker_code.is_a?(Numeric) || \
      STOCK_NAME_TO_REJECT.include?(stock_name)
  end
end

# process = TickerCodeListParser.new.download_and_extract_codes
# p ticker_code.delete_if{|elm| process.include?(elm)} == []
