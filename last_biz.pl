#!/usr/bin/perl
# perldoc -f localtime
#
#use Date::Parse;
use DateTime;

#my $dow_offset=259200+172800;
my $last_biz_day = time+$dow_offset;
my $curr_biz_day = time+$dow_offset;

# Initiate current business day
sub set_and_print_last_biz{
        print "-> Current day is ", $cbd->day_name, ".\n";
        print "-> Current date is ", $cbd->ymd(''),".\n";
        $last_biz_day-=$_[0];
        $lbd=DateTime->from_epoch(epoch=> $last_biz_day);
        print "-> last business day was ", $lbd->day_name,".\n";
        print "-> last business date was ", $lbd->ymd(''),".\n";
}
$cbd=DateTime->from_epoch(epoch=> $curr_biz_day);
if (    $cbd->day_abbr eq "Tue" ||
        $cbd->day_abbr eq "Wed" ||
        $cbd->day_abbr eq "Thu" ||
        $cbd->day_abbr eq "Fri"  ||
        $cbd->day_abbr eq "Sat"  )
{
        set_and_print_last_biz(86400);
} elsif ( $cbd->day_abbr eq "Sun" )
{
        set_and_print_last_biz(172800);
} elsif ( $cbd->day_abbr eq "Mon" )
{
        set_and_print_last_biz(259200);
} else
{
        print "-> Something has gone terribly wrong, abort!\n";
        exit 42;
}
