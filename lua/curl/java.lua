local M = {}

---comment
---@param arg_node TSNode
local function parse_annotation_arguments(arg_node, key)
	for node, _ in arg_node:iter_children() do
		if node:type() == "string_literal" then
			return vim.treesitter.get_node_text(node, 0):gsub('"', "")
		end
		if node:type() == "element_value_pair" then
			for pair_node, field in node:iter_children() do
				if field == "key" then
					local key_name = vim.treesitter.get_node_text(pair_node, 0)

					if key_name == key then
						local value_node = pair_node:next_named_sibling()
						local value = vim.treesitter.get_node_text(value_node, 0)
						return value:gsub('"', "")
					end
				end
			end
		end
	end
end

---comment
---@param root_child TSNode
local function parse_parameters(root_child)
	for node, _ in root_child:iter_children() do
		if node:type() == "formal_parameter" then
			local modifiers = node:child(0)
			if modifiers and modifiers:type() == "modifiers" then
				for modifier, _ in modifiers:iter_children() do
					if modifier:type() == "annotation" then
						for foo, field in modifier:iter_children() do
							if field == "arguments" then
								local value = parse_annotation_arguments(foo, "name")
								return value
							end
						end
					end
				end
			end
		end
	end
end

local function parse_http_method(node)
	local name = vim.treesitter.get_node_text(node, 0)
	if name == "GetMapping" then
		return "GET"
	elseif name == "PostMapping" then
		return "POST"
	end
end

---comment
---@param annotation_node TSNode
local function parse_annotation(annotation_node)
	local http_method, path = "", ""
	for node, field in annotation_node:iter_children() do
		if field == "name" then
			http_method = parse_http_method(node)
		end

		if field == "arguments" then
			path = parse_annotation_arguments(node, "path")

			if path == nil then
				path = parse_annotation_arguments(node, "value")
			end
		end
	end

	return http_method, path
end
---comment
---@param method_node TSNode
local function parse_modifiers(method_node)
	for node, _ in method_node:iter_children() do
		if node:type() == "annotation" then
			local method, path = parse_annotation(node)
			return method, path
		end
	end
end
function M.generate_curl_command()
	local ts_utils = require("nvim-treesitter.ts_utils")
	local parser = vim.treesitter.get_parser(0, "java")
	local tree = parser:parse()[1]
	local root = tree:root()

	-- Find the method node at the cursor
	local node = ts_utils.get_node_at_cursor()
	while node ~= nil and node:type() ~= "method_declaration" do
		node = node:parent()
	end

	if not node then
		print("Cursor is not on a method declaration")
		return
	end

	local method_info = {
		http_method = nil,
		path = nil,
		params = {},
		base_path = nil,
	}
	for root_child, _ in node:iter_children() do
		if root_child:type() == "modifiers" then
			local method, path = parse_modifiers(root_child)
			method_info.http_method = method
			method_info.path = path
		elseif root_child:type() == "formal_parameters" then
			local args = parse_parameters(root_child)
			table.insert(method_info.params, args)
		end
	end

	while node ~= nil and node:type() ~= "class_declaration" do
		node = node:parent()
	end

	if not node then
		print("cant find class")
		return
	end

	for root_child, _ in node:iter_children() do
		if root_child:type() == "modifiers" then
			for mod, _ in root_child:iter_children() do
				if mod:type() == "annotation" then
					for ano_node, field in mod:iter_children() do
						if field == "name" then
							local name = vim.treesitter.get_node_text(ano_node, 0)
							if name == "RequestMapping" then
								local arglist = ano_node:next_named_sibling()
								if arglist then
									for x, _ in arglist:iter_children() do
										if x:type() == "string_literal" then
											local base_path = vim.treesitter.get_node_text(x, 0)
											method_info.base_path = base_path:gsub('"', "")
										end
									end
								end
								break
							end
						end
					end
				end
			end
		end
	end

	local full_path = string.format("localhost:8080%s%s", method_info.base_path, method_info.path)

	if #method_info.params > 0 then
		full_path = full_path .. "?"

		local formatted_query_params = {}
		for _, param in ipairs(method_info.params) do
			table.insert(formatted_query_params, param .. "={value}")
		end

		local query_params = vim.fn.join(formatted_query_params, "&")
		full_path = full_path .. query_params
	end

	local base_curl = string.format('curl -X %s "%s"', method_info.http_method, full_path)

	return base_curl
end

return M
