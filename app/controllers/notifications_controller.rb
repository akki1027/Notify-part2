class NotificationsController < ApplicationController
	def index
		#current_userの投稿に紐づいた通知を全て取得
        @notifications = current_user.passive_notifications
      	#通知のviewカラムがfalse、つまりまだ既読していない通知を既読(true)にする
        @notifications.where(viewed: false).each do |notification|
            notification.update_attributes(viewed: true)
        end
    end
end
