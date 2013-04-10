# Git Pivotal Tracker Integration

This project provides a set of additional Git commands to help developers when working with [Pivotal Tracker][pivotal-tracker].

[pivotal-tracker]: http://www.pivotaltracker.com


## Installation
The `git-pivotal-tracker-integration` requires at least Ruby 2.0.0 in order to run.  It also, unfortunately, depends on a beta version of the [Rugged][rugged] library.  In order to install the proper version of Rugged, do the following:

```plain
$ gem install bundler
$ git clone https://github.com/libgit2/rugged.git
$ cd rugged
$ bundle install
$ rake compile
$ gem build rugged.gemspec
$ gem install rugged-*.gem
```

Once the beta version of Rugged is installed, installation of `git-pivotal-tracker-integration` is as follows:

```plain
$ gem install git-pivotal-tracker-integration
```

[rugged]: https://github.com/libgit2/rugged


## Configuration

### Git Client
In order to use `git-pivotal-tracker-integration`, two Git client configuration properties must be set.  If these properties have not been set, you will be prompted for them and your Git configuration will be updated.

| Name | Description
| ---- | -----------
| `pivotal.api-token` | Your Pivotal Tracker API Token.  This can be found in [your profile][profile] and should be set globally.
| `pivotal.project-id` | The Pivotal Tracker project id for the repository your are working in.  This can be found in the project's URL and should be set.

[profile]: https://www.pivotaltracker.com/profile


### Git Server
In order to take advantage of automatic issue completion, the [Pivotal Tracker Source Code Integration][integration] must be enabled.  If you are using GitHub, this integration is easy to enable by navgating to your project's 'Service Hooks' settings and configuration it with the proper credentials.

[integration]: https://www.pivotaltracker.com/help/integrations?version=v3#scm


## Commands

### `git start [ type | issue ]`
This command starts a story by creating a Git branch and changing the story's state to `started`.  This command can be run in three ways.  First it can be run specifying the issue that you want to start.

```plain
$ git start 12345678
```

The second way to run it is by specyifying the type of story that you would like to start.  In this case it will then offer you a the first five stories of that type (based on the backlog's order) to choose from.

```plain
$ git start feature

1. Lorem ipsum dolor sit amet, consectetur adipiscing elit
2. Pellentesque sit amet ante eu tortor rutrum pharetra
3. Ut at purus dolor, vel ultricies metus
4. Duis egestas elit et leo ultrices non fringilla ante facilisis
5. Ut ut nunc neque, quis auctor mauris
Choose story to start:
```

Finally it can be run without specifying anything.  In this case, it will then offer the first five stories of any type (based on the backlog's order) to choose from.

```plain
$ git start

1. FEATURE Donec convallis leo mi, dictum ornare sem
2. CHORE   Sed et magna lectus, sed auctor purus
3. FEATURE In a nunc et enim tincidunt interdum vitae et risus
4. FEATURE Fusce facilisis varius lorem, at tristique sem faucibus in
5. BUG     Donec iaculis ante neque, ut tempus augue
Choose story to start:
```

Once a story has been selected by one of the three methods, the command then prompts for the name of the branch to create.

```plain
$ git start 12345678
      Title: Lorem ipsum dolor sit amet, consectetur adipiscing elitattributes
Description: Ut consequat sapien ut erat volutpat egestas. Integer venenatis lacinia facilisis.

Enter branch name (12345678-<branch-name>):
```

The value entered here will be prepended with the story id such that the branch name is `<project-id>-<branch-name>`.

### `git finish`
