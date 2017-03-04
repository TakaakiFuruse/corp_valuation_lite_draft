require 'open-uri'
require 'nokogiri'

class Yahoo
  # p Yahoo.new(ticker: 1332).get
  # => {:時価総額=>115874, :発行済株式数=>277210277, :PER=>11.0,
  #    :PBR=>1.32, :前日終値=>423, :始値=>419, :現在値=>418,
  #    :会社名=>"日本水産", :ticker=>1332}

  attr_reader :yahoo, :rakuten_quote
  attr_accessor :ticker

  def initialize(args = {})
    @ticker = args[:ticker]
    @yahoo = args[:yahoo] || default_url
  end

  def default_url
    Nokogiri::HTML(open("http://stocks.finance.yahoo.co.jp/stocks/detail/?code=#{ticker}.T"))
  end

  def ticker_matched?
    ticker == parsed_ticker
  end

  def get
    d_hash = data_hash
    replace_zero_cur_price(d_hash)
    if ticker_matched?
      d_hash
    else
      Rails.logger.warn "Ticker code didn't match. Check Yahoo page of #{ticker}."
    end
  end

  private

  def parsed_ticker
    yahoo.at("#stockinf > div.stocksDtl.clearFix
                                  > div.forAddPortfolio > dl > dt").text.to_i
  end

  def data_hash
    { market_cap: yahoo.css("#rfindex > div.chartFinance >
                       div:nth-child(1) > dl > dd >
                       strong").text.delete(',').to_i,

      outstanding: yahoo.css("#rfindex > div.chartFinance
                            > div:nth-child(2) > dl > dd > strong"
                             ).text.delete(',').to_i,

      p_e: yahoo.css("#rfindex > div.chartFinance > div:nth-child(5)
                    > dl > dd > strong"
                     ).text.gsub(/\((連)\) /, '').to_f,

      p_b: yahoo.css("#rfindex > div.chartFinance > div:nth-child(6)
                           > dl > dd > strong"
                     ).text.gsub(/\((連)\) /, '').to_f,

      close_price: yahoo.css("#detail > div.innerDate > div:nth-child(1)
                                     > dl > dd > strong"
                             ).text.delete(',').to_i,

      open_price: yahoo.css("#detail > div.innerDate > div:nth-child(2)
                                 > dl > dd > strong"
                            ).text.delete(',').to_i,

      current_price: yahoo.xpath("//td[@class='stoksPrice']"
                                 ).text.delete(',').to_i,

      name: yahoo.at("//th[@class='symbol']/h1").text.gsub(/\((株)\)/, ''),
      ticker: ticker
      }
  end

  def replace_zero_cur_price(hash)
    if hash[:current_price] == 0
      hash[:current_price] = hash[:close_price]
    end
  end
end

p Yahoo.new(ticker: 1332).get