require 'sinatra/base'
require 'haml'
require 'less'
require 'rack-flash'

class Converter < Sinatra::Base
  # set :sessions, true
  # set :foo, 'bar'
  use Rack::Session::Cookie
  use Rack::Flash
  
  get '/screen.css' do
    content_type "text/css", :charset => "utf-8"
    Less::Engine.new(File.new("css/screen.less")).to_css
  end
  
  get '/' do
    haml :home
  end
  
  post '/convert' do
    content_type "application/qif"
    attachment "#{Time.now.strftime("%Y%m%d_%H%M%S.qif")}"
    
    output = "!Type:Bank\n"
    raw = params[:transactions]
    raw.split(/\n/).each do |line|
      parts = case params[:table_format]
      when "ddtoi" then ddtoi(line.split("\t"))
      else ddoi(line.split("\t"))
      end
      # parts = ddoi(line.split("\t"))
      output << "D#{parts[:date]}\n"
      output << "P#{parts[:description]}\n"
      output << "T#{parts[:value]}\n"
      output << "^\n"
    end
    
    if params[:convert] == "preview"
      flash[:preview] = output
      flash[:raw] = raw
      redirect "/"
    end
    output
  end
  
  def ddtoi(parts)
    results = {}
    d = Date.strptime(parts[0], params[:date_format])
    results[:date] = d.strftime("%m/%d/%Y")
    results[:description] = parts[1].strip
    withdraw = parts[3].to_f.abs
    deposit = parts[4].to_f.abs
    unless withdraw.zero?
      results[:value] = 0 - withdraw
    else
      results[:value] = deposit
    end
    results
  end
  
  def ddoi(parts)
    results = {}
    d = Date.strptime(parts[0], params[:date_format])
    results[:date] = d.strftime("%m/%d/%Y")
    results[:description] = parts[1].strip
    withdraw = parts[2].to_f.abs
    deposit = parts[3].to_f.abs
    unless withdraw.zero?
      results[:value] = 0 - withdraw
    else
      results[:value] = deposit
    end
    results
  end
end