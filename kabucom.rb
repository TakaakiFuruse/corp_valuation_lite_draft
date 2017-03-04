require 'dotenv'
require "capybara"
require "capybara/dsl"
require 'capybara/poltergeist'

# poltergeist
Capybara.default_max_wait_time = 5
Capybara.ignore_hidden_elements = false
Capybara.current_driver = :poltergeist
Capybara.javascript_driver = :poltergeist
Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(
    app,
    {
      timeout: 120,
      js_errors: false,
      phantomjs_options: ['--load-images=no',
                          '--ignore-ssl-errors=yes',
                          '--local-to-remote-url-access=yes',
                          ]
    }
  )
end


class KabucomParser
  # KabucomParser.new(2501).run => parse ticker code 2501 info from kabu.com

  include Capybara::DSL
  attr_reader :kabu_com, :ticker, :key
  attr_accessor :result_ar, :shikiho

  def initialize(args={})
    @kabu_com = args[:url] || 'https://s10.kabu.co.jp/_mem_bin/members/login.asp?/members/'
    @ticker = args[:ticker]
    @key = ["year", "amount", "entry", "ticker"]
    @result_ar = []
    @shikiho = {}
  end

  def run
    log_in
    search_stock
    p "start #{ticker}"
    find_finance{
      find_years
      find_sales
      find_oprincome
      find_netincome
      find_eps
      find_dividents
      find_s_e
      find_long_term_debt
      find_short_term_debt
      find_dpr
      find_r_d
    }
    visit(shikiho_url)
    shikiho = find_shikiho
    result_ar.flatten
    p result_ar
    p shikiho
    p "end #{ticker}"
  end

  def find_finance
    within_frame('mainbody'){
      within_frame('pagecontent'){
        find(:xpath, "//*[@id=\"but1\.1\"]").trigger("click")
        find(:xpath, "//*[@id=\"but2\.1\"]").trigger("click")
        yield
      }
    }
  end

  def search_stock
    fill_in "SearchWord", :with => "#{ticker}"
    find(:xpath, "/html/body/table[1]/tbody/tr[2]/td[2]/table/tbody/tr[2]/td[1]/form/table/tbody/tr/td/table/tbody/tr/td[3]/input").trigger("click")
  end

  def log_in
    visit(kabu_com)
    fill_in "SsLogonUser", with: "*****"
    fill_in "SsLogonPassword", with: "****"
    find("#image1").trigger("click")
  end


  def shikiho_url
    "http://s20.si0.kabu.co.jp/Members/TradeTool/reutersparts/SD_CompanyBrochure.asp?StockCode=#{ticker}&Market=1"
  end

  def get_finance(args={})
    entry = [find("#{args[:entry_css]}").text.gsub(/\s/,"")]

    unless entry == [args[:entry_name]]
      Rails.logger.warn "#{self.ticker}: #{args[:entry_name]} is #{entry}"
    end

    entry_ar = entry * @years.length
    ticker_ar = [ticker] * @years.length

    amount = (2..6).to_a.map{|n|
      find("#{args[:entry_row]}" + "> td:nth-child(#{n})").text.gsub(/,/,"").to_f
    }.delete_if{|n| n == '--'}

    result = (0..@years.length - 1).to_a.map{ |n|
      key.zip([@years[n], amount[n], entry_ar[n], ticker_ar[n]]).to_h
    }

    result_ar << result

  end

  def find_years
    @years = [
      find("#cbut2 > table:nth-child(2) > tbody > tr:nth-child(3) > td:nth-child(2)").text.to_i,
      find("#cbut2 > table:nth-child(2) > tbody > tr:nth-child(3) > td:nth-child(3)").text.to_i,
      find("#cbut2 > table:nth-child(2) > tbody > tr:nth-child(3) > td:nth-child(4)").text.to_i,
      find("#cbut2 > table:nth-child(2) > tbody > tr:nth-child(3) > td:nth-child(5)").text.to_i,
      find("#cbut2 > table:nth-child(2) > tbody > tr:nth-child(3) > td:nth-child(6)").text.to_i
    ].delete_if{|n| n == '--'}
  end

  def find_sales
    get_finance(
      entry_name: "売上高",
      entry_css: "#cbut2 > table:nth-child(2) > tbody > tr:nth-child(5) > td.qcell1.bdrleft1",
      entry_row: "#cbut2 > table:nth-child(2) > tbody > tr:nth-child(5)"
    )
  end


  def find_oprincome
    get_finance(
      entry_name: "営業利益",
      entry_css: "#cbut2 > table:nth-child(2) > tbody > tr:nth-child(6) > td.qcell1.bdrleft1",
      entry_row: "#cbut2 > table:nth-child(2) > tbody > tr:nth-child(6)"
    )
  end

  def find_netincome
    get_finance(
      entry_name: "当期利益",
      entry_css: "#cbut2 > table:nth-child(2) > tbody > tr:nth-child(8) > td.qcell1.bdrleft1",
      entry_row: "#cbut2 > table:nth-child(2) > tbody > tr:nth-child(8)"
    )
  end

  def find_eps
    get_finance(
      entry_name: "EPS（円）",
      entry_css: "#cbut2 > table:nth-child(2) > tbody > tr:nth-child(9) > td.qcell1.bdrleft1",
      entry_row: "#cbut2 > table:nth-child(2) > tbody > tr:nth-child(9)"
    )
  end

  def find_dividents
    get_finance(
      entry_name: "配当（円）",
      entry_css: "#cbut2 > table:nth-child(2) > tbody > tr:nth-child(10) > td.qcell1.bdrleft1",
      entry_row: "#cbut2 > table:nth-child(2) > tbody > tr:nth-child(10)"
    )
  end

  def find_s_e
    get_finance(
      entry_name: "株主資本",
      entry_css: "#cbut2 > table:nth-child(4) > tbody > tr:nth-child(7) > td.qcell1.bdrleft1",
      entry_row: "#cbut2 > table:nth-child(4) > tbody > tr:nth-child(7)"
    )
  end

  def find_long_term_debt
    get_finance(
      entry_name: "長期有利子負債",
      entry_css: "#cbut2 > table:nth-child(4) > tbody > tr:nth-child(11) > td.qcell1.bdrleft1",
      entry_row: "#cbut2 > table:nth-child(4) > tbody > tr:nth-child(11)"
    )
  end

  def find_short_term_debt
    get_finance(
      entry_name: "短期有利子負債",
      entry_css: "#cbut2 > table:nth-child(4) > tbody > tr:nth-child(12) > td.qcell1.bdrleft1",
      entry_row: "#cbut2 > table:nth-child(4) > tbody > tr:nth-child(12)"
    )
  end

  def find_dpr
    get_finance(
      entry_name: "減価償却費",
      entry_css: "#cbut2 > table:nth-child(4) > tbody > tr:nth-child(14) > td.qcell1.bdrleft1",
      entry_row: "#cbut2 > table:nth-child(4) > tbody > tr:nth-child(14)"
    )
  end

  def find_r_d
    get_finance(
      entry_name: "研究開発費",
      entry_css: "#cbut2 > table:nth-child(4) > tbody > tr:nth-child(15) > td.qcell1.bdrleft1",
      entry_row: "#cbut2 > table:nth-child(4) > tbody > tr:nth-child(15)"
    )
  end

  def find_shikiho
    shikiho = find("body > table:nth-child(1) > tbody > tr > td > table > tbody > tr:nth-child(3) > td").text +
      find("body > table:nth-child(1) > tbody > tr > td > table > tbody > tr:nth-child(4) > td").text +
      find("body > table:nth-child(1) > tbody > tr > td > table > tbody > tr:nth-child(5) > td").text +
      find("body > table:nth-child(1) > tbody > tr > td > table > tbody > tr:nth-child(6) > td").text
    return {shikiho_info: shikiho, ticker: ticker}
  end

end


KabucomParser.new(ticker: 2501).run