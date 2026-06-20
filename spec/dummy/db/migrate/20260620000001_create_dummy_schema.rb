# frozen_string_literal: true

# Single migration that creates the dummy app's schema. Kept in one file
# because the dummy app exists only to exercise Docit, not to model migration
# history. db/schema.rb is the source of truth that actually gets loaded.
class CreateDummySchema < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :full_name
      t.timestamps
    end
    add_index :users, :email, unique: true

    create_table :products do |t|
      t.string  :name, null: false
      t.text    :description
      t.decimal :price, precision: 10, scale: 2, null: false, default: "0.0"
      t.string  :category
      t.boolean :in_stock, null: false, default: true
      t.timestamps
    end

    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.string     :status, null: false, default: "pending"
      t.decimal    :total, precision: 10, scale: 2, null: false, default: "0.0"
      t.datetime   :cancelled_at
      t.timestamps
    end

    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer    :quantity, null: false, default: 1
      t.decimal    :unit_price, precision: 10, scale: 2, null: false, default: "0.0"
      t.timestamps
    end
  end
end
