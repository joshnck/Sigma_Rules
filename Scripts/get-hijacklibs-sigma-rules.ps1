# -=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# File: get-hijacklibs-sigma-rules.ps1
# Purpose: Pull all sigma rules from hijack libs and parse them for internal use
# Author: Josh Nickels
# Date: 10/20/22
# -=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

# Pull the content!
$hijacklibs_raw = (Invoke-WebRequest -Uri "https://hijacklibs.net/sigma_feed_image.yml").content

# Split on --- 
$hijacks_parsed = $hijacklibs_raw -split "---"

# For internal use, this is our PySigma appended block
$internal_append_block = 
"<Add your own append block based on your PySigma needs!>"

# GUID to use later
$guid = [guid]::newGUID()

# Now to do some parsing and string manipulation to get things tidy for our PySigma parser
foreach ($sigma_string in $hijacks_parsed) {
    # remove the first new line character
    $sigma_string = $sigma_string.substring(1)

    # We need to adjust it to get the date and change the format and add a new 
    # element for the id: field and generate GUID here
    $sigma_string_tmp = $sigma_string.split([System.Environment]::NewLine)
    try {
        $sigma_string_tmp = {$sigma_string_tmp}.invoke() ## funny trick to convert to a collection :D
        $sigma_string_tmp[6] = "date: 2022/10/20" # TODO: Convert the actual date instead of being lazy
        $sigma_string_tmp.insert(7, "id: $guid")
        $sigma_string_final = ""
        foreach ($substr in $sigma_string_tmp) {
            $sigma_string_final = $sigma_string_final + "`n" + $substr
        } 
    } catch { Write-Output ("end of file")}

    # append our internal SplunkPy stuff
    $sigma_string_final = $sigma_string_final + $internal_append_block
    $sigma_string_final = $sigma_string_final.substring(1) # idk why it adds a newline at the start. I'm dumb

    # do some fuckery to get a file name
    $dll = $sigma_string_tmp[0] -split " "
    $dll = $dll[5]
    $dll = $dll.Substring(0,$dll.Length-4)
    $file_name = "dll_sideloading_of_$dll"

    # output file
    $sigma_string_final | Out-File -FilePath "C:\Users\a0078531\Documents\Git Workspace\testing\$file_name.yml"
}
