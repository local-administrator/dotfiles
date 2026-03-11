function cbash --description "Safe curl|bash: analyze script with Claude before executing"
    if test (count $argv) -eq 0
        echo "Usage: cbash <url> [curlcheck-options]"
        echo "       cbash https://example.com/install.sh"
        echo "       cbash -y https://example.com/install.sh  # auto-run if low risk"
        return 1
    end

    # Separate the URL (last arg) from any curlcheck flags (earlier args)
    set url $argv[-1]
    set flags $argv[1..-2]

    curl -fsSL $url | ruby ~/.config/fish/curlcheck.rb $flags | bash
end
