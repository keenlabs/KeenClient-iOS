export OUTPUTDIR=/tmp/keen-ios-help
export WEBDIR=/Users/dkador/dev/keen/Keen-Web/app/static/iOS-reference

# clean up old files
rm -rf $OUTPUTDIR
rm -rf $WEBDIR
mkdir $WEBDIR

# generate docs
appledoc --no-create-docset --project-name "Keen iOS Client" --project-company "Keen Labs" --company-id io.keen --output $OUTPUTDIR --index-desc docs/index.markdown KeenClient/KeenProperties.h KeenClient/KeenClient.h

# copy correct files from output directory to Keen-Web
cp -v -r $OUTPUTDIR/html/* $WEBDIR/.
