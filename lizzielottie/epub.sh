#!/bin/bash
echo "Pouf-Pouf Production Books generator"

if [ "$#" -lt 2 ]; then
    echo "  Usage: `basename $0` name lang"
    echo "  End processing"
    exit 1
fi

if [ ! -d $1 ]; then
    echo "  Can not find book '$1'"
    echo "  End processing"
    exit 1
fi

draft=$1/draft_$2.txt

if [ ! -f $draft ]; then
    echo "  Can not find $draft"
    exit 1
fi

#Define STRINGS
title=`grep title $draft | grep -v subtitle | sed -e "s/title://g" | sed -e "s/^ *//g"`
subtitle=`grep subtitle $draft | sed -e "s/subtitle://g" | sed -e "s/^ *//g"`
text=`grep text $draft | grep -v lo_ | sed -e "s/text://g" | sed -e "s/^ *//g"`
illustration=`grep illustration $draft | grep -v lo_ | sed -e "s/illustration://g" | sed -e "s/^ *//g"`
traduction=`grep traduction $draft | grep -v lo_ | sed -e "s/traduction://g" | sed -e "s/^ *//g"`
color=`grep color $draft | sed -e "s/color://g" | sed -e "s/^ *//g"`

lo_text=`grep lo_text $draft | sed -e "s/lo_text://g" | sed -e "s/^ *//g"`
lo_illustration=`grep lo_illustration $draft | sed -e "s/lo_illustration://g" | sed -e "s/^ *//g"`
lo_traduction=`grep lo_text $draft | sed -e "s/lo_traduction://g" | sed -e "s/^ *//g"`

lo_front=`grep lo_front $draft | sed -e "s/lo_front://g" | sed -e "s/^ *//g"`
lo_credit=`grep lo_credit $draft | sed -e "s/lo_credit://g" | sed -e "s/^ *//g"`
lo_story=`grep lo_story $draft | sed -e "s/lo_story://g" | sed -e "s/^ *//g"`
lo_end=`grep lo_end $draft | sed -e "s/lo_end://g" | sed -e "s/^ *//g"`


echo "Processing..."
dest="tmpbook"

if [ -d $dest ]; then
    rm -rf $dest
fi

mkdir $dest
mkdir $dest/OEBPS
cp -r data/META-INF $dest
cp -r $1/res $dest/OEBPS
cp data/mimetype $dest

#=== TOC.NCX ===
sed -e "s/%title%/${subtitle}/g" -e "s/%lo_front%/${lo_front}/g" -e "s/%lo_credit%/${lo_credit}/g" -e "s/%lo_story%/${lo_story}/g" -e "s/%lo_end%/${lo_end}/g" data/toc.ncx > $dest/OEBPS/toc.ncx

#PAGES
sed -e "s/%color%/${color}/g" data/style.css > $dest/OEBPS/style.css
sed -e "s/%title%/${title}/g" -e "s/%subtitle%/${subtitle}/g" data/page_front.xhtml > $dest/OEBPS/page_front.xhtml
sed -e "s/%title%/${title}/g" data/page_credit.xhtml > $dest/OEBPS/page_credit.xhtml

#=== CONTENT.OPF ===
sed -e "s/%title%/${subtitle}/g" data/header.opf > $dest/OEBPS/content.opf
echo '  <manifest>' >> $dest/OEBPS/content.opf
cd $dest/OEBPS

#MANIFEST
for f in res/img/*/*.svg ; do
echo '    <item href="'$f'" media-type="image/svg+xml"/>' >> content.opf
done
echo '    <item href="page_front.xhtml" id="page_front" media-type="application/xhtml+xml"/>' >> content.opf
echo '    <item href="page_credit.xhtml" id="page_credit" media-type="application/xhtml+xml"/>' >> content.opf
echo '    <item href="style.css" id="style" media-type="text/css"/>' >> content.opf
echo '    <item href="toc.ncx" id="ncx" media-type="application/x-dtbncx+xml"/>' >> content.opf

cd ../..
echo '  </manifest>' >> $dest/OEBPS/content.opf

# SPINE
echo '  <spine toc="ncx">' >> $dest/OEBPS/content.opf
echo '    <itemref idref="page_front"/>' >> $dest/OEBPS/content.opf
echo '    <itemref idref="page_credit"/>' >> $dest/OEBPS/content.opf
echo '  </spine>' >> $dest/OEBPS/content.opf
  
# GUIDE
echo '  <guide>' >> $dest/OEBPS/content.opf
echo '    <reference href="page_front.xhtml" title="Title" type="cover"/>'  >> $dest/OEBPS/content.opf
echo '  </guide>'  >> $dest/OEBPS/content.opf

echo '</package>' >> $dest/OEBPS/content.opf

#BUILD EPUB
cd $dest
zip -X -Z store ../$1.epub mimetype
zip -9 -r ../$1.epub  META-INF/ OEBPS/
cd ..
# rm -rf $dest

