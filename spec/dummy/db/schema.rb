# frozen_string_literal: true

# This file is the source of truth for the dummy app's database schema.
# It is loaded automatically when tables are missing (see
# config/initializers/load_schema.rb), so the test suite, `rails runner`, and
# the console all get a ready database without a manual migrate step.
ActiveRecord::Schema[8.0].define(version: 2026_06_20_000001) do
  create_table :users, force: true do |t|
    t.string  :email, null: false
    t.string  :full_name
    t.timestamps
  end
  add_index :users, :email, unique: true

  create_table :products, force: true do |t|
    t.string  :name, null: false
    t.text    :description
    t.decimal :price, precision: 10, scale: 2, null: false, default: "0.0"
    t.string  :category
    t.boolean :in_stock, null: false, default: true
    t.timestamps
  end

  create_table :orders, force: true do |t|
    t.references :user, null: false, foreign_key: true
    t.string     :status, null: false, default: "pending"
    t.decimal    :total, precision: 10, scale: 2, null: false, default: "0.0"
    t.datetime   :cancelled_at
    t.timestamps
  end

  create_table :order_items, force: true do |t|
    t.references :order, null: false, foreign_key: true
    t.references :product, null: false, foreign_key: true
    t.integer    :quantity, null: false, default: 1
    t.decimal    :unit_price, precision: 10, scale: 2, null: false, default: "0.0"
    t.timestamps
  end
end
