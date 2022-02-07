# How to Make a Release

1. Make sure you're in the dev branch. 
1. Make sure all tests are passing and everything is working in the dev branch. 
1. Make sure all development branches are merged into dev. 
1. Edit the EDITION file to set the correct version number for the release. Commit and push the change. 
1. git checkout main, then git merge dev with an appropriate message. Then git push.
1. Go to GitHub and draft a new release in the interface. Get the release notes from the What's New page in the documentation.
1. git checkout dev, and git merge main to bring them into sync. Then increment the version number in EDITION (adding "alpha") and commit/push. 
