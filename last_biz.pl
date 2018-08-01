#!/usr/bin/perl
# perldoc -f localtime
#
#use Date::Parse;
use DateTime;

# For debugging starts. #
#my $dow_offset=13305600;
#my $dow_offset=3110400;
#my $dow_offset=259200+172800;
my $last_biz_day = time+$dow_offset;
my $curr_biz_day = time+$dow_offset;

##################################################
# The following two variables are rather import. #
# Since the mail date of month might introduce   #
# an extra space when it is single digit, this   #
# would fail subject line regex check.           #
##################################################
my $lbd_spacer = ".";
my $cbd_spacer = ".";
my $mail_subj = "";
# Initiate current business day
sub set_and_print_last_biz{
        print "-> Current day is ", $cbd->day_name, ".\n";
        print "-> Current date is ", $cbd->ymd(''),".\n";
        $last_biz_day-=$_[0];
        $lbd=DateTime->from_epoch(epoch=> $last_biz_day);
        if ( length $lbd->day == 1 )
        {
                print "-> Last biz date of month is a single digit, add an extra space.\n";
                $lbd_spacer = "..";
        }
        if ( length $cbd->day == 1 )
        {
                print "-> current biz date of month is a single digit, add an extra space.\n";
                $cbd_spacer = "..";
        }
        $mail_subj = $lbd->month_abbr.$lbd_spacer.$lbd->day." ".$lbd->year."........ to ".$cbd->month_abbr.$cbd_spacer.$cbd->day." ".$cbd->year;
        print "-> last business day was ", $lbd->day_name,".\n";
        print "-> last business date was ", $lbd->ymd(''),".\n";
        return $mail_subj;
}
$cbd=DateTime->from_epoch(epoch=> $curr_biz_day);
if (    $cbd->day_abbr eq "Tue" ||
        $cbd->day_abbr eq "Wed" ||
        $cbd->day_abbr eq "Thu" ||
        $cbd->day_abbr eq "Fri"  ||
        $cbd->day_abbr eq "Sat"  )
{
        $mail_subj = set_and_print_last_biz(86400);
} elsif ( $cbd->day_abbr eq "Sun" )
{
        $mail_subj = set_and_print_last_biz(172800);
} elsif ( $cbd->day_abbr eq "Mon" )
{
        # Last Friday could be a Bank Holiday (Christmas)
        # So there might not be a report on Fridayd's report( with Saturday's date).
        # Hence the last report could be Thursday's(with Friday's date)

        $mail_subj = set_and_print_last_biz(259200);
} elsif ( $cbd->day_abbr eq "Tue" )
{
        # This assumes it is last business is Monday for now.
        # However Monday could be a Bank Holiday
        # Last Friday could be a Bank Holiday (Christmas)
        # We will need an exception for these type of holidays.
        # How can we tell?
        $mail_subj=set_and_print_last_biz(86400);
} else
{
        print "-> Something has gone terribly wrong, abort!\n";
        exit 42;
}

#if ( @mail_index[4] =~ /$mail_subj/ ) 
#{
#        &good();
#} else 
#{
#        &bad();
#}
