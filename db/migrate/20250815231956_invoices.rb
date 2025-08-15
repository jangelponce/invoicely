class Invoices < ActiveRecord::Migration[8.0]
  def change
    create_table :invoices do |t|
      t.string :invoice_number
      t.datetime :invoice_date
      t.decimal :total
      t.boolean :active
    end
  end
end
