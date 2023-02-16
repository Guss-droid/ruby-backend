require 'sinatra'
require 'pg'

conn = PG.connect(dbname: 'app', user: 'docker', password: 'docker')

create_table = <<~SQL
  create table if not exists My_Tasks (
    id serial primary key,
    task varchar(50) not null,
    is_concluded boolean default false
  );
SQL

conn.exec(create_table)

get '/tasks' do
  tasks = []
  conn.exec('SELECT task FROM My_Tasks') do |result|
    result.each do |row|
      tasks << row['task']
    end
  end

  result = tasks.join(',').split(',').map(&:strip)
  {tasks: result}.to_json
end

post '/tasks' do
  data = JSON.parse request.body.read
  is_concluded, task = false, data['task']

  conn.exec_params('insert into My_Tasks (task, is_concluded) values ($1, $2)', [task, is_concluded])

  {message: 'Task created sucessfully'}.to_json
end

get '/tasks/:id' do
  id = params['id']
  task = []

  conn.exec_params('select * from My_Tasks where id = $1', [id]) do |result|
    result.each do |row|
      task.push(id: row['id'] ,task: row['task'], is_concluded: row['is_concluded'])
    end
  end

  task.to_json
end

put '/tasks/:id' do
  data = JSON.parse request.body.read
  id, task = params['id'], data['task']

  conn.exec_params('update My_Tasks set task = $1 where id = $2 and not is_concluded', [task, id])

  {message: 'Task updated'}.to_json
end

delete '/tasks/:id' do
  id = params['id']

  conn.exec_params('delete from My_Tasks where id = $1 and is_concluded', [id])

  {message: 'Task deleted successfully'}.to_json
end

post '/tasks/concluded/:id' do
  id = params['id']

  conn.exec_params('update My_Tasks set is_concluded = true where id = $1 and not is_concluded', [id])

  {message: 'Task mark completed successfully'}.to_json
end

get '/concluded' do
  tasks = []

  conn.exec('select * from My_Tasks where is_concluded = true') do |result|
    result.each do |row|
      tasks.push(id: row['id'] ,task: row['task'], is_concluded: row['is_concluded'])
    end
  end

  tasks.to_json
end
