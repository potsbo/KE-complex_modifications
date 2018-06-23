#!/usr/bin/env ruby

require 'erb'
require 'json'
require_relative '../src/lib/karabiner.rb'

def char_to_option(char)
  return {key_code: char.to_s }                      if (:a..:z).to_a.include?(char.to_sym)
  return {key_code: char.to_s.downcase, modifiers: [:shift] } if (:A..:Z).to_a.include?(char.to_sym)
  return {key_code: char.to_s }                      if ('0'..'9').to_a.include?(char.to_s)
  key_map = {
    "$": {key_code: "4",                      modifiers: [:shift]},
    "!": {key_code: "1",                      modifiers: [:shift]},
    "[": {key_code: "open_bracket",           modifiers: []},
    "{": {key_code: "open_bracket",           modifiers: [:shift]},
    "(": {key_code: "9",                      modifiers: [:shift]},
    "=": {key_code: "equal_sign",             modifiers: []},
    "+": {key_code: "equal_sign",             modifiers: [:shift]},
    ")": {key_code: "0",                      modifiers: [:shift]},
    "}": {key_code: "close_bracket",          modifiers: [:shift]},
    "]": {key_code: "close_bracket",          modifiers: []},
    "*": {key_code: "8",                      modifiers: [:shift]},
    "&": {key_code: "7",                      modifiers: [:shift]},
    "-": {key_code: "hyphen",                 modifiers: []},
    "_": {key_code: "hyphen",                 modifiers: [:shift]},
    "`": {key_code: "grave_accent_and_tilde", modifiers: []},
    "~": {key_code: "grave_accent_and_tilde", modifiers: [:shift]},
    "@": {key_code: "2",                      modifiers: [:shift]},
    "#": {key_code: "3",                      modifiers: [:shift]},
    "%": {key_code: "5",                      modifiers: [:shift]},
    "^": {key_code: "6",                      modifiers: [:shift]},
    "\\": {key_code: "backslash",             modifiers: []},
    "'": {key_code: "quote",                  modifiers: []},
    '"': {key_code: "quote",                  modifiers: [:shift]},
    ",": {key_code: "comma",                  modifiers: []},
    ".": {key_code: "period",                 modifiers: []},
    "/": {key_code: "slash",                  modifiers: []},
    "|": {key_code: "backslash",              modifiers: [:shift]},
    "?": {key_code: "slash",                  modifiers: [:shift]},
    ";": {key_code: "semicolon",              modifiers: []},
    ":": {key_code: "semicolon",              modifiers: [:shift]},
    "<": {key_code: "comma",                  modifiers: [:shift]},
    ">": {key_code: "period",                 modifiers: [:shift]},
  }
  $stderr << "#{char}: #{key_map[char.to_sym].inspect}\n"
  key_map[char.to_sym]
end

def caps_complete(config)
  return config if config[:modifiers].nil?
  return config unless config[:modifiers].include?(:shift)
  config[:optional_modifiers] = (config[:optional_modifiers] || []) + [:caps_lock]
  config
end

def _from(key_code, mandatory_modifiers, optional_modifiers)
  data = {}
  data['key_code'] = key_code

  mandatory_modifiers.each do |m|
    data['modifiers'] = {} if data['modifiers'].nil?
    data['modifiers']['mandatory'] = [] if data['modifiers']['mandatory'].nil?
    data['modifiers']['mandatory'] << m
  end

  optional_modifiers.each do |m|
    data['modifiers'] = {} if data['modifiers'].nil?
    data['modifiers']['optional'] = [] if data['modifiers']['optional'].nil?
    data['modifiers']['optional'] << m
  end
  data
end

def from(key_code, mandatory_modifiers, optional_modifiers)
  JSON.generate(_from(key_code, mandatory_modifiers, optional_modifiers))
end

def _to(events)
  data = []

  events.each do |e|
    d = {}
    d['key_code'] = e[0]
    e[1].nil? || d['modifiers'] = e[1]

    data << d
  end
  data
end

def to(events)
  JSON.generate(_to(events))
end

def each_key(source_keys_list: :source_keys_list, dest_keys_list: :dest_keys_list, from_mandatory_modifiers: [], from_optional_modifiers: [], to_pre_events: [], to_modifiers: [], to_post_events: [], conditions: [], as_json: false)
  data = []
  source_keys_list.each_with_index do |from_key, index|
    to_key = dest_keys_list[index]
    d = {}
    d['type'] = 'basic'
    d['from'] = _from(from_key, from_mandatory_modifiers, from_optional_modifiers)

    # Compile list of events to add to "to" section
    events = []

    to_pre_events.each do |e|
      events << e
    end

    events << if to_modifiers[0].nil?
                [to_key]
              else
                [to_key, to_modifiers]
              end

    to_post_events.each do |e|
      events << e
    end

    d['to'] = JSON.parse(to(events))

    if conditions.any?
      d['conditions'] = []
      conditions.each do |c|
        d['conditions'] << c
      end
    end
    data << d
  end

  if as_json
    JSON.generate(data)
  else
    data
  end
end

def frontmost_application(type, app_aliases)
  app_aliases.is_a?(Enumerable) || app_aliases = [app_aliases]

  JSON.generate(Karabiner.frontmost_application(type, app_aliases))
end

def frontmost_application_if(app_aliases)
  frontmost_application('frontmost_application_if', app_aliases)
end

def frontmost_application_unless(app_aliases)
  frontmost_application('frontmost_application_unless', app_aliases)
end

template = ERB.new $stdin.read
puts JSON.pretty_generate(JSON.parse(template.result))
