# frozen_string_literal: true

class User < ApplicationRecord
  has_many :orders, dependent: :destroy

  validates :email, presence: true, uniqueness: true
end
