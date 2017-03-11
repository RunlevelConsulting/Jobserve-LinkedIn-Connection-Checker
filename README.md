# Jobserve-LinkedIn Connection Checker

## Overview

Recruitment agents tend to be assigned to focus on specific industries. A great way to ensure you're never out of work is to create a connection to these agents. That way, the next time you're looking for a new role, you can simply broadcast this fact to the individuals best-placed to assist.

This tool allows you to input a specific search from Jobserve.com, extract the name of the recruitment agent that posted each vacancy and compare it to a list of your LinkedIn connections. If you're not connected, you can then add them.

When I approach the end of a contract, I simply post an update on LinkedIn that I'll soon be back on the market and it goes directly out to the connections I've amassed. I've always found work very quickly as a result of adding LinkedIn connections in this way - this script is simply a part-automation of an otherwise very manual process.

This tool also has uses for jobseekers as a method of receiving a condensed view of what roles are available. It may also be useful for recruitment agents to keep an eye on the market - and their competition!
<br><br>
## Options

```bash
$ ./jobserve.sh --help

Usage:   ./jobserve.sh --search-id=<SEARCH_ID>

Mandatory Flags:
         --search-id=                   The Jobserve.com Search ID

         You can find the SEARCH_ID by going to Jobserve.com, filling in your job search
         criteria and hitting Search. The next URL will be:
         https://www.jobserve.com/gb/en/JobSearch.aspx?shid=<SEARCH_ID>

Optional Flags:
         --li-file=/path/to/file.csv    Exorted LinkedIn Connections CSV file path
         --only-connected               Only output jobs from LinkedIn connections
         --only-unconnected             Only output jobs from LinkedIn strangers
         --show-jobtitle                Show the Job Title of the posting
         --show-company                 Show the name of the recruitment agency
         --unique-names                 Supress multiple jobs from the same agent
         --output-file=/path/to/file    Send all output to specified file
         -?                             Show Instructions
         --help                         Show Instructions

         Export LinkedIn connections at: https://www.linkedin.com/people/export-settings
```
<br>
## Example Usage

 1. **Obtain Jobserve.com Search ID:**
   - Go to Jobserve.com, fill in your search criteria and hit 'Search'. The next URL will be: https://www.jobserve.com/gb/en/JobSearch.aspx?shid=**SEARCH_ID**
 2. **Export LinkedIn Connections:**
   - Browse to https://www.linkedin.com/people/export-settings and download a **CSV** copy of your LinkedIn Connections.
 
```bash
$ ./jobserve.sh --search-id=7DC44B1B4201643D7F --show-company --show-jobtitle --li-file=~/Downloads/linkedin_connections_export_microsoft_outlook.csv --unique-names

---------- Gathering Job List ---------
Gathering Job IDs, 47 remaining...

------------- Job Details -------------
http://www.jobserve.com/EkaV3  |  [UNCONNECTED]  |  Penny Speight  |  Enterprise storage Consultant - Cisco UCS  |  Ifftner Solutions
http://www.jobserve.com/EkaTs  |  [CONNECTED ✔]  |  Gary Hargreaves  |  Linux Consultant/Engineer  |  X4 Group
http://www.jobserve.com/EkaR3  |  [CONNECTED ✔]  |  Alex Friedman  |  Linux Consultant  |  Computappoint
http://www.jobserve.com/EkaLf  |  [CONNECTED ✔]  |  Jonathan Horwitz  |  Linux Devops Engineer (Puppet/MySQL/PHP)  |  Harvey Nash IT Recruitment UK
http://www.jobserve.com/EkZ4I  |  [UNCONNECTED]  |  George Pollard  |  Senior UNIX/Linux Engineer  |  Nicoll Curtin Technology
http://www.jobserve.com/EkLHR  |  [UNCONNECTED]  |  Graeme McNaull  |  DevOps Build Engineer  |  Harvey Nash Plc
http://www.jobserve.com/EkZq9  |  [CONNECTED ✔]  |  Jack Broughton  |  DevOps Engineer - AWS - Linux - Wintel  |  eSynergy Solutions
http://www.jobserve.com/EkWns  |  [UNCONNECTED]  |  Christian White  |  Infrastructure DevOps Engineer - Contract - £500 - Linux  |  onezeero
[...]

--------------- Finished --------------
```
> **Tip:** Use the **--help** or **-?** flags to see the full list of available flags.

<br>
## Other Information

This script has been tested as far and wide as my **Ubuntu 14.04** machine.
Please fork and contribute if you find any bugs.

Jobserve does offer an API, however you have to apply to them stating your explicit reasons for requesting access, furthermore you're also limited by the number of requests that can be made. This script gets past both of those issues. Sorry Jobserve.
