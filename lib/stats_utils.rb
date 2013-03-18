require 'rubygems'
require 'mongo'

include Mongo

def scrub!(hash)
  # scrubs the keys of the hash to change offending "." and "$" characters
  q = [hash]
  while (!q.empty?)
    curr = q.pop()
    curr.keys.each do |key|
      # replace key with newkey by adding newkey and deleting old key
      newkey = key
      if key.include? "." or key.include? "$"
        newkey = newkey.gsub(".", ",")
        newkey.gsub!("$", "#")
        curr[newkey] = curr[key]
        curr.delete(key)
      end
      q << curr[newkey] if curr[newkey].is_a?(Hash)
    end
  end
  hash
end
