mrieser says:

I tried creating a bash script to convert the current MATSim SVN repository to a GIT repository.
To use the script:
* download the two attached files (migration.sh, dumpInitFixed)
* make sure you have SVN 1.7 or later. If you use SVN 1.8, see the note on line 64 (comment out line 63, and activate line 65). The script uses functionality not available in SVN 1.6.
* Specify the two directories at the top of the script. The paths must be absolute.
* If you are not on a mac, modify line 25 (see comment on line 24)
* run migration.sh and wait 

On my one-year old MacMini (with fusion drive == high speed writes/reads), the process took about 10 hours, without getting the initial svn backup. It resulted in a clean GIT repository having all the branches and tags from the SVN repo.
The script removes all zip and jar files, also in playgrounds! For such files, another solution should be found anyway (like a custom Maven-Repository to upload those files to).
