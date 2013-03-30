Script: add_navtitle.rb

Required: Ruby
          http://rubyinstaller.org/downloads/     (for Windows) 
          http://www.ruby-lang.org/en/downloads/  (for Linux, Mac OS X, etc.)
          
Note: Ruby is already installed on \\pavas01.lsi.com

About this Script:
With the testing of trying to move DITA structured topics to local computers, using the extract map instead of extracting individual topics is more enticing. However, when you extract a map and open it in FrameMaker, unless you have manually added the navtitle attribute to each item in a map, then you will only see the v1234.xml names. When a navtitle is added to each item in a map, you see that title instead of the filename. You can individually add navtitle to each topic in the map via Vasont, but I find that a bit tedious. 

This script will read the current working directory (where you are) and read in each map, make a backup copy of the map, open each topic listed in the map, pull in the title from each topic, then rewrite each map with the navtitle. 

That rewritten map has to be loaded back into Vasont using the primary load method. 


Syntax: 

ruby add_navtitle.rb    <-- Processes all maps in the current directory you are in.

or 

ruby add_navtitle.rb <directory> 


A directory called ditamap_backup is created in the directory where the maps are located. This is done in case something goes wrong with the script. The original untouched ditamaps are available in that directory. If you do not need the maps after the add_navtitle script has completed, you can delete the folder. 



Change History:
===============

(versioning information is available within the script itself. You need to open the script in a text editor to read the versioning information). 

2.0 December 2012- Complete rewrite of script.
2.1 March 2012 - Changed the way files are read in and created a backup of the map in case it is needed.