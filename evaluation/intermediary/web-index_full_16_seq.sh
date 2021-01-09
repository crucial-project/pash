mkfifo {1,2,3}grams

bigrams_aux()
{
    ( mkfifo s2 > /dev/null ) ;
    ( mkfifo s3 > /dev/null ) ;

    sed '$d' s2 > s3 &
    tee s2 |
        tail +2 |
        paste s3 -
    rm s2
    rm s3
}

bigram_aux_map()
{
    IN=$1
    OUT=$2
    AUX_HEAD=$3
    AUX_TAIL=$4

    s2=$(mktemp -u)
    aux1=$(mktemp -u)
    aux2=$(mktemp -u)
    aux3=$(mktemp -u)
    temp=$(mktemp -u)

    mkfifo $s2
    mkfifo $aux1
    mkfifo $aux2
    mkfifo $aux3

    ## New way of doing it using an intermediate file. This is slow
    ## but doesn't deadlock
    cat $IN > $temp

    sed '$d' $temp > $aux3 &
    cat $temp | head -n 1 > $AUX_HEAD &
    cat $temp | tail -n 1 > $AUX_TAIL &
    cat $temp | tail +2 | paste $aux3 - > $OUT &

    # ## Old way of doing it
    # cat $IN |
    #     tee $s2 $aux1 $aux2 |
    #     tail +2 |
    #     paste $s2 - > $OUT &

    # ## The goal of this is to write the first line of $IN in the $AUX_HEAD
    # ## stream and the last line of $IN in $AUX_TAIL

    # cat $aux1 | ( head -n 1 > $AUX_HEAD; $PASH_TOP/evaluation/tools/drain_stream.sh ) &
    # # while IFS= read -r line
    # # do
    # #     old_line=$line
    # # done < $aux2
    # # echo "$old_line" > $AUX_TAIL
    # ( tail -n 1 $aux2 > $AUX_TAIL; $PASH_TOP/evaluation/tools/drain_stream.sh ) &

    wait

    rm $temp
    rm $s2
    rm $aux1
    rm $aux2
    rm $aux3
}

bigram_aux_reduce()
{
    IN1=$1
    AUX_HEAD1=$2
    AUX_TAIL1=$3
    IN2=$4
    AUX_HEAD2=$5
    AUX_TAIL2=$6
    OUT=$7
    AUX_HEAD_OUT=$8
    AUX_TAIL_OUT=$9

    temp=$(mktemp -u)

    mkfifo $temp

    cat $AUX_HEAD1 > $AUX_HEAD_OUT &
    cat $AUX_TAIL2 > $AUX_TAIL_OUT &
    paste $AUX_TAIL1 $AUX_HEAD2 > $temp &
    cat $IN1 $temp $IN2 > $OUT &

    wait

    rm $temp
}


trigrams_aux()
{
    s1=$(mktemp -u)
    s2=$(mktemp -u)
    s3=$(mktemp -u)
    s4=$(mktemp -u)

    mkfifo $s1 $s2 $s3 $s4

    # sed '$d' $s1 > $s2 &
    # sed '$d' $s3 > $s4 &
    tee $s2 |
        tail +2 |
        paste $s2 - |
        tee $s3 |
        cut -f 1 |
        tail +3 |
        paste $s3 - |
        sed '$d' |
        sed '$d'

    rm $s1 $s2 $s3 $s4
}

extract_line()
{
    cat $1 |
        iconv -c -t ascii//TRANSLIT |
        pandoc +RTS -K64m -RTS --from html --to plain --quiet
}

extract_text()
{
    while read -r line
    do
        cat $line |
            iconv -c -t ascii//TRANSLIT |
            pandoc +RTS -K64m -RTS --from html --to plain --quiet
    done
}


cat $IN_DIR/p1.out_16_00 $IN_DIR/p1.out_16_01 $IN_DIR/p1.out_16_02 $IN_DIR/p1.out_16_03 $IN_DIR/p1.out_16_04 $IN_DIR/p1.out_16_05 $IN_DIR/p1.out_16_06 $IN_DIR/p1.out_16_07 $IN_DIR/p1.out_16_08 $IN_DIR/p1.out_16_09 $IN_DIR/p1.out_16_10 $IN_DIR/p1.out_16_11 $IN_DIR/p1.out_16_12 $IN_DIR/p1.out_16_13 $IN_DIR/p1.out_16_14 $IN_DIR/p1.out_16_15|
  sed "s#^#$WIKI#" |
  extract_text |
  tr -cs A-Za-z '\n' |
  tr A-Z a-z |
  grep -vwFf $WEB_INDEX_DIR/stopwords.txt |
  $WEB_INDEX_DIR/stem-words.js |
  tee 3grams 2grams 1grams > /dev/null &

cat 1grams |
    sort |
    uniq -c |
    sort -rn > 1-grams.txt &

cat 2grams |
    tr -cs A-Za-z '\n' |
    tr A-Z a-z |
    bigrams_aux |
    sort |
    uniq -c |
    sort -rn > 2-grams.txt &

cat 3grams |
    tr -cs A-Za-z '\n' |
    tr A-Z a-z |
    trigrams_aux |
    sort |
    uniq -c |
    sort -rn # >> 3-grams.txt

rm {1,2,3}grams
