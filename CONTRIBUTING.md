Contributing to the Advanced Queue JMS Implementation
=======================================================

**Please make all pull requests against the master branch**

Thank you for your interest in contributing to AQ-JMS. Our goal is to make it as easy
as we can for you to contribute changes to AQ-JMS -- So if there's something here that
seems harder than it ought to be, please let us know.

If you find a bug **in this document**, you are bound to contribute a fix. Stop reading now
if you do not wish to abide by this rule.

**Step 1**: If you do not have a github account, create one.

**Step 2**: Fork AQ-JMS to your account. Go to the [main repo](https://github.com/daitangio/oracle-aq-jms)
and click the fork button.

![Fork Me](http://img.skitch.com/20101015-n4ssnfyj16e555cnn7wp2pg717.png)

Here's some general information about the project you might find useful along the way:

* [Submitting Patches](#patches)
* [Project Structure](#project-structure)
* [Miscellaneous Stuff](#faq)
  * [Setting up Git](#setting-up-git)
  * [Using AQ-JMS while Under Development](#running-local-code)
  * [Running Tests](#running-tests)
  * [Recovering from a cherry-pick or a rebase](#recovering-from-rebased-or-cherry-picked-changesets)


Thanks to Github, making small changes is super easy. After forking the project navigate
to the file you want to change and click the edit link.

![Edit Me](http://img.skitch.com/20101015-n2x2iaric7wkey2x7u4fa2m1hj.png)

Change the file, write a commit message, and click the `Commit` button.

![Commit Me](http://img.skitch.com/20101015-br74tfwtd1ur428mq4ejt12kfc.png)
Now you need to get your change [accepted](#patches).


<h2 id="patches">Submitting Patches</h2>

If you are submitting features that have more than one changeset, please create a
topic branch to hold the changes while they are pending merge and also to track
iterations to the original submission. To create a topic branch:

    $ git checkout -b new_branch_name
    ... make more commits if needed ...
    $ git push origin new_branch_name

You can now see these changes online at a url like:

    http://github.com/your_user_name/oracle-aq-jms/commits/new_branch_name

If you have single-commit patches, it is fine to keep them on master. But do keep in
mind that these changesets might be cherry-picked.

Once your changeset(s) are on github, select the appropriate branch containing your
changes and send a pull request. Make sure to choose the same upstream branch that
you developed against (probably stable or master). Most of the description of your
changes should be in the commit messages -- so no need to write a whole lot in the
pull request message. However, the pull request message is a good place to provide a
rationale or use case for the change if you think one is needed. More info on [pull
requests][pulls].

![Pull Request Example](http://img.skitch.com/20101015-rgfh43yhk7e61fchj9wccne9cq.png)

Pull requests are then managed like an issue from the [AQ-JMS issues page][issues].
A code review will be performed by a AQ-JMS core team member, and one of three outcomes
will result:

1. The change is rejected -- We will provide a comment for the reason we rejected it.
2. The change is rejected, *unless* -- Sometimes, there are missing pieces, or
   other changes that need to be made before the change can be accepted. Comments
   will be left on the commits indicating what issues need to be addressed.
3. The change is accepted -- The change is merged into AQ-JMS, sometimes minor
   changes are then applied by the committer after the merge.

<h2 id="project-structure">Project Structure</h2>

    oracle-aq-jms/
      build.gradle           - Main Gradle build file
      src/main               - Main source code
            java/            - Java Classes
            sql/             - Oracle Package
      src/test               - Test code
      oracle-driver/         - Oracle libraries (propietary) 


[pulls]: http://help.github.com/pull-requests/
[issues]: http://github.com/daitangio/oracle-aq-jms/issues
