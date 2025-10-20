class ProductionIssue < ApplicationRecord
  has_many :productions, dependent: :destroy
end
