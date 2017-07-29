class Run < ApplicationRecord
  belongs_to :day
  belongs_to :user

  def start_time
      self.day.day
  end
end
