class Like < ApplicationRecord
	belongs_to :user
	belongs_to :tweet, optional: true
	belongs_to :comment, optional: true

	def save_notification_like!(current_user, tweet)
		notification = current_user.active_notifications.new(
			tweet_id: tweet.id,
			visited_id: tweet.user_id,
			kind: 'like_tweet'
		)
		if notification.visitor_id != notification.visited_id and notification.valid?
			notification.save
		end
	end
end
