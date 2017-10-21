FILE="$1"
DIRNAME="$2"
ROOTDIR="root"
ACCESS_TOKEN="$3"
FOLDER_ID=""

function jsonValue() {
KEY=$1
num=$2
awk -F"[,:}][^://]" '{for(i=1;i<=NF;i++){if($i~/\042'$KEY'\042/){print $(i+1)}}}' | tr -d '"' | sed -n ${num}p | sed -e 's/[}]*$//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/[,]*$//'
}

 QUERY="mimeType='application/vnd.google-apps.folder' and title='$DIRNAME'"
    QUERY=$(echo $QUERY | sed -f url_escape.sed)

    SEARCH_RESPONSE=`/usr/bin/curl \
                    --silent \
                    -XGET \
                    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
                     "https://www.googleapis.com/drive/v2/files/${ROOTDIR}/children?orderBy=title&q=${QUERY}&fields=items%2Fid"`
    FOLDER_ID=`echo $SEARCH_RESPONSE | jsonValue id`


    if [ -z "$FOLDER_ID" ]
    then
        CREATE_FOLDER_POST_DATA="{\"mimeType\": \"application/vnd.google-apps.folder\",\"title\": \"$DIRNAME\",\"parents\": [{\"id\": \"$ROOTDIR\"}]}"
        CREATE_FOLDER_RESPONSE=`/usr/bin/curl \
                                --silent  \
                                -X POST \
                                -H "Authorization: Bearer $ACCESS_TOKEN" \
                                -H "Content-Type: application/json; charset=UTF-8" \
                                -d "$CREATE_FOLDER_POST_DATA" \
                                "https://www.googleapis.com/drive/v2/files?fields=id"`
        FOLDER_ID=`echo $CREATE_FOLDER_RESPONSE | jsonValue id`

    fi



MIME_TYPE=`file --brief --mime-type "$FILE"`
SLUG=`basename "$FILE"`
#FILESIZE=$(stat -f "%z" "$FILE")
FILESIZE=$(stat -f "%z" "$FILE")
postData="{\"mimeType\": \"$MIME_TYPE\",\"title\": \"$SLUG\",\"parents\": [{\"id\": \"${FOLDER_ID:0:28}\"}]}"
    postDataSize=$(echo $postData | wc -c)


uploadlink=`/usr/bin/curl \
                --silent \
                -X POST \
                -H "Host: www.googleapis.com" \
                -H "Authorization: Bearer ${ACCESS_TOKEN}" \
                -H "Content-Type: application/json; charset=UTF-8" \
                -H "X-Upload-Content-Type: $MIME_TYPE" \
                -H "X-Upload-Content-Length: $FILESIZE" \
                -d "$postData" \
                "https://www.googleapis.com/upload/drive/v2/files?uploadType=resumable" \
                --dump-header - | sed -ne s/"Location: "//p | tr -d '\r\n'`

    curl \
    -X PUT \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    -H "Content-Type: $MIME_TYPE" \
    -H "Content-Length: $FILESIZE" \
    -H "Slug: $SLUG" \
    --data-binary "@$FILE" \
    --output /dev/null \
    "$uploadlink" \
    $curl_args

