#!/usr/bin/perl
use Image::Magick;
use YAML;
my $imagefile = shift @ARGV || "image.png";
if(!-e $imagefile || $imagefile eq "--help") {
    print STDERR <<"EOF";
Usage:
    $0 imageFile x0 y0 xm ym xstep ystep
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
EOF
    exit 0;
}
sub GetImage($) {
    my $image=new Image::Magick;
    $image->Read(shift);
    return $image;
}
sub GetPixel($$$) {
    my ($image, $x, $y)=@_;
    return $image->GetPixel(x => $x,
                            y => $y);
}
sub GetTable($$$$$$$) {
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
sub GetRGBTable($$$$$$$) {
    my $collist=&GetTable;
    return [map {sprintf "#%02x%02x%02x", (map {255*$_} @$_)} @$collist];
}
my $image=GetImage($imagefile);
#print YAML::Dump(GetPixel($image, 1, 1));
my ($x0, $y0, $xm, $ym, $xstep, $ystep)=@ARGV;
print YAML::Dump(&GetRGBTable($image, @ARGV));
# 4, 3, 132, 275, 8, 17
