std = "luajit"
max_line_length = 120
unused_args = false

read_globals = {
    "G_reader_settings",
}

files["spec"] = {
    std = "+busted",
}

files["l10n"] = {
    -- Translation tables are data: each entry is one string literal that cannot
    -- be wrapped without turning it into a concatenation, which would only make
    -- the files harder to edit.
    max_line_length = false,
}

exclude_files = {
    ".luarocks",
    "dist",
    "tasks",
}
