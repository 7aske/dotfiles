#!/usr/bin/env sh
# ranger supports enhanced previews.  If the option "use_preview_script"
# is set to True and this file exists, this script will be called and its
# output is displayed in ranger.  ANSI color codes are supported.

# NOTES: This script is considered a configuration file.  If you upgrade
# ranger, it will be left untouched. (You must update it yourself.)
# Also, ranger disables STDIN here, so interactive scripts won't work properly

# Meanings of exit codes:
# code | meaning    | action of ranger
# -----+------------+-------------------------------------------
# 0    | success    | success. display stdout as preview
# 1    | no preview | failure. display no preview at all
# 2    | plain text | display the plain content of the file
# 3    | fix width  | success. Don't reload when width changes
# 4    | fix height | success. Don't reload when height changes
# 5    | fix both   | success. Don't ever reload
# 6    | image      | success. display the image $cached points to as an image preview
# 7    | image      | success. display the file directly as an image

# Meaningful aliases for arguments:
path="$1"            # Full path of the selected file
width="$2"           # Width of the preview pane (number of fitting characters)
height="$3"          # Height of the preview pane (number of fitting characters)
cached="$4"          # Path that should be used to cache image previews
preview_images="$5"  # "True" if image previews are enabled, "False" otherwise.

maxln=200    # Stop after $maxln lines.  Can be used like ls | head -n $maxln

# Find out something about the file:
mimetype=$(xdg-mime query filetype "$path")
default_mimetype="$(file --mime-type -Lb $path)"
extension=$(/bin/echo "${path##*.}" | awk '{print tolower($0)}')
default_size="1920x1080"

# Functions:
# runs a command and saves its output into $output.  Useful if you need
# the return value AND want to use the output in a pipe
try() { output="$(eval '"$@"')"; }

# writes the output of the previously used "try" command
dump() { /bin/echo "$output"; }

# a common post-processing function used after most commands
trim() { head -n "$maxln"; }

# wraps highlight to treat exit code 141 (killed by SIGPIPE) as success
safepipe() { "$@"; test $? = 0 -o $? = 141; }

# Image previews, if enabled in ranger.
if [ "$preview_images" = "True" ]; then
    case "$mimetype" in
        ## Font
        application/font*|application/*opentype)
            preview_png="/tmp/$(basename "${cached%.*}").png"
            if fontimage -o "${preview_png}" \
                         --pixelsize "120" \
                         --fontname \
                         --pixelsize "80" \
                         --text "  ABCDEFGHIJKLMNOPQRSTUVWXYZ  " \
                         --text "  abcdefghijklmnopqrstuvwxyz  " \
                         --text "  0123456789.:,;(*!?') ff fl fi ffi ffl  " \
                         --text "  The quick brown fox jumps over the lazy dog.  " \
                         "${path}";
            then
                convert -- "${preview_png}" "${cached}" \
                    && rm "${preview_png}" \
                    && exit 6
            else
                exit 1
            fi
            ;;
        model/*) # preview in f3d
            f3d --config=thumbnail --load-plugins=native --color=0.36,0.50,0.67 --background-color=0.18,0.20,0.25 --verbose=quiet --output="$cached" "$path" && exit 6 || exit 1 ;;
        # Image previews for SVG files, disabled by default.
        image/x-fuji-raf)
           exiftool "$path" -previewimage -b  > "$cached" && exit 6 || exit 1 ;;
        image/svg+xml|image/svg)
            rsvg-convert --keep-aspect-ratio --width "${default_size%x*}" "${path}" -o "${cached}.png" \
                && mv "${cached}.png" "${cached}" \
                && exit 6
            exit 1;;

        ## PDF
        application/pdf)
            pdftoppm -f 1 -l 1 \
                    -scale-to-x "${default_size%x*}" \
                    -scale-to-y -1 \
                    -singlefile \
                    -jpeg -tiffcompression jpeg \
                    -- "${path}" "${cached%.*}" \
                && exit 6 || exit 1;;
        # Image previews for image files. w3mimgdisplay will be called for all
        # image files (unless overriden as above), but might fail for
        # unsupported types.
        image/*)
            local orientation
            orientation="$( identify -format '%[EXIF:Orientation]\n' -- "${path}" )"
            ## If orientation data is present and the image actually
            ## needs rotating ("1" means no rotation)...
            if [[ -n "$orientation" && "$orientation" != 1 ]]; then
                ## ...auto-rotate the image according to the EXIF data.
                convert -- "${path}" -auto-orient "${cached}" && exit 6
            fi


            exit 7;;
        # Image preview for video
        audio/*)
            # Get embedded thumbnail
            ffmpeg -i "${path}" -map 0:v -map -0:V -c copy "${cached}" && exit 6;;
        video/*)
            # Get embedded thumbnail
            ffmpeg -i "${path}" -map 0:v -map -0:V -c copy "${cached}" && exit 6
            # Get frame 10% into video
            ffmpegthumbnailer -i "${path}" -o "${cached}" -s 0 && exit 6
            exit 1;;
    esac

    case "$extension" in
        exe)
            wrestool -x -t 14 "$path" -o "$cached"
            if [ -e "$cached" ]; then
                exit 6
            fi
    esac
fi

case "$extension" in
    # Archive extensions:
    a|ace|alz|arc|arj|bz|bz2|cab|cpio|deb|gz|jar|lha|lz|lzh|lzma|lzo|\
    rpm|rz|t7z|tar|tbz|tbz2|tgz|tlz|txz|tZ|tzo|war|xpi|xz|Z|zip)
        try als "$path" && { dump | trim; exit 0; }
        try acat "$path" && { dump | trim; exit 3; }
        try bsdtar -lf "$path" && { dump | trim; exit 0; }
        exit 1;;
    rar)
        # avoid password prompt by providing empty password
        try unrar -p- lt "$path" && { dump | trim; exit 0; } || exit 1;;
    7z)
        # avoid password prompt by providing empty password
        try 7z -p l "$path" && { dump | trim; exit 0; } || exit 1;;
    # PDF documents:
    pdf)
        try pdftotext -l 10 -nopgbrk -q "$path" - && \
            { dump | trim | fmt -s -w $width; exit 0; } || exit 1;;
    json)
        safepipe jq --color-output . "$path" | trim && exit 5;;
   # BitTorrent Files
    torrent)
        try transmission-show "$path" && { dump | trim; exit 5; } || exit 1;;
    # ODT Files
    odt|ods|odp|sxw)
        try odt2txt "$path" && { dump | trim; exit 5; } || exit 1;;
    # HTML Pages:
    htm|html|xhtml)
        try w3m    -dump "$path" && { dump | trim | fmt -s -w $width; exit 4; }
        try lynx   -dump "$path" && { dump | trim | fmt -s -w $width; exit 4; }
        try elinks -dump "$path" && { dump | trim | fmt -s -w $width; exit 4; }
        ;; # fall back to highlight/cat if the text browsers fail
esac

case "$mimetype" in
    ## RTF and DOC
    text/rtf|*msword|*/wps-office.doc)
        ## Preview as text conversion
        ## note: catdoc does not always work for .doc files
        ## catdoc: http://www.wagner.pp.ru/~vitus/software/catdoc/
        catdoc -- "${path}" && exit 5
        exit 1;;
    application/vnd.efi.*)
        iso-info -i "${path}" && exit 5
        exit 1;;
    ## DOCX, ePub, FB2 (using markdown)
    ## You might want to remove "|epub" and/or "|fb2" below if you have
    ## uncommented other methods to preview those formats
    *wordprocessingml.document|*/epub+zip|*/x-fictionbook+xml|*/wps-office.doc|*/wps-office.docx)
        ## Preview as markdown conversion
        pandoc -s -t markdown -- "${path}" && exit 5
        exit 1;;

    application/octet-stream | application/vnd.microsoft.portable-executable)
        file --dereference --brief -- "${path}" && exit 5
        exit 1;;

    application/x-executable | application/x-pie-executable | application/x-sharedlib)
        readelf -WCa "${path}" && exit 5
        exit 1;;
    text/* | application/*)
        echo "mimetype: $mimetype file_mimetype: $default_mimetype extension: $extension"
        if [[ "$default_mimetype" =~ .*/xml ]]; then
            cat "$path" | xmllint - --format --output - && { dump | trim; exit 5; }
            exit 1
        elif [[ "$default_mimetype" =~ text/.* ]]; then
            pygmentize_format=terminal
            highlight_format=ansi
            safepipe highlight --out-format=${highlight_format} "$path" && { dump | trim; exit 5; }
            safepipe pygmentize -f ${pygmentize_format} "$path" && { dump | trim; exit 6; }
            exit 2
        fi ;;
    # Ascii-previews of images:
    image/*)
        img2txt --gamma=0.6 --width="$width" "$path" && exit 4 || exit 1;;
    # Display information about media files:
    video/*|audio/*)
        mediainfo "${path}" | trim && exit 5
        exiftool "${path}" | trim && exit 5
        exit 1;;
esac

echo '----- File Type Classification -----' && file --dereference --brief -- "${path}" &&
echo "mimetype: $mimetype file_mimetype: $default_mimetype extension: $extension"
&& exit 5
