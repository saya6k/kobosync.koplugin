std = "luajit"
max_line_length = 120
unused_args = false

read_globals = {
    "G_reader_settings",
}

files["spec"] = {
    std = "+busted",
}

exclude_files = {
    ".luarocks",
    "dist",
    "tasks",
}
