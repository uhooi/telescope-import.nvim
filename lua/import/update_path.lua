function update_import_path(import_string, old_file_path, new_file_path)
  local function split(str, sep)
    local fields = {}
    str:gsub("[^" .. sep .. "]+", function(c)
      fields[#fields + 1] = c
    end)
    return fields
  end

  local function resolve_path(base, relative)
    local path_parts = split(base, "/")
    table.remove(path_parts) -- Remove the file part from the path

    for part in relative:gmatch("[^/]+") do
      if part == ".." then
        table.remove(path_parts) -- Go up one directory
      elseif part ~= "." then
        table.insert(path_parts, part) -- Go into a subdirectory
      end
    end

    return table.concat(path_parts, "/")
  end

  local function compute_relative_path(from, to)
    local from_parts = split(from, "/")
    local to_parts = split(to, "/")

    -- Remove the file names
    table.remove(from_parts)
    table.remove(to_parts)

    local common_length = 0
    for i = 1, math.min(#from_parts, #to_parts) do
      if from_parts[i] ~= to_parts[i] then
        break
      end
      common_length = i
    end

    -- Construct the new relative path
    local new_path = ""
    for i = 1, #from_parts - common_length do
      new_path = new_path .. "../"
    end

    for i = common_length + 1, #to_parts do
      new_path = new_path .. to_parts[i] .. "/"
    end

    -- Add the file name from the resolved path
    local resolved_file_name = select(#split(to, "/"), unpack(split(to, "/")))
    new_path = new_path .. resolved_file_name

    return new_path
  end

  -- Resolve the absolute path of the original import
  local resolved_path = resolve_path(old_file_path, import_string)
  -- Compute the new relative path from the new file location
  return compute_relative_path(new_file_path, resolved_path)
end

return update_import_path
