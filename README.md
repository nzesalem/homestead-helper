# Homestead helper
A bash script that helps you easily create and delete homestead sites on Unix based systems.

*Note:* You must have [Homestead](https://laravel.com/docs/5.7/homestead) setup and working to be able to use this script.

## Pre-installation
1. Create a folder named `workspace` in you home directory:
```
$ mkdir ~/workspace
```
Then move your `Homestead` directory (The one you downloaded from [Homestead's Github Release Page](https://github.com/laravel/homestead/releases)) into the `~/workspace` folder you just created.

2. Create a folder at `~/workspace/www/homestead`:
```
$ mkdir -R ~/workspace/www/homestead
```
_This is where all your homestead sites will reside in your host machine._

3. SSH into your homestead vagrant box and create a `~/projects` folder:
```
$ cd ~/workspace/Homestead
$ vagrant up
$ vagrant ssh
$ mkdir -R ~/projects
```

3. Edit the `folders` property of your `Homestead.yaml` file to look like the following:
```
folders:
    - map: ~/workspace/www/homestead
      to: /home/vagrant/projects
```

## Installation
1. Download the script and add execute permission:
```
$ chmod +x /path/to/homestead.sh
```
2. Optional: if you want to use the script globally, you need to copy the file to your `/usr/local/bin` directory, it is better if you copy it without the .sh extension:
```
$ sudo cp /path/to/homestead.sh /usr/local/bin/homestead
```

## Usage
### To create a new nginx site:
```
$ sudo homestead create example.test
```
The above command will do the following:

1. Add `example.test` in your `/etc/hosts` file

2. Create the site's folder in your host system at `~/workspace/www/homestead` with the name `example`

3. Add an entry for `example.test` in your `Homestead.yml` file

4. Reload and re-provision vagrant

### To create a new nginx site with a custom directory name:
```
$ sudo homestead create example.test dir_name
```

### To create a new apache site:
```
$ sudo homestead create example.test dir_name apache
```

### To delete a site:
```
$ sudo homestead destroy example.test
```

To delete a site with custom directory name:
```
$ sudo homestead destroy example.test dir_name
```