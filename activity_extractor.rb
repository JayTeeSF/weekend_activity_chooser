#!/usr/bin/env ruby

# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

# Raw markdown for the README
RAW_README_URL = 'https://raw.githubusercontent.com/the-best-of/bay-area/master/README.md'

CATEGORY_TYPE_MAP = {
  'Day Trips'             => 'day-trip',
  'Events'                => 'event',
  'Food'                  => 'food',
  'Fun and Games'         => 'fun-and-games',
  'Hiking'                => 'outdoor-activity',
  'Museums and Galleries' => 'indoor-activity',
  'Parks & Playgrounds'   => 'outdoor-activity',
  'Performing Arts'       => 'indoor-activity',
  'Shopping'              => 'shopping',
  'Sights'                => 'sightseeing',
  'Sports'                => 'sports',
  'Wedding Venues'        => 'wedding-venue'
}.freeze

def fetch_readme
  uri = URI.parse(RAW_README_URL)
  Net::HTTP.get(uri)
end

markdown = fetch_readme

activities = []

current_category = nil  # e.g. "Food"
current_area     = nil  # e.g. "Peninsula"
current_city     = nil  # e.g. "Half Moon Bay"

markdown.each_line do |line|
  line = line.rstrip

  # Top-level category: "# Food"
  if line =~ /^# (.+)$/
    current_category = Regexp.last_match(1).strip
    next
  end

  # Skip the main repo title "# the-best-of/bay-area"
  current_category = nil if current_category == 'the-best-of/bay-area'

  # Sub-area: "### Peninsula"
  if line =~ /^### (.+)$/
    current_area = Regexp.last_match(1).strip
    next
  end

  # City prefix bullets: "  * Livermore:" or "  * San Francisco:"
  if line =~ /^\s*\* ([^:]+):/
    current_city = Regexp.last_match(1).strip
    next
  end

  # Markdown links: [Name](https://example.com)
  if line =~ /\[([^\]]+)\]\((https?:\/\/[^\)]+)\)/
    name = Regexp.last_match(1).strip
    url  = Regexp.last_match(2).strip

    type = CATEGORY_TYPE_MAP[current_category] || 'misc'

    activities << {
      'Activity'                    => name,
      'Category'                    => current_category,
      'Area'                        => current_area,
      'City'                        => current_city,
      'Type'                        => type,
      'URL'                         => url,
      'Last Recommended'            => nil,
      'JT Rating History'           => '',
      'Ayo Rating History'          => '',
      'Good for Health'             => nil,
      'Cost'                        => nil,
      'Enjoyability'                => nil,
      'Approximate Time (minutes)'  => nil,
      'Image URL'                   => ''
    }
  end
end

# Deduplicate by Activity + URL just in case
activities.uniq! { |a| [a['Activity'], a['URL']] }

puts JSON.pretty_generate(activities)
