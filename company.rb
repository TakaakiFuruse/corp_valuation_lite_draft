include CompaniesHelper
class Company < ActiveRecord::Base
  has_many :finances, class_name: 'Finance', foreign_key: 'company_id', dependent: :destroy

end
