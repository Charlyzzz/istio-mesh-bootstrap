#!/usr/bin/env ruby

require 'ostruct'
require 'json'

instances = JSON.parse(`aws ec2 describe-instances --profile 10pines --region us-east-1 --output json`, object_class: OpenStruct)
#instances = OpenStruct.new json_instances

running_machines = instances
  .Reservations
  .flat_map {|r| r.Instances }
  .select { |i| i.State.Name == "running" && i.Tags.any? {|t| t.Key.include? "k8s.io/role"}} 
  .map(&:InstanceId)

if running_machines.empty?
  puts "no machines running"
else 
  graph =   
    "https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#metricsV2:graph="+
    "~(metrics~(~(~'AWS*2fEC2~'CPUUtilization~'InstanceId~'#{running_machines.first})"
  running_machines.drop(1).each { |i| graph.concat("~(~'...~'#{i})") }
  trailing = ")~view~'timeSeries~stacked~false~region~'us-east-1~stat~'Average~period~60);"
  puts(graph + trailing)
end
