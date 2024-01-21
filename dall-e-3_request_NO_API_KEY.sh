#!/usr/bin/bash

# dall-e-3_request.sh
#
# Takes one input arg.: text prompt in double quotes
#
# One flag possible: -a ("as-is"), MUST COME BEFORE input arg
#   Prepends the text specified by openAI for limiting embellishment of
#   the prmompt:
#     "I NEED to test how the tool works with extremely simple prompts.
#      DO NOT add any detail, just use it AS-IS: "
#   This text isn't included in *.txt, but can examine *.json to see
#     whether *txt prompt was embellished or not.
#
# Outputs: two text files (*.txt and *.json) and image file (*.png)
#   where * indicates prompt text with spaces replaced
#   by underscores, plus a 6-char hex random string.
#     *.txt is the prompt that was input.
#     *.json includes the revised (elaborated) prompt produced
#       by openAI (unless -a option used) and the URL for
#       downloading the image file
#
# Must have "jq" command line tool installed on system
#
# begun 2023-12-29 by adc

# Uses code from:
#   https://platform.openai.com/docs/api-reference/images/create



# Read input args, including flags
#---------------------------------

AS_IS=false

while test $# -gt 0; do
    case "$1" in
	-a)
	    export AS_IS=true
	    shift
	    ;;
	*)
	    break
	    ;;
    esac
done

# Define constants
#-----------------

# ADD API KEY HERE!!!!!!!!!!
OPENAI_API_KEY=

PROMPT_TEXT=$1

AS_IS_TEXT="I NEED to test how the tool works with extremely simple prompts. DO NOT add any detail, just use it AS-IS: "

# Clean up problematic characters in case they're present
outFileStr=$(echo $PROMPT_TEXT | sed "s/'//g")
outFileStr=$(echo $outFileStr | sed 's/\?//g')

# Take only first 60 characters of prompt
outFileStr=${outFileStr:0:59}

# Replace spaces with underscores
outFileStr=$(echo $outFileStr | sed 's/ /_/g')

# Append a 6-char random hexadecimal string
#   (over 16 million unique combinations) to the end
# This allows entering the same prompt repeatedly
outFileStr=$outFileStr"_"$(echo $RANDOM | md5sum | head -c 6; echo)


# Save the prompt text
#-----------------------

echo "$PROMPT_TEXT" > $outFileStr.txt



# Prepend the text that minimizes revision/embellishment of the
#   text prompt, if the -a flag was included in the command
#---------------------------------------------------------------

if [ $AS_IS = true ]; then  # var exists, is set

    PROMPT_TEXT=$AS_IS_TEXT$PROMPT_TEXT

fi


# Function that makes request of openai using curl
#-------------------------------------------------

# This function will return a json string
curl_request () {

curl https://api.openai.com/v1/images/generations \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d '{
    "model": "dall-e-3",
    "prompt": "'"$PROMPT_TEXT"'",
    "n": 1,
    "size": "1024x1024",
    "style": "natural"
  }' \
 -o $outFileStr.json

}

# Call the function
curl_request



# Download the image
#--------------------

# Make sure "jq" command line tool is on system
# jq statement is based on the particular structure of the json string
#   returned by openai's website
# Result will be inside double quotes
imageURL=$(cat $outFileStr.json | jq .data[0].url)

# Remove the double quotes
imageURL=$(echo $imageURL | sed 's/"//g')

wget -O $outFileStr.png $imageURL  





