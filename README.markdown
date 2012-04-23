## A flexible email spooler, as-yet unnamed.

### Please note, alpha alpha software - you have been warned!

Developed with Newman in mind, but has no dependencies on Newman. It only 
expects to be fed [Mail](https://github.com/mikel/mail) objects, which it transforms into files according to
rules.

One application would be to dump mailing-list messages in a spot where they can 
be processed and served up as an archive by another process - in other words, a 
file system queue. 

Potentially later this could be abstracted so different queue back-ends could
be developed.

Some examples (not all of this is implemented yet):

````ruby
# maildir-ish

maildir = Spool.new('/var/spool/newman')

maildir.message do |out, m|
  out.path    "#{USER}/tmp"
  out.raw     Spool.unique(m)
end
maildir.after do |files, attachments|
  files.each do |f|
    FileUtils.mv(f, "../new/#{f + ':2,'}")
  end
end

# another scenario

spool.message do |out, m|
  out.path       Spool.hash_path(m, 2)
  out.json       "#{Spool.escape(m.subject.decoded)}.json"
  out.text_part  "#{Spool.escape(m.subject.decoded)}.txt"
  out.html_part  "#{Spool.escape(m.subject.decoded)}.html"
  out.attachments 'image/*',   'images'  # save image attachments to images dir
  out.attachments :all,        'other'   # save all other attachments to other dir
end

spool.after do |files, attachments|
  manifest = File.join("#{File.basename(files[0])}.manifest", spool.base_dir)
  File.open( manifest, "w+") do |f|
    f.write files.join("\n")
    f.write attachments.join("\n")
  end
end

# writing a single message to the spooler
spool << message

# writing multiple
spool.push msg1, msg2

````