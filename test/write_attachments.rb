require File.expand_path('../lib/spool',File.dirname(__FILE__))
require File.expand_path('helper', File.dirname(__FILE__))

module SpoolWriteAttachmentsTests

describe 'Spool#write_attachments' do
  
  module Fixtures
  
    TEST_OUTPUT_ROOT   = File.expand_path('output', File.dirname(__FILE__))
    TEST_FIXTURES_ROOT = File.expand_path('fixtures', File.dirname(__FILE__))
    
    Emails = {  
      :pdf   => "#{TEST_FIXTURES_ROOT}/test_pdf.eml",
      :multi => "#{TEST_FIXTURES_ROOT}/test_multi.eml"
    }
  end
  
  describe "all attachments saved to same location" do
  
    before do 
      FileUtils.rm_f("#{Fixtures::TEST_OUTPUT_ROOT}/test_write_attachments/all")
    end
    
    subject {
      spool = Spool.new(Fixtures::TEST_OUTPUT_ROOT)
      spool.message do |out, m|
        out.path 'test_write_attachments'
        out.attachments :all, 'all'
      end
      spool    
    }
    
    [:pdf, :multi].each do |fix_key|
      it 'should save files named in email' do
         fix = ::Mail::Message.new(File.read(Fixtures::Emails[fix_key]))
         fix_filenames = fix.attachments.map(&:filename)
         subject.write_attachments(fix, subject.output_rules(fix))
         fix_filenames.each do |file|
           assert File.exist?( 
              exp_file = \
              File.join(subject.base_dir, 
                        'test_write_attachments/all', 
                        file
                       )
              ), "#{exp_file} was not created"       
         end
      end
    end
    
  end
  
  
  describe "attachments saved to different locations with default" do

    before do 
      FileUtils.rm_f("#{Fixtures::TEST_OUTPUT_ROOT}/test_write_attachments/pdf")
      FileUtils.rm_f("#{Fixtures::TEST_OUTPUT_ROOT}/test_write_attachments/gif")
      FileUtils.rm_f("#{Fixtures::TEST_OUTPUT_ROOT}/test_write_attachments/other")
    end
    
    subject {
      spool = Spool.new(Fixtures::TEST_OUTPUT_ROOT)
      spool.message do |out, m|
        out.path 'test_write_attachments'
        out.attachments :all, 'other'
        out.attachments 'image/gif', 'gif'
        out.attachments 'application/pdf', 'pdf'
      end
      spool    
    }
    
    [:pdf, :multi].each do |fix_key|
      it 'should save files named in email according to specs' do
         fix = ::Mail::Message.new(File.read(Fixtures::Emails[fix_key]))
         fix_filenames = fix.attachments.map(&:filename)
         subject.write_attachments(fix, subject.output_rules(fix))
         fix_filenames.each do |file|
           subdir = case file
                    when /\.pdf$/i; 'pdf'
                    when /\.gif$/i; 'gif'
                    else;           'other'
                    end
           assert File.exist?( 
              exp_file = \
              File.join(subject.base_dir, 
                        "test_write_attachments/#{subdir}", 
                        file
                       )
              ), "#{exp_file} was not created"       
         end
      end
    end

  end
  
end

end