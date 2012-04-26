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

  describe 'parameters' do
  
    before do
      FileUtils.rm_f("#{Fixtures::TEST_OUTPUT_ROOT}/test_after")
    end
    
    subject {
      spool = Spool.new(Fixtures::TEST_OUTPUT_ROOT)
      spool.message do |out, m|
        out.path 'test_after'
        out.raw  'raw.eml'
        out.body 'output.txt',  :part => :text
        out.body 'output.html', :part => :html
        out.json 'output.json', :properties => [:body]
        out.attachments :all, 'attachments'
      end
      spool    
    }
    
    [:simple, :multipart, :with_attachments].each do |fix_key|
      it "should include raw, text, html, json filenames for #{fix_key} case" do
        fix = Fixtures::Emails[fix_key]
        subject.after do |files, attachments, _|
          puts "---------- after #{fix_key}"
          puts files.join("\n")
          puts attachments.join("\n")
          assert_equal 4, files.size
          assert_equal fix.attachments.size, attachments.size
          %w[raw.eml output.txt output.html output.json].each do |f|
            assert_includes files, 
              "#{Fixtures::TEST_OUTPUT_ROOT}/test_after/#{f}"
          end
        end
        subject << fix
      end
    end
    
    it 'should include all attachment filenames into after proc' do
      fix_key = :with_attachments
      fix = Fixtures::Emails[fix_key]
      subject.after do |files, attachments, _|
        puts "---------- after #{fix_key}"
        puts files.join("\n")
        puts attachments.join("\n")
        assert_equal 4, files.size
        assert_equal fix.attachments.size, attachments.size
        fix.attachments.map(&:filename).each do |f|
          assert_includes attachments, 
            "#{Fixtures::TEST_OUTPUT_ROOT}/test_after/attachments/#{f}"
        end
      end
      subject << fix
    end
    
  end
  
end

end

  