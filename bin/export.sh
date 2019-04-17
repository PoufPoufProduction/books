#!/bin/bash
echo "Pouf-Pouf Production Books generator"
echo "------------------------------------"

# VERIFICATIONS
if [ "$#" -lt 2 ]; then
    echo "  Usage: `basename $0` name lang [epub|html|latex|pdf]"
    exit 1
fi


if [ ! -f "data/locale.txt" ]; then
    echo "  Can not find data/locale.txt - Please run bin/`basename $0` from root directory."
    exit 1
fi

if [ ! -d $1 ]; then
    echo "  Can not find book '$1'"
    exit 1
fi

txt=$1/content.txt
if [ ! -f $txt ]; then
    echo "  + Can not find book content: $txt"
    exit 1
fi

output="epub"
if [ ! -z $3 ] ; then output=$3; fi
if [[ "$output" != "epub" && "$output" != "latex" && "$output" != "pdf" && "$output" != "html" ]]; then
    echo "  Usage: `basename $0` name lang [epub|html|latex|pdf]"
    exit 1
fi
echo " + Generating $output for $1"

# DEFINES
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

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


# GET LOCALIZATION VALUE
lo=data/locale.txt
echo -e " + Get localization from \e[4m$lo\e[0m"
lo_title=`grep $2_title $lo | sed -e "s/.._title://g" | sed -e "s/^[ \t]*//g"`
lo_subtitle=`grep $2_subtitle $lo | sed -e "s/.._subtitle://g" | sed -e "s/^[ \t]*//g"`
lo_text=`grep $2_text $lo | sed -e "s/.._text://g" | sed -e "s/^[ \t]*//g"`
lo_update=`grep $2_update $lo | sed -e "s/.._update://g" | sed -e "s/^[ \t]*//g"`
lo_illustration=`grep $2_illustration $lo | sed -e "s/.._illustration://g" | sed -e "s/^[ \t]*//g"`
lo_traduction=`grep $2_traduction $lo | sed -e "s/.._traduction://g" | sed -e "s/^[ \t]*//g"`
lo_front=`grep $2_front $lo | sed -e "s/.._front://g" | sed -e "s/^[ \t]*//g"`
lo_credit=`grep $2_credit $lo | sed -e "s/.._credit://g" | sed -e "s/^[ \t]*//g"`
lo_story=`grep $2_story $lo | sed -e "s/.._story://g" | sed -e "s/^[ \t]*//g"`
lo_end=`grep $2_end $lo | sed -e "s/.._end://g" | sed -e "s/^[ \t]*//g"`
lo_color=`grep $2_color $lo | sed -e "s/.._color://g" | sed -e "s/^[ \t]*//g"`
lo_legal=`grep $2_legal $lo | sed -e "s/.._legal://g" | sed -e "s/^[ \t]*//g"`


# GET CREDIT
cr=$1/credit.txt
title="PoufPouf vector comics"
text="John Doe"
illustration="John Doe"

if [ -f $cr ] ; then 
	echo -e " + Read information from \e[4m$cr\e[0m"
	title=`grep title $cr | grep -v subtitle | sed -e "s/title[ \t]*://g" | sed -e "s/^[ \t]*//g"`
	subtitle=`grep subtitle $cr | sed -e "s/subtitle[ \t]*://g" | sed -e "s/^[ \t]*//g"`
	text=`grep text $cr | grep -v textupd | sed -e "s/text[ \t]*://g" | sed -e "s/^[ \t]*//g"`
	textupd=`grep textupd $cr | sed -e "s/textupd[ \t]*://g" | sed -e "s/^[ \t]*//g"`
	illustration=`grep illustration $cr | sed -e "s/illustration[ \t]*://g" | sed -e "s/^[ \t]*//g"`
	traduction=`grep traduction_$2 $cr | sed -e "s/traduction_$2[ \t]*://g" | sed -e "s/^[ \t]*//g"`
else
	echo -e " + Can not find information file \e[4m$cr\e[0m"
fi

printf " %15s : " "$lo_title";        echo -e "${YELLOW}$title${NC}"
printf " %15s : " "$lo_subtitle";     echo -e "${YELLOW}$subtitle${NC}"
printf " %15s : " "$lo_text";         echo -e "${YELLOW}$text${NC}"
printf " %15s : " "$lo_update";       echo -e "${YELLOW}$textupd${NC}"
printf " %15s : " "$lo_traduction";   echo -e "${YELLOW}$traduction${NC}"
printf " %15s : " "$lo_illustration"; echo -e "${YELLOW}$illustration${NC}"

# GET CONFIGURATION
co=$1/config.txt
color="gray"
legal="copyleft"
if [ -f $co ] ; then 
	echo -e " + Read configuration from \e[4m$co\e[0m"
	color=`grep color $co | sed -e "s/color://g" | sed -e "s/^[ \t]*//g"`
	if [ -z $color ] ; then color="gray" ; fi
	legal=`grep legal $co | sed -e "s/legal://g" | sed -e "s/^[ \t]*//g"`
	if [ -z $legal ] ; then legal="copyleft" ; fi
else
	echo -e " + Can not find configuration file \e[4m$co\e[0m"
fi

printf " %15s : " $lo_color;        echo -e "${YELLOW}$color${NC}"
printf " %15s : " $lo_legal;        echo -e "${YELLOW}$legal${NC}"


# PREPARE OUTPUT
dest=".book"
echo -e " + Prepare $output"
if [ -d $dest ]; then rm -rf $dest ; fi
mkdir $dest

case "$output" in
	epub*)
		mkdir $dest/OEBPS
		cp -r data/html/META-INF $dest/OEBPS
		cp data/html/mimetype $dest
		sed -e "s/%color%/${color}/g" data/html/style.css > $dest/OEBPS/style.css
	;;
	html*)
		sed -e "s/%color%/${color}/g" data/html/style.css > $dest/style.css
	;;	
esac


# READ CONTENT
echo -e " + Processing \e[4m$txt\e[0m"
IFS=$'\n'
section=""
page=0
type=""
content=""
img=""
for l in `cat $txt` ; do
	case $l in
	type*)	type=`echo $l | sed -e "s/type[ ]*:[ ]*//g"` ;;
	*text*)
		if [[ -z $content || ! -z `echo $l | grep "$2_text"` ]] ; then
			content=`echo $l | sed -e "s/.*text[ ]*:[ ]*//g"`
		fi
	;;
	*img*)
		if [[ -z $img || ! -z `echo $l | grep "$2_img"` ]] ; then
			img=`echo $l | sed -e "s/.*img[ ]*:[ ]*//g"`
		fi
	;;
	[*)
		# EMPTY LINE FOR END OF PAGE
		if [ ! -z $type ] ; then
			printf "  . Page #%03d [%s] - type: " $page $section ; echo $type
			if [ ! -z $content ] ; then echo -n "    - $content" | head -c 80; echo "..."; fi
			if [ ! -z $img ] ; then echo "    - $img"; fi
			# GET SUBTYPE IF ANY
			subtype=""
			if [ `echo $type | grep "/" | wc -l` -eq 1 ] ; then
				subtype=`echo $type | sed -e "s|[^/]*/||g"`
				type=`echo $type | sed -e "s|/.*||g"`
			fi
			
			# BUILD CURRENT PAGE
			case $type in
				cover*)
					
				
				;;
				img*)
					echo "   + img"
				
				;;
				
			esac
			
		fi
	
		section=`echo $l | sed -e "s/\[//g" -e "s/\]//g"`
		page=$(($page+1))
		img=""
		content=""
	;;
	
	esac

	
done

exit 1


echo "Processing..."
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

