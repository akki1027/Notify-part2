Rails.application.routes.draw do
	root 'tweets#index'
	devise_for :users
	resources :tweets, except: :index do
		resources :comments, only: [:create, :destroy]
	end
	post 'create/:tweet_id/likes_tweets' => 'likes#like_tweets', as: 'create_likes_tweet'
	delete 'destroy/:tweet_id/likes_tweets' => 'likes#not_like_tweets', as: 'destroy_likes_tweet'
	post 'create/:comment_id/likes_comments' => 'likes#like_comments', as: 'create_likes_comment'
	delete 'destroy/:comment_id/likes_comments' => 'likes#not_like_comments', as: 'destroy_likes_comment'
	resources :notifications, only: :index
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
