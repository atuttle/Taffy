# Contributing to Taffy

Contributions of all shapes and sizes are welcome, encouraged, and greatly appreciated! Not sure where to start? [Learn how here!](https://makeapullrequest.com)

For all contributions, you'll need a [free GitHub account](https://github.com/join).

## Bug Reports / Feature Requests

Please include all of the following information in your ticket:

- CFML Platform and version (e.g. Adobe ColdFusion 9.0.2, or Lucee 4.5.0)
- Java version (look it up in Lucee/CF Administrator, or do `java -version` at the command line)
- Taffy version (for bugs)

## Documentation

Documentation is in the `/docs` folder.

- When fixing a bug for an existing version, if it necessitates a docs update, be sure to update the correct version's markdown file.
- When adding a new feature, make the appropriate updates to `@next.md`. This file will be used to generate the new version file at release time.

✨ There's no such thing as perfect documentation! It can never be thorough enough, nor ever perfectly organized. If you find something confusing or outdated, please be so kind as to file a bug report for it, if you can't or won't fix it. (Yes, documentation bugs!)

## Code

All new development is done against the `main` branch. When you want to make a change and submit it for the Bleeding Edge Release (BER), do the following:

1. [Fork the project](https://github.com/atuttle/Taffy/fork_select)
1. Clone to your local machine: `git clone https://github.com/YOUR-GITHUB-USERNAME/Taffy.git`
1. Create a topic branch for your changes: `git checkout -b BRANCH_NAME`
1. Make your changes and commit them.
1. Push your changes back to your fork. `git push -u origin BRANCH_NAME`
1. Send a pull request ([Learn how here!](https://makeapullrequest.com))

- Please make sure you select `atuttle/main` as the destination branch

### Styling changes

Taffy uses LessCSS to style the dashboard and documentation. To compile changes to `dash.less`, you'll need to have Node.js/npm installed.

1. From the root of your Taffy clone, run `npm ci` to install the dependencies for compiling LessCSS to CSS.
1. Then run `npm run less`. This will compile the latest `dash.less` and update `dash.css`.

### Tests

_⚠️ Unfortunately our test suite doesn't currently run. We're [working on getting it setup on GitHub Actions](https://github.com/atuttle/Taffy/issues/415) and your help doing so would be greatly appreciated._

If at all possible, please include test cases for anything you add or change. To run the tests, you must have [MxUnit](https://mxunit.org/) installed at `/mxunit` (not just a global mapping, put the folder in your web-root, as there are CSS/JS/etc assets that will be needed).

1. Clone the Taffy repo to `/taffy` in your web root.
1. Point your browser at `http://localhost/taffy/tests/` to initialize the test-harness API that the tests will use
1. Point your browser at `http://localhost/taffy/tests/tests/` to run the test suite.

If you are on vanilla Tomcat or another app server (most Lucee users are), you may find that you need to [add an additional servlet mapping](https://docs.taffy.io/#/3.3.0?id=tomcat-jboss-and-other-app-server-idiosyncrasies) to get the tests to run.

Please [report any errors or failures as bugs](https://github.com/atuttle/Taffy/issues), and be sure to include relevant platform information.
