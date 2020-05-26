module NotificationsHelper
	def notification_form(notification)
		#どのユーザーからの通知なのかを取得
		visitor = notification.visitor
		case notification.kind
		when 'like_tweet' then
			tweet = Tweet.find_by(id: notification.tweet_id)
			tag.a(visitor.name) + 'があなたの' + tag.a('ツイート', href: tweet_path(notification.tweet_id)) + 'をいいねしました。'
		when 'like_comment' then
			comment = Comment.find_by(id: notification.comment_id)
			tag.a(visitor.name) + 'があなたの' + tag.a('コメント', href: tweet_path(comment.tweet.id)) + 'をいいねしました。'
		when 'comment' then
			# kindがcommentだった時、コメントを取得する。
			@comment = Comment.find_by(id: notification.comment_id)
			tag.a(visitor.name) + 'があなたの' + tag.a('ツイート', href: tweet_path(notification.tweet_id)) + 'にコメントしました。'
		end
	end
	def new_notifications
    	@notifications = current_user.passive_notifications.where(viewed: false)
	end
end
