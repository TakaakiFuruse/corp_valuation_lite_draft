class Finance < ActiveRecord::Base
  belongs_to :company
  after_save :add_companyid_to_finance

  def add_companyid_to_finance
    Company.find_by(ticker: ticker).finances << self if self.ok_to_add_comp_id?
  end

  def ok_to_add_comp_id?
    Company.find_by(ticker: ticker).present? && self.company_id.nil?
  end
end
