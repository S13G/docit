# frozen_string_literal: true

# Sample data so the dummy app returns realistic output and the System Map has
# real models, associations, and records to show. Idempotent: safe to re-run.
ActiveRecord::Base.transaction do
  OrderItem.delete_all
  Order.delete_all
  Product.delete_all
  User.delete_all

  alice = User.create!(email: "alice@example.com", full_name: "Alice Carter")
  bob   = User.create!(email: "bob@example.com", full_name: "Bob Nguyen")

  widget = Product.create!(name: "Widget", description: "A useful widget", price: 29.99,
                           category: "tools", in_stock: true)
  gadget = Product.create!(name: "Gadget", description: "A shiny gadget", price: 49.99,
                           category: "electronics", in_stock: false)
  cable  = Product.create!(name: "Cable", description: "USB-C cable", price: 9.99,
                           category: "electronics", in_stock: true)

  shipped = alice.orders.create!(status: "shipped", total: 79.97)
  shipped.order_items.create!(product: widget, quantity: 2, unit_price: widget.price)
  shipped.order_items.create!(product: cable, quantity: 2, unit_price: cable.price)

  pending = bob.orders.create!(status: "pending", total: 49.99)
  pending.order_items.create!(product: gadget, quantity: 1, unit_price: gadget.price)

  puts "Seeded #{User.count} users, #{Product.count} products, " \
       "#{Order.count} orders, #{OrderItem.count} order items."
end
