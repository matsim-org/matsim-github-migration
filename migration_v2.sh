#!/bin/bash
#

# WORKDIR: the directory where this script should write data to. Must be /absolute/ path.
WORKDIR=/data/matsim/mrieser/git/data

# SUPPORTDIR: the directory containing the file "dumpInitFixed", see below. Must be /absolute/ path.
SUPPORTDIR=/data/matsim/mrieser/git

### The Support Dir should contain the following file:
### -dumpInitFixed: contains the first 3 revisions with manual corrections (you can
### compare it to dumpInit created below) to handle the file paths we'll modify later

echo "=== getting off-line backup of svn-repository"
date

cd $WORKDIR

rsync -av svn.code.sf.net::p/matsim/source/* repository.bak/

echo "=== extracting authors from svn-repository"
date

# on MAC OS X, use "grep -e", on other platforms "grep -P"
svn log --xml file://$WORKDIR/repository.bak | grep -e "^<author" | sort -u | perl -pe 's/<author>(.*?)<\/author>/$1 = $1 <$1\@users.sf.net>/' > authors.txt

echo "=== dumping svn repository"
date

svnadmin dump -r0:2 repository.bak  > dumpInit

svnadmin dump -r3:HEAD --incremental repository.bak  > dumpCode

echo "=== filtering svn dump"
date

# "--pattern" requires SVN 1.7+, and for some reason the simple paths are interpreted different when --pattern is used, thus make two calls
svndumpfilter exclude \
	deqsim \
	matsim/trunk/libs \
	matsim/trunk/src/playground/wrashid/test/test6/deq_events.txt \
	matsim/trunk/src2/archive/org \
	matsim/trunk/src2/archive/playground/arvidDaniel \
	matsim/trunk/src2/archive/playground/david \
	matsim/trunk/src2/archive/playground/dgrether \
	matsim/trunk/src2/archive/teach \
	matsim/trunk/src2/experimental \
	matsim/trunk/src/playground/fabrice/primloc/resources/zh_costs.txt \
	contrib/trunk/matsim4urbansim/v7.5.0/EPSG.data \
	contrib/trunk/socnetsim/examples/siouxfalls-socialnetwork/Siouxfalls_facilities.xml \
	contrib/trunk/socnetsim/examples/siouxfalls-socialnetwork/Siouxfalls_population.xml \
	playgrounds/trunk/dhosse/input \
	playgrounds/trunk/dhosse/nullaccessibility_indicators.csv \
	playgrounds/trunk/dhosse/nullbikeAccessibility_cellsize_100.0.txt \
	playgrounds/trunk/dhosse/nullparcels.csv \
	playgrounds/trunk/dhosse/test/linkLengthComparison \
	playgrounds/trunk/dhosse/test/linkLengthComparison.txt \
	playgrounds/trunk/fabrice/primloc/resources \
	playgrounds/trunk/fhuelsmann/test/input/playground/fhuelsmann/emissions/MainTest/test1/visumnetzlink.txt \
	playgrounds/trunk/fuerbas/src/main/java/matrix/BetweennessSchweiz \
	playgrounds/trunk/fuerbas/src/main/java/matrix/BetweennessSchweiz_ \
	playgrounds/trunk/fuerbas/src/main/java/matrix/linkbc.600.txt \
	playgrounds/trunk/gregor/data \
	playgrounds/trunk/gregor/lib \
	playgrounds/trunk/jjoubert/lib \
	playgrounds/trunk/jjoubert/tempInput \
	playgrounds/trunk/kai/out \
	playgrounds/trunk/lcrociani/src/main/resources/originalTrajectories180DegConverted.txt \
	playgrounds/trunk/ma/input \
	playgrounds/trunk/ma/outputCopies \
	playgrounds/trunk/mzilske/inputs \
	playgrounds/trunk/singapore/input \
	playgrounds/trunk/smeintjes/tmp/zonecompletenesslog \
	playgrounds/trunk/staheale/input \
	playgrounds/trunk/thibautd/test/input/playground/thibautd/socnetsim/replanning/selectors/FullyExploredPlansProvider/playground.thibautd.socnetsim.replanning.selectors.EmptyIncompatiblePlansIdentifierFactory/false/jointplans.xml \
	playgrounds/trunk/thibautd/test/input/playground/thibautd/socnetsim/replanning/selectors/FullyExploredPlansProvider/playground.thibautd.socnetsim.replanning.selectors.FewGroupsIncompatibilityFactory/true/plans.xml \
	playgrounds/trunk/tnicolai/configs/brandenburg/ \
	playgrounds/trunk/wrashid/test/input/playground/wrashid/sschieffer/plans20000.xml \
	 < dumpCode > dumpFiltered.tmp
svndumpfilter exclude --pattern "*.jar" "*.zip" "*.mvi" "*.tar" "playgrounds/trunk/*/test/output*" "playgrounds/trunk/*/output*" "wrashid/test/test1/*.xml" "wrashid/test/test2/*.xml" < dumpFiltered.tmp > dumpFiltered

echo "=== modifying svn dump"
date

### converts the paths in the svn dump to a SVN standard (single project) layout
### *1/trunk --> trunk/*1
### *1/branches/*2 --> branches/*1-*2
### *1/tags/*2 --> tags/*1-*2
### with matsim, contrib, playgrounds for *1

perl -p -e 's#-path: matsim/trunk#-path: trunk/matsim#g' dumpFiltered | \
perl -p -e 's#-path: matsim/branches/#-path: branches/matsim-#g' | \
perl -p -e 's#-path: matsim/tags/#-path: tags/matsim-#g' | \
perl -p -e 's#-path: contrib/trunk#-path: trunk/contribs#g' | \
perl -p -e 's#-path: contrib/branches/#-path: branches/contribs-#g' | \
perl -p -e 's#-path: contrib/tags/#-path: tags/contribs-#g' | \
perl -p -e 's#-path: playgrounds/trunk#-path: trunk/playgrounds#g' | \
perl -p -e 's#-path: playgrounds/branches/#-path: branches/playgrounds-#g' | \
perl -p -e 's#-path: playgrounds/tags/#-path: tags/playgrounds-#g' > dumpCodeFixed

echo "=== re-creating clean svn repository"
date

rm -rf cleanRepo
svnadmin create cleanRepo
# if you use SVN 1.8, you need to it to a 1.6 style repository, because git seems not yet to support newer svn repos
#svnadmin create --compatible-version 1.6 cleanRepo
svnadmin load --ignore-uuid cleanRepo < $SUPPORTDIR/dumpInitFixed
svnadmin load --bypass-prop-validation --ignore-uuid cleanRepo < dumpCodeFixed

echo "=== converting clean svn repository to git"
date

git svn clone file://$WORKDIR/cleanRepo/ --stdlayout --authors-file=authors.txt matsim.git

echo "=== cleaning up git repository"
date

# just make a backup at this point, it would be too bad to repeat the whole import process if we mix something up in the rest now
cp -r matsim.git matsim.git.bak

cd matsim.git

# based on http://www.javacodegeeks.com/2013/11/migrating-from-a-subversion-repository-to-github.html

git for-each-ref refs/remotes/tags | cut -d / -f 4- | grep -v @ | while read tagname; do git tag "$tagname" "tags/$tagname"; git branch -r -d "tags/$tagname"; done

git for-each-ref refs/remotes | cut -d / -f 3- | grep -v @ | while read branchname; do git branch "$branchname" "refs/remotes/$branchname"; git branch -r -d "$branchname"; done

git branch -d trunk

cd ..

echo "=== everything done!"
date

