require File.expand_path('../lib/spool',File.dirname(__FILE__))
require File.expand_path('helper', File.dirname(__FILE__))

module SpoolAfterTests

describe 'Spool#after' do
  
  module Fixtures
  
    TEST_OUTPUT_ROOT   = File.expand_path('output', File.dirname(__FILE__))
    TEST_FIXTURES_ROOT = File.expand_path('fixtures', File.dirname(__FILE__))
    
    Emails = {
      
      :simple => ::Mail::Message.new {
         to       'stimpy@example.com'
         from     'ren@example.com'
         subject  'hello old friend!'
         body     'Oh my darling, my little cucaracha, I kiss your sleep encrusted eye of morn. I caress your large bublous nose. Oh let us join lip in one final sweet exchange of saliva.'
         },
         
      :multipart => ::Mail::Message.new {
         to       'stimpy@example.com'
         from     'ren@example.com'
         subject  'hello old friend!'
         body     'Oh my darling, my little cucaracha, I kiss your sleep encrusted eye of morn. I caress your large bublous nose. Oh let us join lip in one final sweet exchange of saliva.'
         add_part ::Mail::Part.new {
           content_type 'text/html'
           body '<html><body><p><b>Oh my darling, my little cucaracha</b>, I kiss your sleep encrusted eye of morn. I caress your large bublous nose. Oh let us join lip in one final sweet exchange of saliva.</p></body></html>'
         }
       },
       
       :with_attachments => ::Mail::Message.new( 
                              File.read("#{TEST_FIXTURES_ROOT}/test_multi.eml")
                            )
    }
  
  end

  describe 'output raw, text, html, json, and attachments' do
  
    subject {
      spool = Spool.new(Fixtures::TEST_OUTPUT_ROOT)
      spool.message do |out, m|
        out.path 'test_after'
        out.raw  'raw.eml'
        out.text_part 'output.txt'
        out.html_part 'output.html'
        out.json 'output.json'
        out.attachments :all, 'attachments'
      end
      spool    
    }
    
    it 'should pass raw and json filenames into after proc for simple case' do
      fix = Fixtures::Emails[:simple]
      subject.after do |files, attachments, _|
        puts files.join("\n")
        assert_equal 2, files.size
        assert_equal 0, attachments.size
        assert_includes files, "#{Fixtures::TEST_OUTPUT_ROOT}/test_after/raw.eml"
        assert_includes files, "#{Fixtures::TEST_OUTPUT_ROOT}/test_after/output.json"
      end
      subject << fix
    end
    
  end
  
end

end

  