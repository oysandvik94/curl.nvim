local M = {}

-- Function to parse variables from the buffer content
function M.parse_variables(content)
    local vars = {}
    for key, value in content:gmatch("{{(.-)}}%s*=%s*(.-)\n") do
        vars[key] = value
    end
    return vars
end

-- Function to replace placeholders in the curl command with variable values
function M.replace_placeholders(content, vars)
    for key, value in pairs(vars) do
        content = content:gsub("{{" .. key .. "}}", value)
    end
    return content
end

return M
