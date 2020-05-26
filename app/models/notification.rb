class Notification < ApplicationRecord
	belongs_to :visitor, class_name: 'User', foreign_key: 'visitor_id', optional: true
	belongs_to :visited, class_name: 'User', foreign_key: 'visited_id', optional: true
	belongs_to :tweet, optional: true
	belongs_to :comment, optional: true
	validates :visitor_id, presence: true
	validates :visited_id, presence: true
	KIND_VALUES = ["comment", "like_tweet", "like_comment"]
	validates :kind, presence: true, inclusion: { in: KIND_VALUES }
	validates :viewed, inclusion: { in: [true, false] }
	default_scope -> { order(created_at: :desc) }
end
