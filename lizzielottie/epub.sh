#!/bin/bash
echo "Pouf-Pouf Production Books generator"

if [ "$#" -lt 1 ]; then
    echo "  Usage: `basename $0` name"
    echo "  Book name is missing"
    echo "  End processing"
    exit 1
fi

if [ ! -d $1 ]; then
    echo "  Can not find book '$1'"
    echo "  End processing"
    exit 1
fi

#LOCALE STRINGS
toc_front="Couverture"

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
title=`head --lines 1 $1/draft.txt`
sed -e "s/%title%/${title}/g" -e "s/%front%/${toc_front}/g" data/toc.ncx > $dest/OEBPS/toc.ncx

#PAGES
sed -e "s/%title%/${title}/g" data/header.xhtml > $dest/OEBPS/page_front.xhtml
echo "<img src='res/img/pages/p000.svg'/></body></html>" >> $dest/OEBPS/page_front.xhtml

#=== CONTENT.OPF ===
sed -e "s/%title%/${title}/g" data/header.opf > $dest/OEBPS/content.opf
echo '  <manifest>' >> $dest/OEBPS/content.opf
cd $dest/OEBPS

#MANIFEST
for f in res/img/*/*.svg ; do
echo '    <item href="'$f'" media-type="image/svg+xml"/>' >> content.opf
done
echo '    <item href="page_front.xhtml" id="page_front" media-type="application/xhtml+xml"/>' >> content.opf
echo '    <item href="toc.ncx" id="ncx" media-type="application/x-dtbncx+xml"/>' >> content.opf

cd ../..
echo '  </manifest>' >> $dest/OEBPS/content.opf

# SPINE
echo '  <spine toc="ncx">' >> $dest/OEBPS/content.opf
echo '    <itemref idref="page_front"/>' >> $dest/OEBPS/content.opf
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

