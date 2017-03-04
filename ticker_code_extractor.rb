require 'roo'
require 'roo-xls'

class TickerCodeExtractor
  # p TickerCodeExtractor.new.codes[0..10]
  # => [1301, 1332, 1333, 1352, 1377, 1379, 1414, 1417, 1419, 1420, 1514]
  attr_accessor :codes

  def initialize
    @codes = []
    @xls = xls
    extract_code
  end


  def xls
    ['data_j.xls']
  end

  def reject_cell
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
      sheet = Roo::Spreadsheet.open(xls)
      code_kubun_ar = sheet.column(2).zip(sheet.column(4))
      code_kubun_ar.each do |elm|
        codes.push(elm[0]) if reject_ticker_codes(elm[0], elm[1])
      end
    end
  end

  def reject_ticker_codes(elm1, elm2)
    elm1 != 25935.0 && elm1.is_a?(Numeric) && !reject_cell.include?(elm2)
  end

  def extract_code
    read_xls
    codes.map!(&:to_i)
  end
end
