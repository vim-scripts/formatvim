#!/usr/bin/perl
use strict;
use warnings;
use Image::Magick;
use YAML::XS;
use File::Basename;
use Cwd;
if($ARGV[0] eq "--help") {
    print STDERR <<"EOF";
Usage:
    $0 imageFile x0 y0 xm ym xstep ystep
    $0 imageFile rows cols
    $0 targetFile numcolors
    where
        imageFile
            is a file that contains a screenshot of
                vim -c 'source colortable.vim' -c 'call SetupTable(N, M)'
            where N*M is equal to number of terminal colors,
                  N<\$LINES, M<\$COLUMNS
        x0 and y0
            are coordinates of first pixel of first symbol (it is normally
            a black space)
        xm and ym
            are coordinates of last pixel of last symbol
        xstep and ystep
            are dimensions of symbols

        rows
            is a number of colored lines (second argument to SetupTable if you 
            used tools/colortable.vim). You must have used tools/colortable.vim 
            if you have chosen three-argument form.
        cols
            is a number of colored columns (second argument to SetupTable if you 
            used tools/colortable.vim). You must have used tools/colortable.vim 
            if you have chosen three-argument form.

        targetFile
            file where data will be written to
        numcolors
            is a number of colors your terminal supports.

        Two-argument form requires you to either have xdotool installed or 
        manually pointing window where vim was opened. Note: two-argument form
EOF
    exit 0;
}
sub GetImage {
    my $image=new Image::Magick;
    my $imagefile=shift;
    defined $imagefile && -e $imagefile
        or die "File is not readable: $imagefile";
    $image->Read($imagefile);
    return $image;
}
sub GetPixel {
    my ($image, $x, $y)=@_;
    return $image->GetPixel(x => $x,
                            y => $y);
}
sub GetTable {
    my ($image, $x0, $y0, $xm, $ym, $xstep, $ystep)=@_;
    my $r=[];
    my $y=$y0;
    while($y<$ym) {
        my $x=$x0;
        while($x<$xm) {
            push @$r, [GetPixel($image, $x, $y)];
            $x+=$xstep;
        }
        $y+=$ystep;
    }
    return $r;
}
sub GetRGBTable {
    my $collist=&GetTable;
    return [map {sprintf "#%02x%02x%02x", (map {255*$_} @$_)} @$collist];
}
sub CEq {
    my $a=shift;
    my $b=shift;
    return (    $a->[0] == $b->[0]
            and $a->[1] == $b->[1]
            and $a->[2] == $b->[2]);
}

sub CheckHypothesis {
    my ($image, $x0, $y0, $xm, $ym, $xstep, $ystep, $color1, $color2)=@_;
    my $mx0=$x0-2*$xstep;
    my $my0=$y0-2*$ystep;
    my $mxm=$mx0+4*$xstep-1;
    my $mym=$my0+4*$ystep-1;
    my $y=$my0;
    while($y<$mym) {
        my $x=$mx0-1;
        while($x<$mxm-1) {
            $x+=1;
            next if($x>=$x0 and $y>=$y0);
            my $n=(((($x-$mx0)/$xstep)%2));
            my $m=(((($y-$my0)/$ystep)%2));
            my $color=(((($x-$mx0)/$xstep)%2) xor
                       ((($y-$my0)/$ystep)%2))?
                            $color1 :
                            $color2;
            my $curcolor=[GetPixel($image, $x, $y)];
            return 0 unless CEq($curcolor, $color);
        }
        $y+=1;
    }
    return 1;
}

sub DetermineBorders {
    my $image = shift;
    my $cols  = shift;
    my $rows  = shift;
    my $tym = $image->Get("height");
    my $txm = $image->Get("width");
    my $y=0;
    my $prevx = 0;
    my $color     = [-2, -2, -2];
    my $prevcolor;
    while($y<$tym) {
        my $x=0;
        while($x<$txm) {
            my $color=[GetPixel($image, $x, $y)];
            if(not defined $prevcolor) {
                $prevx=$x;
                $prevcolor=$color;
            }
            elsif(not CEq($color, $prevcolor)) {
                my $xstep = $x-$prevx;
                if(    $xstep>3
                   and $x+$xstep<$txm
                   and CEq([GetPixel($image, $x+$xstep, $y)], $prevcolor))
                {
                    my $oldy=$y;
                    my $ystep=0;
                    while($y<$tym) {
                        my $newcolor=[GetPixel($image, $prevx, $y)];
                        if(CEq($prevcolor, $newcolor)) {
                            $y+=1; }
                        elsif(CEq($color, $newcolor)) {
                            $ystep=$y-$oldy;
                            last;
                        }
                        else {
                            last; }
                    }
                    if($ystep) {
                        my $x0 = $prevx+(2*$xstep);
                        my $y0 = $oldy+(2*$ystep);
                        my ($xm, $ym);
                        if(defined $cols) {
                            $xm = $x0+($cols*$xstep);
                            $ym = $y0+($rows*$ystep);
                        }
                        else {
                            my ($cols, $rows);
                            my $x=$x0+(2*$xstep);
                            my $y=$oldy;
                            while($x<$txm) {
                                if(    CEq([GetPixel($image, $x, $y)], $prevcolor)
                                   and CEq([GetPixel($image, $x, $y+$ystep)], $color)) {
                                    $cols=($x-$x0)/$xstep;
                                    last;
                                }
                                $x+=$xstep;
                            }
                            $x=$prevx;
                            $y=$y0+(2*$ystep);
                            while($y<$tym) {
                                if(    CEq([GetPixel($image, $x, $y)], $prevcolor)
                                   and CEq([GetPixel($image, $x+$xstep, $y)], $color)) {
                                    $rows=($y-$y0)/$ystep;
                                    last;
                                }
                                $y+=$ystep;
                            }
                            $x=$prevx;
                            next unless defined $cols and defined $rows;
                            $xm = $x0+($cols*$xstep);
                            $ym = $y0+($rows*$ystep);
                            print STDERR "Columns: $cols\nLines: $rows\n";
                        }
                        unless($xm>$txm or $ym>$tym) {
                            print STDERR "Hyp: ($x0, $y0)-($xm, $ym) by ($xstep, $ystep)\n";
                            if(CheckHypothesis($image,
                                               $x0,    $y0,
                                               $xm,    $ym,
                                               $xstep, $ystep,
                                               $color, $prevcolor)) {
                                return ($x0, $y0, $xm, $ym, $xstep, $ystep);
                            }
                        }
                    }
                    else {
                        $y=$oldy; }
                }
                $prevx=$x;
                $prevcolor=$color;
            }
            $x+=1;
        }
        $y+=1;
        undef $prevcolor;
    }
}

my @args;
my $image;
my $targetfile;
if(scalar @ARGV == 9) {
    $image=GetImage(shift @ARGV);
    @args=@ARGV;
}
elsif(scalar @ARGV == 3) {
    $image=GetImage(shift @ARGV);
    my $rows = shift @ARGV || 16;
    my $cols = shift @ARGV || 16;
    @args=DetermineBorders($image, $cols, $rows);
}
elsif(scalar @ARGV == 2) {
    $targetfile=shift @ARGV;
    $ENV{"CT_AUTO"}=((+(shift @ARGV)) || 256)."";
    $ENV{"CT_TEMP"}||="/tmp/colortable.png";
    my $scriptpath=File::Basename::dirname(Cwd::realpath($0))."/colortable.vim";
    system vim => "-u", "NONE", "-i", "NONE", "-S", $scriptpath;
    $image=GetImage($ENV{"CT_TEMP"});
    @args=DetermineBorders($image);
}
else {
    die "Invalid number of arguments";
}
my $F;
if(defined $targetfile) {
    open $F, '>', $targetfile;
}
else {
    $F=*STDOUT;
}
print $F YAML::XS::Dump(&GetRGBTable($image, @args));
close $F;
# 4, 3, 132, 275, 8, 17
