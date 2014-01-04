require 'rubygems'
require 'sinatra'
require 'active_support/all'
require 'redis_pagination'

require './app'

enable :sessions

configure do
  set :host, '127.0.0.1'
  set :port, 86
end

log = File.new(File.expand_path("../log/production.log", __FILE__), "a+")
$stdout.reopen(log)
$stderr.reopen(log)


redis_config = {
    'host' => '127.0.0.1',
    'port' => '6379'
}
$redis_write = Redis.new( redis_config   )
$redis_write.select(0)

RedisPagination.configure do |configuration|
  configuration.redis = $redis_write
  configuration.page_size = 50
end

get '/' do
  items_paginator = RedisPagination.paginate('content_data_list')
  @items = items_paginator.page(1)
  @top_data = []
  @items[:items].map do|item|
    key = item[0]
    if @top_data.size < 5

      d = $redis_write.mapped_hmget "content_data:#{key}", :id, :created_at_str, :subject, :type
      @top_data.push(d) if d[:type].blank? or d[:type] == 'xinwen'
    end
  end
  @top_data

  erb :index
end

get '/data_content' do
  id = params[:id]
  @ret = ($redis_write.hgetall "content_data:#{id}")

  @subject = @ret['subject']
  @content = @ret['content']
  erb :data_content
end

get '/data_list' do
  page_no = params[:page].to_i || 1
  items_paginator = RedisPagination.paginate('content_data_list')
  @items = items_paginator.page(page_no)
  @ret = []
  @items[:items].map do|item|
    key = item[0]

    d = $redis_write.mapped_hmget "content_data:#{key}", :id, :created_at_str, :subject, :type
    @ret.push(d) if d[:type].blank? or d[:type] == 'xinwen'
  end
  @items[:items] = @ret
  erb :data_list
end

get '/anli_list' do
  page_no = params[:page].to_i || 1
  items_paginator = RedisPagination.paginate('content_data_list')
  @items = items_paginator.page(page_no)
  @ret = []
  @items[:items].map do|item|
    key = item[0]
    d = $redis_write.mapped_hmget "content_data:#{key}", :id, :created_at_str, :subject, :type
    @ret.push(d) if d[:type] == 'anli'
  end
  @items[:items] = @ret
  erb :anli_list
end

get '/admin_login' do
  erb :admin_login
end

post'/admin_login' do
  password = params[:password]
  if password != 'admin123'
    redirect '/admin_login'
  else
    session[:admin] = true
    redirect '/data_list'
  end

end


post '/data_add' do
  author  = params[:author ]
  subject = params[:subject]
  content = params[:content]
  id      = params[:id     ]
  type    = params[:type   ]

  if id.blank?
    new_id = $redis_write.incr 'content_data_max_id'
  else
    new_id = id
  end

  $redis_write.mapped_hmset "content_data:#{new_id}", {
      :id             => new_id,
      :type           => type,
      :author         => author,
      :created_at     => Time.now.to_i,
      :created_at_str => Time.now.to_s(:db),
      :subject        => subject,
      :content        => content,
      :read_count     => 0
  }
  $redis_write.zadd "content_data_list", Time.now.to_i, new_id
  if id.blank?
    "add success"
  else
    "update success"
  end
end

get '/data_add' do
  if params[:id]
    @ret = ($redis_write.hgetall "content_data:#{params[:id]}")
  else
    @ret = {}
  end
  erb :data_add
end


get '/data_delete' do

  if session[:admin] and params[:id]
    $redis_write.zrem "content_data_list", params[:id]
    "delete success"
  end

end

get '/env' do
  ips = "REMOTE_ADDR: #{request.env['REMOTE_ADDR']}<br/>" +
        "HTTP_VIA: #{request.env['HTTP_VIA']}<br/>" +
        "HTTP_X_FORWARDED_FOR: #{request.env['HTTP_X_FORWARDED_FOR']}<br/>"
  headers = request.env.inspect
  
  ips + headers
end

#run Sinatra::Application
