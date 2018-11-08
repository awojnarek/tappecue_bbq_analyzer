#!/usr/bin/env ruby

require 'pp'
require 'csv'
require 'date'


#############
# Variables #
#############
file = ARGV[0]



#############
# Functions #
#############
def calculate_total_session_time(csv)

   # Tappecue puts the session start and stop on every line, so we just need the first row
   session_start = csv.first["SessionStart"]
   session_end   = csv.first["SessionEnd"]

   # Attempt to parse the date
   start_epoch = DateTime.strptime("#{session_start} -0400", "%m/%d/%Y %l:%M:%S %p %z").to_time.to_i
   end_epoch   = DateTime.strptime("#{session_end} -0400", "%m/%d/%Y %l:%M:%S %p %z").to_time.to_i

   # Determine the seconds between
   duration = end_epoch - start_epoch

   return duration
end

def calculate_total_stall_time(csv)

   # Store data
   values   = Hash.new { |h, k| h[k] = [] }
   data     = Hash.new {|h,k| h[k] = Hash.new(&h.default_proc) }
   stalled  = false
   duration = Hash.new(0) 

   # Loop through CSV
   csv.each do |row|

     # If the probe isn't connected, skip it
     next if row["ProbeName"] =~ /None/
     next if row["ProbeName"] =~ /chamber/

     # Parse data
     item = "#{row["ProbeNumber"]} #{row["ProbeName"]}"
     temp = "#{row["ActualTemp"]}"
     time = "#{row["ActualTime"]}"

     # Push our data to our values
     values[item].push(temp.to_i)
   end

   values.each do |k,v|
     ranges = [ 100, 110, 120, 130, 140, 150, 160, 170, 180, 190, 200 ]

     ranges.each do |range|
       points = v.select { |e| e > range and e < (range + 10) }.count
       data[k]["#{range}-#{range + 10}"] = points
     end
   end

  # Now that we have the ranges, we can simply do math on the common ranges
  data.each do |type,hash|
    hash.each do |range,counts|
      if counts > 100
        duration[type] += counts * 30
      end
    end
  end

  return duration
end



########
# Main #
########

# Parse the CSV
csv_text = File.read(file)
csv      = CSV.parse(csv_text, :headers => true)

# Calculate some values
total_session_time = calculate_total_session_time(csv)
total_stall_time   = calculate_total_stall_time(csv)

printf "\nSource,ProbeNumber,TotalStallTime,TotalSessionTime\n"
total_stall_time.each do |k,v|
  printf "#{file},#{k},#{v},#{total_session_time}\n"
end
