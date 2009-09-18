require 'sinatra/base'
require 'haml'
require 'rack-flash'

class Converter < Sinatra::Base
  # set :sessions, true
  # set :foo, 'bar'
  use Rack::Session::Cookie
  use Rack::Flash

  get '/' do
    haml :home
  end
  
  post '/convert' do
    content_type "application/qif"
    attachment "#{Time.now.strftime("%Y%m%d_%H%M%S.qif")}"
    
    output = "!Type:Bank\n"
    raw = params[:transactions]
    raw.split(/\n/).each do |line|
      parts = line.split("\t") #.gsub(/[\t|\s]+\t/, "\t")
      output << "D#{Time.parse(parts[0]).strftime("%m/%d/%Y")}\n"
      output << "T#{parts[1].strip}\n"
      withdraw = parts[2].to_f.abs
      deposit = parts[3].to_f.abs
      unless withdraw.zero?
        output << "P-#{withdraw}\n"
      else
        output << "P#{deposit}\n"
      end
      output << "^\n"
    end
    if params[:convert] == "preview"
      flash[:preview] = output
      flash[:raw] = raw
      redirect "/"
    end
    output
  end
end