require File.expand_path('../lib/spool',File.dirname(__FILE__))
require File.expand_path('helper', File.dirname(__FILE__))

module SpoolWriteRawTests

describe 'Spool#write_raw' do
  
  module Fixtures
  
    TEST_OUTPUT_ROOT = File.expand_path('output', File.dirname(__FILE__))
    
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
      }
    }
  end
  
  # Todo remove output files before each test
  
  describe 'without scrubbing' do
  
    before do 
      FileUtils.rm_f("#{Fixtures::TEST_OUTPUT_ROOT}/test_write_raw/without_scrubbing")
    end
    
    subject {
      spool = Spool.new(Fixtures::TEST_OUTPUT_ROOT)
      spool.message do |out, m|
        out.path 'test_write_raw/without_scrubbing'
        out.raw  'test-without-scrubbing.eml'
      end
      spool
    }
    
    it 'should write raw message without attachments to specified path' do
      fix = Fixtures::Emails[:multipart]
      subject.write_documents(fix, subject.output_rules(fix))
      assert File.exist?( 
        File.join(subject.base_dir, 
                  'test_write_raw/without_scrubbing', 
                  'test-without-scrubbing.eml'
                 )
        )
    end
  end
  
  describe 'with scrubbing, body only' do
  
    before do 
      FileUtils.rm_f("#{Fixtures::TEST_OUTPUT_ROOT}/test_write_raw/with_scrubbing")
    end
    
    subject {
      spool = Spool.new(Fixtures::TEST_OUTPUT_ROOT)
      spool.message do |out, m|
        out.path 'test_write_raw/with_scrubbing'
        out.raw  'test-with-scrubbing-body.eml', 
                   :headers => ['From', 'Subject'],
                   :properties => ['body_raw']
      end
      spool
    }
    
    it 'should write scrubbed message to specified path' do
      fix = Fixtures::Emails[:simple]
      subject.write_documents(fix, subject.output_rules(fix))
      assert File.exist?( 
        exp_file = \
          File.join(subject.base_dir, 
                  'test_write_raw/with_scrubbing', 
                  'test-with-scrubbing-body.eml'
                 )
        ), "#{exp_file} was not created"
    end
  end
  
  describe 'with scrubbing, parts specified' do

    before do 
      FileUtils.rm_f("#{Fixtures::TEST_OUTPUT_ROOT}/test_write_raw/with_scrubbing_html_only")
    end
  
    subject {
      spool = Spool.new(Fixtures::TEST_OUTPUT_ROOT)
      spool.message do |out, m|
        out.path 'test_write_raw/with_scrubbing_html_only'
        out.raw  'test-with-scrubbing-html.eml', 
                   :headers => ['From', 'Subject', 'Content-Type'],
                   :properties => ['body_raw', 'charset'],
                   :mime_types => ['text/html']
      end
      spool
    }
    
    it 'should write scrubbed message to specified path' do
      fix = Fixtures::Emails[:multipart]
      subject.write_documents(fix, subject.output_rules(fix))
      assert File.exist?( 
        File.join(subject.base_dir, 
                  'test_write_raw/with_scrubbing_html_only', 
                  'test-with-scrubbing-html.eml'
                 )
        )
    end  
  end
  
end

end