# DHSnapshot

This script was created out of the need to have [snapshots-like backups](http://www.mikerubel.org/computers/rsync_snapshots/) using the [DreamHost Backup service](http://wiki.dreamhost.com/Personal_Backup), which provides 50GB of space for personal backups but gives very limited access to it's servers.
Basically, you have no SSH access, only RSync and SFTP.

It can be used to backup any machine: your computer, a server or even a Dreamhost-hosted website.

You just need to configure it with the path to backup, your dreamhost backup account and the private key used for authentication and it will create daily backups and keep the last 7 days, 4 weeks and 6 months.

# Quick Start

1. Place the files in a directory
2. Rename dhsnapshot.conf.sample to dhsnapshot.conf
3. Edit it.
4. Make sure the directory you're backing up to on the backup server exists
5. Setup ssh public key authentication and save the private key to a file named id_rsa on the same directory
6. Run it manually for the first time
7. Schedule a set of cron jobs to do it automatically.


# Step by step

## Download the project

    [bob@dreamhost]~$ git clone git://github.com/carloslima/dhsnapshot.git
    Initialized empty Git repository in /home/bob/dhsnapshot/.git/
    remote: Counting objects: 11, done.
    remote: Compressing objects: 100% (9/9), done.
    remote: Toremote: tal 11 (delta 3), reused 0 (delta 0)
    Receiving objects: 100% (11/11), done.
    Resolving deltas: 100% (3/3), done.

## Setup the config file

    [bob@dreamhost]~$ cd dhsnapshot/
    [bob@dreamhost]~/dhsnapshot$ cp dhsnapshot.conf.sample dhsnapshot.conf
    [bob@dreamhost]~/dhsnapshot$ vi dhsnapshot.conf
    [bob@dreamhost]~/dhsnapshot$ more dhsnapshot.conf
    $conf{'backup_source'} = "/home/bob/trac_trac/";
    $conf{'backup_dest'} = 'b000000@hanjin.dreamhost.com:backup';

    $conf{'rsync_path'} = '/usr/bin/rsync';
    $conf{'sftp_path'} = '/usr/bin/sftp';

    return 1;

## Generate an ssh key pair to use

    [bob@dreamhost]~/dhsnapshot$ ssh-keygen -q -N "" -f ./id_rsa

## Setup the backup server

1.Create the directory where the backup will be placed

    [bob@dreamhost]~/dhsnapshot$ sftp b000000@hanjin.dreamhost.com
    Connecting to hanjin.dreamhost.com...
    The authenticity of host 'hanjin.dreamhost.com (205.196.216.115)' can't be established.
    RSA key fingerprint is 0e:c2:f6:f4:d9:86:9d:4b:c4:3d:77:e7:a4:bb:59:14.
    Are you sure you want to continue connecting (yes/no)? yes
    Warning: Permanently added 'hanjin.dreamhost.com,205.196.216.115' (RSA) to the list of known hosts.
    b000000@hanjin.dreamhost.com's password:
    sftp> mkdir backup

2.Configure the key as authorized key  
*This is needed so the backup script doesn't need to type a password to connect :)*

    sftp> mkdir .ssh
    sftp> chmod 700 .ssh
    Changing mode on /vol/shelf1/zool/b000000/.ssh
    sftp> cd .ssh
    sftp> put id_rsa.pub
    Uploading id_rsa.pub to /vol/shelf1/zool/b000000/.ssh/id_rsa.pub
    id_rsa.pub                                    100%  395     0.4KB/s   00:00
    sftp> rename id_rsa.pub authorized_keys
    sftp> chmod 700 authorized_keys
    Changing mode on /vol/shelf1/zool/b000000/.ssh/authorized_keys
    sftp> quit

## Setup permissions for your script and keys

    [bob@dreamhost]~/dhsnapshot$ chmod 400 id_rsa
    [bob@dreamhost]~/dhsnapshot$ chmod 500 dhsnapshot.pl
    [bob@dreamhost]~/dhsnapshot$ chmod 400 dhsnapshot.conf

## Run the first backup manually to see if everything is ok

    [bob@dreamhost]~/dhsnapshot$ ./dhsnapshot.pl daily
    Changing to: /vol/shelf1/zool/b000000/backup
    sftp>
    sftp> -rmdir daily.6
    sftp> -rename daily.5 daily.6
    Couldn't rename file "/vol/shelf1/zool/b000000/backup/daily.5" to "/vol/shelf1/zool/b000000/backup/daily.6": No such file or directory
    sftp> -rename daily.4 daily.5
    Couldn't rename file "/vol/shelf1/zool/b000000/backup/daily.4" to "/vol/shelf1/zool/b000000/backup/daily.5": No such file or directory
    sftp> -rename daily.3 daily.4
    Couldn't rename file "/vol/shelf1/zool/b000000/backup/daily.3" to "/vol/shelf1/zool/b000000/backup/daily.4": No such file or directory
    sftp> -rename daily.2 daily.3
    Couldn't rename file "/vol/shelf1/zool/b000000/backup/daily.2" to "/vol/shelf1/zool/b000000/backup/daily.3": No such file or directory
    sftp> -rename daily.1 daily.2
    Couldn't rename file "/vol/shelf1/zool/b000000/backup/daily.1" to "/vol/shelf1/zool/b000000/backup/daily.2": No such file or directory
    sftp> -rename daily.0 daily.1
    Couldn't rename file "/vol/shelf1/zool/b000000/backup/daily.0" to "/vol/shelf1/zool/b000000/backup/daily.1": No such file or directory
    --link-dest arg does not exist: ../daily.1

> The errors here are ok, they just say that the "daily.X" directory doesn't exist (yet).  
> After running the script for 7 days, the errors will disappear.  
> The same is valid for the Weekly and Monthly backups

## Setup the crontab to run your backups automatically

    [bob@dreamhost]~/dhsnapshot$ crontab -l
    no crontab for bob
    [bob@dreamhost]~/dhsnapshot$ crontab -e
    It looks like you don't have a MAILTO line in your crontab file
    For performance reasons we ask that you specify an address where
    cronjob output will be delivered.  If you do not wish to receive
    cronjob output, simply press enter and cronjob output will not be
    mailed to you.

    For more information regarding this, please visit:
    http://wiki.dreamhost.com/Crontab#MAILTO_variable_requirement

    Where would you like cronjob output delivered? (leave blank to disable)
    : email@example.com

    cronjob output will be emailed to email@example.com
    confirm? (y/N): y
    /usr/bin/crontab: installing new crontab

    [bob@dreamhost]~/dhsnapshot$ crontab -l
    MAILTO="email@example.com"
    0  2  1 * * /home/bob/dhsnapshot/dhsnapshot.pl monthly
    0  3  * * 0 /home/bob/dhsnapshot/dhsnapshot.pl weekly
    0  4  * * * /home/bob/dhsnapshot/dhsnapshot.pl daily
    [bob@dreamhost]~/dhsnapshot$

Monthly backups are rolled every 1st at 2am  
Weeklys are rolled every Sunday 3am  
Dailys are rolled and a new backup generated everyday at 4am

> If you setup your email here, you will get daily notifications containing the 'sftp renames' results and error messages if any.  
> I think it's good to receive it so you know your backup is running and if any problem arises you get aware about it very fast.

