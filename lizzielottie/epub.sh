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

uuid()
{
    local N B T

    for (( N=0; N < 16; ++N ))
    do
        B=$(( $RANDOM%255 ))

        if (( N == 6 ))
        then
            printf '4%x' $(( B%15 ))
        elif (( N == 8 ))
        then
            local C='89ab'
            printf '%c%x' ${C:$(( $RANDOM%${#C} )):1} $(( B%15 ))
        else
            printf '%02x' $B
        fi

        for T in 3 5 7 9
        do
            if (( T == N ))
            then
                printf '-'
                break
            fi
        done
    done

    echo
}
uid=`uuid`

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
lo_traduction=`grep lo_traduction $draft | sed -e "s/lo_traduction://g" | sed -e "s/^ *//g"`

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
cp data/licence/$2.svg $dest/OEBPS/res/img/licence.svg
cp data/mimetype $dest

#=== TOC.NCX ===
sed -e "s/%title%/${subtitle}/g" -e "s/%lo_front%/${lo_front}/g" -e "s/%lo_credit%/${lo_credit}/g" -e "s/%lo_story%/${lo_story}/g" -e "s/%lo_end%/${lo_end}/g" -e "s/%uuid%/${uid}/g" data/toc.ncx > $dest/OEBPS/toc.ncx

#PAGES
sed -e "s/%color%/${color}/g" data/style.css > $dest/OEBPS/style.css
sed -e "s/%title%/${title}/g" -e "s/%subtitle%/${subtitle}/g" data/page_front.xhtml > $dest/OEBPS/page_front.xhtml
sed -e "s/%subtitle%/${subtitle}/g" -e "s/%lo_text%/${lo_text}/g" -e "s/%text%/${text}/g" -e "s/%lo_illustration%/${lo_illustration}/g" -e "s/%illustration%/${illustration}/g" -e "s/%lo_traduction%/${lo_traduction}/g" -e "s/%traduction%/${traduction}/g" data/page_credit.xhtml > $dest/OEBPS/page_credit.xhtml


for f in `seq 1 50`; do
if [ $f -lt 10 ]; then v=00$f; else if [ $f -lt 100 ]; then v=0$f; else v=$f; fi; fi
g=`grep -n "#$v" $draft`
if [ ! -z $g ]; then
    l=`echo $g | sed -e "s/:.*$//g"`
    ok=1
    
    echo "page ${v}..."
    
    sed -e "s/%subtitle%/${subtitle}/g" -e "s/%page%/${v}/g" data/page_default.xhtml > tmp1.xhtml
            
    for offset in `seq 1 5`; do
        ll=$(( $l + $offset ))
        content=`head --lines $ll $draft | tail --lines 1`
        if [ -z "$content" ]; then ok=0; fi
        if [ $ok -eq 1 ]; then

            max=$f
            sed -e "s/%line${offset}%/${content}/g" tmp1.xhtml > tmp2.xhtml
        else
            sed -e "s/%line${offset}%//g" tmp1.xhtml > tmp2.xhtml
        fi
        
        rm -f tmp1.xhtml
        mv tmp2.xhtml tmp1.xhtml
    done
    
    mv tmp1.xhtml $dest/OEBPS/page${v}.xhtml
fi
done

#=== CONTENT.OPF ===
sed -e "s/%title%/${subtitle}/g" data/header.opf > $dest/OEBPS/content.opf
echo '  <manifest>' >> $dest/OEBPS/content.opf
cd $dest/OEBPS

#MANIFEST
i=0
for f in res/img/*/*.svg ; do
    fid=`basename $f .svg`
    echo '    <item href="'$f'" id="'${fid}'_'${i}'" media-type="image/svg+xml"/>' >> content.opf
    i=$((i+1))
done
echo '    <item href="res/img/licence.svg" id="licence" media-type="image/svg+xml"/>' >> content.opf

echo '    <item href="page_front.xhtml" id="page_front" media-type="application/xhtml+xml"/>' >> content.opf
echo '    <item href="page_credit.xhtml" id="page_credit" media-type="application/xhtml+xml"/>' >> content.opf

for f in `seq 1 $max`; do
    if [ $f -lt 10 ]; then v=00$f; else if [ $f -lt 100 ]; then v=0$f; else v=$f; fi; fi
    echo '    <item href="page'${v}'.xhtml" id="page'${v}'" media-type="application/xhtml+xml"/>' >> content.opf
done

echo '    <item href="style.css" id="style" media-type="text/css"/>' >> content.opf
echo '    <item href="toc.ncx" id="ncx" media-type="application/x-dtbncx+xml"/>' >> content.opf

cd ../..



echo '  </manifest>' >> $dest/OEBPS/content.opf

# SPINE
echo '  <spine toc="ncx">' >> $dest/OEBPS/content.opf
echo '    <itemref idref="page_front"/>' >> $dest/OEBPS/content.opf
echo '    <itemref idref="page_credit"/>' >> $dest/OEBPS/content.opf
for f in `seq 1 $max`; do
    if [ $f -lt 10 ]; then v=00$f; else if [ $f -lt 100 ]; then v=0$f; else v=$f; fi; fi
    echo '    <itemref idref="page'${v}'"/>' >> $dest/OEBPS/content.opf
done
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

