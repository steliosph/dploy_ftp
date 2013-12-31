dploy_ftp
=========

An FTP deployment tool build with bash.
This will run in any linux machine with out any requirements.
You can upload your code to a number of machines.

This version will upload all files.
A later version will most probably hold the update date of the files uploaded and will not upload if the file has not been updated


Install
=======

Just download the 3 files in the src folder.

Basic example
=============

The dploy file will hold all the server requirements.
All of the attribitutes are required. Skipping one at this point, will most definetely break something.

```
name: demo
scheme: ftp
host: ftp.myserver.com
port: 21
user: USER
pass: PASSWORD
path-local: /var/www/dploy/
path-remote: public_html/
----next----
```

You can add multiple servers, with the same format.
It will upload your code to the servers in the dploy file

Execute
=======

To execute the script simply go into the directory and run
```
bash run.sh
```

Mentions
========

This script was inspired by another tool [dploy](https://github.com/LeanMeanFightingMachine/dploy)
This script would handle all the github files and upload them through FTP

Warnings
========

This is my first bash file, so things might not work as expected.
Feel free to Optimize the script if you feel something needs changed.
This is an initiale first version, where it simply works.
There are a lot that will change later on
