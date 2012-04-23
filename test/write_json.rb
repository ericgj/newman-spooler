require File.expand_path('../lib/spool',File.dirname(__FILE__))
require File.expand_path('helper', File.dirname(__FILE__))

describe 'Spool write json document' do
  
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
  
  describe 'simple email' do
    include MailTestHelpers
    
    subject {
      spool = Spool.new(Fixtures::TEST_OUTPUT_ROOT)
      spool.message do |out, m|
        out.path 'test_write_json'
        out.json 'test-simple.json'
      end
      spool
    }
    
    it 'should write single-part message to json file on specified path' do
      fix = Fixtures::Emails[:simple]
      subject.write_documents(fix, subject.output_rules(fix))
      assert File.exist?( 
        File.join(subject.base_dir, 
                  'test_write_json', 
                  'test-simple.json'
                 )
        )
    end

    it 'fields should match in email json' do
      fix = Fixtures::Emails[:simple]
      subject.write_documents(fix, subject.output_rules(fix))
      file = File.join(subject.base_dir, 
                  'test_write_json', 
                  'test-simple.json'
                 )
      json = MultiJson.load(File.read(file))
      
      assert_includes_mail_headers fix, json['headers']
      assert_equal_mail_headers    fix, json['headers']
      assert_equal_mail_body       fix, json['body_raw']
      assert_equal_mail_property   fix, :charset, json['charset']
    end
    
  end

  describe 'simple email with specified headers and properties' do
    include MailTestHelpers
    
    subject {
      spool = Spool.new(Fixtures::TEST_OUTPUT_ROOT)
      spool.message do |out, m|
        out.path 'test_write_json'
        out.json 'test-simple-scrubbed.json', 
          :headers => ['From', 'Subject'],
          :properties => ['body']
      end
      spool
    }
    
    it 'should write single-part message to json file on specified path' do
      fix = Fixtures::Emails[:simple]
      subject.write_documents(fix, subject.output_rules(fix))
      assert File.exist?( 
        File.join(subject.base_dir, 
                  'test_write_json', 
                  'test-simple-scrubbed.json'
                 )
        )
    end

    it 'selected fields should match in email json' do
      fix = Fixtures::Emails[:simple]
      subject.write_documents(fix, subject.output_rules(fix))
      file = File.join(subject.base_dir, 
                  'test_write_json', 
                  'test-simple-scrubbed.json'
                 )
      json = MultiJson.load(File.read(file))
      
      assert_equal_mail_headers    fix, json['headers']
      assert_equal_mail_body       fix, json['body']
      assert_equal_mail_property   fix, :charset, json['charset']
    end
    
  end
  
  describe 'multipart email' do
    include MailTestHelpers
    
    subject {
      spool = Spool.new(Fixtures::TEST_OUTPUT_ROOT)
      spool.message do |out, m|
        out.path 'test_write_json'
        out.json 'test-multipart.json', :mime_types => ['text/plain', 'text/html']
      end
      spool
    }
  
    it 'should write single-part message to json file on specified path' do
      fix = Fixtures::Emails[:multipart]
      subject.write_documents(fix, subject.output_rules(fix))
      assert File.exist?( 
        File.join(subject.base_dir, 
                  'test_write_json', 
                  'test-multipart.json'
                 )
        )
    end

    it 'fields should match in email json' do
      fix = Fixtures::Emails[:multipart]
      subject.write_documents(fix, subject.output_rules(fix))
      file = File.join(subject.base_dir, 
                  'test_write_json', 
                  'test-multipart.json'
                 )
      json = MultiJson.load(File.read(file))
      
      assert_includes_mail_headers fix, json['headers']
      assert_equal_mail_headers    fix, json['headers']
      assert_equal_mail_property   fix, :charset, json['charset']
      
      assert_includes_mail_part    'text/plain', json['multipart_body']
      assert_includes_mail_part    'text/html',  json['multipart_body']
      assert_equal_mail_part_body  fix, 'text/plain', json['multipart_body']
      assert_equal_mail_part_body  fix, 'text/html',  json['multipart_body']
      
    end
  
  end
  
end