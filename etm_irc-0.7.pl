#!/usr/bin/perl -w
#
# etm_irc.pl v0.7 (17-12-2005)
#
# DEMO Irc-Client for the etadmin_mod tcp-interface.
# If you can do it better, do it! ;)
#
#
# Download demo config here:
# http://et.d1p.de/etadmin_mod/test_/etm_irc.cfg
#
# Start with: ./etm_irc.pl etm_irc.cfg

use Socket;
use Net::IRC;
use IO::File;
use FileHandle;

#use strict;

my $irc         = new Net::IRC;
my $buffer      = '';
my $last        = time;
my $last_sleep  = 1.5;
my %requests    = ();
my $req_counter = 0;
my $connected   = 0;
my %hostmasks   = ();
my $debug       = 0;
my %opts        = ();
my %config      = ();
my %template 	= ();
my $global_self;
my $work_buffer     = "";
my $handle          = new IO::Socket;
my @irc_admin_chans = ();
my @dynamic_chans   = ();
use constant BUFFSIZE => 2**20;
my %notify = ();

my $authorized = 0;

$| = 1;

# for cades flood algorithm
my %FLOOD = ();

my $configfile = shift || die("usage $0 <config_file>");

# Load config
&load_dynamic_chans();
&load_config($configfile);
&post_config_check();

my $k = chr(3);

# Color Hash / Farb hash
# ET-Color -> IRC-Color
my %rpl = (
    "^7" => "${k}00",    # 0
    "^w" => "${k}00",
    "^W" => "${k}00",
    "^0" => "${k}01",
    "^p" => "${k}01",
    "^P" => "${k}01",
    "^4" => "${k}02",
    "^h" => "${k}03",
    "^1" => "${k}04",
    "^i" => "${k}04",
    "^I" => "${k}04",
    "^q" => "${k}04",
    "^Q" => "${k}04",
    "^j" => "${k}05",
    "^J" => "${k}05",
    "^k" => "${k}05",
    "^K" => "${k}05",
    "^+" => "${k}05",
    "^?" => "${k}05",
    "^@" => "${k}05",
    "^c" => "${k}06",
    "^C" => "${k}06",
    "^e" => "${k}06",
    "^E" => "${k}06",
    "^8" => "${k}07",
    "^a" => "${k}07",
    "^A" => "${k}07",
    "^l" => "${k}07",
    "^L" => "${k}07",
    "^x" => "${k}07",
    "^X" => "${k}07",
    "^3" => "${k}08",
    "^o" => "${k}08",
    "^O" => "${k}08",
    "^s" => "${k}08",
    "^S" => "${k}08",
    "^/" => "${k}08",
    "^2" => "${k}09",
    "^g" => "${k}09",
    "^G" => "${k}09",
    "^r" => "${k}09",
    "^R" => "${k}09",
    "^b" => "${k}10",
    "^B" => "${k}10",
    "^-" => "${k}10",
    "^5" => "${k}11",
    "^u" => "${k}11",
    "^U" => "${k}11",
    "^d" => "${k}12",
    "^D" => "${k}12",
    "^f" => "${k}12",
    "^F" => "${k}12",
    "^t" => "${k}12",
    "^T" => "${k}12",
    "^6" => "${k}13",
    "^v" => "${k}13",
    "^V" => "${k}13",
    "^9" => "${k}14",
    "^m" => "${k}14",
    "^M" => "${k}14",
    "^y" => "${k}14",
    "^Y" => "${k}14",
    "^n" => "${k}15",
    "^N" => "${k}15",
    "^z" => "${k}15",
    "^Z" => "${k}15",
    "^*" => "${k}15",
    "^^" => "${k}00",

    # added for etadmin_mod 0.29t20
    "^;" => "${k}01",
          );

#%rev_rpl = reverse %rpl;
my %rev_rpl = (
    "0"  => "^7",
    "00" => "^7",
    "1"  => "^p",
    "01" => "^p",
    "2"  => "^4",
    "02" => "^4",
    "3"  => "^h",
    "03" => "^h",
    "4"  => "^1",
    "04" => "^1",
    "5"  => "^j",
    "05" => "^j",
    "6"  => "^c",
    "06" => "^c",
    "7"  => "^8",
    "07" => "^8",
    "8"  => "^3",
    "08" => "^3",
    "9"  => "^2",
    "09" => "^2",
    "10" => "^b",
    "11" => "^5",
    "12" => "^f",
    "13" => "^6",
    "14" => "^9",
    "15" => "^n"

              );

# rest
for ( 16 .. 99 )
{
    $rev_rpl{"$_"} = "^7";
}

#%rev_rpl = reverse %rpl;

########################################################################################

# First create the etadmin_mod connect.
&etm_connect();

$buffer = '';
my %settings = ();
$settings{'chat'} = 1;

die("Usage: $0 <irc_server> <channel>\n") unless ( $config{'irc_server'} && $config{'irc_chan'} );
&log("Creating connection to IRC server...");

my $conn = $irc->newconn(
                          Server   => ( $config{'irc_server'} ),
                          Port     => $config{'irc_port'},
                          Nick     => $config{'irc_nick'},
                          Ircname  => 'https://hirntot.org https://hirntot.org/discord',
                          Username => 'hirntot'
                        )
  or die "$0: Can't connect to IRC server ($config{'irc_server'}:$config{'irc_port'}, Nick: $config{'irc_nick'}).\n";

&log("Connected to $config{'irc_server'}.");
$irc->addfh( $handle, \&irc_in, "r" );

#
#  Here are the handler subroutines. Fascinating, huh?
#

# What to do when the bot successfully connects.
sub on_connect
{
    my $self = shift;
    $global_self = $self;

    &send_qauth();

    &log("Joining $config{'irc_chan'}...");
    if ( $config{'chan_pass'} )
    {
        $self->join( $config{'irc_chan'} . ' ' . $config{'chan_pass'});
    }
    else
    {
        $self->join( $config{'irc_chan'} );
    }

    for (@irc_admin_chans)
    {
        &log("Joining Admin_chan $_");
        select( undef, undef, undef, 0.5 );
        $self->join($_);
    }

    for (@dynamic_chans)
    {
    	if ($_) {
        	&log("Joining dynamic channel $_");
        	select( undef, undef, undef, 0.5 );
        	$self->join($_);
        }
    }

    #$self->topic($config{'irc_chan'});
    $connected = 1;
}

sub send_qauth
{

    # send Q-auth
    if ( $config{'q_username'} && $config{'q_password'} )
    {
        &log("Sending Q-Auth");
        $global_self->privmsg( 'Q@CServe.quakenet.org', "AUTH $config{'q_username'} $config{'q_password'}" );
        sleep 1;
        $global_self->mode( $global_self->nick, "+x" );
    }
    sleep 1;

}

# Handles some messages you get when you connect
sub on_init
{
    my ( $self, $event ) = @_;
    my (@args) = ( $event->args );
    shift(@args);

    print "*** @args\n";
}

# What to do when someone leaves a channel the bot is on.
sub on_part
{
    my ( $self, $event ) = @_;
    my ($channel) = ( $event->to )[0];

    &log( sprintf( "*** %s has left channel %s", $event->nick, $channel ) );
}

# What to do when someone joins a channel the bot is on.
sub on_join
{
    my ( $self, $event ) = @_;
    my ($channel) = ( $event->to )[0];

    &log( sprintf( "*** %s (%s) has joined channel %s", $event->nick, $event->userhost, $channel ) );

    if ( $config{'op_admins_on_join'} && &check_permission( $event->userhost ) >= 2 )
    {
        $self->mode( "$channel", "+o", $event->nick );    # matches hostmask.
    }

}

# What to do when we receive a private PRIVMSG.
sub on_msg
{
    my ( $self, $event ) = @_;
    my ($nick) = $event->nick;
    my $command = join( ' ', $event->args );

    my $permission = &check_permission( $event->userhost );

    if ( $command eq "help" )
    {
        if ( $permission == 0 )
        {
            &send( $nick, "Use /msg " . $self->nick . " identify <password> to identify yourself." );
        }
        elsif ( $permission == 1 )
        {
            &send(
                   $nick,
                   "You are authed as guest. You only have permission talk to players ingame with "
                     . $config{"irc_prefix"}
                     . "text in my channels."
                 );
        }
        elsif ( $permission == 2 )
        {
            &send(
                $nick,
"You are authed as etadmin. You have permission to use all etadmin_mod commands. No bot commands are available for your level."
            );
        }
        elsif ( $permission == 3 )
        {
            &send(
                   $nick,
                   "You are authed as botadmin. Bot commands: /msg "
                     . $self->nick
                     . " join #chan|part #chan|qauth|readconfig(not yet)|quit."
                 );
        }
    }
    elsif ( $command =~ /^identify (.*)$/i )
    {
        if ( $config{'bot_password'} && $1 eq $config{'bot_password'} )    # bot_password can't be empty
        {
            $hostmasks{ $event->userhost }{'level'}     = 3;
            $hostmasks{ $event->userhost }{'timestamp'} = time;
            &send( $nick,
                   "You have been granted bot admin rights. See /msg " . $self->nick . " help for command overview." );
            sleep 1;
        }
        elsif ( $config{'admin_password'} && $1 eq $config{'admin_password'} )
        {
            $hostmasks{ $event->userhost }{'level'}     = 2;
            $hostmasks{ $event->userhost }{'timestamp'} = time;
            &send( $nick, "You have been granted admin rights." );
            sleep 1;
        }
        elsif ( $config{'guest_password'} && $1 eq $config{'guest_password'} )
        {
            $hostmasks{ $event->userhost }{'level'}     = 1;
            $hostmasks{ $event->userhost }{'timestamp'} = time;
            &send( $nick, "You have been granted guest rights" );
            sleep 1;
        }
        else
        {

            # Better do nothing
        }
    }
    elsif ( $permission > 2 )
    {
        if ( $command =~ /^join (.*)/i )
        {

            my $chan = $1;
            if (    !&in_array( \@dynamic_chans, $chan )
                 && !&in_array( \@irc_admin_chans, $chan )
                 && $config{'irc_chan'} ne $chan )
            {
                if ( $chan =~ /^\#/ )
                {
                    &send( $nick, "Trying to join channel $chan." );
                    $self->join($chan);
                    &add_temp_chan($chan);
                }
                else
                {

                    # invalid chan.
                    &send( $nick, "Invalid channel name $chan." );
                }
            }
            elsif (    &in_array( \@dynamic_chans, $chan )
                    || &in_array( \@irc_admin_chans, $chan )
                    || $config{'irc_chan'} eq $chan )
            {
                &send( $nick, "Channel already configured. Trying to rejoin channel $chan(if not joined)." );
                $self->join($chan);
            }

            #else {
            #		&send( $nick, "Channel $chan already joined / configured." );
            #}
        }
        elsif ( $command =~ /^leave (.*)/i || $command =~ /^part (.*)/i )
        {

            my $chan = $1;
            if ( &in_array( \@dynamic_chans, $chan ) )
            {

                &send( $nick, "Parting channel $chan." );
                my $chan = $1;
                $self->part($chan);
                &del_temp_chan($chan);

            }
            elsif ( &in_array( \@irc_admin_chans, $chan ) )
            {
                &send( $nick, "Won't part channel $chan. It's configured as admin channel." );
            }
            elsif ( $config{'irc_chan'} eq $chan )
            {
                &send( $nick, "Refusing to leave channel $chan. This is my main channel." );
            }
            else
            {
                &send( $nick, "I'm not in channel $chan." );
            }

        }
        elsif ( $command =~ /^readconfig/i )
        {

            #&load_config($configfile)
            &send( $nick, "readconfig: fixme." );
        }
        elsif ( $command =~ /^qauth/i )
        {

            if ( $config{'q_username'} && $config{'q_password'} )
            {
                &send( $nick, "Sending qnet auth..." );
                &log("Sending qauth again.");
                &send_qauth();
            }
            else
            {
                &send( $nick, "No Quakenet auth configured.." );
            }
        }
        elsif ( $command =~ /quit/i )
        {
            $self->quit("Watch my ass!");
            &log( "Got signal to quit (" . $event->nick . "," . $event->userhost . ")" );
            exit(0);
        }
    }

    #&log( "*$nick (" . $event->userhost . ")*  ", ( $event->args ) );

}

sub add_temp_chan
{
    my $chan = shift;
    return if ( !$chan );
    push( @dynamic_chans, $chan );
    &save_dynamic_chans();
}

sub del_temp_chan
{

    my $chan = shift;
    my @tmp  = ();
    for (@dynamic_chans)
    {
        push( @tmp, $_ ) if ( $chan ne $_ );
    }
    @dynamic_chans = @tmp;

    &save_dynamic_chans();
}

sub save_dynamic_chans
{
    open( TMP, ">dynamic_chans" ) || &log("Error opening file dynamic_chans for writing: $!");
    for (@dynamic_chans)
    {
        print TMP $_ . "\n";
    }
    close(TMP);

}

sub load_dynamic_chans
{

    &log("Loading dynamic chans.");
    open( TMP, "dynamic_chans" ) || &log("Couldn't open file dynamic_chans for reading: $!");
    while ( $line = <TMP> )
    {
        chomp $line;
        $line =~ s/(^\s+|\s+$)//g;
        next if ( !$line );
        push( @dynamic_chans, $line ) if ( $line =~ /^\#/ );
    }
    close(TMP);

}

# What to do when we receive channel text.
sub on_public
{
    my ( $self, $event ) = @_;
    my @to = $event->to;
    my ( $nick, $mynick ) = ( $event->nick, $self->nick );
    my ($arg) = ( $event->args );

    my $chan = $to[0];
    &check_hostmasks();

    # Note that $event->to() returns a list (or arrayref, in scalar
    # context) of the message's recipients, since there can easily be
    # more than one.

    #&log( "$chan: <$nick> $arg") if ($debug);
    &log( "$chan: <$nick> " . &irc_decolorize($arg) ) if ($debug);

    if ( index( lc($arg), "!serverinfo" ) == 0 )
    {

        # Floodcheck
        #my $wait = flood_check( 2, 20, $event->userhost ) || flood_check( 10, 120, '*' );
        my $wait = $config{'flood_protection'} ? flood_check( 1, 10, "serverinfo" ) : 0;

        if ( $wait > 0 && &check_permission( $event->userhost ) < 2 )
        {

            &log("Flood protection triggered: $wait");

            # Send notification only once.
            &send( $event->nick, "Please wait $wait seconds before trying again." ) if ( !$notify{ $event->userhost } );
            $notify{ $event->userhost } = 1;
        }
        else
        {

            delete $notify{ $event->userhost };

            $requests{$req_counter}{'target'} = $chan;
            $requests{$req_counter}{'intcmd'} = "serverinfo";
            $requests{$req_counter}{'buffer'} = "";

            print $handle "ETM-" . $req_counter . ":/serverinfo\r\n";

            $req_counter++;
            $req_counter %= 50;    # Store a maximum of 50 request handles.
        }

        return;
    }
    elsif ( index( lc($arg), "!players" ) == 0 )
    {

        # Floodcheck
        #my $wait = flood_check( 2, 20, $event->userhost ) || flood_check( 10, 120, '*' );
        my $wait = $config{'flood_protection'} ? (flood_check( 1, 10, "flood-".$nick ) || flood_check( 3, 9, 'flood-protection' )) : 0;

        if ( $wait > 0 && &check_permission( $event->userhost ) < 2 )
        {
            &log("Flood protection triggered: $wait");

            # Send notification only once.
            &send( $event->nick, "Please wait $wait seconds before trying again." ) if ( !$notify{ $event->userhost } );
            $notify{ $event->userhost } = 1;
        }
        else
        {
            delete $notify{ $event->userhost };

            $requests{$req_counter}{'target'} = $chan;
            #$requests{$req_counter}{'target'} = $chan;
            if ( check_permission( $event->userhost ) >= 2 )
            {
                $requests{$req_counter}{'intcmd'} = "players_admin";
            }
            else
            {
                $requests{$req_counter}{'intcmd'} = "players";
            }
            $requests{$req_counter}{'buffer'} = "";

            print $handle "ETM-" . $req_counter . ":/listplayers\r\n";

            $req_counter++;
            $req_counter %= 50;
        }
        return;
    }
    elsif ( &check_permission( $event->userhost ) >= 1 )
    {

        if ( index( lc($arg), "!chat" ) == 0 && &check_permission( $event->userhost ) >= 2 )
        {
            if ( $arg =~ /!chat\s+(\d+)/i )
            {
                $settings{'chat'} = $1;
                &send( $event->nick, "Set chat to: " . $settings{'chat'} );
            }
            else
            {
                &send( $event->nick, "Current Value of chat: " . $settings{'chat'} );
            }
        }
        elsif ( index( lc($arg), "!colors" ) == 0 && &check_permission( $event->userhost ) >= 2 )
        {
            if ( $arg =~ /!colors\s+(\d+)/i )
            {
                $config{'colors'} = $1;
                &send( $event->nick, "Set colors to: " . $config{'colors'} );
            }
            else
            {
                &send( $event->nick, "Current Value of colors: " . $config{'colors'} );
            }
        }
        else
        {
            if ( $arg =~ s/^\s*$config{'irc_prefix'}// )
            {

                # Floodcheck
                my $wait =
                  $config{'flood_protection'}
                  ? ( flood_check( 3, 15, $event->userhost ) || flood_check( 6, 30, '*' ) )
                  : 0;

                if ( $wait > 0 && &check_permission( $event->userhost ) < 2 )
                {

                    &log("Flood protection triggered: $wait");

                    # Send notification only once.
                    &send( $event->nick, "Please wait $wait seconds before trying again." )
                      if ( !$notify{ $event->userhost } );
                    $notify{ $event->userhost } = 1;
                }
                else
                {

                    delete $notify{ $event->userhost };

                    if ( $arg =~ /^\s*\// && &check_permission( $event->userhost ) > 1 )
                    {
                        $requests{$req_counter}{'target'} = $nick;
                        $requests{$req_counter}{'intcmd'} = "";
                        $requests{$req_counter}{'buffer'} = "";
                        &log("Storing $req_counter -> $nick") if ($debug);
                        print $handle "ETM-" . $req_counter . ":" . $arg . "\r\n";

                        $req_counter++;
                        $req_counter %= 50;
                    }
                    else
                    {
                        if ( $arg =~ /^\s*\Q$config{'etm_prefix'}\E/ && &check_permission( $event->userhost ) > 1 )
                        {
                            &log("Sending $arg ($nick) command") if ($debug);
                            print $handle &irc_decolorize($arg) . "\r\n";
                        }
                        else
                        {
                            &log("Sending $nick -> $arg text");
                            print $handle $nick . ": " . &irc_decolorize($arg) . "\r\n";
                        }
                        sleep 1;
                    }
                }
            }
        }

    }

    return;

    if ( $arg =~ /^chat/i )
    {    # Request a DCC Chat initiation
        $self->new_chat( 1, $event->nick, $event->host );
    }

    # You can invoke this next part with "Send me Filename" or
    # "Send Filename to me". It doesn't much like ending punctuation, though.

    $arg =~ s/[^"'\w]*?\b(to|me)\b[^'"\w]*?//g;

    if ( $arg =~ /^send\s+(\S+)\s*/i )
    {
        if ( -e $1 )
        {
            $self->privmsg( $nick, "Sending $1 in 10 seconds..." );
            $self->schedule( 10, \&Net::IRC::Connection::new_send, $nick, $1 );
        }
        else
        {
            $self->privmsg( $nick, "No such file as $1, sorry." );
        }
    }
}

sub on_umode
{
    my ( $self, $event ) = @_;
    my @to = $event->to;
    my ( $nick, $mynick ) = ( $event->nick, $self->nick );
    my ($arg) = ( $event->args );

    # Note that $event->to() returns a list (or arrayref, in scalar
    # context) of the message's recipients, since there can easily be
    # more than one.

    &log("<$nick> $arg");

    return;

    #if ( $arg =~ /Go away/i )
    #{                                              # Tell him to leave, and he does.
    #    $self->quit("Yow!!");
    #    exit 0;
    #}

    if ( $arg =~ /^chat/i )
    {    # Request a DCC Chat initiation
        $self->new_chat( 1, $event->nick, $event->host );
    }

    # You can invoke this next part with "Send me Filename" or
    # "Send Filename to me". It doesn't much like ending punctuation, though.

    $arg =~ s/[^"'\w]*?\b(to|me)\b[^'"\w]*?//g;

    if ( $arg =~ /^send\s+(\S+)\s*/i )
    {
        if ( -e $1 )
        {
            $self->privmsg( $nick, "Sending $1 in 10 seconds..." );
            $self->schedule( 10, \&Net::IRC::Connection::new_send, $nick, $1 );
        }
        else
        {
            $self->privmsg( $nick, "No such file as $1, sorry." );
        }
    }
}

# What to do when we receive a message via DCC CHAT.
sub on_chat
{
    my ( $self, $event ) = @_;
    my ($sock) = ( $event->to )[0];

    my $command = join( ' ', $event->args );

    #print '*' . $event->nick . '* "' . $command . '"\n';

}

# Prints the names of people in a channel when we enter.
sub on_names
{
    my ( $self, $event )   = @_;
    my ( @list, $channel ) = ( $event->args );    # eat yer heart out, mjd!

    # splice() only works on real arrays. Sigh.
    ( $channel, @list ) = splice @list, 2;

    &log("Users on $channel: @list");
}

# What to do when we receive a DCC SEND or CHAT request.
sub on_dcc
{
    my ( $self, $event ) = @_;
    my $type = ( $event->args )[1];

    return;

    # we don't do dcc.

    if ( uc($type) eq 'SEND' )
    {
        open TEST, ">/tmp/net-irc.dcctest"
          or do { warn "Can't open test file: $!"; return; };
        $self->new_get( $event, \*TEST );
        print "Saving incoming DCC SEND to /tmp/net-irc.dcctest\n";
    }
    elsif ( uc($type) eq 'CHAT' )
    {
        $self->new_chat($event);
    }
    else
    {
        print STDERR ( "Unknown DCC type: " . $type );
    }
}

# Yells about incoming CTCP PINGs.
sub on_ping
{
    my ( $self, $event ) = @_;
    my $nick = $event->nick;

    $self->ctcp_reply( $nick, join( ' ', ( $event->args ) ) );
    &log("*** CTCP PING request from $nick received");
}

# Gives lag results for outgoing PINGs.
sub on_ping_reply
{
    my ( $self, $event ) = @_;
    my ($args) = ( $event->args )[1];
    my ($nick) = $event->nick;

    $args = time - $args;
    &log("*** CTCP PING reply from $nick: $args sec.");
}

# Change our nick if someone stole it.
sub on_nick_taken
{
    my ($self) = shift;

    $self->nick( substr( $self->nick, -1 ) . substr( $self->nick, 0, 8 ) );
}

# Display formatted CTCP ACTIONs.
sub on_action
{
    my ( $self, $event ) = @_;
    my ( $nick, @args )  = ( $event->nick, $event->args );

    &log("* $nick @args ");
}

# Reconnect to the server when we die.
sub on_disconnect
{
    my ( $self, $event ) = @_;

    &log( "Disconnected from irc-server.",
          $event->from(), " (",
          ( $event->args() )[0],
          "). Attempting to reconnect..." );
    sleep 1;
    $connected = 0;
    $self->connect();
}

# Look at the topic for a channel you join.
sub on_topic
{
    my ( $self, $event ) = @_;
    my @args = $event->args();

    # Note the use of the same handler sub for different events.

    if ( $event->type() eq 'notopic' )
    {
        &log("No topic set for $args[1].");

        # If it's being done _to_ the channel, it's a topic change.
    }
    elsif ( $event->type() eq 'topic' and $event->to() )
    {
        print "Topic change for ", $event->to(), ": $args[0]\n";

    }
    else
    {
        print "The topic for $args[1] is \"$args[2]\".\n";
    }
}

sub blah
{
    my ( $self, $event ) = @_;
    print "Got event of type: " . $event->type . "\n";
    print $event->args . "\n";

    if ( $event->type eq "invite" && &check_permission( $event->userhost ) >= 3 )
    {

        my $chan = ( $event->args )[0];

        if (    !&in_array( \@dynamic_chans, $chan )
             && !&in_array( \@irc_admin_chans, $chan )
             && $config{'irc_chan'} ne $chan )
        {
            my $chan = $1;
            if ( $chan =~ /^\#/ )
            {
                &send( $nick, "Trying to join channel $chan." );
                $self->join($chan);
                &add_temp_chan($chan);
            }
            else
            {

                # invalid chan.
                &send( $nick, "Invalid channel name $chan." );
            }
        }
        if ( &in_array( \@dynamic_chans, $1 ) || &in_array( \@irc_admin_chans, $1 ) || $config{'irc_chan'} eq $1 )
        {
            &send( $nick, "Channel already configured. Trying to rejoin channel $chan (if not joined)." );
            $self->join($chan);
        }
        else
        {
            &send( $nick, "Channel $chan already joined / configured." );
        }

    }

    my ( $nick, $mynick ) = ( $event->nick, $self->nick );
    print "Nicks: $nick / $mynick - Args: " . join( ':', $event->args ) . "\n";

}

sub on_kick
{
    my ( $self, $event ) = @_;
    my ( $nick, $mynick ) = ( $event->nick, $self->nick );
    &log( "Got kicked from " . ( ( $event->args )[0] ) . " (Rejoining in 1 second)" ) if ($nick eq $mynick);
    #&log( "Saw kick: $nick / $mynick - Args: " . join( ':', $event->args ) );

    sleep 1;
    $self->join( ( $event->args )[0] );

}

&log("Installing handler routines...");

#$conn->add_default_handler(\&blah);
$conn->add_handler( 'cping',   \&on_ping );
$conn->add_handler( 'kick',    \&on_kick );
$conn->add_handler( 'invite',  \&blah );
$conn->add_handler( 'crping',  \&on_ping_reply );
$conn->add_handler( 'msg',     \&on_msg );
$conn->add_handler( 'chat',    \&on_chat );
$conn->add_handler( 'public',  \&on_public );
$conn->add_handler( 'caction', \&on_action );
$conn->add_handler( 'join',    \&on_join );
$conn->add_handler( 'umode',   \&on_umode );
$conn->add_handler( 'part',    \&on_part );

#$conn->add_handler('cdcc',   \&on_dcc);
#$conn->add_handler('topic',   \&on_topic);
#$conn->add_handler('notopic',   \&on_topic);

$conn->add_global_handler( [ 251, 252, 253, 254, 302, 255 ], \&on_init );
$conn->add_global_handler( 'disconnect', \&on_disconnect );
$conn->add_global_handler( 376,          \&on_connect );
$conn->add_global_handler( 433,          \&on_nick_taken );
$conn->add_global_handler( 353,          \&on_names );

#&log("Starting irc loop.");

my $sleep = 0.7;
$irc->start;

sub irc_in
{
    my $socket = shift;
    my ($self) = shift;

    $sleep = 0.7;

    my $read = sysread( $handle, $buffer, BUFFSIZE - length $buffer, length $buffer );

    if ( !$buffer )
    {
        close($handle);
        warn("Connection gone away. Reconnect in 30 seconds.");
        if ($global_self)
        {
            $global_self->privmsg( $config{'irc_chan'},
                                   "Connection to the etadmin_mod has gone away. Reconnect in 30 seconds." );
        }
        sleep 30;
        &etm_connect();
    }
    else
    {
        if ( $last + 2 > time )
        {
            $sleep = ( $last_sleep ? $last_sleep : 1.6 );
        }

        $work_buffer .= $buffer;

        while ( $work_buffer =~ s/^(.*?)\r?\n// )
        {
            my $dat    = $1;
            my $send   = 1;
            my $target = "";

            &log("SERVER: '$dat'") if ($debug);

	    if (!$authorized && index($dat, "You have authorized yourself as") == 0) {
	    	   &log("Authorized to the etadmin_mod as user $config{'username'}, setting default filter to 191.");
                   print $handle "/etm 223\r\n";
                   print $handle "/etm_kills 2\r\n";
                   print $handle "/etm_chat 3\r\n";
        	   #print $handle "/filter 2\r\n";
	    	   next ;	
	    }
	    elsif (!$authorized && index($dat, "Permission denied") == 0) {
   	   	&log("etadmin_mod authorisation failed, check your config.");
	        if ($global_self)
	        {
	            $global_self->privmsg( $config{'irc_chan'},
	                                   "Wrong username / password for connecting to etadmin_mod. Quiting, check config!" );
	        }
	        exit;   
	    }

            if ( $dat =~ s/^ETM-ANSWER-(\d+):// )
            {

                # add to buffer
                $requests{$1}{'buffer'} .= $dat . "\n";
                $send = 0;
            }
            elsif ( $dat =~ /^ETM-ANSWER-(\d+)-END$/ )
            {

                my $id = $1;

                # message ends. Process it.
                if ( $requests{$id}{'intcmd'} )
                {

                    # Internal command, lets see, what it is...

                    if ( $requests{$id}{'intcmd'} eq "players" || $requests{$id}{'intcmd'} eq "players_admin" )
                    {

                        my %datahash = ();

                        my @data = split( /\n/, $requests{$id}{'buffer'} );
                        for (@data)
                        {

                            # 13  0 7D6F19B0BC656C38499D0FDE619A649A 62.214.154.145 b 2.70 E tarantula
                            if (/^\s*(\d+)\s+(\d+) \w{32} \d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3} \w [^\s]+ \w (.*)$/)
                            {
                                $datahash{$1}{'name'}  = $3;
                                $datahash{$1}{'level'} = $2;
                            }
                        }

                        my $counter = 1;
                        my $output  = "Players: ";
                        my @keysa   = keys %datahash;
                        my $max     = $#keysa + 1;

                        if ( $max == 0 )
                        {
                            &send( $requests{$id}{'target'}, "Players: No players on the server. :(" );
                        }
                        else
                        {

                            foreach my $player ( sort { $a <=> $b } keys %datahash )
                            {

                                $output .=
                                    $datahash{$player}{'level'} > 0
                                  ? &colorize("^1") . $datahash{$player}{'name'} . "${k}${k}"
                                  : "$datahash{$player}{'name'} ";
                                $output .= $requests{$id}{'intcmd'} eq "players_admin" ? "($player)" : "";
                                $output .= "|" if ( $max != $counter );
                                if ( length( $output ) > 160 || $max == $counter )
                                {
                                    &send( $requests{$id}{'target'}, $output );
                                    $output = "";
                                }
                                $counter++;
                            }
                            if ($output)
                            {
                                &send( $requests{$id}{'target'}, $output );
                            }
                        }

                    }
                    elsif ( $requests{$id}{'intcmd'} eq "serverinfo" )
                    {

                        my %datahash = ();

                        my @data = split( /\n/, $requests{$id}{'buffer'} );
                        for (@data)
                        {
                            if (/^([^\s]+)\s+(.*)$/)
                            {
                                $datahash{ lc($1) } = $2;
                            }
                        }

                        if ( $datahash{'sv_hostname'} && $datahash{'sv_maxclients'} && $datahash{'mapname'} )
                        {

                            $datahash{'P'} = "" if ( !$datahash{'P'} );

                            # Count players:
                            my $axis   = $datahash{'p'} =~ s/1/4/g || 0;
                            my $allies = $datahash{'p'} =~ s/2/4/g || 0;
                            my $spec   = $datahash{'p'} =~ s/3/4/g || 0;
                            my $private = $datahash{'sv_privateclients'} || 0;
                            my $max     = $datahash{'sv_maxclients'}     || 0;
                            my $overall = $datahash{'p'} =~ s/[\d]/-/g || 0;

         # show data.
         #print "Data: $axis $allies $spec $overall/$datahash{'sv_maxclients'} Map: $datahash{'mapname'}\n" if ($debug);
                            &send(
                                $requests{$id}{'target'},
                                &colorize(
"$datahash{'sv_hostname'} ${k}${k}Mapname: $datahash{'mapname'} Axis:$axis Allies:$allies Spec:$spec [$overall/"
                                      . ( $max - $private )
                                      . "+$private]"
                                )
                            );
                        }
                        else
                        {

                            #print "Insufficent data\n";
                            &send( $requests{$id}{'target'}, "Not enough informations to display a status" );
                        }
                    }
                    else
                    {

                        # dunno.. ignoring.
                        &log("Ignoring: $requests{$id}{'intcmd'}") if ($debug);
                    }

                }
                else
                {
                    &log( "Found private message to: " . $requests{$1}{'target'} ) if ($debug);
                    &send( $requests{$id}{'target'}, split( /\n/, &decolorize( $requests{$1}{'buffer'} ) ) );
                }
                delete $requests{$id};

                # i already sent this.
                $send = 0;
            }
            else
            {

                if ( $dat =~ s/^ETM-([^:]+):\s*(.*)$/$2/ )
                {
                    my $info = $1;
                    #print "Dat: ".$dat."\n";
                    if ( $info eq "CHAT" )
                    {
                        if ( $dat =~
s/^(say[:\s]+?|qsay|chat)\s*\"?(.*?)\"?$/"Chat event [ ".&color("^h").&decolorize($2)."${k}${k} ]"/gie
                           )
                        {
                            if ($2)
                            {
                                my %cvar = (
                                             "<CTEXT>" => $2,
                                             "<TEXT>"  => &decolorize($2)
                                           );
                                $dat = &template_replace( $template{'chat:global'}, \%cvar );

                                $send = 1;
                            }

                            if ( $2 =~ /^(.*): \Q$config{'etm_prefix'}\Eadmin(\s+(.*)$|$)]/ )
                            {

                                # Send to admin channels.
                                for (@irc_admin_chans)
                                {
                                    if ($2)
                                    {
                                        $global_self->privmsg(
                                                  $_,
                                                  &decolorize($1)
                                                    . &colorize(
                                                      " ^1issued the !admin command. Matter: ${k}${k}" . &decolorize($2)
                                                    )
                                        );
                                    }
                                    else
                                    {
                                        $global_self->privmsg( $_,
                                                          &decolorize($1)
                                                        . &colorize(" ^1issued the !admin command. No matter given.") );
                                    }
                                    select( undef, undef, undef, $sleep );
                                    $sleep += 0.1 if ( $sleep < 2.0 );
                                }
                            }
                        }
                        elsif ( $dat =~
s/^(sayteam:)\s*\"?(.*?)\"?$/"Chat event [ ".&color("^b").&decolorize($2)."${k}${k} ]"/gie
                          )
                        {
                            my %cvar = (
                                         "<CTEXT>" => $2,
                                         "<TEXT>"  => &decolorize($2)
                                       );
                            $dat =
                              &template_replace( $template{'chat:team'}, \%cvar );
                            $send = 1;
                        }
                        elsif ( $dat =~
s/^(saybuddy:)\s*\"?(.*?)\"?$/"Chat event [ ".&color("^b").&decolorize($2)."${k}${k} ]"/gie
                          )
                        {
                            my %cvar = (
                                         "<CTEXT>" => $2,
                                         "<TEXT>"  => &decolorize($2)
                                       );
                            $dat =
                              &template_replace( $template{'chat:buddy'}, \%cvar );
                            $send = 1;
                        }
                        else
                        {
                            $send = 0;
                        }
                    }
                    elsif ( $info eq "RCON" )
                    {
                        if ( $dat =~
                             s/^(bp|cpmsay|cp)\s*\"?(.*?)\"?$/"Banner event [ ".&color("^y").&decolorize($2)." ]"/gie )
                        {
                            my %cvar = (
                                         "<CTEXT>" => $2,
                                         "<TEXT>"  => &decolorize($2)
                                       );
                            $dat = &template_replace( $template{'chat:banner'}, \%cvar );
                            $send = 1;
                        }
                        else
                        {
                            $send = 0;
                        }
                    }
                    elsif ( $info eq "WARN" )
                    {
                    	$dat =~ s/^Warned//i;
                        my %cvar = (
                                "<CTEXT>" => $dat,
                                "<TEXT>"  => &decolorize($dat)
                                  );
                        $dat = &template_replace( $template{'warn'}, \%cvar );
                        $send = 1;
                    }                    
                    elsif ( $info eq "VOTE" )
                    {

                        # ^7^8-=^d[^8VP^d]^lH.^oPo^nTT^3eR^8=- ^7called a vote: Coin Toss
                        # "^7^8-=^d[^8VP^d]^lH.^oPo^nTT^3eR^8=- ^7called a vote: Coin Toss"
                        if ( $dat =~ /^(.+) (\^[7;])?called a vote: (.+)$/i )
                        {
                            my %cvar = (
                                         "<CNAME>" => $1,
                                         "<NAME>"  => &decolorize($1),
                                         "<VOTE>"  => &decolorize($3),
                                         "<CVOTE>" => $3,
                                       );
                            $dat = &template_replace( $template{'vote:cast'}, \%cvar );
                        }
                        elsif ( $dat =~ /^Vote (Failed|Passed): (.*)$/i )
                        {
                            my %cvar = (
                                         "<RESULT>" => $1,
                                         "<VOTE>"   => &decolorize($2),
                                         "<CVOTE>"  => $2
                                       );
                            $dat = &template_replace( $1 eq "Failed" ? $template{'vote:failed'} : $template{'vote:passed'}, \%cvar );
                        }
                        $send = 1;
                    }
                    elsif ( $info eq "KILL" )
                    {

                        print "Found KILL: $dat\n" if ($debug);

                        # KILL: ^2T^7ibledorn ^;(1) -> ^1Bender^7Bending^1Rodriguez ^;(1)
                        if (
                            $dat =~ /^KILL: (.+) (\^[7;])?\((\d+)\) -> (.+) (\^[7;])?\((\d+)\)\s*\^?;?(by [\w_-]+)?$/i )
                        {

                            my $weapon = $7 ? " $7" : "";
                            my %cvar = (
                                         "<CKILLER>" => &decolorize($1),
                                         "<KILLER>"  => $1,
                                         "<KILLS>"   => $3,
                                         "<KILLED>"  => &decolorize($4),
                                         "<CKILLED>" => $4,
                                         "<DEATHS>"  => $6,
                                         "<WEAPON>"  => $weapon
                                       );
                            $dat = &template_replace( $template{'kill:kill'}, \%cvar );

                            $send = 1;
                        }
                        elsif (
                              $dat =~ /^TK: (.+) (\^[7;])?\((\d+)\) -> (.+) (\^[7;])?\((\d+)\)\s*\^?;?(by [\w_-]+)?$/i )
                        {
                            my $weapon = $7 ? " $7" : "";
                            my %cvar = (
                                         "<CKILLER>" => &decolorize($1),
                                         "<KILLER>"  => $1,
                                         "<KILLS>"   => $3,
                                         "<KILLED>"  => &decolorize($4),
                                         "<DEATHS>"  => $6,
                                         "<WEAPON>"  => $weapon
                                       );
                            $dat = &template_replace( $template{'kill:teamkill'}, \%cvar );

                            $send = 1;
                        }
                        elsif ( $dat =~ /^SUICIDE: (.+) (\^[7;])?\((\d+)\)$/i )
                        {
                            my %cvar = (
                                         "<CNAME>" => $1,
                                         "<NAME>"  => &decolorize($1)
                                       );
                            $dat = &template_replace( $template{'kill:suicide'}, \%cvar );
                            $send = 1;
                        }
                    }
                    elsif ( $info eq "KICK" )
                    {

                        #Kick: BFU*Vycik. Reason: Name stealing / faking.
                        if ( $dat =~ /^Kick: (.+)\. Reason: (.*)$/i )
                        {
                            my %cvar = (
                                         "<CNAME>"  => $1,
                                         "<NAME>"   => &decolorize($1),
                                         "<REASON>" => $2
                                       );
                            $dat = &template_replace( $template{'kick'}, \%cvar );

                            $send = 1;
                        }
                    }
                    elsif ( $info eq "ETPRO" )
                    {

                        #$dat =~ s/^etpro announce: (.*)$/$1/;
                        #$dat =~ s/^etpro popup: (.*)$/$1/;
                        $dat =~ s/^etpro //;
                        #$dat = "Game Event [ " . &color("^8") . &decolorize($dat) . "${k}${k} ]";
                        my %cvar = (
                                     "<CTEXT>" => $dat,
                                     "<TEXT>"  => &decolorize($dat)
                                   );
                        $dat = &template_replace( $template{'etpro'}, \%cvar );

                        $send = 1;
                    }
                    elsif ( $info eq "INFO" )
                    {
                        if ( $dat =~ /Map: (.*) \(Timelimit: ([\d\.]+) minutes\)/ )
                        {
                            my %cvar = (
                                         "<MAP>"       => $1,
                                         "<TIMELIMIT>" => $2,
                                       );
                            $dat = &template_replace( $template{'info:map'}, \%cvar );

                        }
                        elsif ( $dat =~ /^(.*) (\^[7;])?on slot (\d+) disconnected./ )
                        {
                            my %cvar = (
                                         "<CNAME>" => $1,
                                         "<NAME>"  => &decolorize($1),
                                         "<SLOT>"  => $3,
                                       );
                            $dat = &template_replace( $template{'info:disconnect'}, \%cvar );

                        }
                        elsif ( $dat =~ /^(.*) (\^[7;])?(dis)?connected on slot (\d+)./ )
                        {
                            my %cvar = (
                                         "<CNAME>" => $1,
                                         "<NAME>"  => &decolorize($1),
                                         "<SLOT>"  => $4
                                       );
                            $dat =
                              &template_replace( $3 ? $template{'info:disconnect'} : $template{'info:connect'},
                                                 \%cvar );
                        }
                        elsif ( $dat eq "Intermission starts" )
                        {
                            my %cvar = ();
                            $dat = &template_replace( $template{'info:intermission'}, \%cvar );
                        }
                        elsif ( index( $dat, "Namechange:" ) == 0 )
                        {
			    $dat =~ /^Namechange: (.*) (\^[7;])?-> (.*)$/i;                        	
                            my %cvar = (
                                         "<COLDNAME>" => $1,
                                         "<OLDNAME>"  => &decolorize($1),
                                         "<CNEWNAME>" => $3,
                                         "<NEWNAME>"  => &decolorize($3)
                                       );

                            # Player  hellish renamed to  HelliSh.
                            $dat = &template_replace( $template{'info:namechange'}, \%cvar );
                        }

                        $send = 1;
                    }
                }
                else
                {
                    $send = 0;
                }
            }

            if ( $send && $connected )
            {
                $dat =~ s/^"(.*)"$/$1/;
                $dat =~ s/=([\dA-Fa-f][\dA-Fa-f])/pack ("C", hex($1))/eg;

                #$dat =~ s/:/^7:/g;
                #$dat =~ s/ killed / ${k}${k}killed /g if ( $dat =~ s/ by MOD/ ${k}by MOD/g );

                &log("Sleep: $sleep (ls: $last_sleep, last: $last)") if ($debug > 1);
                my $message = &colorize($dat);
                if ($global_self)
                {
                    &log("Chan: $config{'irc_chan'}, Msg: $message") if ( $debug > 0 );
                    $global_self->privmsg( $config{'irc_chan'}, $message );
                }

                select( undef, undef, undef, $sleep );
                $sleep += 0.1 if ( $sleep < 2.0 );
                $last = time;
            }
        }
        $buffer = '';

    }
    $last_sleep = $sleep;

}

sub colorize
{
    my $message = shift;

    $message =~ s/(\^.)/$rpl{$1}/ge;
    return $message;
}

sub irc_decolorize
{
    my $message = shift;

    $message =~ s/${k}$k/$k/g;
    $message =~ s/${k}(\D)/^7$1/g;
    $message =~ s/${k}(\d{1,2})(,\d{1,2})?/$rev_rpl{$1}/ge;

    return $message;
}

sub decolorize
{
    my $message = shift;
    $message =~ s/\^.//g;
    return $message;

}

sub check_permission
{
    my $hostmask = shift;

    if ( defined( $hostmasks{$hostmask} ) && $hostmasks{$hostmask} > 0 )
    {
        $hostmasks{$hostmask}{'timeout'} = time;
        return $hostmasks{$hostmask}{'level'};
    }

    return 0;

}

sub check_hostmasks
{
    foreach my $mask ( keys %hostmasks )
    {
        if ( ( $hostmasks{$mask}{'timestamp'} + $config{'timeout'} * 60 ) < time() )
        {
            &log(   "Hostmask $mask timed ("
                  . ( $hostmasks{$mask}{'timestamp'} + $config{'timeout'} * 60 ) . " < "
                  . time()
                  . ") out" );
            delete $hostmasks{$mask};
        }
    }

}

sub etm_connect
{

    my $quite = shift || 0;
    $authorized = 0;

    socket( $handle, PF_INET, SOCK_STREAM, getprotobyname('tcp') );
    my $internet_addr = inet_aton( $config{'remote_host'} )
      or die("Konnte $config{'remote_host'} nicht in eine Internetaddresse umwandeln: $!\n");
    my $paddr = sockaddr_in( $config{'remote_port'}, $internet_addr );

    my $status = connect( $handle, $paddr );

    if ( !$status )
    {

	#warn("Konnte keine Verbindung zu $remote_host:$remote_port aufbauen\n");
	#if (!$quite && $global_self) {
	#	$global_self->privmsg( $IRC_CHAN, "Connection to the etadmin_mod failed. Retrying in 60 seconds (last time you see this message)." );
	#	$global_self->schedule( 60, \&etm_connect, 1 );
	#}

    }
    else
    {

        select($handle);
        $| = 1;
        select(STDOUT);

        print $handle "/identify $config{'username'} $config{'password'}\r\n";
        
        $authorized = 0;

    }

    if ( $status && $global_self )
    {
        $global_self->privmsg( $config{'irc_chan'}, "Connection to the etadmin_mod established." );
    }

}

# shall i use more colors or not.
sub color
{
    my $color = shift;
    return ( $config{'colors'} ? $color : "" );
}

sub send
{
    my $target = shift;
    my @data   = @_;
    my $amount = $#data + 1;

    &log("Sending to $target") if ($debug);

    if ($connected)
    {

        for (@data)
        {

            # don't send empty lines
            next                                                 if ( !$_ );
            &log("Sleep: $sleep (ls: $last_sleep, last: $last)") if ($debug);
            if ( index( $target, "#" ) == 0 )
            {
                $global_self->privmsg( $target, $_ );
            }
            else
            {
                if ( $amount > 3 )
                {

                    # send query
                    $global_self->privmsg( $target, $_ );
                }
                else
                {

                    # send notice
                    $global_self->notice( $target, $_ );
                }
            }
            select( undef, undef, undef, $sleep );
            $sleep += 0.1 if ( $sleep < 2.0 );
            $last = time;
        }

    }

}

sub load_config
{

    my ($file)    = @_;
    my $fh        = 'fh00';
    my $abschnitt = "config";

    @irc_admin_chans = ();

    &log("Loading config_file $file");
    open( $fh, $file ) || die("Error opening file $file: $!");

    my $store = "";
    my $buff  = "";
    while ( sysread $fh, $buff, 4096 )
    {
        $store .= $buff;
    }

    my @lines = split /\r?\n/, $store;

    for (@lines)
    {
        
        s/\s*\/\/.*//;          # strip of comments with // (even in lines) (used by some people)
        s/(^\s+|\s*\r*$)//g;    # strip off whitespaces and windows breaks

        #next if ( !$_ || /^\s*\#/ );
        next if ( !$_ );

        if (/^\[(.*)\]$/)
        {
        	$abschnitt = lc($1);    
        	next;
        }

        if ( $abschnitt eq "config" )
        {
            $config{$1} = $2 if (/^(.*?)\s*=\s*(.*)$/);
            &log("Config: $1 - $2\n") if ( $debug > 1 );
        }
        elsif ( $abschnitt eq "templates" )
        {
            $template{$1} = $2 if (/^(.*?)\s*=\s*(.*)$/);
            &log("Template: $1 - $2\n") if ( $debug > 1 );
        }

    }
    close($fh);

    if ( $config{'irc_admin_chans'} )
    {
        my @tmp = split( /\s*[,;]\s*/, $config{'irc_admin_chans'} );
        for my $chan (@tmp)
        {
            if ( $chan =~ /^\#(.*)$/ )
            {
                push( @irc_admin_chans, $chan );
            }
        }
    }

}

sub log
{

    my $log = shift;
    chomp $log;
    $log =~ s/\n/::/g;

    # if not in debug mode and message says:
    # 'DEBUG: this is debug text'
    # message will be ignored
    # cade.
    return if $log =~ s/^DEBUG:\s*//i and !$config{'debug'};
    print STDOUT &time2date(time) . " $log\n";

}

sub time2date
{
    my $time = shift || time;
    my ( $sec, $min, $std, $mtag, $mon, $jahr, $wochentag, $jahrestag ) = localtime($time);

    $mon++;
    $jahr += 1900;
    $jahr =~ s/^..//;

    $sec  = "0$sec"  if ( $sec < 10 );
    $min  = "0$min"  if ( $min < 10 );
    $std  = "0$std"  if ( $std < 10 );
    $mtag = "0$mtag" if ( $mtag < 10 );
    $mon  = "0$mon"  if ( $mon < 10 );

    #return "$mtag/$mon/$jahr $std:$min:$sec";
    return "$mon/$mtag/$jahr $std:$min:$sec";
}

sub post_config_check
{

    # CHECK IRC_DATA

    if ( $config{'irc_server'} && $config{'irc_port'} && $config{'irc_chan'} && $config{'irc_nick'} )
    {

        # basic config exists.
    }
    else
    {
        &log("Basic IRC-Setup incomplete. Check irc_server / irc_port / irc_chan and irc_nick.");
        exit(1);
    }

    if ( !$config{'username'} || !$config{'password'} )
    {
        &log("Basic etadmin_mod user setup incomplete. Check username / password.");
        exit(1);
    }

    if ( !$config{'remote_host'} || !$config{'remote_port'} )
    {
        &log("Basic etadmin_mod connection setup incomplete. Check remote_host / remote_port.");
        exit(1);
    }

    if ( !$config{'admin_password'} || !$config{'password'} )
    {
        &log("You have not configured a guest or admin_password!");
        exit(1);
    }
    if ( !$config{'bot_password'} )
    {
        &log("You have not configured a bot_password to administrate the irc-bot (new in etm_irc.pl v0.5)!");
        exit(1);
    }
    if ( $config{'colors'} != 0 && $config{'colors'} != 1 )
    {
        &log("colors option unset. Using default of 1.");
        $config{'colors'} = 1;
    }

    if ( !$config{'irc_prefix'} )
    {
        &log("irc_prefix option unset. Using default value \"::\"");
        $config{'prefix'} = "::";
    }

    if ( !$config{'etm_prefix'} )
    {
        &log("etm_prefix option unset. Using default value \"!\"");
        $config{'prefix'} = "::";
    }

    if ( !$config{'timeout'} || $config{'timeout'} < 0 || $config{'timeout'} =~ /[^\d]/ )
    {
        &log("Illegal timeout value. Using default of 60.");
        $config{'timeout'} = 60;
    }

    # check templates
    $template{'chat:global'} = "Chat event [ ^h<TEXT><K> ]"   if ( !$template{'chat:global'} );
    $template{'chat:team'}   = "Chat event [ ^b<TEXT><K> ]"   if ( !$template{'chat:team'} );
    $template{'chat:buddy'}  = "Chat event [ ^b<TEXT><K> ]"   if ( !$template{'chat:buddy'} );
    $template{'chat:banner'} = "Banner event [ ^y<TEXT><K> ]" if ( !$template{'chat:banner'} );

    $template{'vote:cast'}   = "Vote called [ ^1<VOTE><K> ] by <NAME>" if ( !$template{'vote:cast'} );
    $template{'vote:failed'} = "Vote <RESULT> [ <VOTE><K> ]"           if ( !$template{'vote:failed'} );
    $template{'vote:passed'} = "Vote <RESULT> [ <VOTE><K> ]"           if ( !$template{'vote:passed'} );

    $template{'info:namechange'} = "^1Player<K> <OLDNAME> ^1renamed to <K><NEWNAME>"
      if ( !$template{'info:namechange'} );
    $template{'info:map'}        = "^1Map changed to [ <K><MAP> ^1]"            if ( !$template{'info:map'} );
    $template{'info:connect'}    = "<NAME> ^1on slot<K> <SLOT>^1 connected."    if ( !$template{'info:connect'} );
    $template{'info:disconnect'} = "<NAME> ^1on slot<K> <SLOT>^1 disconnected." if ( !$template{'info:disconnect'} );
    $template{'info:intermission'} = "^1----------- [ <K>Intermission ^1] -----------"
      if ( !$template{'info:intermission'} );
    
    $template{'warn'} = "Warn Event [ ^1<TEXT><K> ]" if ( !$template{'warn'} );
    $template{'kick'} = "Kick Event [ ^1<NAME>. Reason: <REASON><K> ]" if ( !$template{'kick'} );
    $template{'etpro'} = "Game Event [ ^8<TEXT><K> ]" if ( !$template{'etpro'} );

    $template{'kill:kill'} = "Kill Event [ ^1<KILLER> (<KILLS>) killed <KILLED> (<DEATHS>) by <WEAPON><K> ]"
      if ( !$template{'kill:kill'} );
    $template{'kill:teamkill'} = "TK Event [ ^1<KILLER> (<KILLS>) killed <KILLED> (<DEATHS>) by <WEAPON><K> ]"
      if ( !$template{'kill:suicide'} );
    $template{'kill:suicide'} = "Suicide Event [ ^1<NAME><K> ]" if ( !$template{'kill:suicide'} );


}

sub template_replace
{
    my $temp = shift;
    my $vars = shift;
    #&log("Template: $temp");

    $$vars{'<K>'} = ${k};

    foreach my $key ( keys %$vars )
    {
        $temp =~ s/$key/$$vars{$key}/g;
    }
    $temp = &colorize($temp);

    #&log("Template Result: $temp");
    return $temp;

}

sub in_array
{

    my $ahash = shift;
    my $arg   = shift;

    for (@$ahash)
    {
        return 1 if ( $_ eq $arg );
    }
    return 0;
}

##############################################################################
#
#  Algorith::FloodControl
#  Vladi Belperchinov-Shabanski "Cade" <cade@biscom.net> <cade@datamax.bg>
#  $Id: FloodControl.pm,v 1.1 2004/02/29 03:39:24 cade Exp $
#
#  DISTRIBUTED UNDER GPL! SEE `COPYING' FILE FOR DETAILS
#
##############################################################################

# this package hash holds flood arrays for each event name
# hash with flood keys, this is the internal flood check data storage

# Note by Mark D.: added this to etm_irc.pl instead of a seperate file to avoid
# multiple files and update / installation confusion.
sub flood_check
{
    my $fc = shift;    # max flood events count
    my $fp = shift;    # max flood time period for $fc events
    my $en = shift;    # event name (key) which identifies flood check data

    if ( $en eq '' )
    {
        my ( $p, $f, $l ) = caller;    # construct event name by:
        $en = "$p:$f:$l";              # package + filename + line
                                       # print STDERR "EN: $en\n";
    }

    $FLOOD{$en} ||= [];                # make empty flood array for this event name
    my $ar = $FLOOD{$en};              # get array ref for event's flood array
    my $ec = @$ar;                     # events count in the flood array

    if ( $ec >= $fc )
    {

        # flood array has enough events to do real flood check
        my $ot = $$ar[0];              # oldest event timestamp in the flood array
        my $tp = time() - $ot;         # time period between current and oldest event

        # now calculate time in seconds until next allowed event
        my $wait = int( ( $ot + ( $ec * $fp / $fc ) ) - time() );
        if ( $wait > 0 )
        {

            # positive number of seconds means flood in progress
            # event should be rejected or postponed
            # print "WARNING: next event will be allowed in $wait seconds\n";
            return $wait;
        }

        # negative or 0 seconds means that event should be accepted
        # oldest event is removed from the flood array
        shift @$ar;
    }

    # flood array is not full or oldest event is already removed
    # so current event has to be added
    push @$ar, time();

    # event is ok
    return 0;
}

