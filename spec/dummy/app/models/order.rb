# frozen_string_literal: true

class Order < ApplicationRecord
  STATUSES = %w[pending shipped cancelled].freeze

  belongs_to :user
  has_many :order_items, dependent: :destroy
  has_many :products, through: :order_items

  validates :status, inclusion: { in: STATUSES }
  validates :total, numericality: { greater_than_or_equal_to: 0 }

  def cancel!
    update!(status: "cancelled", cancelled_at: Time.current)
  end
end
