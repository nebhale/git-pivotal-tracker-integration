# Git Pivotal Tracker Integration [![Build Status](https://travis-ci.org/nebhale/git-pivotal-tracker-integration.png?branch=master)](https://travis-ci.org/nebhale/git-pivotal-tracker-integration)

This project provides a set of additional Git commands to help developers when working with [Pivotal Tracker][pivotal-tracker].

[pivotal-tracker]: http://www.pivotaltracker.com

## Installation
To install `git-pivotal-tracker-integration` simply run:

```
gem install git-pivotal-tracker-integration
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
In order to take advantage of automatic issue completion, the [Pivotal Tracker Source Code Integration][integration] must be enabled.  If you are using GitHub, this integration is easy to enable by navgating to your project's 'Service Hooks' settings and configuration it with the proper credentials.

[integration]: https://www.pivotaltracker.com/help/integrations?version=v3#scm


## Commands

### `git start [type] [issue]`

### `git info [type] [issue]`

### `git finish`
