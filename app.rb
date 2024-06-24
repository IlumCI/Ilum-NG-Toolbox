require 'sinatra'
require 'json'
require 'sinatra/reloader' if development?
require 'colorize'

# ASCII Banner
def display_banner
  puts "\n  ███████╗██╗     ██╗   ██╗███╗   ███╗███╗   ██╗ ███╗   ██╗\n  ██╔════╝██║     ██║   ██║████╗ ████║████╗  ██║ ████╗  ██║\n  ███████╗██║     ██║   ██║██╔████╔██║██╔██╗ ██║ ██╔██╗ ██║\n  ╚════██║██║     ██║   ██║██║╚██╔╝██║██║╚██╗██║ ██║╚██╗██║\n  ███████║███████╗╚██████╔╝██║ ╚═╝ ██║██║ ╚████║ ██║ ╚████║\n  ╚══════╝╚══════╝ ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═══╝ ╚═╝  ╚═══╝".colorize(:light_blue)
end

display_banner

set :bind, '0.0.0.0'

# Function to switch network interface to monitor mode
def enable_monitor_mode(interface)
  log_info("Switching #{interface} to monitor mode...")
  result = `sudo ifconfig #{interface} down`
  log_warning(result) unless result.empty?
  result = `sudo iwconfig #{interface} mode monitor`
  log_warning(result) unless result.empty?
  result = `sudo ifconfig #{interface} up`
  log_warning(result) unless result.empty?
  log_info("#{interface} is now in monitor mode.")
end

# Enhanced network retrieval function with detailed logging
def get_networks(interface)
  enable_monitor_mode(interface)
  log_info("Starting network scan on #{interface}...")
  result = `sudo airodump-ng -w scan_results --output-format json #{interface}`
  log_error(result) unless result.empty?
  log_info("Scan completed. Parsing results...")
  scan_results = JSON.parse(File.read('scan_results-01.json'))
  log_info("Results parsed successfully.")
  networks = scan_results['wireless-network']
  networks.map do |network|
    {
      'SSID' => network['SSID'],
      'BSSID' => network['BSSID'],
      'Channel' => network['channel'],
      'Signal' => network['signal']
    }
  end
end

# Function to enable verbose logging
def log_info(message)
  puts "[INFO] #{message}".colorize(:light_green)
end

def log_error(message)
  puts "[ERROR] #{message}".colorize(:light_red)
end

def log_warning(message)
  puts "[WARNING] #{message}".colorize(:yellow)
end

get '/' do
  erb :index
end

get '/networks' do
  interface = 'wlan0' # replace with your interface
  content_type :json
  get_networks(interface).to_json
end

get '/export' do
  content_type 'application/octet-stream'
  attachment "scan_results-01.json"
  File.read('scan_results-01.json')
end
