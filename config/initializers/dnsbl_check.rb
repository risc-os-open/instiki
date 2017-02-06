require File.join(File.dirname(__FILE__),'..','..','lib','dnsbl_check','dnsbl_check')
ActionController::Base.send :include, DNSBL_Check
