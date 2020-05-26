class Comment < ApplicationRecord
	belongs_to :user
	belongs_to :tweet
	has_many :notifications, dependent: :destroy
	has_many :likes, dependent: :destroy
	validates :content, presence: true, length: { maximum: 200 }

	def liked_by?(user)
		likes.where(user_id: user.id).exists?
	end

	def save_notification_like_comment!(current_user, comment)
		notification = current_user.active_notifications.new(
			comment_id: comment.id,
			visited_id: comment.user_id,
			kind: 'like_comment'
		)
		if notification.visitor_id != notification.visited_id and notification.valid?
			notification.save
		end
	end
end
