require 'fileutils'

# This filter can be used to debug a webby. just place is some where in the filter chain
# currently it supports only to dump the filter input to :outfile
default_options = {
  :outdir => "tmp",
  :outfile => "filter_input.txt",
}
Webby::Filters.register :debug, :defaults => default_options do |input, cursor|
  opts = cursor.current_options
  FileUtils.mkdir_p opts[:outdir]
  if opts[:outfile]
    File.open(File.join(opts[:outdir], opts[:outfile]), 'w') do |f|
      f.write input
    end
  end
  # return input unchanged
  input
end

# EOF
