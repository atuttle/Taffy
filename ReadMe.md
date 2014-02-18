[![Taffy: The REST framework for ColdFusion and Railo](https://raw.github.com/atuttle/Taffy/master/dashboard/logo-lg.png)](http://taffy.io)

You're here because creating REST APIs with the native functionality in ColdFusion 10 and Railo is verbose, complex, and developer-hostile. Or maybe you're still on an older version of ColdFusion.

**You've come to the right place.**

Taffy is low friction, extremely simple to get started, and it's compatible as far back as ColdFusion 8.

It's terse because it uses convention over configuration, and doesn't require writing a bunch of boilerplate code. How terse? [A functional API can fit into a tweet](https://twitter.com/cf_taffy/statuses/327415972581486592).

It's easy to debug because error messages are returned as JSON by default and it optionally integrates with your favorite IoC libraries like **ColdSpring** and **DI/1**.

## Build Status

[![Taffy Build Status](http://fusiongrokker.com:8080/job/Taffy/badge/icon)](http://fusiongrokker.com:8080/job/Taffy/)

Taffy has a comprehensive test suite and uses continuous integration to ensure that the code is always usable. If you'd like, you can [review the Jenkins build history for Taffy](http://fusiongrokker.com:8080/job/Taffy/).

## Currently Supported Versions

* Taffy 2.1.x
* Taffy 2.0.x
* Taffy 1.3.x

If you file a bug or ask for support please indicate which version of Taffy you're using. If it's an older release, we usually ask you to upgrade. Officially, we promise to support the current and previous **minor** releases and the last **minor** release of the previous **major** release. Taffy follows versioning guidelines defined in [semver](http://semver.org/).

Supported versions get priority for bug fixes. No promises are made to fix bugs filed against **unsupported** versions. If your version is supported and your bug is reproducible and isolatable, we'll do everything within our power to address it.

If you're on an unsupported version, upgrade is not an option in your case, and you still have an isolatable and reproducable bug, [contact me](http://fusiongrokker.com/page/contact-me) to discuss further options.

## Documentation

Primary documentation is available at [docs.taffy.io](http://docs.taffy.io), with a few of the more detailed guides remaining [in the wiki][3] for now.

### You can contribute to the documentation

If you would like to contribute to documentation, [please read this blog post][2]. If you still have questions, [ask them on our mailing list][1]. :)

## Roadmap

In addition to the [GitHub issues list](https://github.com/atuttle/Taffy/issues), we use a [public trello board](https://trello.com/b/Nz5nyqZg/) to track and plan the framework roadmap.

[![Taffy Roadmap](https://trello.com/b/Nz5nyqZg.png)](https://trello.com/b/Nz5nyqZg/)

## Community

We have [a mailing list for Taffy Users][1]. Feel free to ask for help, discuss potential bugs, and share new ideas there.

I also frequent/idle in the **#ColdFusion** channel [on Freenode](https://kiwiirc.com/client/irc.freenode.net/) (IRC).

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
[2]:http://fusiongrokker.com/post/how-you-can-contribute-to-taffy-documentation
[3]:http://atuttle.github.com/Taffy/documentation.html
