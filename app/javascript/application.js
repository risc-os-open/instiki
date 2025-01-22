// THIS FILE IS NOT USED. TL;DR, maintain "package.json" if you make changes.
//
// All of the JS herein predates modules so use of 'esbuild' with forced
// bundling proved very troublesome. It was much simpler to just concatenate
// all files manually via "package.json".
//
// Procfile.dev lists the commands run by "bin/dev". If using SASS supporting a
// watcher mode, then a '--watch' parameter does the trick. Unix 'cat' does not
// have such a thing, so instead task "nodemon" is used to monitor files and
// re-run the "cat" task if it sees changes.
//
// These tasks - along with the list of JavaScript files you will need to
// update if you add or remove anything here - are, again, in "package.json".
