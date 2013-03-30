# Version 3.1 March 2013
# Changed reading of files from binary back to text.
# Added backup folder "...just in case"
# Added fix for Vasont extract Maps
# Added .dita files to script
# Changed parsing of title to xpath via Nokogiri
# Added htmlentities dependency to fix those title with HTML characters
# 3.1 version:
# Added doctype to XSLT processing
# Added locktitle removal in cleanup (probably leftover from prior versions of the script on some internal maps)
# 3.2 version:
# Added options for bookmap as well as plain map
# Added option for navtitle as an element (dita 1.2) or as an attribute (dita 1.1)
 
 
require 'fileutils'
require 'nokogiri'
require 'htmlentities'
require 'optparse'
@coder = HTMLEntities.new

# -- Option parser -- #

options = {}

optparse = OptionParser.new do|opts|
  # Set a banner, displayed at the top
  # of the help screen.
  opts.banner = "\nUsage: ruby add_navtitle_v3.rb [options] <directory>"

# Define the options, and what they do

  options[:ditamap] = true
  opts.on( '-d', '--ditamap', 'Write output map as a plain ditamap (default)' ) do
    options[:ditamap] = true
  end

  options[:bookmap] = false
  opts.on( '-b', '--bookmap', 'Write output map as a bookmap' ) do
    options[:bookmap] = true
    options[:ditamap] = false
  end

  options[:attribute] = true
  opts.on( '-a', '--attribute', 'Write navtitle as a topicref attribute (DITA 1.1) (default)' ) do
    options[:attribute] = true
  end

  options[:element] = false
  opts.on( '-e', '--element', 'Write navtitle as an element in the map. (DITA 1.2)' ) do
    options[:element] = true
    options[:attribute] = false
  end

   opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    puts "\nBy default, if no options are specified, a standard ditamap (not bookmap) is created with all navtitles using the DITA 1.1 topicref attribute.\n
Note: You may have to use a path in front of the add_navtitle script and the directory file depending on where items are located on your computer.\n\n"

    exit
  end
end

# ----- CODE ---- #

 
 
def cleanup(xml)
  if xml.match(/locktitle/)
    xml.gsub!(/locktitle.*\"/, "")
  end
     if xml.match(/\/>/)
       xml.gsub!(/\/>/, "")
       @autoclose = "true"
     else
       xml.gsub!(/\>/, "")
       @autoclose = "false"
     end
end
 

optparse.parse!
 
directorypath = ARGV[0]
if directorypath.nil?
  directorypath = Dir.pwd
end
 
filelist = Dir.entries(directorypath).join(' ')
filelist = filelist.split(' ').grep(/\.ditamap/)
 
puts "\nFile Directory: #{directorypath}\n\n"
@missing_files = Array.new
count = 0
 
 
 
Dir::mkdir("#{directorypath}/backup_ditamaps") unless File.exists?("#{directorypath}/backup_ditamaps")
 
puts "Maps in Directory:\n"
filelist.each do |the_map|
puts "#{the_map}\n"
input_dir = "#{directorypath}/#{the_map}"
output_dir = "#{directorypath}/backup_ditamaps/"
FileUtils.cp input_dir, output_dir
end
 
puts "\n\n"
 
 
 
filelist.each do |a_ditamap|
 
  fileName = "#{directorypath}/#{a_ditamap}"
  f = File.open("#{fileName}", 'r')
  ditamp_file_utf = f.read
  f.close
 
    add_returns = ditamp_file_utf.to_s.gsub(/>\s*?</, ">_split_<")
 
  @mapcontents = add_returns.split("_split_")   # store contents into an array
 
  @touched_lines = 0
  @not_touched = 0
 
  @mapcontents.each_with_index do |mapline, index|
    @autoclose = "false"
 
 
   if mapline.match(/(\.xml|\.dita)/) and mapline.match(/\<topicref/)           # Look only for .xml or .dita files, ignore other lines in array
      if mapline.match(/navtitle/)      # if title already exists do nothing!
        @not_touched +=1
     else
       replacement_line = mapline
       cleanup(replacement_line)
       xml_replacement_line = Nokogiri::XML(mapline)
       x_href = xml_replacement_line.xpath('string(//topicref/@href)').to_s
       search_line = "#{directorypath}/#{x_href}"
 
 
	 begin 
     	filecontents =  File.read(search_line)    # Open file up to read title
      file_xml_contents = Nokogiri::XML(filecontents)    # Parse XML with Xpath
      title = file_xml_contents.xpath('//title/text()').first.to_s
      title = @coder.decode(title)
      title.strip! if !title.nil?
   if @autoclose.match("false")
     if options[:attribute]
     	  @mapcontents[index] = "#{replacement_line} navtitle=\"#{title}\" locktitle=\"yes\" >"   # put back into array
     elsif options[:element]
        @mapcontents[index] = "#{replacement_line} locktitle=\"yes\"><topicmeta><navtitle>#{title}</navtitle></topicmeta>"   # put back into array
     end
   elsif @autoclose.match("true")
     if options[:ditamap]
        @mapcontents[index] = "#{replacement_line} navtitle=\"#{title}\" locktitle=\"yes\" \/>"
     elsif options[:bookmap]
        @mapcontents[index] = "#{replacement_line} locktitle=\"yes\"><topicmeta><navtitle>#{title}</navtitle></topicmeta></topicref>"   # put back into array
     end
   end
 
       @touched_lines +=1
       @autoclose = "false"
     rescue Exception
     	@missing_files << "#{search_line}\n\r"
      @mapcontents[index] = "#{replacement_line}>"
     end
   end # end of mapline.match /navtitle/
   end # end of mapline.match.xml
  end # end of mapcontents.each
 
  # Write out file here
  filecontents = @mapcontents.join.to_s
  @mapcontents.clear

  if options[:ditamap]
  xsl ="<xsl:stylesheet version=\"1.0\" xmlns:xsl=\"http://www.w3.org/1999/XSL/Transform\">
  	  <xsl:output method=\"xml\" encoding=\"UTF-8\" indent=\"yes\"
        doctype-public=\"-//OASIS//DTD DITA Map//EN\"
        doctype-system=\"../dtd/technicalContent/dtd/map.dtd\" />
  	  <xsl:strip-space elements=\"*\"/>
  	  <xsl:template match=\"/\">
  	    <xsl:copy-of select=\".\"/>
  	  </xsl:template>
  	</xsl:stylesheet>"
  elsif options[:bookmap]
    xsl ="<xsl:stylesheet version=\"1.0\" xmlns:xsl=\"http://www.w3.org/1999/XSL/Transform\">
     	  <xsl:output method=\"xml\" encoding=\"UTF-8\" indent=\"yes\"
           doctype-public=\"-//OASIS//DTD DITA BookMap//EN\"
           doctype-system=\"..bookmap/dtd/bookmap.dtd\" />
     	  <xsl:strip-space elements=\"*\"/>
     	  <xsl:template match=\"/\">
     	    <xsl:copy-of select=\".\"/>
     	  </xsl:template>
     	</xsl:stylesheet>"
  end
 
      doc  = Nokogiri::XML(filecontents)
      xslt = Nokogiri::XSLT(xsl)
      out  = xslt.transform(doc)
 
      filecontents= out.to_xml
 
        File.open(fileName, 'w+') {|f| f.write(filecontents) }
        puts "ditamap: #{fileName}\n added navtitle to: #{@touched_lines} topics \n Already had navtitles in: #{@not_touched} topics (not modified). \n\n"
        touched_lines = 0
  end
 
 
if !@missing_files.empty?
puts "\n\nMissing XML Files: #{@missing_files.count}\n#{@missing_files.join.to_s}"
end