require 'sinatra'
require 'active_support/all'
require 'redis_pagination'

redis_config = {
    'host' => '127.0.0.1',
    'port' => '6379'
}
$redis_write = Redis.new( redis_config   )
$redis_write.select(0)



author  = 'admin'
subject = 'a'
content = 'aa'

new_id = $redis_write.incr 'content_data_max_id'
$redis_write.mapped_hmset "content_data:#{new_id}", {
    :id             => new_id,
    :author         => author,
    :created_at     => Time.now.to_i,
    :created_at_str => Time.now.to_s(:db),
    :subject        => subject,
    :content        => content,
    :read_count     => 0
}
$redis_write.zadd "content_data_list", Time.now.to_i, new_id

