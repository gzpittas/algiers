class Production < ApplicationRecord
  belongs_to :production_issue
  has_many :emails, dependent: :destroy
end
