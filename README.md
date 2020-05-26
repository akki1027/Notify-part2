# NotifyPart2ication(コメントなどされた時に通知を送れる/受け取れるようにしよう)


# 初めに
ユーザー機能、投稿機能、コメント機能まで既に作成されていることが前提で始めていきます。  
まだできていない方はまずそれをやりましょう。  
因みに、私は投稿を(tweet)、コメントを(comment)と命名して進めていきます。


# NotifyPart2icationモデルの作成
```bash
$ rails g model notification visitor_id:integer visited_id:integer tweet_id:integer comment_id:integer kind:string viewed:boolean
```

```bash
def change
	create_table :notifications do |t|
		t.integer :visitor_id
		t.integer :visited_id
		t.integer :tweet_id
		t.integer :comment_id
		t.string :kind, null: false
		t.boolean :viewed, default: false, null: false

		t.timestamps
	end
end
```
* visitor_id 通知を送る側のユーザー(例: コメントしたユーザー)  
* visited_id 通知をもらう側のユーザー  
* tweet_id 投稿と結びつけるためのカラムです。違う名前を使用している場合、ご自身が命名された名前に置き換えてください。  
* comment_id　コメントと結びつけるためのカラムです。違う名前を使用している場合、ご自身が命名された名前に置き換えてください。  
* kind なんの種類の通知であるかが入ります(コメントされた時の通知なのか、フォローされた通知なのか等)  
* viewed 通知を既読した場合はtrueが入り、新着の通知(まだ既読してない通知)にはfalseが入る  
カラムの設定が完了したらdb:migrateしてください。

```bash
$ rails db:migrate
```


# NotifyPart2icationsコントローラーの作成
```bash
$ rails g controller notifications index
```
ついでにroutesも設定してください。  
config/routes.rb
```bash
resources :notifications, only: :index
```


# NotifyPart2icationモデルの設定
app/models/notification.rb
```bash
belongs_to :visitor, class_name: 'User', foreign_key: 'visitor_id', optional: true
belongs_to :visited, class_name: 'User', foreign_key: 'visited_id', optional: true
belongs_to :tweet, optional: true
belongs_to :comment, optional: true
validates :visitor_id, presence: true
validates :visited_id, presence: true
KIND_VALUES = ["comment"]
validates :kind, presence: true, inclusion: { in: KIND_VALUES }
validates :viewed, inclusion: { in: [true, false] }
default_scope -> { order(created_at: :desc) }
```
viewedカラムには、通知を既読済みか、未読かしか入れたくないので、inclusionでtrueかfalseの二択の値しか入らないようにする。  
default_scope -> { order(created_at: :desc) }で、新着が上に並ぶように設定する。  


# Userモデルに追記
app/models/user.rbに以下を追加してください。  
app/models/user.rb
```bash
has_many :active_notifications, class_name: 'NotifyPart2ication', foreign_key: 'visitor_id', dependent: :destroy
has_many :passive_notifications, class_name: 'NotifyPart2ication', foreign_key: 'visited_id', dependent: :destroy
```


# Commentモデルに追記
app/models/comment.rb
```bash
has_many :notifications, dependent: :destroy
```


# Tweet(投稿)モデルに追記
Tweet(投稿)モデルに、save_notification_comment!というメソッドを作成しておきます。  
コメントを作成した際に、同時に通知を作成するために後で使います。  
app/models/tweet.rb
```bash
has_many :notifications, dependent: :destroy

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
```


# Commentsコントローラーの編集
Commentsコントローラーに、先ほど作成したsave_notification_comment!メソッドを追加します。  
これで、コメントが作成された際に、通知を送ることができるようになります。  
app/controllers/comments_controller.rb
```bash
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
```


# NotifyPart2icationsコントローラーの設定
app/controllers/notifications_controller.rb
```bash
def index
	#current_userの投稿に紐づいた通知を全て取得
    @notifications = current_user.passive_notifications
  	#通知のviewカラムがfalse、つまりまだ既読していない通知を既読(true)にする
    @notifications.where(viewed: false).each do |notification|
        notification.update_attributes(viewed: true)
    end
end
```


# NotifyPart2icationsヘルパーファイルの設定
ヘルパーに、後で使うメソッドを二つ作成しておきます。  
* １つ目のメソッドについて  
ここでは、まずどの種類の通知かを判断します。例えば、誰かが自分のTweet(投稿)にコメントしてきた場合、通知の種類がコメントの時の処理が走り、『Aさんが、あなたのツイートにコメントしました』という内容の通知を表示します。  
* ２つ目のメソッドについて  
未読の通知がある場合に、アイコンなどを表示させ、ユーザーに未読の通知があるのを知らせたい時に使います。  
app/helpers/notifications_helper.rb
```bash
def notification_form(notification)
	#どのユーザーからの通知なのかを取得
	visitor = notification.visitor
	case notification.kind
	when 'comment' then
		# kindがcommentだった時、コメントを取得する。
		@comment = Comment.find_by(id: notification.comment_id)
		tag.a(visitor.name) + 'があなたの' + tag.a('ツイート', href: tweet_path(notification.tweet_id)) + 'にコメントしました。'
	end
end
def new_notifications
    @notifications = current_user.passive_notifications.where(viewed: false)
end
```


# 最後に、表示画面を書いていきます
ここで、先ほどヘルパーファイルに作成した１つ目のメソッドを使います。  
それにより、通知の種類によって、通知の表示を変更することが可能になります。  
app/views/notifications/index.html.erb
```bash
<div class="container">
	<div class="row">
		<% if @notifications.exists? %>
			<div class="notifications-list">
				<% @notifications.each do |notification| %>
				  <%= notification_form(notification) %><%= "(#{time_ago_in_words(notification.created_at)}前)" %><br>
				  <% if @comment.present? %>
				    <p><%= notification.comment.content.truncate(50) %></p>
				  <% end %>
				<% end %>
			</div>
		<% else %>
			<p>通知はありません。</p>
		<% end %>
	</div>
</div>
```


#### 未読の通知がある時、通知という文字の隣にアイコンを表示させる
先ほどヘルパーファイルに作成した２つ目のメソッドを使います。
```bash
<% if new_notifications.any? %>
	<li><i class="fas fa-circle" style="color: #FFD725"></i><%= link_to '通知', notifications_path %></li>
<% else %>
	<li><%= link_to '通知', notifications_path %></li>
<% end %>
```
