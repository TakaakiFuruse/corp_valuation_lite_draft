class Finance < ActiveRecord::Base
  belongs_to :company
  after_save :add_companyid_to_finance

  scope :fin_asc, -> {order(year: :asc)}
  scope :fin_desc, -> {order(year: :desc)}

  scope :amt_asc, -> {order(amount: :asc)}
  scope :amt_desc, -> {order(amount: :desc)}

  scope :fix_ast_dpr, -> {where(entry: '固定資産償却費')}
  scope :sp_loss, -> {where(entry: '特別損失_利益')}
  scope :opr_income, -> {where(entry: '営業利益')}
  scope :sale, -> {where(entry: '売上高')}

  scope :r_d_array, -> {where(entry: '研究開発')}
  scope :multi_year_amount_ar, ->(entry){where(entry: entry)}
  scope :current_year_num, ->(entry){multi_year_amount_ar(entry).last.amount}

  scope :s_e, -> {current_year_num('株主持分')}
  scope :r_d, -> {current_year_num('研究開発')}
  scope :int_b_debt, -> {current_year_num('有利子負債')}
  scope :dpr_sum, -> {where(entry: '固定資産償却費').pluck(:amount).first.to_i}

  scope :cash, -> {current_year_num('現金')}

  def add_companyid_to_finance
    Company.find_by(ticker: ticker).finances << self if self.ok_to_add_comp_id?
  end

  def ok_to_add_comp_id?
    Company.find_by(ticker: ticker).present? && self.company_id.nil?
  end
end
