class LikesController < ApplicationController
	def like_tweets
		tweet = Tweet.find(params[:tweet_id])
		like = current_user.likes.new(tweet_id: tweet.id)
		if like.save
			tweet.save_notification_like_tweet!(current_user, tweet)
			redirect_back(fallback_location: root_url)
		end
	end

	def not_like_tweets
		tweet = Tweet.find(params[:tweet_id])
		like = current_user.likes.find_by(tweet_id: tweet.id)
		like.destroy
		redirect_back(fallback_location: root_url)
	end

	def like_comments
		comment = Comment.find(params[:comment_id])
		like = current_user.likes.new(comment_id: comment.id)
		if like.save
			comment.save_notification_like_comment!(current_user, comment)
			redirect_back(fallback_location: root_url)
		end
	end

	def not_like_comments
		comment = Comment.find(params[:comment_id])
		like = current_user.likes.find_by(comment_id: comment.id)
		like.destroy
		redirect_back(fallback_location: root_url)
	end
end
