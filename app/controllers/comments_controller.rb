class CommentsController < ApplicationController
	before_action :ensure_correct_user, only: :destroy
	def create
		tweet = Tweet.find(params[:tweet_id])
		comment = current_user.comments.new(comment_params)
		comment.tweet_id = params[:tweet_id]
		if comment.save
			tweet.save_notification_comment!(current_user, comment.id, tweet.user_id)
			redirect_to tweet_path(tweet)
		else
			redirect_to tweet_path(tweet)
		end
	end

	def destroy
		tweet = Tweet.find(params[:tweet_id])
		comment = Comment.find(params[:id])
		comment.destroy
		redirect_to tweet_path(tweet)
	end

	private
	def comment_params
		params.require(:comment).permit(:content, :user_id, :tweet_id)
	end

	def ensure_correct_user
		tweet = Tweet.find(params[:tweet_id])
		comment = current_user.comments.find_by(tweet_id: tweet.id)
		if comment.user != current_user
			redirect_to tweet_path(tweet)
		end
	end
end
