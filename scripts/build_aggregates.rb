#!/usr/bin/env ruby
# frozen_string_literal: true

# Rebuilds aggregates/{day,week,month,quarter,year,all}.json from daily/**/*.json.
# Run by GitHub Actions (push trigger) with stdlib only. No gem dependencies.
#
# See schema/aggregate.json for the output format.
# clearnet and onion are kept as separate series (combining is the display layer's job).

require 'json'
require 'fileutils'
require 'time'

ROOT = File.expand_path('..', __dir__)
DAILY_DIR = File.join(ROOT, 'daily')
OUT_DIR = File.join(ROOT, 'aggregates')

# granularity => [retained span (seconds), resolution]
RANGES = {
  'day' => [2 * 86_400, :snapshot],
  'week' => [7 * 86_400, :snapshot],
  'month' => [31 * 86_400, :daily],
  'quarter' => [92 * 86_400, :daily],
  'year' => [366 * 86_400, :daily],
  'all' => [nil, :daily]
}.freeze

# Read all daily files and flatten into [ts, inst, union, candidates] per network_class
def load_snapshots
  series = Hash.new { |h, k| h[k] = [] }
  Dir.glob(File.join(DAILY_DIR, '**', '*.json')).sort.each do |path|
    data = JSON.parse(File.read(path))
    data['snapshots'].each do |s|
      series[s['network_class']] << [s['ts'], s['instantaneous'], s['union_24h'], s['candidates']]
    end
  end
  series.each_value { |points| points.sort_by!(&:first) }
  series
end

# Aggregate into one point per day: instantaneous / candidates are averaged, union_24h is the max.
def daily_buckets(points)
  points.group_by { |ts, _, _, _| ts - (ts % 86_400) }.map do |day_ts, group|
    insts = group.map { |p| p[1] }
    unions = group.map { |p| p[2] }
    cands = group.map { |p| p[3] }
    [day_ts, (insts.sum.to_f / insts.size).round, unions.max, (cands.sum.to_f / cands.size).round]
  end.sort_by(&:first)
end

series = load_snapshots
if series.empty?
  warn 'no daily data found; nothing to do'
  exit 0
end

latest_ts = series.values.flat_map { |points| points.map(&:first) }.max
FileUtils.mkdir_p(OUT_DIR)

RANGES.each do |granularity, (span, resolution)|
  out_series = series.transform_values do |points|
    selected = span ? points.select { |ts, _, _, _| ts > latest_ts - span } : points
    resolution == :daily ? daily_buckets(selected) : selected
  end
  out = {
    'granularity' => granularity,
    'resolution' => resolution.to_s,
    'generated_at' => Time.now.to_i,
    'series' => out_series
  }
  File.write(File.join(OUT_DIR, "#{granularity}.json"), JSON.generate(out) + "\n")
  puts "aggregates/#{granularity}.json: " +
       out_series.map { |k, v| "#{k}=#{v.size}pts" }.join(' ')
end

# latest.json: the newest snapshot per network class with its full breakdowns
# (by_country / by_asn / by_user_agent), for the dashboard's map and ranking
# views. Time-series files above stay lean; detail lives only here.
latest_file = Dir.glob(File.join(DAILY_DIR, '**', '*.json')).max
latest_daily = JSON.parse(File.read(latest_file))
latest = { 'date' => latest_daily['date'], 'generated_at' => Time.now.to_i, 'networks' => {} }
latest_daily['snapshots'].each do |s|
  latest['networks'][s['network_class']] = {
    'ts' => s['ts'],
    'instantaneous' => s['instantaneous'],
    'union_24h' => s['union_24h'],
    'by_network' => s['by_network'],
    'by_country' => s['by_country'],
    'by_asn' => s['by_asn'],
    'by_user_agent' => s['by_user_agent']
  }.compact # onion has no by_country/by_asn; clearnet may lack them before geoip ran
end
File.write(File.join(OUT_DIR, 'latest.json'), JSON.generate(latest) + "\n")
puts "aggregates/latest.json: #{latest['date']} (#{latest['networks'].keys.join(', ')})"
