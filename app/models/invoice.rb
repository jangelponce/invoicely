# == Schema Information
#
# Table name: invoices
#
#  id             :bigint           not null, primary key
#  invoice_number :string
#  invoice_date   :datetime
#  total          :decimal
#  active         :boolean
#
class Invoice < ApplicationRecord
end
