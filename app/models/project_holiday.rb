class ProjectHoliday < ActiveRecord::Base
  include Redmine::SafeAttributes
  unloadable

  belongs_to :project, inverse_of: :holidays

  validates_presence_of :project_id, :date

  safe_attributes "project_id", "date"

  default_scope -> { order("project_holidays.date ASC") }
end
