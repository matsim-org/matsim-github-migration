I (mrieser) tried creating a bash script to convert the current MATSim SVN repository to a GIT repository.
To use the script:
* download the two attached files (migration.sh, dumpInitFixed)
* make sure you have SVN 1.7 or later. If you use SVN 1.8, see the note on line 106 (comment out line 105, and activate line 107). The script uses functionality not available in SVN 1.6.
* Specify the two directories at the top of the script. The paths must be absolute.
* If you are not on a mac, modify line 25 (see comment on line 24)
* run migration.sh and wait 

On my two-year old MacMini (with fusion drive == high speed writes/reads), the process took about 10 hours, without getting the initial svn backup. It resulted in a clean GIT repository having all the branches and tags from the SVN repo.
The script removes all zip and jar files, also in playgrounds! For such files, another solution should be found anyway (like a custom Maven-Repository to upload those files to).

The script also removes most files known to be larger than 10MB, as well as personal input or output directories (except the test/input directories), as test data should not be part of a code repository.
