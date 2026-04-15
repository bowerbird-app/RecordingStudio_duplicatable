class Workspace < ApplicationRecord
  has_many :pages, dependent: :destroy
  has_many :reports, dependent: :destroy
  has_many :folders, dependent: :destroy
end
