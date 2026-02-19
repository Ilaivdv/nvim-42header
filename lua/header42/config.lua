local log = require("header42.log")

local M = {}

---@class header42.Config
---@field username string | fun(): string
---@field domain string | fun(): string
---@field email string | fun(username: string, domain: string): string
---@field autocmd { create: boolean, pattern: string[] }
---@field asciiart string[]
---@field commentstrings  { [string]: [string, string, string] }

---@type header42.Config
local default_config = {
  username = function()
    return require("header42.git").username() or os.getenv("USER") or "unknown"
  end,
  domain = "student.codam.nl",
  email = function(username, domain)
    return require("header42.git").email() or os.getenv("MAIL") or username .. "@" .. domain
  end,
  autocmd = {
    create = true,
    pattern = { "*.c", "*.h", "*.cc", "*.hh", "*.cpp", "*.hpp", "*.py" },
  },
  asciiart = {
  	"       ::::::::          ",
    "     :+:    :+:          ",
    "    +:+                  ",
    "   +#+                   ",
    "  +#+                    ",
    "#+#    #+#               ",
    "########   odam.nl       ",
	},
  commentstrings = {
    c = { "/*", "*", "*/" },
    h = { "/*", "*", "*/" },
    cc = { "/*", "*", "*/" },
    hh = { "/*", "*", "*/" },
    cpp = { "/*", "*", "*/" },
    hpp = { "/*", "*", "*/" },
    python = { "#", "#", "#" },
    lua = { "--", "-", "--" },
    fallback = { "#", "*", "#" },
  },
}

--- This function returns the username.
---@param config header42.Config
---@return string
function M.get_username(config)
  local username = config.username

  if type(username) == "string" then
    return username
  end

  return username()
end

--- This function returns the domain.
---@param config header42.Config
---@return string
function M.get_domain(config)
  local domain = config.domain

  if type(domain) == "string" then
    return domain
  end

  return domain()
end

--- This function returns the email address.
---@param config header42.Config
---@return string
function M.get_email(config)
  local email = config.email

  if type(email) == "string" then
    return email
  end

  local username = M.get_username(config)
  local domain = M.get_domain(config)

  return email(username, domain)
end

--- This function validates the fields in the config.
---@param config header42.Config
function M.validate(config)
  vim.validate("username", config.username, { "string", "function" })
  if type(config.username) == "function" then
    vim.validate("username()", config.username(), "string")
  end
  vim.validate("get_username()", M.get_username(config), "string")

  vim.validate("domain", config.domain, { "string", "function" })
  if type(config.domain) == "function" then
    vim.validate("domain()", config.domain(), "string")
  end
  vim.validate("get_domain()", M.get_domain(config), "string")

  vim.validate("email", config.email, { "string", "function" })
  if type(config.email) == "function" then
    vim.validate("email()", config.email(M.get_username(config), M.get_domain(config)), "string")
  end
  vim.validate("get_email()", M.get_email(config), "string")

  vim.validate("autocmd.create", config.autocmd.create, "boolean")
  vim.validate("autocmd.pattern", config.autocmd.pattern, "table")
  vim.validate("asciiart", config.asciiart, "table")
  vim.validate("commentstrings", config.commentstrings, "table")
end

--- This function merges the user config with the default config.
---@param config header42.Config
---@return header42.Config
function M.merge_config(config)
  local merged = vim.tbl_deep_extend("force", default_config, config or {})

  local success, error = pcall(M.validate, merged)
  if not success then
    log.error("Invalid configuration: " .. error)
  end

  return merged
end

--- This function parses the nvim commentstring into three separate strings.
---@param config header42.Config
---@param filetype string
---@return [string, string, string]?
local function parse_nvim_commentstring(config, filetype)
  local commentstring = vim.api.nvim_get_option_value("commentstring", { filetype = filetype })

  if not commentstring:find("%%s") then
    return nil
  end

  local open, close = commentstring:match("(.*)%%s(.*)")
  open = vim.trim(open)
  close = vim.trim(close)

  if close == "" then
    return { open, config.commentstrings.fallback[2], open }
  else
    return { open, config.commentstrings.fallback[2], close }
  end
end

--- This function returns three strings used for commenting the header.
---@param config header42.Config
---@param filetype string
---@return string, string, string
function M.get_commentstring(config, filetype)
  local commentstring = config.commentstrings[filetype]
    or parse_nvim_commentstring(config, filetype)
    or config.commentstrings.fallback

  local open, filler, close = commentstring[1], commentstring[2], commentstring[3]

  if open == nil or filler == nil or close == nil then
    return config.commentstrings.fallback[1], config.commentstrings.fallback[2], config.commentstrings.fallback[3]
  end

  return open, filler, close
end

return M
