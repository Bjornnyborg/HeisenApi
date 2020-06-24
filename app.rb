# app.rb
require 'sinatra'
require 'sinatra/cross_origin'
require 'json'
require 'mysql2'
require 'yaml'


class App < Sinatra::Base

  configure do
    enable :cross_origin
  end

  before do
    response.headers['Access-Control-Allow-Origin'] = '*'
  end

  config = YAML.load(ERB.new(File.read(File.join("config","database.yml"))).result)["production"]

  puts config['host']
  puts config['username']
  puts config['password']
  puts config['database']

  client = Mysql2::Client.new(:host => config['host'], :username => config['username'], :password => config['password'], :database => config['database'], :socket => config['socket'])
  client.query("CREATE TABLE IF NOT EXISTS \
    highscores(Id INT PRIMARY KEY AUTO_INCREMENT, name VARCHAR(25), time INT, level INT, createdDate TIMESTAMP NOT NULL DEFAULT current_timestamp)")

  get '/highscore/:level' do
    scores = []

    client.query("SELECT id, name, time, level, createdDate FROM highscores WHERE level='#{params['level']}' ORDER BY time ASC;").each do |row|
      scores.push(row)
    end

    content_type :json
    scores.to_json

  end

  post '/highscore' do
    push = JSON.parse(request.body.read)

    client.query("INSERT INTO highscores (name, time, level)
      VALUES ('#{push["name"]}', '#{push["time"]}', '#{push["level"]}')")

  end

  options "*" do
    response.headers["Allow"] = "GET, PUT, POST, DELETE, OPTIONS"
    response.headers["Access-Control-Allow-Headers"] = "Authorization, Content-Type, Accept, X-User-Email, X-Auth-Token"
    response.headers["Access-Control-Allow-Origin"] = "*"
    200
  end
end