# [![Taffy: The REST framework for ColdFusion and Lucee](https://raw.github.com/atuttle/Taffy/main/dashboard/logo-lg.png)](https://taffy.io)

[![Build Status](https://travis-ci.org/atuttle/Taffy.svg?branch=main)](https://travis-ci.org/atuttle/Taffy)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat)](https://makeapullrequest.com)

---

**PROBLEM:** Creating REST APIs with the native functionality in ColdFusion 10+ and Lucee is verbose, complex, and developer-hostile. Or maybe you're still on an older version of ColdFusion.

**SOLUTION:** A framework that focuses on Developer Experience and helps you "fall into a pit of success". **You've come to the right place.** Taffy is low friction, simple to get started, and compatible as far back as ColdFusion 8. CF8 was released in 2007! 😱

---

## What makes Taffy's developer experience better?

- It's terse. How terse? [A functional API can fit into a tweet](https://twitter.com/taffyio/status/327415972581486592). (_BEFORE they doubled the max tweet length!_)
- Smart and secure defaults, easily overridden with metadata in most cases.
- Easy to debug: Error messages are returned as JSON by default.
- Integrated dashboard gives you a direct view into how Taffy has parsed your code.
- Optionally integrates with your favorite IOC libraries like **ColdSpring** and **DI/1**, or use the baked-in IOC.

## Currently Supported Versions

- Taffy 3.3.x+
- Taffy 2.2.x

If you file a bug or ask for support please indicate which version of Taffy you're using. If it's an older release, we usually ask you to upgrade. Officially, we promise to support the current and previous **minor** releases and the last **minor** release of the previous **major** release. To the best of our abilities Taffy follows the versioning guidelines defined in [semver](https://semver.org/).

Supported versions get priority for bug fixes. No promises are made to fix bugs filed against _unsupported_ versions. If your version is supported and your bug is reproducible and isolatable, we'll do everything within our power to address it.

If you're on an unsupported version, upgrade is not an option in your case, and you still have an isolatable and reproducible bug, [contact me][5] to discuss further options.

## Documentation

Primary documentation is available at [docs.taffy.io](https://docs.taffy.io), with a few of the more detailed guides remaining [in the wiki][3] for now.

### You can contribute to the documentation

Contributing documentation changes is as easy as submitting a pull request with modifications to the markdown files in the `/docs` folder.

## Roadmap

Features and bug fixes are coordinated via the [GitHub issues list](https://github.com/atuttle/Taffy/issues).

## Community

The most active place where Taffy users and contributors gather is in the **#taffy** channel of the [CFML Slack][4]. It's a great place to ask for help. We also have [a mailing list][1], but it hasn't been used much since the CFML Slack came around.

## Need serious help?

If your problem is too big or too private to ask for help in a chat room, [I am available to hire for freelance work][5].

## LICENSE

> **The MIT License (MIT)**
>
> Copyright (c) 2011 Adam Tuttle and Contributors
>
> Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

[1]: https://groups.google.com/forum/#!forum/taffy-users
[3]: https://github.com/atuttle/Taffy/wiki
[4]: https://cfml-slack.herokuapp.com
[5]: https://twitter.com/adamtuttle
