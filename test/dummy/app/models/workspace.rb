class Workspace < ApplicationRecord
  has_many :pages, dependent: :destroy
end
