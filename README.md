BLAH
# Git Pivotal Tracker Integration

`git-pivotal-tracker-integration` provides a set of additional Git commands to help developers when working with [Pivotal Tracker][pivotal-tracker].

[pivotal-tracker]: http://www.pivotaltracker.com


## Installation
`git-pivotal-tracker-integration` requires at least **Ruby 2.0.0** and **Git 1.8.2.1** in order to run.  It is tested against Rubies _2.0.0_.  In order to install it, do the following:

```plain
$ gem install specific_install
$ gem specific_install https://github.com/Firmstep/git-pivotal-tracker-integration.git
```


## Usage
`git-pivotal-tracker-integration` is intended to be a very lightweight tool, meaning that it won't affect your day to day workflow very much.  To be more specific, it is intended to automate branch creation and pull requests as well as story state changes.  The typical workflow looks something like the following:

```plain
$ git start story_id   # Creates branch and starts story
$ git commit ...
$ git commit ...  # Your existing development process
$ git commit ...
$ git finish      # Adds [finishes #story_id] to the last commit made, pushes to origin, and opens a new pull request
```

## Configuration

### Git Client
In order to use `git-pivotal-tracker-integration`, two Git client configuration properties must be set.  If these properties have not been set, you will be prompted for them and your Git configuration will be updated.

| Name | Description
| ---- | -----------
| `pivotal.api-token` | Your Pivotal Tracker API Token.  This can be found in [your profile][profile] and should be set globally.
| `pivotal.project-id` | The Pivotal Tracker project id for the repository your are working in.  This can be found in the project's URL and should be set.

[profile]: https://www.pivotaltracker.com/profile


### Git Server
In order to take advantage of automatic issue completion, the [Pivotal Tracker Source Code Integration][integration] must be enabled.  If you are using GitHub, this integration is easy to enable by navgating to your project's 'Service Hooks' settings and configuring it with the proper credentials.

[integration]: https://www.pivotaltracker.com/help/integrations?version=v3#scm


## Commands

### `git start [ type | story-id ]`
This command starts a story by creating a Git branch and changing the story's state to `started`.  This command can be run in three ways.  First it can be run specifying the id of the story that you want to start.

```plain
$ git start 12345678
```

The second way to run the command is by specyifying the type of story that you would like to start.  In this case it will then offer you the first five stories (based on the backlog's order) of that type to choose from.

```plain
$ git start feature

1. Lorem ipsum dolor sit amet, consectetur adipiscing elit
2. Pellentesque sit amet ante eu tortor rutrum pharetra
3. Ut at purus dolor, vel ultricies metus
4. Duis egestas elit et leo ultrices non fringilla ante facilisis
5. Ut ut nunc neque, quis auctor mauris
Choose story to start:
```

Finally the command can be run without specifying anything.  In this case, it will then offer the first five stories (based on the backlog's order) of any type to choose from.

```plain
$ git start

1. FEATURE Donec convallis leo mi, dictum ornare sem
2. CHORE   Sed et magna lectus, sed auctor purus
3. FEATURE In a nunc et enim tincidunt interdum vitae et risus
4. FEATURE Fusce facilisis varius lorem, at tristique sem faucibus in
5. BUG     Donec iaculis ante neque, ut tempus augue
Choose story to start:
```

Once a story has been selected by one of the three methods, the branch is created with a truncated, human-readable name of the story name.

```plain
$ git start 12345678
        Title: Lorem ipsum dolor sit amet, consectetur adipiscing elitattributes
  Description: Ut consequat sapien ut erat volutpat egestas. Integer venenatis lacinia facilisis.

Enter branch name (12345678-<branch-name>):
```

The truncated name will be prepended with the story id such that the branch name is `<story-id>-<branch-name>`.  This branch is then created and checked out.

If it doesn't exist already, a `prepare-commit-msg` commit hook is added to your repository.  This commit hook augments the existing commit messsage pattern by appending the story id to the message automatically.

```plain

[#12345678]
# Please enter the commit message for your changes. Lines starting
# with '#' will be ignored, and an empty message aborts the commit.
# On branch 12345678-lorem-ipsum
# Changes to be committed:
#   (use "git reset HEAD <file>..." to unstage)
#
#	new file:   dolor.txt
#
```

### `git finish [--no-complete]`
This command finishes a story by creating a pull request to github.

```plain
$ git finish
... *insert real messages* ...
```
You will need to enter your github password at this point, at the moment the pull request is created with cUrl, no oauth etc.

### `git release [story-id]`
This command creates a release for a story.  It does this by updating the version string in the project and creating a tag.  This command can be run in two ways.  First it can be run specifying the release that you want to create.

```plain
$ git release 12345678
```
The other way the command can be run without specifying anything.  In this case, it will select the first release story (based on the backlog's order).

```plain
$ git release
      Title: Lorem ipsum dolor sit amet, consectetur adipiscing elitattributes
```

Once a story has been selected by one of the two methods, the command then prompts for the release version and next development version.

```plain
$ git release
      Title: Lorem ipsum dolor sit amet, consectetur adipiscing elitattributes

Enter release version (current: 1.0.0.BUILD-SNAPSHOT): 1.0.0.M1
Enter next development version (current: 1.0.0.BUILD-SNAPSHOT): 1.1.0.BUILD-SNAPSHOT
Creating tag v1.0.0.M1... OK
Pushing to origin... OK
```

Once these have been entered, the version string for the current project is updated to the release version and a tag is created.  Then the version string for the current project is updated to the next development version and a new commit along the original branch is created.  Finally the tag and changes are pushed to the remote sever.

Version update is currently supported for the following kinds of projects.  If you do not see a project type that you would like supported, please open an issue or submit a pull request.

* Gradle
