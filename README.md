# Notify-part2(ツイートとコメントがいいねされた時に通知を送れる/受け取れるようにしよう)


# 初めに
Notifyが既に完了していることを前提に進めていきます。  
Notifyでは、ツイートにコメントをした時に通知を送れる/された側は受け取れるようにしました。  
Notify-part2に取り組む前に、Notifyを先にやることをお勧めします。


# Likeモデルの作成
ツイートとコメントのどちらにもいいねができるように、tweet_idとcomment_idを用意します。
```bash
$ rails g model Like user_id:integer tweet_id:integer comment_id:integer
$ rails db:migrate
```


# Likesコントローラーの作成
```bash
$ rails g controller likes
```
ついでにroutesも設定してください。  
config/routes.rb
```bash
post 'create/:tweet_id/likes_tweets' => 'likes#like_tweets', as: 'create_likes_tweet'
delete 'destroy/:tweet_id/likes_tweets' => 'likes#not_like_tweets', as: 'destroy_likes_tweet'
post 'create/:comment_id/likes_comments' => 'likes#like_comments', as: 'create_likes_comment'
delete 'destroy/:comment_id/likes_comments' => 'likes#not_like_comments', as: 'destroy_likes_comment'
```


# Likeモデルの設定
app/models/like.rb
```bash
belongs_to :user
belongs_to :tweet, optional: true
belongs_to :comment, optional: true
```
ツイートとコメントにはoptional: trueをつけることが肝です。  
理由は、ツイートかコメントのどちらかにいいねをした時、必ずどちらか一方が空になるからです。


# Notificationモデルの編集
ツイートとコメントにもいいねをできるようにしたため、KIND_VALUESに新たな値を追加する必要があります。  
ツイートにいいねをした時はlike_tweet、  
コメントにいいねをした時はlike_comment、  
がkindカラムに保存されるようにします。  
app/models/notification.rb
```bash
KIND_VALUES = ["comment", "like_tweet", "like_comment"]
```


# Tweetモデルに追記
Likeモデルとアソシエート、また、後に使うメソッドを２つ作成します。  
app/models/tweet.rb
```bash
has_many :likes, dependent: :destroy

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
```


# Commentモデルに追記
ここでもLikeモデルとアソシエート、また、後に使うメソッドを２つ作成します。  
app/models/comment.rb
```bash
has_many :likes, dependent: :destroy

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
```


# Likeコントローラーの設定
ツイートにいいねをした時(取り消した時)と、コメントにいいねをした時(取り消した時)の２パターンが必要なため、createとdestroyをそれぞれ作成する必要があります。  
ここで先ほど作成したメソッド
* save_notification_like_tweet!
* save_notification_like_comment!
を使い、いいねをした時に通知も作成することができるようにします。  
app/conrtollers/likes_controller.rb
```bash
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
```


# Viewの作成


#### Tweetをいいねする
表示させたい場所に埋め込んでください。  
また、アイコンフォントはお好みのものに変更してください。
```bash
<% if tweet.liked_by?(current_user) %>
	<%= link_to destroy_likes_tweet_path(tweet.id), method: :delete do %>
		<i class="fas fa-heart liked"></i>
	<% end %>
<% else %>
	<%= link_to create_likes_tweet_path(tweet.id), method: :post do %>
		<i class="far fa-heart not_liked"></i>
	<% end %>
<% end %>
```


#### Commentをいいねする
表示させたい場所に埋め込んでください。  
また、アイコンフォントはお好みのものに変更してください。
```bash
<% if comment.liked_by?(current_user) %>
	<%= link_to destroy_likes_comment_path(comment.id), method: :delete do %>
		<i class="fas fa-heart liked"></i>
	<% end %>
<% else %>
	<%= link_to create_likes_comment_path(comment.id), method: :post do %>
		<i class="far fa-heart not_liked"></i>
	<% end %>
<% end %>
```


# 最後に、通知の種類を区別し表示する
最後に、通知の種類を区別し表示したいので、app/helpers/notifications_helper.rbに以下の追記をします。  
これにより、kindカラムにlike_tweet、like_comment、commentのどれが保存されているかによって表示内容を変更することが可能になります。  
app/helpers/notifications_helper.rb
```bash
def notification_form(notification)
	#どのユーザーからの通知なのかを取得
	visitor = notification.visitor
	case notification.kind
# ------------------------------------------追記------------------------------------------
	when 'like_tweet' then
		tweet = Tweet.find_by(id: notification.tweet_id)
		tag.a(visitor.name) + 'があなたの' + tag.a('ツイート', href: tweet_path(notification.tweet_id)) + 'をいいねしました。'
	when 'like_comment' then
		comment = Comment.find_by(id: notification.comment_id)
		tag.a(visitor.name) + 'があなたの' + tag.a('コメント', href: tweet_path(comment.tweet.id)) + 'をいいねしました。'
# ----------------------------------------追記ここまで------------------------------------------
	when 'comment' then
		# kindがcommentだった時、コメントを取得する。
		@comment = Comment.find_by(id: notification.comment_id)
		tag.a(visitor.name) + 'があなたの' + tag.a('ツイート', href: tweet_path(notification.tweet_id)) + 'にコメントしました。'
	end
end
```
