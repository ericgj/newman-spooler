require File.expand_path('../lib/spool',File.dirname(__FILE__))
require File.expand_path('helper', File.dirname(__FILE__))

describe 'Spool::Builder#[]' do

  module Fixtures
    Emails = {
      
      :simple => DummyEmail.new {
         self.to = 'stimpy'
         self.from = 'ren'
         self.subject = 'hello old friend!'
         self.text_part = 'Oh my darling, my little cucaracha, I kiss your sleep encrusted eye of morn. I caress your large bublous nose. Oh let us join lip in one final sweet exchange of saliva.'
         self.html_part ='<html><body><p><b>Oh my darling, my little cucaracha</b>, I kiss your sleep encrusted eye of morn. I caress your large bublous nose. Oh let us join lip in one final sweet exchange of saliva.</p></body></html>'
      }
    }
  end
  
  subject do
    Spool::Builder.new do |out, m|
      out.path       "test"
      out.text_part  "#{m.subject}.txt"
      out.html_part  "html/#{m.subject}.html"
      out.attachments 'image/jpg', 'images'  # save image attachments to images dir
      out.attachments :all,        'other'   # save all other attachments to other dir      
    end
  end
  
  it 'should return text_part file as specified with path' do
    fix = Fixtures::Emails[:simple]
    out = subject[fix]
    assert_equal "test/#{fix.subject}.txt", out.text_part_path
  end

  it 'should return html_part file as specified with path' do
    fix = Fixtures::Emails[:simple]
    out = subject[fix]
    assert_equal "test/html/#{fix.subject}.html", out.html_part_path
  end
  
  it 'should resolve attachment paths as specified' do
    fix = Fixtures::Emails[:simple]
    out = subject[fix]
    assert_equal "test/images", out.attachments_path('image/jpg')
    assert_equal "test/other", out.attachments_path(:all)
    assert_equal "test/other", out.attachments_path
  end
  
end