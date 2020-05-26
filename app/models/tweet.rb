class Tweet < ApplicationRecord
	belongs_to :user
	has_many :comments, dependent: :destroy
	has_many :notifications, dependent: :destroy
	has_many :likes, dependent: :destroy
	validates :content, presence: true, length: { maximum: 200 }

	def save_notification_comment!(current_user, comment_id, user_id)
        # コメントは複数回することが考えられるため、１つの投稿に複数回通知する
        notification = current_user.active_notifications.new(
			tweet_id: id,
			comment_id: comment_id,
			visited_id: user_id,
			kind: 'comment'
        )
        # 自分で自分のツイートにコメントした時は、通知を送らない。自分自身に通知を送るのは、個人的に変な気がする
        if notification.visitor_id != notification.visited_id and notification.valid?
        	notification.save
        end
    end

    def liked_by?(user)
		likes.where(user_id: user.id).exists?
	end

	def save_notification_like_tweet!(current_user, tweet)
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
