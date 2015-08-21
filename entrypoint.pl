#!/usr/bin/perl
# vim:set et ts=2 sw=2:

# Author : djluo
# version: 2.0(20150107)
#
# 初衷: 每个容器用不同用户运行程序,已方便在宿主中直观的查看.
# 需求: 1. 动态添加用户,不能将添加用户的动作写死到images中.
#       2. 容器内尽量不留无用进程,保持进程树干净.
# 问题: 如用shell的su命令切换,会遗留一个su本身的进程.
# 最终: 使用perl脚本进行添加和切换操作. 从环境变量User_Id获取用户信息.

use strict;
#use English '-no_match_vars';

my $uid = 1000;
my $gid = 1000;

$uid = $gid = $ENV{'User_Id'} if $ENV{'User_Id'} =~ /\d+/;

sub add_user {
  my ($name,$id)=@_;

  system("/usr/sbin/useradd",
    "-s", "/bin/false",
    "-d", "/var/empty/$name",
    "-U", "--uid", "$id",
    "$name");
}
unless (getpwuid("$uid")){
  add_user("nginx",  "1080");
  add_user("docker", "$uid");
}

system("mkdir", "/logs") unless ( -d "/logs" );
system("chown docker.docker -R /logs");

# 修复不恰当的权限
if ( -d "/zentaopms/tmp/") {
  system("chmod 755 -R /zentaopms/tmp/");
  system("chown docker.docker -R /zentaopms/tmp/");
}
if ( -d "/zentaopms/config/"){
  system("chmod 755 /zentaopms/config/");
  system("chown docker.docker /zentaopms/config/");
}
system("chmod 755 /zentaopms/module/")           if ( -d "/zentaopms/module/");
system("chmod 644 /zentaopms/config/config.php") if ( -f "/zentaopms/config/config.php");

if( $ENV{'RSYNC_PASSWORD'} ){
  system("rm", "-f", "/run/crond.pid") if ( -f "/run/crond.pid" );
  system("/usr/sbin/cron");

  my $min  = int(rand(60));
  my $hour = int(rand(5));

  my $ip=$ENV{'backup_ip'};
  my $dest=$ENV{'backup_dest'}."_".$ENV{'HOSTNAME'};
  my $port="2873";
  $port="$ENV{'RSYNC_PORT'}" if ( $ENV{'RSYNC_PORT'} );
  my $rsync_opts = "/usr/bin/rsync --del --port=$port -al --password-file=/rsync.pass";

  my $umask = umask;
  umask 0277;
  open (PW,'>', '/rsync.pass') or die "$!";
  print PW $ENV{'RSYNC_PASSWORD'};
  close(PW);
  umask $umask;

  open (CRON,"|/usr/bin/crontab") or die "crontab error?";
  print CRON ("$min $hour * * * ($rsync_opts /zentaopms/www/ docker@". $ip ."::backup/$dest/)\n");
  close(CRON);
}

# 切换当前运行用户,先切GID.
#$GID = $EGID = $gid;
#$UID = $EUID = $uid;
$( = $) = $gid; die "switch gid error\n" if $gid != $( ;
$< = $> = $uid; die "switch uid error\n" if $uid != $< ;

exec(@ARGV);
