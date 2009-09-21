require 'sinatra/base'
require 'haml'
require 'less'
require 'rack-flash'

class Converter < Sinatra::Base
  # set :sessions, true
  # set :foo, 'bar'
  use Rack::Session::Cookie
  use Rack::Flash
  
  set :static, true
  set :root, File.dirname(__FILE__)
  set :public, Proc.new { File.join(root, "public") }
  
  helpers do
    def opt(name, param)
      {:value => name, :selected => (param == name ? "selected" : nil)}
    end
    # def select(name, val)
    #   name == val ? "selected", nil
    # end
  end
  
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
    key = case params[:table_format]
    when "ddtoi" then {:date => 0, :description => 1, :out => 3, :in => 4}
    else {:date => 0, :description => 1, :out => 2, :in => 3}
    end
    raw.split(/\n/).each do |line|
      parts = extract_parts(line, key)
      output << "D#{parts[:date]}\n"
      output << "P#{parts[:description]}\n"
      output << "T#{parts[:value]}\n"
      output << "^\n"
    end
    if params[:convert] == "preview"
      flash[:preview] = output
      flash[:raw] = raw
      flash[:table_format] = params[:table_format]
      flash[:date_format] = params[:date_format]
      redirect "/"
    end
    output
  end
  
  def extract_parts(line, key)
    results = {}
    parts = line.split("\t")
    d = Date.strptime(parts[key[:date]], params[:date_format])
    results[:date] = d.strftime("%m/%d/%Y")
    results[:description] = parts[key[:description]].strip
    withdraw = parts[key[:out]].to_f.abs
    deposit = parts[key[:in]].to_f.abs
    unless withdraw.zero?
      results[:value] = 0 - withdraw
    else
      results[:value] = deposit
    end
    results
  end
  
end