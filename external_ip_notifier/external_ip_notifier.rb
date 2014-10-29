#update person with external ip
require 'rubygems'
require 'yaml'
require 'net/smtp'
require 'tlsmail'

def send_mail(external_ip, config)
    
  config['mailing_list'].each do |dest|
    
    message =<<EOF
To: <#{dest}>
From: IP Address Updater  <#{config['smtp_user']}>
Subject: IP Address Update

Your new WAN IP is: #{external_ip} 
EOF
    
    Net::SMTP.enable_tls(OpenSSL::SSL::VERIFY_NONE)
    Net::SMTP.start(config['smtp_server'], config['smtp_port'], "gmail.com", config['smtp_user'], config['smtp_pass'], :plain) do |smtp|

      smtp.send_message message, config['smtp_user'], dest
    end
    
  end
end

#attempt to load the cached ip
config_file ="config.yaml" 
ip_directive = "cached_ip"

abort("Could not find config file " + config_file) unless File.exists?(config_file)

config = YAML::load_file(config_file)

cached_ip = config[ip_directive]
cached_ip = nil unless cached_ip =~ /\b(?:\d{1,3}\.){3}\d{1,3}\b/

#get the current ip
external_ip = `/usr/bin/dig +short myip.opendns.com @resolver1.opendns.com`
external_ip.chomp!

if( !cached_ip or external_ip != cached_ip )
   
  #alert the people
  send_mail(external_ip, config)
  
  config[ip_directive] = external_ip
  
  #overwrite cached ip
  File.open(config_file, 'w') {|f| f.write config.to_yaml }
end

