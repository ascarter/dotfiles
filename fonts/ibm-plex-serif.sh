FONT_REPO=IBM/plex
FONT_ASSET="ibm-plex-serif.zip"
FONT_GLOB="fonts/complete/ttf/*.ttf"
FONT_STRIP_COMPONENTS=1
TOOL_VERSION_MATCH="@([0-9].*)"

font_latest_tag() {
  gh release list --repo IBM/plex --limit 100 \
    --json tagName,isDraft,isPrerelease \
    --jq 'map(select((.isDraft | not) and (.isPrerelease | not) and (.tagName | startswith("@ibm/plex-serif@"))))[0].tagName'
}
