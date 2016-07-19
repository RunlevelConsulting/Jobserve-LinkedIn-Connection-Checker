# S3 Bucket Search And Grep

## Overview

Imaginatively titled, **S3 Bucket Search And Grep** takes a public S3 Bucket URL as a parameter value and gathers a full list of files and subdirectories within that bucket, outputting the details into a CSV file. It then allows you to select a subdirectory to gather a file list for, again output to another CSV file.

Furthermore, the **--grep** flag allows you to search for a string within files in a directory of your choice.  This is perhaps useful for active reconnaissance but likely serves multiple purposes.

As each directory's data is downloaded, a CSV of it's contents is automatically created and can be then used as a cache file for future searches to avoid having to re-download data on (what may be) thousands of files in a bucket.
<br><br>
## Options

```bash
Usage:     ./s3bucket.sh --url=http://mysite.s3.amazonaws.com --use-cache --grep

Mandatory Flags:
           --url=               The URL of the S3 Bucket

Optional Flags:
           --grep               Search for string within files
           --use-cache          Use S3 Bucket list from a previous run (may not be up-to-date but will be much faster)
           -?                   Show Instructions
           --help               Show Instructions
```
<br>
## Example Usage

In this example, we search an S3 Bucket, and opt to gather the file list of the **admin** subdirectory. 
Once downloaded, we then do a search for the string "**scripting**" within the **txt** and **html** files in that subdirectory. The files that match and do not match are output on screen and into a final CSV file.
```
$ ./s3bucket.sh --url=http://s3.amazonaws.com/searchandgrep --use-cache --grep

Info: This script will use a cache file to generate top-level and subdirectory data if the respective cache files exist. Otherwise, it will download new data.

Gathering Top-Level Contents...
Analysing Top-Level Contents...

--------------------------------------------

[0] /
[1] admin
[2] photos
[3] scripts
[4] uploads

Please input the NUMBER of the directory you wish to search: 1

--------------------------------------------

Gathering admin Contents...
Analysing admin Contents...

--------------------------------------------

Below is a list of file extensions and the number of occurrence of each extension in this directory:
      1 bmp
      2 png
      3 html
      3 jpg
      5 txt

What string are you looking for? (e.g: password): scripting
Look for "scripting" in which file extensions? (comma-separated, eg: json, html, cfg): txt, html

Searching...
[1/8] ✔  http://s3.amazonaws.com/searchandgrep/admin/index.html
[2/8] ✘  http://s3.amazonaws.com/searchandgrep/admin/login.html
[3/8] ✘  http://s3.amazonaws.com/searchandgrep/admin/myfile1.txt
[4/8] ✘  http://s3.amazonaws.com/searchandgrep/admin/myfile2.txt
[5/8] ✔  http://s3.amazonaws.com/searchandgrep/admin/myfile3.txt
[6/8] ✘  http://s3.amazonaws.com/searchandgrep/admin/files/file.txt
[7/8] ✔  http://s3.amazonaws.com/searchandgrep/admin/files/private/notes.txt
[8/8] ✘  http://s3.amazonaws.com/searchandgrep/admin/page.html

--------------------------------------------

Output: result.https3amazonawscomsearchandgrep.admin.search.csv

--------------------------------------------
```
<br>
The above example produces **3** files:
 
 - **result.https3amazonawscomsearchandgrep.csv** - A list of files and directories at the top level
 - **result.https3amazonawscomsearchandgrep.admin.csv** - A list of files and directories in the **admin** subdirectory.
 - **result.https3amazonawscomsearchandgrep.admin.search.csv** - A list of files searched through for a specific string with a ✔ or ✘ to indicate a match or no-match.

The first two CSV files can later be used as cache files with the **--use-cache** flag to speed up future searches.*

> **Tip:** Use the **--help** or **-?** flags to see the full list of available flags.

<br>
##Other Information

This script has been tested as far and wide as my **Ubuntu 16.04** machine.
Please fork and contribute if you find any bugs.
