class TweetsController < ApplicationController
  before_action :ensure_correct_user, only: [:edit, :update]
  def index
  	@tweets = Tweet.all
  	@tweet = Tweet.new
  end

  def create
  	tweet = Tweet.new(tweet_params)
  	tweet.user_id = current_user.id
  	if tweet.save
  		flash[:notice] = "ツイートしました。"
  		redirect_to root_path
  	else
  		render 'root_path'
  	end
  end

  def edit
  	@tweet = Tweet.find(params[:id])
  end

  def show
  	@tweet = Tweet.find(params[:id])
  	@comment = Comment.new
  	@comments = @tweet.comments
  end

  def update
  	@tweet = Tweet.find(params[:id])
  	if @tweet.update(tweet_params)
  		flash[:notice] = "ツイートを編集しました。"
  		redirect_to root_path
  	else
  		render 'edit'
  	end
  end

  def destroy
  	tweet = Tweet.find(params[:id])
  	tweet.destroy
  	redirect_to root_path
  end

  private
  def tweet_params
  	params.require(:tweet).permit(:content, :user_id)
  end

  def ensure_correct_user
  	@tweet = Tweet.find(params[:id])
  	if @tweet.user != current_user
  		redirect_to root_path
  	end
  end
end
