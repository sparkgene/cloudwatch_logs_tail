#!/usr/bin/env ruby
# encoding: UTF-8
#
# tail_cwlog
# Script for discribe cloudwatch logs
#
# Copyright 2015, Jun Ichikawa <jun1ka0@gmail.com>

require 'optparse'
require 'net/http'
require 'json'
require 'aws-sdk-core'

options = {}
help = ""
def parse_options(argv)
  opts = {}

  @parser = OptionParser.new do |o|

    o.on '--aws-profile=[VALUE]', "AWS PROFILE" do |arg|
      opts[:aws_profile] = arg
    end
    
    o.on '--aws-region=[VALUE]', "AWS REGION" do |arg|
      opts[:aws_region] = arg
    end
    
    o.on '--aws-access-key=[VALUE]', "AWS ACCESS KEY" do |arg|
      opts[:aws_access_key] = arg
    end
    
    o.on '--aws-secret-key=[VALUE]', "AWS SECRET KEY" do |arg|
      opts[:aws_secret_key] = arg
    end

    o.on '--discribe-groups', "Describe log groups" do |arg|
      opts[:discribe_groups] = arg
    end

    o.on '--discribe-streams', "Describe log streams" do |arg|
      opts[:discribe_streams] = arg
    end

    o.on '--tailf', "tail -f log stream" do |arg|
      opts[:tailf] = arg
    end

    o.on '--tail=[VALUE]', "tail log stream" do |arg|
      opts[:tail] = arg
    end

    o.on '--log-group=[VALUE]', "log group name" do |arg|
      opts[:log_group] = arg
    end

    o.on '--log-stream=[VALUE]', "log stream name" do |arg|
      opts[:log_stream] = arg
    end
  end
  @parser.parse!(argv)
  opts[:aws_region] ||= "us-east-1"
  opts[:use_iamrole] = !(opts[:aws_profile] || opts[:aws_access_key] || opts[:aws_secret_key])
  opts
end

def validate_credentials!(options)
  return if options[:use_iamrole]
  return if opts[:aws_profile] || (options[:aws_access_key] && options[:aws_secret_key])

	if options[:aws_access_key]
		puts "--aws-secret-key is required"
	elsif options[:aws_secret_key]
		puts "--aws-access-key is required"
	else
		puts "--aws_profile or --aws-access-key and --aws-secret-key is required"
	end

  exit 1
end

def validate_params(options)
  validate_credentials!(options)

  type_cnt = 0
  type_cnt += 1 if options[:discribe_groups]
  type_cnt += 1 if options[:discribe_streams]
  type_cnt += 1 if options[:tail]
  type_cnt += 1 if options[:tailf]
  if type_cnt != 1
    puts "Specify one type [--discribe-groups, --discribe-streams, --tail, --tailf]"
    exit(1)
  end

  if options[:discribe_streams]
    (puts "--log-group is required"; exit(1)) unless options[:log_group]
  end

  if options[:tailf] || options[:tail]
    (puts "--log-group is required"; exit(1)) unless options[:log_group]
    (puts "--log-stream is required"; exit(1)) unless options[:log_stream]
  end
end

def cloudwatch_client(options)
  if options[:use_iamrole]
    Aws::CloudWatchLogs::Client.new(
      region: options[:aws_region]
    )
  elsif options[:aws_profile]
    Aws::CloudWatchLogs::Client.new(
      region: options[:aws_region],
      profile: Aws::SharedCredentials.new(
        profile_name: options[:aws_profile])
      )
    )
  else
    Aws::CloudWatchLogs::Client.new(
      region: options[:aws_region],
      credentials: Aws::Credentials.new(
        options[:aws_access_key],
        options[:aws_secret_key]
      )
    )
  end
end

def describe_groups(options)
  cloudwatchlogs = cloudwatch_client(options)
  pages = cloudwatchlogs.describe_log_groups()
  pages.each_page do |resp|
    resp.log_groups.each do |group|
      puts group.log_group_name
    end
  end
end

def discribe_streams(options)
  cloudwatchlogs = cloudwatch_client(options)
  pages = cloudwatchlogs.describe_log_streams(
    log_group_name: options[:log_group]
  )
  pages.each_page do |resp|
    resp.log_streams.each do |group|
      puts group.log_stream_name
    end
  end
end

def tail_stream(options)
  cloudwatchlogs = cloudwatch_client(options)
  pages = cloudwatchlogs.get_log_events(
    log_group_name: options[:log_group],
    log_stream_name: options[:log_stream],
    limit: options[:tailf] ? 20 : options[:tail]
  )
  last_token = ""
  pages.each_page do |resp|
    resp.events.each do |log|
      puts log.message
    end
    return if options[:tail]
    if last_token == resp.next_forward_token
      sleep(5)
    end
    last_token = resp.next_forward_token
    return if resp.last_page?
  end
rescue Interrupt
   puts ""
end

options = parse_options(ARGV)
validate_params(options)

if options[:discribe_groups]
  describe_groups(options)
  exit!
end

if options[:discribe_streams]
  discribe_streams(options)
  exit!
end

if options[:tail] || options[:tailf] 
  tail_stream(options)
  exit!
end
