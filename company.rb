include CompaniesHelper
class Company < ActiveRecord::Base
  has_many :finances, class_name: 'Finance', foreign_key: 'company_id', dependent: :destroy
  has_many :company_tags
  has_many :tags, through: :company_tags

  def dpr_tangible_ar(_args = {})
    finances.fix_ast_dpr.pluck(:amount)
  end

  def dpr_intangible_ar(_args = {})
    finances.dpr_intang.pluck(:amount)
  end

  def beta(args = {})
    args[:beta] ||= 0.75
    BigDecimal("#{args[:beta]}")
  end

  def dpr_arr
    finances.fix_ast_dpr.pluck(:amount)
  end

  def epv_of_the_business_n0
    (
      normal_ebit_aft_tax_n0 /
      (
        wacc / BigDecimal('100')
      )
    )
  end

  def epv_of_the_business_n1
    (
      normal_ebit_aft_tax_n1 /
      (
        wacc / BigDecimal('100')
      )
    )
  end

  def equity_cost(arg = {})
    arg[:beta] ||= beta
    arg[:mrp] ||= mrp

    BigDecimal('1') +
      BigDecimal("#{arg[:beta]}") *
    BigDecimal("#{arg[:mrp]}")
  end

  def ebit_avg
    ebit.inject { |m, n| m + n } / BigDecimal("#{ebit.count}")
  end

  def ebit
    ebit_ar.reverse
  end

  def ebit_ar
    opr_inc.pluck(:amount)
  end

  def excess_cash(args = {})
    args[:excess_cash] ||= 0.03
    finances.cash - (sales_ar[-1] * BigDecimal("#{args[:excess_cash]}"))
  end

  def interest(args = {})
    args[:interest] ||= 0.02
    BigDecimal("#{args[:interest]}")
  end


  def int_b_debt_div_total_less_ex_cash
    (self.finances.int_b_debt /
     (
       market_cap_less_excess_cash +
       self.finances.int_b_debt
     )
     )
  end

  def int_b_debt_div_total_with_ex_cash
    self.finances.int_b_debt /
    (market_cap + self.finances.int_b_debt)
  end

  def int_b_debt_div_total_book
    self.finances.int_b_debt /
    (self.finances.s_e + self.finances.int_b_debt)
  end


  def market_cap_less_excess_cash
    market_cap - excess_cash
  end

  def mkt_div_total
    market_cap /
    (market_cap + self.finances.int_b_debt)
  end

  def book_div_total
    self.finances.s_e /
    (self.finances.s_e + self.finances.int_b_debt)
  end


  def market_cap_less_excess_cash_div_total
    (
      market_cap_less_excess_cash /
      (
        market_cap_less_excess_cash +
        self.finances.int_b_debt
      )
    )
  end

  def multi_yr_amount_array(args = {})
    self.finances.multi_year_amount_ar(args[:entry])
  end

  def mrp(args = {})
    args[:mrp] ||= 0.07
    (BigDecimal("#{args[:mrp]}") * BigDecimal('100'))
  end

  def market_cap
    (
      (
        BigDecimal("#{outstanding}") *
        BigDecimal("#{current_price}")
      ) / BigDecimal("#{1_000_000}")
    )
  end

  def market_cap_div_epv_mkt_value_n0
    (market_cap / epv_of_the_business_n0)
  end

  def market_cap_div_epv_mkt_value_n1
    (market_cap / epv_of_the_business_n1)
  end

  def normal_ebit
    (
      sales.last.amount * ( ebit_avg / sales_avg )
    )
  end

  def normal_ebit_aft_tax_n0
    normal_ebit *
    (BigDecimal('1') - tax)
  end

  def normal_ebit_aft_tax_n1(arg = {})
    dpr ||= dpr_arr[-1]
    r_d ||= r_d_ar.pluck(:amount)[0]

    normal_ebit_aft_tax_n0 +
    (
      dpr *
      BigDecimal('0.25') +
      r_d *
      BigDecimal('0.25')
    )
  end

  def roic_mkt_value
    (
      normal_ebit_aft_tax_n0 /
      (
        market_cap_less_excess_cash +
        finances.int_b_debt
      )
    )
  end

  def roic_div_wacc_mkt_value
    (
      roic_mkt_value /
      (wacc / BigDecimal('100'))
    )
  end

  def sm_x_roic_div_wacc
    safety_margin_mkt_value_n1 *
    roic_div_wacc_mkt_value
  end

  def r_d_ar(args = {})
    self.finances.r_d_array
  end


  def safety_margin_mkt_value_n0
    BigDecimal('1') - market_cap_div_epv_mkt_value_n0
  end

  def safety_margin_mkt_value_n1
    BigDecimal('1') - market_cap_div_epv_mkt_value_n1
  end


  def sales
    self.finances.sale.fin_asc
  end

  def sales_ar
    # finances.sale.fin_asc.map(&:amount)
    sales.pluck(:amount)
  end

  def sales_avg
    ((sales_ar.inject(0) { |m, n| m + n }) / sales.count)
  end

  def tax(args = {})
    args[:tax] ||= 0.4
    BigDecimal("#{args[:tax]}")
  end

  def wacc
    (
      (equity_cost *
       market_cap_less_excess_cash_div_total
       ) +
      (interest *
       (BigDecimal('1') - tax) *
       BigDecimal('100') *
       int_b_debt_div_total_less_ex_cash)
    )
  end

  def wacc_with_excess_cash
    (
      (
        equity_cost *
        mkt_div_total
      ) +
      (interest *
       (BigDecimal('1') - tax) *
       BigDecimal('100') *
       int_b_debt_div_total_with_ex_cash)
    )
  end

  def wacc_book
    (
      (
        equity_cost *
        book_div_total
      ) +
      (interest *
       (BigDecimal('1') - tax) *
       BigDecimal('100') *
       int_b_debt_div_total_book)
    )
  end

  def epv_of_the_business_n0_with_ex_cash
    (normal_ebit_aft_tax_n0 /
     (wacc_with_excess_cash / BigDecimal('100')))
  end

  def epv_of_the_business_n0_book
    (normal_ebit_aft_tax_n0 /
     (wacc_book / BigDecimal('100')))
  end

  def epv_of_the_business_n1_with_ex_cash
    (normal_ebit_aft_tax_n1 /
     (wacc_with_excess_cash / BigDecimal('100')))
  end

  def epv_of_the_business_n1_book
    (normal_ebit_aft_tax_n1 /
     (wacc_book / BigDecimal('100')))
  end

  def company_epv_n0_with_ex_cash
    epv_of_the_business_n0_with_ex_cash +
      (finances.cash - finances.int_b_debt)
  end

  def company_epv_n0_book
    epv_of_the_business_n0_book +
      (finances.cash - finances.int_b_debt)
  end

  def company_epv_n1_with_ex_cash
    epv_of_the_business_n1_with_ex_cash +
      (finances.cash - finances.int_b_debt)
  end

  def company_epv_n1_book
    epv_of_the_business_n1_book +
      (finances.cash - finances.int_b_debt)
  end

  def market_cap_div_epv_n0_with_ex_cash
    (market_cap / company_epv_n0_with_ex_cash)
  end

  def s_e_div_epv_n0_book
    (self.finances.s_e / company_epv_n0_with_ex_cash)
  end

  def market_cap_div_epv_n1_with_ex_cash
    (market_cap / company_epv_n1_with_ex_cash)
  end

  def market_cap_div_epv_n1_book
    (self.finances.s_e / company_epv_n1_with_ex_cash)
  end

  def safety_margin_n0_with_ex_cash
    BigDecimal('1') - market_cap_div_epv_n0_with_ex_cash
  end

  def safety_margin_n0_book
    BigDecimal('1') - s_e_div_epv_n0_book
  end

  def safety_margin_n1_with_ex_cash
    BigDecimal('1') - market_cap_div_epv_n1_with_ex_cash
  end

  def safety_margin_n1_book
    BigDecimal('1') - market_cap_div_epv_n1_book
  end

  def roic_with_ex_cash
    (normal_ebit_aft_tax_n0 / (market_cap + finances.int_b_debt))
  end

  def roic_book
    (
      normal_ebit_aft_tax_n0 /
      (self.finances.s_e + self.finances.int_b_debt)
    )
  end

  def roic_div_wacc_ex_cash
    (
      roic_with_ex_cash /
      (
        wacc_with_excess_cash / BigDecimal('100')
      )
    )
  end

  def roic_div_wacc_book
    (
      roic_book /
      (
        wacc_book / BigDecimal('100')
      )
    )
  end

  def sm_x_roic_div_wacc_ex_cash
    safety_margin_n1_with_ex_cash * roic_div_wacc_ex_cash
  end

  def sm_x_roic_div_wacc_book
    safety_margin_n1_book * roic_div_wacc_book
  end

  def hash_for_after_save_method
    {
      roic_bfr: non_num_to_zero(roic_mkt_value.round(6)),
      wacc_bfr: non_num_to_zero(wacc.round(6)),
      smar_bfr: non_num_to_zero(safety_margin_mkt_value_n1.round(6)),
      roic_wacc_bfr: non_num_to_zero((roic_div_wacc_mkt_value/100).round(6)),
      roic_aft: non_num_to_zero(roic_with_ex_cash.round(6)),
      wacc_aft: non_num_to_zero(wacc_with_excess_cash.round(6)),
      smar_aft: non_num_to_zero(safety_margin_n1_with_ex_cash.round(6)),
      roic_wacc_aft: non_num_to_zero((roic_div_wacc_ex_cash/100).round(6))
    }
  end

  def save_roic_and_epv
    self.update(hash_for_after_save_method)
  rescue
    nil
  end

  private

  def fxd_ast_dpr_exp(_args = {})
    finances.fix_ast_dpr.fin_desc
  end

  def opr_inc(_args = {})
    finances.opr_income.fin_desc
  end

end
