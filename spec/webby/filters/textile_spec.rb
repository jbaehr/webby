
require ::File.expand_path(
    ::File.join(::File.dirname(__FILE__), %w[.. .. spec_helper]))

# ---------------------------------------------------------------------------
describe 'Webby::Filters::Textile' do

  it 'should regsiter the textile filter handler' do
    Webby::Filters._handlers['textile'].should_not be_nil
  end

  if try_require('redcloth')

    it 'processes textile markup into HTML' do
      cursor = mock("Cursor")
      cursor.stub!(:current_options).and_return({})
      cursor.stub!(:remaining_filters).and_return([])
      input = "p(foo). this is a paragraph of text"
      output = Webby::Filters._handlers['textile'].processor.call(input, cursor)

      output.should == %q{<p class="foo">this is a paragraph of text</p>}
    end

  else

    it 'raises an error when RedCloth is used but not installed' do
      input = "p(foo). this is a paragraph of text"
      lambda {Webby::Filters._handlers['textile'].processor.call(input)}.should raise_error(Webby::Error, "'RedCloth' must be installed to use the textile filter")
    end

  end
end

# EOF
