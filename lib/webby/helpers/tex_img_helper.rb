require Webby.libpath(*%w[webby stelan mktemp])
require 'fileutils'

module Webby::Helpers
module TexImgHelper
 # Helper function to procude a complete latex document.
 def self.create_document(inner_tex, opts)
   <<-END_DOCUMENT
     \\nonstopmode
     \\documentclass{article}
     \\usepackage[#{opts[:encoding]}]{inputenc}
     #{opts[:preamble]}
     \\pagestyle{empty}
     \\begin{document}
     #{inner_tex}
     \\end{document}
   END_DOCUMENT
  end

  # The +latex_formula+ method converts a section of mathematical TeX script
  # into an image and embeds the resulting image into the page. See +tex2img+
  # for details and options.
  #
  # Example:
  #
  #    <% latex_formular( "wave_eq", :path => "images", :alt => "wave equation" ) do -%>
  #      $\psi_{tot}(x,-t_0,r) = \frac{1}{(2\pi)^2} \int\!\!\!\int
  #      \tilde\Psi_{tot}\left(k_x,\frac{c}{2}\sqrt{k_x^2 + k_r^2},r=0\right)$
  #    <% end -%>
  #
  def latex_formula(*args, &block)
    opts = args.last.instance_of?(Hash) ? args.pop : {}
    opts[:preamble] = <<-END_PREAMBLE
      \\usepackage[T1]{fontenc}
      \\usepackage{amsmath,amsfonts,amssymb,wasysym,latexsym,marvosym,txfonts}
      \\usepackage[pdftex]{color}
    END_PREAMBLE
    opts[:closure] = Proc.new do |text|
      <<-END_TEX
        {
        \\fontsize{12}{24}
        \\selectfont
        \\[
        #{text}
        \\]
        }
      END_TEX
    end
    return tex2img(*args.push(opts), &block)
  end

  # The +tikz_picture+ method converts a section of gpf/tikz TeX script
  # into an image and embeds the resulting image into the page. See +tex2img+
  # for details and options.
  #
  # Example (taken from the excelent pfg/tikz manual):
  #
  #    <% tikz_picture 'tikz_test2', :path => 'images' do -%>
  #    \draw[fill=yellow] (0,0) -- (60:.75cm) arc (60:180:.75cm);
  #    \draw(120:0.4cm) node {$\alpha$};
  #    \draw[fill=green!30] (0,0) -- (right:.75cm) arc (0:60:.75cm);
  #    \draw(30:0.5cm) node {$\beta$};
  #    \begin{scope}[shift={(60:2cm)}]
  #      \draw[fill=green!30] (0,0) -- (180:.75cm) arc (180:240:.75cm);
  #      \draw (30:-0.5cm) node {$\gamma$};
  #      \draw[fill=yellow] (0,0) -- (240:.75cm) arc (240:360:.75cm);
  #      \draw (-60:0.4cm) node {$\delta$};
  #    \end{scope}
  #    \begin{scope}[thick]
  #      \draw (60:-1cm) node[fill=white] {$E$} -- (60:3cm) node[fill=white] {$F$};
  #      \draw[red] (-2,0) node[left] {$A$} -- (3,0) node[right]{$B$};
  #      \draw[blue,shift={(60:2cm)}] (-3,0) node[left] {$C$} -- (2,0) node[right]{$D$};
  #    \end{scope}
  #    <% end -%>
  #
  def tikz_picture(*args, &block)
    opts = args.last.instance_of?(Hash) ? args.pop : {}
    opts[:preamble] = <<-END_PREAMBLE
    \\usepackage[T1]{fontenc}
    \\usepackage{lmodern}
    \\usepackage{amsmath,amsfonts,amssymb,wasysym,latexsym,marvosym,txfonts}
    \\usepackage{tikz}
    END_PREAMBLE
    opts[:closure] = Proc.new do |text|
      <<-END_TEX
      \\begin{tikzpicture}
      #{text}
      \\end{tikzpicture}
      END_TEX
    end
    return tex2img(*args.push(opts), &block)
  end

  # The +tex2img+ method converts a a section of TeX script
  # into an image and embeds the resulting image into the page. The TeX
  # engine must be installed on your system along with the ImageMagick
  # +convert+ program.
  # This function is not ment to be used as a helper directly but rather
  # as a backend for special purpose helpers. To stay backward compatible
  # it delegates a call to +latex_formular+ when used directly.
  #
  # A frontend function has to define at least the :closure option to
  # generate the inner tex code.
  #
  # A simple fronend function may look like this:
  #
  #    def my_helper(*args, &block)
  #      opts = args.last.instance_of?(Hash) ? args.pop : {}
  #      opts[:preamble] = "\\usepackage{mypackage}
  #      opts[:closure] = Proc.new do |text|
  #        <<-END_TEX
  #        \\begin{myenv}
  #        #{text}
  #        \\end{myenv}
  #        END_TEX
  #      end
  #      return tex2img(*args.push(opts), &block)
  #    end
  #    
  # The supported TeX options are the following:
  #
  #    :path         : where generated images will be stored
  #                    [default is "/"]
  #    :type         : the type of image to generate (png, jpeg, gif)
  #                    [default is png]
  #    :bg           : the background color of the image (color name,
  #                    TeX color spec, or #aabbcc). If set, the image
  #                    interpreted as an alpha channel where the black
  #                    text becomes transparent and the white background
  #                    is filled with the given color. Normally used in
  #                    combination with :fg
  #    :fg           : the foreground color of the image (color name,
  #                    TeX color spec, or #aabbcc). If set, the image
  #                    is interpreted as an alpha channel where white
  #                    background becommes transparent and the black text
  #                    is filled with teh given color.
  #    :resolution   : the desired resolution in dpi (HxV)
  #                    [default is 150x150]
  #    :encoding     : used as parameter for the inputenc package to allow
  #                    you to type other then ascii chars as without special
  #                    escaping/transcoding. [default is utf8]
  #    :preamble     : text that is included in the preable of the generated
  #                    latex document. This is used by frontend functions to
  #                    load packages or define commands.
  #    :closure      : A Proc object to generate the inner tex code to be 
  #                    included in the latex document or which is returned
  #                    in the case of @page.format == :latex.
  #                    This has to be provided by the frontend functions.
  #
  #    the following options are passed as-is to the generated <img /> tag
  #    :style    : CSS styles to apply to the <img />
  #    :class    : CSS class to apply to the <img />
  #    :id       : HTML identifier
  #    :alt      : alternate text for the <img />
  #
  # Site wide options can be given in the Sitefile. They will override the
  # helper's defaults and can be overridden by the actual helper parameters.
  #
  #    SITE.helper_options[:tex2img] = {
  #      :encoding => 'latin1',
  #      :path => "images",
  #      :resolution => "200x200"
  #    } 
  #
  def tex2img( *args, &block )
    opts = args.last.instance_of?(Hash) ? args.pop : {}
    name = args.first
    raise 'TeX graphics must have a name' if name.nil?

    text = capture_erb(&block)
    return if text.empty?

    unless opts.has_key? :closure
      Webby.deprecated "calling tex2img without a :closure options", "please use latex_formula"
      return latex_formula(name, opts, &block)
    end

    inner_tex = opts[:closure].call text

    if @page.format == :latex
      # if we should prodruce latex output, we return the text as-is,
      # protected from further textile filters
      concat_erb(_guard(inner_tex), block.binding)
      return
    end

    unless ::Webby.site.tex2img.empty?
      Webby.deprecated "site.tex2img", "please use site.helper_options[:tex2img]"
      defaults = ::Webby.site.tex2img
      path = opts.getopt(:path, defaults[:path])
      type = opts.getopt(:type, defaults[:type])
      bg   = opts.getopt(:bg, defaults[:bg])
      fg   = opts.getopt(:fg, defaults[:fg])
      res  = opts.getopt(:resolution, defaults[:resolution])
    else
      opts = ::Webby::Helpers.options_for :tex2img, opts
      path = opts[:path]
      type = opts[:type]
      bg = opts[:bg]
      fg = opts[:fg]
      res = opts[:resolution]
    end

    # fix color escaping
    fg = fg =~ %r/^[a-zA-Z]+$/ ? fg : "\"#{fg}\"" if fg
    bg = bg =~ %r/^[a-zA-Z]+$/ ? bg : "\"#{bg}\"" if bg

    # generate the image filename based on the path, graph name, and type
    # of image to generate
    image_fn = path.nil? ? name.dup : ::File.join(path, name)
    image_fn = ::File.join('', image_fn) << '.' << type

    # generate the image using convert -- but first ensure that the
    # path exists
    out_dir = ::Webby.site.output_dir
    out_file = ::File.join('..', out_dir, image_fn)
    FileUtils.mkpath(::File.join(out_dir, path)) unless path.nil?

    tex = TexImgHelper.create_document(inner_tex, opts)

    # make a temporarty directory to store all the TeX files
    pwd = Dir.pwd
    tmpdir = ::Webby::MkTemp.mktempdir('tex2img_XXXXXX')

    begin
      Dir.chdir(tmpdir)
      File.open('out.tex', 'w') {|fd| fd.puts tex}
      dev_null = test(?e, "/dev/null") ? "/dev/null" : "NUL:"

      %x[pdflatex -interaction=batchmode out.tex &> #{dev_null}]

      convert =  "\\( -density #{res} out.pdf -trim +repage \\) "
      convert << "\\( -clone 0 -negate -background #{bg} -channel A -combine \\) " if bg
      convert << "\\( -clone 0 -background #{fg} -channel A -combine \\) " if fg
      convert << "-delete 0 " if fg or bg
      convert << "-compose dst-over -composite " if fg and bg
      convert << out_file
      %x[convert #{convert} &> #{dev_null}]
    ensure
      Dir.chdir(pwd)
      FileUtils.rm_rf(tmpdir) if test(?e, tmpdir)
    end

    # generate the HTML img tag to insert back into the document
    out = "<img src=\"#{image_fn}\""
    %w[class style id alt].each do |atr|
      val = opts.getopt(atr)
      next if val.nil?
      out << " %s=\"%s\"" % [atr, val]
    end
    out << " />\n"

    # put some guards around the output (specifically for textile)
    out = _guard(out)

    concat_erb(out, block.binding)
    return
  end
end  # module TexImgHelper

if  cmd_available?(%w[pdflatex --version]) \
and cmd_available?(%w[convert --help])
  default_options = {
    :encoding => 'utf8',
    :type => 'png',
    :resolution => '150x150'
    }
  register(TexImgHelper, :tex2img => default_options)
else
  register_dummy(TexImgHelper, "You need to install a TeX distribution and ImageMagick to use the tex2img")
end

end  # module Webby::Helpers

# EOF
