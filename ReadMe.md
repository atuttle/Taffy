[![Taffy: The REST framework for ColdFusion and Lucee](https://raw.github.com/atuttle/Taffy/master/dashboard/logo-lg.png)](http://taffy.io)

[![Build Status](https://travis-ci.org/atuttle/Taffy.svg?branch=master)](https://travis-ci.org/atuttle/Taffy)


You're here because creating REST APIs with the native functionality in ColdFusion 10+, Railo, and Lucee is verbose, complex, and developer-hostile. Or maybe you're still on an older version of ColdFusion.

**You've come to the right place.**

Taffy is low friction, extremely simple to get started, and it's compatible as far back as ColdFusion 8.

It's terse because it uses convention over configuration, and doesn't require writing a bunch of boilerplate code. How terse? [A functional API can fit into a tweet](https://twitter.com/cf_taffy/statuses/327415972581486592).

It's easy to debug because error messages are returned as JSON by default and it optionally integrates with your favorite IoC libraries like **ColdSpring** and **DI/1**.

## Currently Supported Versions

* Taffy 3.1.x
* Taffy 3.0.x
* Taffy 2.2.x

If you file a bug or ask for support please indicate which version of Taffy you're using. If it's an older release, we usually ask you to upgrade. Officially, we promise to support the current and previous **minor** releases and the last **minor** release of the previous **major** release. To the best of our abilities Taffy follows the versioning guidelines defined in [semver](http://semver.org/).

Supported versions get priority for bug fixes. No promises are made to fix bugs filed against **unsupported** versions. If your version is supported and your bug is reproducible and isolatable, we'll do everything within our power to address it.

If you're on an unsupported version, upgrade is not an option in your case, and you still have an isolatable and reproducible bug, [contact me](http://twitter.com/adamtuttle) to discuss further options.

## Running the Tests

To run the tests, you must have [MxUnit](http://mxunit.org/) installed at `/mxunit` (not just a global mapping, put the folder in your web-root, as there are CSS/JS/etc assets that will be needed).

1. Clone the Taffy repo to `/taffy` in your web root.
1. Point your browser at `http://localhost/taffy/tests/` to initialize the test-harness API that the tests will use
1. Point your browser at `http://localhost/taffy/tests/tests/` to run the test suite.

If you are on vanilla Tomcat or another app server (most Railo users are), you may find that you need to [add an additional servlet mapping](http://docs.taffy.io/3.1.0#tomcat-jboss-and-other-app-server-idiosyncrasies) to get the tests to run.

Please [report any errors or failures as bugs](https://github.com/atuttle/Taffy/issues), and be sure to include relevant platform information.

## Documentation

Primary documentation is available at [docs.taffy.io](http://docs.taffy.io), with a few of the more detailed guides remaining [in the wiki][3] for now.

### You can contribute to the documentation

Contributing documentation changes is as easy as submitting a pull request to the [TaffyDocs][2] repo.

## Roadmap

Features and bug fixes are coordinated via the [GitHub issues list](https://github.com/atuttle/Taffy/issues).

## Community

We have [a mailing list for Taffy Users][1]. Feel free to ask for help, discuss potential bugs, and share new ideas there.

You can also find us in the [CFML Slack][4], where there is even a dedicated **#taffy** channel.

## Open Source!

Part of the beauty of open source is that _you can affect change_. You can help improve the documentation, fix a bug, add tests, or even propose new features. Nothing is off limits, and I try to be very responsive to pull requests and on the mailing list.

## LICENSE

>**The MIT License (MIT)**
>
>Copyright (c) 2011 Adam Tuttle and Contributors
>
>Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
>
>The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
>
>THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

**What does that mean?**

It means you can use Taffy pretty much any way you like. You can fork it. You can include it in a proprietary product, sell it, and not give us a dime. Pretty much the only thing you can't do is hold us accountable if anything goes wrong.

[1]:https://groups.google.com/forum/#!forum/taffy-users
[2]:https://github.com/atuttle/TaffyDocs
[3]:http://atuttle.github.com/Taffy/documentation.html
[4]:http://cfml-slack.herokuapp.com
