# generate docs
appledoc --no-create-docset --project-name "Keen iOS Client" --project-company "Keen Labs" --company-id io.keen --output ~/help --index-desc docs/index.markdown KeenClient/KeenClient.h

# copy correct files from output directory to Keen-Web
cp -v -r ~/help/html/* ~/dev/keen/Keen-Web/app/static/docs/iOS-client/.