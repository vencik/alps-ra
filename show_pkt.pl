#!/usr/bin/perl

use strict;
use warnings;


# AlpsPS/2 packet decoder
# Set (and implement, if necessary) accordingly to your device
# For starters, you may set it thus to simply get packet bitwise dump
#*decode_packet = "dump_packet";
*decode_packet = "decode_packet_v7";


# Get bistring of a byte (masking ignored bits)
sub byte2bits($@) {
    my $byte        = shift;
    my $ignore_mask = shift || 0x00;

    my $mask = $byte;
    my @bits;

    for (my $i = 0; $i < 8; ++$i, $mask <<= 1, $ignore_mask <<= 1) {
        my $c = 'x';

        if (!(0x80 & $ignore_mask)) {
            $c = 0x80 & $mask ? '1' : '0';
        }

        push(@bits, $c);
    }

    return sprintf("%s %s %s %s  %s %s %s %s",
        $bits[0], $bits[1], $bits[2], $bits[3],
        $bits[4], $bits[5], $bits[6], $bits[7]);
}


# Dump packet bytes
sub dump_packet(@) {
    foreach my $byte (@_) {
        print("    ", byte2bits($byte), "\n");
    }
}


# Represent n bits as a signed integer (in binary complement encoding)
sub signed($$) {
    my ($bit_cnt, $bits) = @_;

    $bit_cnt > 0 || return;  # 0-bit number set is empty

    my $sign_mask = (0x1 << ($bit_cnt - 1));

    ($bits & $sign_mask) || return $bits;

    return (-1 << $bit_cnt) | $bits;
}


# Decode touch event packet (AlpsPS/2 v7)
sub decode_touch_packet_v7(@) {
    my ($B0, $B1, $B2, $B3, $B4, $B5) = @_;

    # Check touch packet invariant
    if (!((0x40 == (0x40 & $B0)) && (0x48 == (0x48 & $B3)) && (0x00 == (0x40 & $B5)))) {
        print("    Touch event packet format invariant VIOLATED\n");

        return dump_packet(@_);
    }

    # Touchpad initial packet
    my $init = 0x10 & $B0 ? 1 : 0;

    print("    ", ($init ? "Initial" : "Sequential"), " touch event packet\n");

    # Yet unknown bit
    my $unknown = 0x20 & $B0 ? 1 : 0;

    $unknown && print("    Unknown multi-touch related (?) bit set\n");

    # Check !i bit hypothesis
    if (!((((0x10 & $B0) << 2) ^ $B4) & 0x40)) {
        print("    Initial bit negation hypothesis DOES NOT HOLD\n");
    }

    # Touchpad button pressed
    my $button = 0x80 & $B0 ? 1 : 0;

    $button && print("    TP button pressed\n");

    # Primary coordinates
    my $x1 = 0x07 & $B3;  # low 3 bits
    my $y1 = 0x07 & $B0;  # low 3 bits

    $x1 |= (0x30 & $B3) >> 1;  # bits 4 and 5
    $x1 |= (0x3f & $B2) << 5;  # bits 6 to 11
    $x1 |= (0x80 & $B2) << 4;  # bit 12

    $y1 |= $B1 << 3;  # bits 4 to 11

    # Secondary coordinates
    my $x2 = 0x3f & $B4;  # low 6 bits
    my $y2 = 0x3f & $B5;  # low 6 bits

    $x2 |= (0x80 & $B4) >> 1;  # bit 7
    $x2 |= (0x80 & $B3);       # bit 8

    $y2 |= (0x80 & $B5) >> 1;  # bit 7

    $x2 <<= 4;  # sec. coords are less precise
    $y2 <<= 4;

    printf("    Coordinates: [0x%04x, 0x%04x], [0x%04x, 0x%04x] == [%d, %d], [%d, %d]\n",
           $x1, $y1, $x2, $y2, $x1, $y1, $x2, $y2);
}


# Decode touch idle packet (AlpsPS/2 v7)
sub decode_touch_idle_packet_v7(@) {
    my ($B0, $B1, $B2, $B3, $B4, $B5) = @_;

    # Check touch idle packet invariant
    if (!(0x48 == $B0 && 0x00 == $B1 && 0x40 == $B2 && 0x48 == $B3 && 0x00 == $B4 && 0x00 == $B5)) {
        print("    Touch idle packet format VIOLATED\n");

        return dump_packet(@_);
    }

    print("    Touch idle packet\n");
}


# Decode trackstick packet (AlpsPS/2 v7)
sub decode_trackstick_packet_v7(@) {
    my ($B0, $B1, $B2, $B3, $B4, $B5) = @_;

    # Check trackstick packet invariant
    if (!((0x48 == $B0) && (0xe8 == (0xfc & $B1)))) {
        print("    Trackstick packet format invariant VIOLATED\n");

        return dump_packet(@_);
    }

    # Final idle packet
    if (0x3f == $B5) {
        # Check trackstick final idle packet invariant
        if (!((0x7f == $B2) && (0xff == $B3) && (0x3e == $B4) && (0x3f == $B5))) {
            print("    Trackstick final idle packet format VIOLATED\n");

            return dump_packet(@_);
        }

        print("    Final trackstick idle packet\n");

        return;
    }

    # Check B5 == 0x00 hypothesis
    if (!(0x00 == $B5)) {
        print("    Trackstick inner packet B5 == 0x00 hypothesis DOES NOT HOLD\n");

        return dump_packet(@_);
    }

    # Trackstick idle packet
    if ((0x40 == $B2) && (0x48 == $B3) && (0x06 == $B4)) {
        print("    Trackstick idle packet\n");

        return;
    }

    print("    Trackstick event packet\n");

    # Check trackstick event packet invariant
    if (!((0x48 == (0xc8 & $B3)) && (0x06 == (0x46 & $B4) && (0x00 == $B5)))) {
        print("    Trackstick event packet invariant DOES NOT HOLD\n");
    }

    # Buttons
    my $left_button  = 0x01 & $B1;
    my $right_button = 0x02 & $B1 ? 1 : 0;

    $left_button  && print("    Left button pressed\n");
    $right_button && print("    Right button pressed\n");

    # Vector
    my $x = (0x3f & $B2);  # low 6 bits
    my $y = (0x07 & $B3);  # low 3 bits

    $x |= (0x10 & $B3) << 2;  # bit 7
    $x |= (0x80 & $B2);       # bit 8

    $y |= (0x20 & $B3) >> 2;  # bit 4
    $y |= (0x38 & $B4) << 1;  # bits 5 to 7
    $y |= (0x80 & $B4);       # bit 8

    printf("    Vector: [0x%02x, 0x%02x] == [%d, %d]\n", $x, $y, signed(8, $x), signed(8, $y));

    #print("    Bits:\n"); dump_packet(@_);
}


# Decode packet (AlpsPS/2 v7)
sub decode_packet_v7(@) {
    my ($B0, $B1, $B2, $B3, $B4, $B5) = @_;

    # Check fixed bits hypothesis
    if (!((0x48 == (0x48 & $B0)) && (0x40 == (0x40 & $B2)) && (0x48 == (0x48 & $B3)))) {
        print("    Fixed bits hypothesis DOES NOT HOLD\n");
        printf("    0x48 & B0 == 0x%02x\n", 0x48 & $B0);
        printf("    0x40 & B2 == 0x%02x\n", 0x40 & $B2);
        printf("    0x48 & B3 == 0x%02x\n", 0x48 & $B3);
    }

    # Touch event packet (detection based on i ^ !i)
    (((0x10 & $B0) << 2) ^ (0x40 & $B4)) && return decode_touch_packet_v7(@_);

    # Trackstick packet
    (0xe8 == (0xec & $B1)) && return decode_trackstick_packet_v7(@_);

    # Touch idle packet
    (0x00 == $B1) && return decode_touch_idle_packet_v7(@_);

    # Unknown packet type
    print("    UNKNOWN PACKET FORMAT\n");

    dump_packet(@_);
}


# Main routine
my $dmesg   = `dmesg @ARGV`;
my @pkt_all = grep(s/.*AlpsPS\/2 packet dump: //, split("\n", $dmesg));
my @pkt_cnt;

foreach my $pkt (@pkt_all) {
    if (@pkt_cnt && $pkt_cnt[-1]->[0] eq $pkt) {
        ++$pkt_cnt[-1]->[1];

        next;
    }

    push(@pkt_cnt, [$pkt, 1]);
}

foreach my $pkt_cnt (@pkt_cnt) {
    my $pkt = $pkt_cnt->[0];
    my $cnt = $pkt_cnt->[1];

    print(($cnt > 1 ? "$cnt packets" : "Packet"), ": ($pkt)\n");

    decode_packet(map(hex, split(' ', $pkt)));
}
