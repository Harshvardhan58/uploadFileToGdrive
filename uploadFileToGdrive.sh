FILE="$1"
ACCESS_TOKEN="$2"
MIME_TYPE=`file --brief --mime-type "$FILE"`
SLUG=`basename "$FILE"`
FILESIZE=$(stat -f "%z" "$FILE")

postData="{\"mimeType\": \"$MIME_TYPE\",\"title\": \"$SLUG\"}"
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

