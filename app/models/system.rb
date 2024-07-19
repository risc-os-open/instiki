class System < ApplicationRecord
  self.table_name = 'system'
  validates_presence_of :password
end
