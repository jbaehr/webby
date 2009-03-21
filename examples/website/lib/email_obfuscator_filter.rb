Webby::Filters.register :email_obfuscator do |input|
  # transform "user@example.com" into "example dot com: user"
  input.gsub /([a-z0-9_.-]+)@([a-z0-9.-]+)\.([a-z]{2,4})/i do
    "#{$2} dot #{$3}: #{$1}"
  end
end