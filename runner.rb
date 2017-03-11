require 'tty'

def clear_screen
  puts "\e[H\e[2J"
end

@prompt = TTY::Prompt.new
result = ''
table = ''

loop do
  clear_screen

  p result unless result.empty?
  puts table.render(:ascii) unless table.empty?
  answer = @prompt.select("機能を選択してください",
                         %w(全銘柄のクローリング
                            個別銘柄のデータ表示
                            全銘柄のデータをエクスポート
                            個別の財務データをエクスポート
                            EXIT))

  case answer
  when '全銘柄のクローリング'
    p 'now crawling all...'
    sleep 1
    result = "全部クローリングが終わりました"
    clear_screen
  when '個別銘柄のデータ表示'
    ticker = @prompt.ask('銘柄コードを入力してください')
    p "now crawling #{ticker}..."
    sleep 1
    result = "#{ticker}の個別クローリングが終わりました"
    table = TTY::Table.new(['SafetyMargine', 'ROIC', '株価', '目標株価'], [['70%', '10%', '100', '170']])

    clear_screen
  when 'EXIT'
    exit
  end
end

