class Day < ApplicationRecord
  has_many :runs
  has_many :users, :through => :runs

  def start_time
      self.day
  end
end
