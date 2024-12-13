function guess_username()
    local username = "Your Name"

    try
        if Sys.iswindows()
            username = ENV["USERNAME"]
        elseif Sys.isapple()
            username = readchomp(`id -un`)
        elseif Sys.islinux()
            username = readchomp(`whoami`)
        end
    catch end

    return username
end
