# Bottlenose

Bottlenose is a web app for managing assignment submission and grading in computer science courses. It provides a flexible mechanism for automatic grading of programming assignments.

For detailed documentation, see the [Wiki](https://github.com/NatTuck/bottlenose/wiki).

## Linux Setup (Vagrant)

The goal of this section is to get a working Debian 8 machine up and running.
We also want to have this project's source in `$BOTTLENOSE`. I'm working on OS X
so I'll be using a VM to do this. If you are working directly on the Linux
machine then skip directly to [bottlenose setup](#bottlenose-setup).

[VirtualBox](https://www.virtualbox.org) is a virtualization software that can
run Debian 8. [Download](https://www.virtualbox.org/wiki/Downloads) and install
this tool.

[Vagrant](https://www.vagrantup.com) is another tool designed to avoid manual VM
management. [Download](https://www.vagrantup.com/downloads.html) and install
this tool as well.

Once you have both VirtualBox and Vagrant run the script below (from this
directory) to start up your Debian 8 VM.

```sh
# Creates the Vagrantfile in the current directory, this file holds VM
# configuration information. The debian/jessie64 argument tells vagrant to
# use Debian 8 64bit.
vagrant init debian/jessie64
```

Open the `Vagrantfile` and add the line

```
config.vm.network "forwarded_port", guest: 3000, host: 3000
```

inside the config block. This allows the host to access the Rails server
on port 3000.

```sh
# Start the VM with virtualbox.
vagrant up --provider virtualbox
```

Now that you have a working VM running Debian 8 we can SSH into it and begin
setting it up.

```sh
# SSH into the VM.
vagrant ssh

# Move into the bottlenose project directory. Using Vagrant $BOTTLENOSE is
# /vagrant, this is because Vagrant keeps the directory on the host system
# with the Vagrantfile in sync with /vagrant on the client system.
cd /vagrant
```

## Linux Setup (Manual)

As root. `$BOTTLENOSE` is `/home/bottlenose/src`.

```sh
apt-get update
apt-get install sudo git
mkdir /home/bottlenose
useradd -d /home/bottlenose -G sudo bottlenose
chown -R bottlenose:bottlenose /home/bottlenose
su - bottlenose
chsh -s /bin/bash
git clone https://github.com/nixpulvis/bottlenose.git src
cd src
```

## Bottlenose Setup

The goal of this section is to have a working web-server running Bottlenose and
all of it's dependencies. All scripts in this sections start in the
`$BOTTLENOSE` directory unless explicitly stated otherwise.

### Basics

Some packages are generally good to have, and needed by many future steps in
the setup process.

```sh
sudo apt-get install \
    git \
    vim \
    curl
```

### Postgres

TODO: I was using 9.5, is this correct?

Bottlenose uses Postgres 9.4+ as the database. Install and setup the bottlenose
role with the following script.

```sh
# Install postgresql and the development library.
sudo apt-get install postgresql

# Switch to the postgres user to create the new bottlenose role.
sudo su - postgres

# Create the bottlenose role for postgres.
createuser -d bottlenose

# Exit back to the vagrant user.
exit
```

TODO: Talk about the pg_hba.conf file.

### Ruby

Installing Ruby is easiest with the aid of a tool like
[rbenv](https://github.com/rbenv/rbenv). Install both rbenv, and ruby-build with
the following script.

```sh
# Download both rbenv, and ruby-build.
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build

# Add the `rbenv` executable to your $PATH.
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
# Run rbenv's init when Bash starts.
echo 'eval "$(rbenv init -)"' >> ~/.bashrc

# Restart the shell.
exec bash
```

Now we can install Ruby using rbenv and ruby-build.

```sh
# Install the Ruby system dependencies.
sudo apt-get install \
    build-essential \
    libssl-dev \
    libreadline-dev \
    zlib1g-dev \
    libpq-dev \
    qt4-default

# Install the Ruby determined by the contents of the
# .ruby-version file.
rbenv install

# Ensure Ruby was install correctly. Where <version> is the
# correct version as described in the .ruby-version file.
ruby --version
#=> ruby <version> ...
```

Once you have Ruby installed, install the Ruby dependencies.

```sh
# Install Ruby's package manager "Bundler".
gem install bundler

# If you're using rbenv, you may need to run this command to
# ensure new executables are loaded into your PATH.
rbenv rehash

# Install Bottlenose's dependencies.
bundle install
```

### Rails

The last step is to set up the Rails app.

```sh
# Create the database.
rake db:create
# Run database migrations.
rake db:migrate
```

## Usage

To run the server in development mode run the following script. The binding
is up to your desired configuration, however this will work for most cases.

```sh
# Run the server, binding to 0.0.0.0 is needed for Vagrant.
rails s -b 0.0.0.0
```

To get access to a Ruby REPL with the application environment loaded, run
`rails c`. The database REPL can be accessed using `rails db`.

Other tasks are done via rake, run `rake -T` to view all tasks available. The
following are the most common tasks.

```sh
# Create the database.
rake db:create

# Run the database migrations.
rake db:migrate

# Rollback the last database migration.
rake db:rollback

# List all routes in the application.
rake routes
```
